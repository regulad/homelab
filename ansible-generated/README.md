# Ansible: generated hosts

Phase 4 of [`.claude/PLAN.md`](../.claude/PLAN.md): the Proxmox guests and OCI
instances that OpenTofu creates or adopts. This stage runs after OpenTofu and
reads **only** `inventory/inventory.py`, built from each root's `ansible_hosts`
output; it never sees the hand-written hardware inventory. Hardware hosts are
configured from [`ansible-hardware/`](../ansible-hardware/README.md).

| Path | Contents |
|---|---|
| `inventory/inventory.py` | Dynamic inventory from OpenTofu outputs; every host joins the `generated` group |
| `inventory/group_vars/`, `inventory/host_vars/<host>/` | Variables, including each host's `services.yml` |
| `playbooks/site.yml` | Imports `base.yml`, then `services.yml` |
| `roles/` | Roles only this stage uses |
| `requirements.yml` | Collections, pinned to exact versions as roles first need them |

| Role | Purpose | Playbook and hosts |
|---|---|---|
| `base` (shared) | Packages, admin user, time sync, and sshd hardening only where it is already policy | `base.yml` (`generated`) |
| `tailscale` (shared) | Tailscale client; joins only when `tailscale_join` is set | `base.yml` (`generated`) |
| `podman` | Podman and its registries | `base.yml` (`podman_hosts`) |
| `avahi` | mDNS reflection between the podman bridge and the LAN | `base.yml` (`podman_hosts`) |
| `quadlet` | Quadlet units rendered from each host's `quadlet_services` | `services.yml` (`podman_hosts`) |

Shared roles live in [`ansible-common/roles/`](../ansible-common/README.md),
which `ansible.cfg` lists after `roles/`. The roles are skeletons: their tasks
land in Phase 4.

## Running

Ansible reads `ansible.cfg` from the current directory, so run from this one.
`inventory.py` runs `tofu output` for each root it lists, so the state backend's
credentials must be in the environment: source `tofu/oracle/prepare.sh` in the
same shell first.

```bash
. tofu/oracle/prepare.sh
cd ansible-generated
ansible-inventory --graph
ansible-playbook playbooks/site.yml --syntax-check
ansible-lint --offline
ansible-playbook playbooks/base.yml --check --diff --limit <host>
```

The script lists no roots yet; each root joins in Phase 4, once it exports
`ansible_hosts`. A root that cannot be read fails the whole inventory, because
`ansible.cfg` sets `any_unparsed_is_failed`.
