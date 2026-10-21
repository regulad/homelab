#!/usr/bin/python
# Copyright: Parker Wahle
# AGPL-3.0
"""Converge an already-joined Tailscale node's tags check, settings and Serve."""

DOCUMENTATION = r"""
module: tailscale_node
short_description: Converge a joined Tailscale node's settings and Serve configuration
description:
  - Reads the node's status, preferences and Serve configuration through the
    tailscale CLI. A node that is not logged in is reported with C(joined=false)
    and left alone, so joining stays an explicit, separate step.
  - On a joined node, fails if its tags differ from O(tags), runs
    C(tailscale set) only for the declared settings that differ, and adds or
    removes only the Serve and Funnel ports that differ. Supports check mode.
options:
  tags:
    description: The node's tags, without the C(tag:) prefix.
    type: list
    elements: str
    required: true
  settings:
    description:
      - Settings to converge, by name; undeclared settings are left alone.
      - accept_dns, accept_routes, advertise_exit_node, auto_update,
        snat_subnet_routes, ssh, shields_up, stateful_filtering (bool);
        hostname, operator (str); relay_server_port (int);
        advertise_routes, relay_server_static_endpoints (list).
    type: dict
    default: {}
  serve:
    description:
      - The complete Serve configuration, a list of HTTPS ports each with a
        target; C(funnel=true) also publishes the port with Funnel. Omit to
        leave Serve alone.
    type: list
    elements: dict
author: Parker Wahle
"""

import json

from ansible.module_utils.basic import AnsibleModule

EXIT_ROUTES = {"0.0.0.0/0", "::/0"}

# setting -> (tailscale set flag, reader of the current value from prefs)
SETTINGS = {
    "accept_dns": ("--accept-dns", lambda p: bool(p.get("CorpDNS"))),
    "accept_routes": ("--accept-routes", lambda p: bool(p.get("RouteAll"))),
    "advertise_exit_node": ("--advertise-exit-node", lambda p: EXIT_ROUTES <= set(p.get("AdvertiseRoutes") or [])),
    "advertise_routes": ("--advertise-routes", lambda p: sorted(set(p.get("AdvertiseRoutes") or []) - EXIT_ROUTES)),
    "auto_update": ("--auto-update", lambda p: bool((p.get("AutoUpdate") or {}).get("Apply"))),
    "hostname": ("--hostname", lambda p: p.get("Hostname") or ""),
    "operator": ("--operator", lambda p: p.get("OperatorUser") or ""),
    "relay_server_port": ("--relay-server-port", lambda p: p.get("RelayServerPort")),
    "relay_server_static_endpoints": ("--relay-server-static-endpoints", lambda p: sorted(p.get("RelayServerStaticEndpoints") or [])),
    "shields_up": ("--shields-up", lambda p: bool(p.get("ShieldsUp"))),
    "snat_subnet_routes": ("--snat-subnet-routes", lambda p: not p.get("NoSNAT")),
    "ssh": ("--ssh", lambda p: bool(p.get("RunSSH"))),
    "stateful_filtering": ("--stateful-filtering", lambda p: not p.get("NoStatefulFiltering")),
}


def normalize(name, value):
    if name in ("advertise_routes", "relay_server_static_endpoints"):
        return sorted(value or [])
    if name == "relay_server_port":
        return None if value in (None, "") else int(value)
    if name in ("hostname", "operator"):
        return value or ""
    return bool(value)


def render(name, value):
    if isinstance(value, list):
        return ",".join(value)
    if isinstance(value, bool):
        return "true" if value else "false"
    return "" if value is None else str(value)


def run_json(module, args):
    rc, out, err = module.run_command(args)
    if rc != 0:
        module.fail_json(msg="%s failed: %s" % (" ".join(args), err.strip() or out.strip()))
    text = out[out.find("{"):] if "{" in out else "{}"
    return json.loads(text)


def current_serve(status):
    """Map HTTPS port -> (target, funnel) from `tailscale serve status --json`."""
    funnel = {k.rsplit(":", 1)[-1] for k, v in (status.get("AllowFunnel") or {}).items() if v}
    ports = {}
    for hostport, web in (status.get("Web") or {}).items():
        port = hostport.rsplit(":", 1)[-1]
        handler = (web.get("Handlers") or {}).get("/") or {}
        target = handler.get("Proxy") or handler.get("Path") or handler.get("Text")
        ports[port] = (target, port in funnel)
    return ports


def main():
    module = AnsibleModule(
        argument_spec=dict(
            tags=dict(type="list", elements="str", required=True),
            settings=dict(type="dict", default={}),
            serve=dict(type="list", elements="dict"),
        ),
        supports_check_mode=True,
    )
    tailscale = module.get_bin_path("tailscale", required=True)
    status = run_json(module, [tailscale, "status", "--json", "--self", "--peers=false"])
    if status.get("BackendState") != "Running":
        module.exit_json(changed=False, joined=False, backend_state=status.get("BackendState"))

    tags = sorted(t.replace("tag:", "") for t in ((status.get("Self") or {}).get("Tags") or []))
    if tags != sorted(module.params["tags"]):
        module.fail_json(msg="The node's tags %s differ from the declared %s; fix them in the admin console or re-join deliberately." % (tags, sorted(module.params["tags"])))

    prefs = run_json(module, [tailscale, "debug", "prefs"])
    unknown = set(module.params["settings"]) - set(SETTINGS)
    if unknown:
        module.fail_json(msg="Unknown settings: %s" % ", ".join(sorted(unknown)))
    before, after, flags = {}, {}, []
    for name, value in module.params["settings"].items():
        flag, read = SETTINGS[name]
        want, have = normalize(name, value), normalize(name, read(prefs))
        if want != have:
            before[name], after[name] = have, want
            flags.append("%s=%s" % (flag, render(name, want)))

    serve_cmds = []
    if module.params["serve"] is not None:
        have = current_serve(run_json(module, [tailscale, "serve", "status", "--json"]))
        want = {str(e["port"]): (e["target"], bool(e.get("funnel", False))) for e in module.params["serve"]}
        for port in sorted(set(have) - set(want)):
            serve_cmds.append([tailscale, "funnel" if have[port][1] else "serve", "--https=%s" % port, "off"])
        for port, (target, funnel) in sorted(want.items()):
            if have.get(port) != (target, funnel):
                if port in have:
                    serve_cmds.append([tailscale, "funnel" if have[port][1] else "serve", "--https=%s" % port, "off"])
                serve_cmds.append([tailscale, "funnel" if funnel else "serve", "--bg", "--https=%s" % port, target])
        if serve_cmds:
            before["serve"] = {p: list(v) for p, v in sorted(have.items())}
            after["serve"] = {p: list(v) for p, v in sorted(want.items())}

    changed = bool(flags or serve_cmds)
    if changed and not module.check_mode:
        if flags:
            rc, out, err = module.run_command([tailscale, "set"] + flags)
            if rc != 0:
                module.fail_json(msg="tailscale set failed: %s" % (err.strip() or out.strip()))
        for cmd in serve_cmds:
            rc, out, err = module.run_command(cmd)
            if rc != 0:
                module.fail_json(msg="%s failed: %s" % (" ".join(cmd[1:]), err.strip() or out.strip()))
    module.exit_json(changed=changed, joined=True, set_flags=flags,
                     diff=dict(before=json.dumps(before, indent=2, sort_keys=True) + "\n",
                               after=json.dumps(after, indent=2, sort_keys=True) + "\n"))


if __name__ == "__main__":
    main()
