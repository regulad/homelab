# Plan: migrate pet containers to IaC

Replace hand-configured "pet" containers with declarative, relocatable services
across a home Proxmox cluster and an OCI tenancy. This file holds the goals, the
phases, and each phase's current status. The rules agents follow, the model
architecture, and the conventions are in [`AGENTS.md`](../AGENTS.md).

Two neighbouring areas are already declarative in their own repositories and stay
out of this one: the tailnet's ACL policy and DNS in
[`regulad/tailscale-acls`](https://github.com/regulad/tailscale-acls), and
workstation configuration in [`regulad/dotfiles`](https://github.com/regulad/dotfiles).

Ansible runs in two phases, one on each side of OpenTofu:
- **Hardware hosts** are the machines OpenTofu cannot create, such as the
  Proxmox nodes. They come first, from an inventory written by hand.
- **Generated hosts** are the machines OpenTofu creates or adopts: Proxmox
  guests and OCI instances. They come after it, from an inventory built from
  OpenTofu's outputs.

## Status

| Phase | Status |
|---|---|
| 0. Scaffold and tooling | Partly done. Ignore rules, SOPS, license, OCI version pins, pre-commit (file hygiene, OpenTofu, privacy guards), and the Ansible scaffold for both stages are in place. Pinned Python tooling, the Ansible lint hooks, and runbooks remain. |
| 1. Discovery | OCI done, with snapshots kept locally. Proxmox, hardware hosts, cluster and Ceph settings, and the per-host service inventory are not started. |
| 2. Ansible: hardware hosts | Started: `hardware.yml` lists the initial hardware hosts, seeded from the operator's SSH configuration. The roles are skeletons, and the network switch scripts are not started. |
| 3. OpenTofu | OCI done: the agreed scope (74 resources) is adopted in `tofu/oracle`, its plan is a no-op, and state is remote in the `homelab-tofu-state` bucket that `tofu/oracle` manages. Proxmox guests and cluster settings are not started. |
| 4. Ansible: generated hosts | Not started. |
| 5. Portability proof | Not started. |
| 6. Drift and CI (optional) | Not started. |

Each phase ends with its acceptance criteria met and a check-in with Parker. Do
not start the next phase without it. The OCI part of Phase 3 was done before this
order was set; it depends on nothing in Phase 2. Commit, and open a PR, only when
Parker asks.

## Goal and non-goals

**Goal**
- Machines (Proxmox LXC/VM, OCI instances) are declared in **OpenTofu** and tracked in state.
- Proxmox cluster-wide and Ceph cluster-wide settings are declared here too: in **OpenTofu** where the `bpg/proxmox` provider supports a setting, otherwise applied to the nodes by **Ansible**.
- Host configuration (podman, the Tailscale client, Avahi, service definitions) is applied by **Ansible**: on hardware hosts from a hand-written inventory, and on generated hosts from an inventory built from OpenTofu outputs.
- Network switch configuration is applied by the repository's own **bash scripts**, because the switches cannot run Ansible's modules.
- Each containerized service is a **Podman Quadlet** (systemd-native), rendered from data, so moving a service between hosts is a `host_vars` edit plus a playbook run.
- Existing infrastructure is **adopted** (imported), not recreated.

**Non-goals (for now)**
- Kubernetes, Nix/NixOS, Flux/Argo, or any GitOps controller.
- Migrating data inside containers automatically. Parker plans data movement per service.
- CI/drift automation (optional Phase 6).
- The VMware guests on `turk`, which runs VMware so its Windows guests get hardware-accelerated graphics. Bringing them into OpenTofu is a far-future addition; `turk` itself is a hardware host.

## Inputs from Parker

| Needed by | Input | Status |
|---|---|---|
| Phase 0 | `age` public key(s) for `.sops.yaml` | Provided |
| Phase 0 | Python/tool manager | `uv` |
| Phase 1 | OCI access | Provided: Parker's session token in the `DEFAULT` profile |
| Phase 1 | SSH access from the operator machine to Proxmox nodes and guests over the tailnet; a read-only Proxmox API token (`PVEAuditor`) | Needed |
| Phase 2 | Confirmation of an out-of-band path (LAN/console) to every Proxmox node and network switch before any cluster firewall, network, Ceph, or switch change | Needed |
| Phase 3 | Remote state backend choice and credentials | Provided: OCI Object Storage through the s3 backend, with `svc-tofu-state`'s key in `tofu/oracle/backend.sops.env` |
| Phase 3 | A scoped Proxmox API token/role for management (Parker creates it) | Needed |
| Phase 3 | A Proxmox API token/role with the privileges cluster-wide settings need (Parker creates it) | Needed |
| Phase 6 | A non-expiring OCI credential (API-key user or instance principal) | Needed |

## Phases

### Phase 0 — Scaffold and tooling
- Create the tree from the model architecture in `AGENTS.md`, with placeholder READMEs.
- `.gitignore` first, then `.sops.yaml`, pre-commit config, `ansible.cfg` (inventory = `ansible/inventory`, `roles_path = ansible/roles`, `collections_path = ansible/collections`).
- Pin tooling: OpenTofu in each root's `versions.tf`; Python dependencies for `ansible-core` and `ansible-lint` through `uv`. Parker installs tools.
- **Accept:** `pre-commit run --all-files` passes; `git status` shows no ignored-class files tracked.
- **Remaining:** `uv`-managed Python dependencies, `ansible-lint` and `yamllint` hooks, and `docs/runbooks/`. The Ansible tree, `ansible.cfg`, both inventories, the stage playbooks, and skeleton roles exist; `ansible-lint` passes on them.

### Phase 1 — Read-only discovery snapshot
Record what actually exists under `docs/snapshot/`. It is gitignored and stays on
the operator's machine; only configuration derived from it is committed. Never
modify anything.
- Proxmox (run on a node, read-only):
  ```bash
  pvesh get /cluster/resources --type vm --output-format json
  pct config <vmid>
  qm config <vmid>
  pvesh get /nodes/<node>/storage --output-format json
  ```
- Hardware hosts: every physical machine, Proxmox nodes and any others, with its role and tailnet name. Network switches too, with their running configuration captured read-only over SSH.
- Cluster-wide settings, read-only:
  - Proxmox: datacenter options, cluster firewall, HA groups and resources, storage definitions, SDN, users/groups/roles/ACLs, and backup and replication jobs.
  - Ceph: `ceph config dump`, pools, CRUSH rules, and monitor/manager/MDS layout.
  - For each setting, verify whether `bpg/proxmox` manages it, and record its owner: OpenTofu (Phase 3) if it does, Ansible on the nodes (Phase 2) if not.
- Per hardware host and per guest (over SSH): OS release, `podman ps -a --format json`, `podman inspect` of each container, `podman network ls`/`inspect`, `systemctl list-units --state=running`, Avahi config (`/etc/avahi/avahi-daemon.conf`), `tailscale status --json`, listening ports, mounts/volumes.
- Compose files / `podman run` histories where they exist.
- OCI (read-only): compartments, instances, VCNs, subnets, security lists/NSGs, volumes, reserved IPs.
- Produce `docs/snapshot/SUMMARY.md`:
  - one table per host, hardware or guest: guest ID, role, containers, volumes, ports, networks, tailnet name;
  - one table of cluster and Ceph settings with their owners;
  - an **Open questions** list.
- **Accept:** Parker has reviewed `SUMMARY.md` and answered the open questions. This review gates Phases 2 and 3.
- **Remaining:** Proxmox cluster, hardware-host, settings, and guest discovery and the per-host service inventory, then review with Parker.

### Phase 2 — Ansible: hardware hosts (manual inventory)
Hardware hosts change only when hardware does, so their inventory is written by
hand and committed.
- Static inventory `ansible/inventory/hardware.yml` matching the snapshot. Hosts are listed by tailnet MagicDNS name, in groups such as `hardware` and `proxmox_nodes`.
- Roles:
  - `base`: packages, admin user, sshd hardening only if already the current policy, time sync.
  - `tailscale`: install and enable; join logic gated on a variable so existing members are untouched.
  - A host takes only the roles its discovery calls for. These roles are reused for generated hosts in Phase 4.
- Cluster and Ceph settings that Phase 1 assigned to Ansible are applied on the nodes with idempotent tasks, in the `proxmox_cluster` role.
  - Adopt the current values first, with **no changes**: a `changed=0` check run.
  - Change settings only afterwards, each diff reviewed line by line by Parker.
  - **Check-only until Parker confirms** a LAN/console path to every node. Firewall, network, and Ceph changes can lock out a node, interrupt the cluster, or start data movement.
- Run against **one** node first: `ansible-playbook ansible/playbooks/hardware.yml --check --diff --limit <node>`.
- **Accept:**
  - Parker has reviewed the `--check --diff` output.
  - After an approved real run, a **second run reports `changed=0`** (idempotency).
  - Every Ansible-owned cluster and Ceph setting is captured as code.
  - No service restarted unexpectedly.

**Network switches (outside Ansible)**
The two Cisco SG300 switches and the Arista 7010T run no Python, so Ansible's
usual modules cannot manage them. They stay out of the Ansible inventory, and the
repository's own bash scripts manage them over SSH instead.
- The scripts connect through the operator's SSH configuration, which holds each switch's address, its user, and the legacy algorithms the SG300s need.
- Capture each switch's running configuration read-only into `docs/snapshot/` first. Raw configurations can hold secrets such as password hashes, so only configuration derived from them is committed, with sensitive values in SOPS.
- Adopt first: the scripts reproduce each switch's current configuration with **no diff**. Change settings only afterwards, each diff reviewed line by line by Parker.
- **Read-only until Parker confirms** a console path to each switch. A bad change can cut off a switch's management address or the hosts behind it.
- **Accept:** for every switch, the configuration the scripts produce matches the running configuration, and Parker has reviewed both.

### Phase 3 — OpenTofu
OpenTofu declares the machines, and the cluster settings its providers support.
Each root keeps its state in the shared `homelab-tofu-state` bucket, under its own
key and with its own enforced encryption passphrase, before any import.

#### OCI (`tofu/oracle`): done
- **Scope:** compute instances and boot volumes, VCN networking (VCNs, subnets, gateways, route tables, security lists, DHCP options), NSGs, and Email Delivery (domain, senders, DKIM, `svc-mail` policy). Out of scope: identity-domain apps/users/groups, Oracle-created policies and tag defaults, `ManagedCompartmentForPaaS`, the OS Management Hub profile, the DNS resolvers/views/private zones VCNs create automatically, and boot-volume backups themselves (data, not configuration).
- Inventory with the read-only `oci` CLI, then adopt in `tofu/oracle` through `import {}` blocks and `tofu plan -generate-config-out`. `oracle/oci` is published on the OpenTofu registry. Refactor the generated configuration into readable HCL (`AGENTS.md` conventions).
- Reconcile until `tofu plan` is a no-op.
- **Accept:** `tofu plan` is a no-op, and no plan showed a destroy or replace.
- **Note:** the adopted boot volumes are not a from-scratch recreation recipe: creating a new volume needs a separately reviewed source. The state bucket and its service user live in `tofu/oracle`'s `state-backend` module.

#### Proxmox guests (`tofu/proxmox`)
- `tofu/proxmox`: `versions.tf` (pin `bpg/proxmox`), `providers.tf`, `state.tf` (backend and encryption, as in `tofu/oracle`), `variables.tf`, `main.tf`, `outputs.tf`, and readable HCL following the conventions in `AGENTS.md`.
- Auth: API token via environment variables only; SSH for the provider via ssh-agent.
- Adoption:
  1. Generate one `import {}` block per guest. Draft (verify the ID format and resource names against the provider docs first):
     ```bash
     pvesh get /cluster/resources --type vm --output-format json | jq -r '.[] | select(.template==0) | "import {\n  to = proxmox_virtual_environment_\(if .type=="lxc" then "container" else "vm" end).g\(.vmid)\n  id = \"\(.node)/\(.vmid)\"\n}\n"' > tofu/proxmox/imports.tf
     ```
  2. `tofu -chdir=tofu/proxmox plan -generate-config-out=generated.tf` (the target file must not already exist; the output format is not stable across versions).
  3. Refactor `generated.tf` into readable resources and the `lxc-guest`/`vm-guest` modules: remove computed attributes and plaintext secrets, and keep names stable.
  4. Iterate until `tofu plan` shows **no changes**. Add `lifecycle { ignore_changes = [...] }` only where justified (e.g., HA-managed guests that may migrate between nodes) and comment why.
  5. Remove the `import` blocks after the Parker-approved apply that records them.
- **Accept:** `tofu plan` is a no-op; no `destroy`/`replace` appeared in any reviewed plan; the lock file is committed; state is in the remote bucket.

#### Proxmox and Ceph cluster settings (highest outage risk)
- Adopt the settings Phase 1 assigned to OpenTofu in `tofu/proxmox`, with `import {}` blocks.
- Adopt the current values first, with **no changes**: a no-op plan. Change settings only afterwards, each diff reviewed line by line by Parker.
- **Plan-only until Parker confirms** a LAN/console path to every node, as in Phase 2.
- **Accept:** every OpenTofu-owned cluster and Ceph setting is captured as code, and the plan is a no-op.

### Phase 4 — Ansible: generated hosts (OpenTofu-fed inventory)
Generated hosts appear in and disappear from Ansible with their OpenTofu
resources, without a manual inventory edit.

**Inventory handoff**
- Each root exports the same output shape:
  ```hcl
  output "ansible_hosts" {
    value = {
      for name, g in local.guests : name => {
        address = g.tailnet_name   # MagicDNS name, so it works from the laptop
        groups  = g.groups         # e.g. ["podman_hosts", "proxmox_guests"]
      }
    }
  }
  ```
- `ansible/inventory/inventory.py`: executable dynamic inventory.
  - For each root, run `tofu -chdir=<root> output -json ansible_hosts`; merge; emit Ansible's `--list` JSON including `_meta.hostvars`; support `--host`. Every host also joins a `generated` group, mirroring `hardware`.
  - Reading outputs needs the backend credentials that sourcing `prepare.sh` exports, in the control node's environment.
  - Cache nothing; fail loudly if a root is unreadable.
- It sits beside `hardware.yml` in `ansible/inventory/`, so one inventory covers hardware and generated hosts.
- Keep the inventory **minimal** (name, address, groups). Services and other variables stay in `host_vars/` in git.
- `tofu/oracle` gets its `ansible_hosts` output here, once host identities are chosen.
- Optional later: the Ansible Terraform provider (`ansible_host`/`ansible_group` resources) with the `cloud.terraform.terraform_provider` inventory plugin (requires initialized roots; shells out to a `terraform` binary, so verify `tofu` compatibility).
- **Accept:** `ansible-inventory --graph` shows every hardware and generated host in its expected groups; `ansible all -m ping` succeeds over the tailnet from the laptop.

**Baseline (non-destructive)**
- cloud-init, set by OpenTofu, did only the minimal bootstrap; Ansible owns everything inside a guest after it.
- Roles, reusing Phase 2's `base` and `tailscale`:
  - `podman`: install podman; configure registries; enable `podman.socket` only if currently used.
  - `avahi`: template `avahi-daemon.conf` (`enable-reflector=yes`, `allow-interfaces=` the podman bridge + LAN interface, as discovered). Pin the podman network subnet/bridge name so this is deterministic.
- Run against **one** low-risk guest first: `ansible-playbook ansible/playbooks/base.yml --check --diff --limit <host>`.
- **Accept:** Parker has reviewed the `--check --diff` output; after an approved real run, a **second run reports `changed=0`** (idempotency); no service restarted unexpectedly.

**Quadlet service model**
- Convert the first low-stakes service with `podlet` (compose or `podman run` input), then review and hand-edit the output.
- Implement the data-driven `quadlet` role, fed by each host's `quadlet_services`. Schema (per host):
  ```yaml
  # ansible/inventory/host_vars/<host>/services.yml
  quadlet_services:
    - name: example
      image: registry.example/app:1.2.3     # pinned tag, no :latest
      ports: ["8080:8080"]
      volumes: ["example-data:/data"]
      networks: [svcnet]
      env_file: example.env                 # secret file, sops-encrypted
      state: present                        # present | absent
  ```
- The role templates `.container`, `.volume`, `.network` into `/etc/containers/systemd/`, notifies a `systemctl daemon-reload` handler, and enables/starts the generated unit. `state: absent` removes the unit.
- Migrate one service **side by side**: stand up the Quadlet version on a spare port or host, verify, cut over, and only then retire the old container (Parker approves the removal).
- **Accept:** the service runs as a systemd-managed Quadlet; a restart/reboot test passes; data persists; the old container is retired only after Parker signs off; a second playbook run is idempotent.

### Phase 5 — Portability proof
- Pick one stateless-ish service. Move it by deleting its entry from host A's `services.yml`, adding it to host B (including an OCI host), and running `services.yml` for both with `--check` first.
- Document, per service, a data strategy (restic restore, shared mount, or stateless) in `docs/runbooks/move-a-service.md`.
- **Accept:** the service runs on host B, is gone from host A, and the runbook reflects exactly what was done.

### Phase 6 — Optional: drift and CI
- Scheduled `tofu plan -detailed-exitcode` and `ansible-playbook --check` (hardware and generated hosts) from a runner on the tailnet, alerting on drift. Plans only; never auto-apply.
- Needs a non-expiring OCI credential, because the current session token lasts at most 24 hours. It also needs the state backend's key.

## Known uncertainties (verify, do not assume)
- bpg/proxmox: current resource type names and the import ID format (believed `node/vmid`; resource naming has been shifting). The provider uses SSH for some actions; HA-managed guests can migrate without the provider knowing.
- bpg/proxmox coverage of cluster-wide settings (datacenter options, firewall, HA, storage, SDN, access control, backup and replication jobs) and whether it covers any Ceph configuration; verify each before choosing between OpenTofu and Ansible.
- `-generate-config-out`: documented as potentially changing output format between minor versions; no config generation for `for_each` imports; may emit plaintext secrets.
- `cloud.terraform` inventory plugins: `terraform_state` supports only AWS/Azure/GCP per its docs; `terraform_provider` needs initialized project dirs; `tofu` binary support unconfirmed.
- Podman-in-LXC: requires `nesting=1` (sometimes `keyctl=1`); rootless inside unprivileged LXC can be fiddly with subuid/subgid ranges.
- Third-party MCP server `mcp-proxmox` (`proxmox_generate_terraform`) is unevaluated and includes mutating operations; use it only with a read-only token and after reading its source.

## Risks and rollback

| Risk | Mitigation / rollback |
|---|---|
| State loss | Client-side encrypted state in a versioned bucket with S3-native locking; the encryption passphrase in SOPS and the age identity kept safe off-repo |
| Import produces a plan that wants to replace a guest | Stop; adjust config (not the guest) until the plan is a no-op; ask Parker |
| Bad Ansible change on a prod host | `--check --diff` first, `--limit` to one host, keep the old container until verified |
| A cluster firewall, network, or Ceph change locks out a node, interrupts the cluster, or starts data movement | Adopt current values with no changes first; plan-only and check-only without approval; keep the LAN/console path; Parker reviews every diff line by line |
| Secrets leak | `.gitignore` and privacy pre-commit hooks; SOPS only |
| Quadlet migration data loss | Side-by-side migration; snapshot/backup before cutover; Parker approves old-container removal |

## Definition of done
- Every hardware host is in the hand-written inventory, and its playbook run reports `changed=0`.
- Every network switch's running configuration is reproduced by the repository's scripts with no diff.
- Every in-scope guest is in OpenTofu state with a **no-op plan** in both provider roots (`tofu/oracle`, `tofu/proxmox`).
- Every in-scope Proxmox and Ceph cluster-wide setting is captured as code, with a no-op plan and a `changed=0` check run.
- The generated hosts' inventory is built from OpenTofu outputs, with services defined only in `host_vars/`.
- Every in-scope container runs as a pinned, Ansible-rendered Quadlet; a second playbook run reports no changes.
- At least one service has been moved between hosts by changing data only, with a written runbook.
- No secrets, state, or generated state files in git history.
