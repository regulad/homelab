# Plan: migrate pet containers to IaC

Replace hand-configured "pet" containers with declarative, relocatable services
across a home Proxmox cluster and an OCI tenancy. This file holds the goals, the
phases, and each phase's current status. The rules agents follow, the model
architecture, and the conventions are in [`AGENTS.md`](../AGENTS.md).

## Status

| Phase | Status |
|---|---|
| 0. Scaffold and tooling | Partly done. Ignore rules, SOPS, license, OCI version pins, and pre-commit (file hygiene, OpenTofu, privacy guards) are in place. The Ansible scaffold and pinned Python tooling remain. |
| 1. Discovery | OCI done, with snapshots kept locally. Proxmox and the per-host service inventory are not started. |
| 2. Ansible baseline | Not started. |
| 3. Quadlet services | Not started. |
| 4. Proxmox OpenTofu | Not started. |
| 5. OCI OpenTofu | Done: the agreed scope (74 resources) is adopted in `tofu/oracle`, and its plan is a no-op. Remote state is deferred. |
| 6. Tailnet | Not started. |
| 7. Inventory handoff | Not started. |
| 8. Portability proof | Not started. |
| 9. Drift and CI (optional) | Not started. |

Each phase ends with its acceptance criteria met and a check-in with Parker. Do
not start the next phase without it. Commit, and open a PR, only when Parker asks.

## Goal and non-goals

**Goal**
- Machines (Proxmox LXC/VM, OCI instances, tailnet keys/ACLs) are declared in **OpenTofu** and tracked in state.
- Host configuration (podman, Tailscale, Avahi, service definitions) is applied by **Ansible**.
- Each containerized service is a **Podman Quadlet** (systemd-native), rendered from data, so moving a service between hosts is a `host_vars` edit plus a playbook run.
- Existing infrastructure is **adopted** (imported), not recreated.

**Non-goals (for now)**
- Kubernetes, Nix/NixOS, Flux/Argo, or any GitOps controller.
- Managing Proxmox/Ceph cluster-level settings (not supported by the `bpg/proxmox` provider).
- Migrating data inside containers automatically. Parker plans data movement per service.
- CI/drift automation (optional Phase 9).

## Inputs from Parker

| Needed by | Input | Status |
|---|---|---|
| Phase 0 | `age` public key(s) for `.sops.yaml` | Provided |
| Phase 0 | Python/tool manager | `uv` |
| Phase 1 | OCI access | Provided: Parker's session token in the `DEFAULT` profile |
| Phase 1 | SSH access from the operator machine to Proxmox nodes and guests over the tailnet; a read-only Proxmox API token (`PVEAuditor`) | Needed |
| Phase 4 | Remote state backend choice and credentials (S3-compatible, e.g. OCI Object Storage or MinIO); state-encryption passphrase handling | Deferred until the rest of the repository is ready |
| Phase 4 | A scoped Proxmox API token/role for management (Parker creates it) | Needed |
| Phase 6 | Confirmation of an out-of-band path (LAN/console) to every Proxmox node before touching tailnet ACLs | Needed |
| Phase 9 | A non-expiring OCI credential (API-key user or instance principal) | Needed |

## Phases

### Phase 0 — Scaffold and tooling
- Create the tree from the model architecture in `AGENTS.md`, with placeholder READMEs.
- `.gitignore` first, then `.sops.yaml`, pre-commit config, `ansible.cfg` (inventory = `ansible/inventory`, `roles_path = ansible/roles`, `collections_path = ansible/collections`).
- Pin tooling: OpenTofu in each root's `versions.tf`; Python dependencies for `ansible-core` and `ansible-lint` through `uv`. Parker installs tools.
- **Accept:** `pre-commit run --all-files` passes; `git status` shows no ignored-class files tracked.
- **Remaining:** the Ansible tree and `ansible.cfg`, `uv`-managed Python dependencies, `ansible-lint` and `yamllint` hooks, and `docs/runbooks/`.

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
- Per guest (over SSH): OS release, `podman ps -a --format json`, `podman inspect` of each container, `podman network ls`/`inspect`, `systemctl list-units --state=running`, Avahi config (`/etc/avahi/avahi-daemon.conf`), `tailscale status --json`, listening ports, mounts/volumes.
- Compose files / `podman run` histories where they exist.
- OCI (read-only): compartments, instances, VCNs, subnets, security lists/NSGs, volumes, reserved IPs.
- Produce `docs/snapshot/SUMMARY.md`: one table per host (guest ID, role, containers, volumes, ports, networks, tailnet name) and an **Open questions** list.
- **Accept:** Parker has reviewed `SUMMARY.md` and answered the open questions. This review gates the adoption phases.
- **Remaining:** Proxmox cluster and guest discovery and the per-host service inventory, then review with Parker.

### Phase 2 — Ansible baseline (non-destructive)
- Static inventory first (`inventory/hosts.yml`) matching the snapshot; groups: `podman_hosts`, `proxmox`, `oracle`.
- Roles:
  - `base`: packages, admin user, sshd hardening only if already the current policy, time sync.
  - `podman`: install podman; configure registries; enable `podman.socket` only if currently used.
  - `tailscale`: install and enable; join logic gated on a variable so existing members are untouched.
  - `avahi`: template `avahi-daemon.conf` (`enable-reflector=yes`, `allow-interfaces=` the podman bridge + LAN interface, as discovered). Pin the podman network subnet/bridge name so this is deterministic.
- Run against **one** low-risk host first: `ansible-playbook ansible/playbooks/base.yml --check --diff --limit <host>`.
- **Accept:** Parker has reviewed the `--check --diff` output; after an approved real run, a **second run reports `changed=0`** (idempotency); no service restarted unexpectedly.

### Phase 3 — Quadlet service model
- Convert the first low-stakes service with `podlet` (compose or `podman run` input), then review and hand-edit the output.
- Implement `quadlet_services` as a data-driven role. Schema (per host):
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

### Phase 4 — OpenTofu: adopt Proxmox guests
- `tofu/proxmox`: `versions.tf` (pin `bpg/proxmox`), `providers.tf`, `backend.tf`, `variables.tf`, `main.tf`, `outputs.tf`, and readable HCL following the conventions in `AGENTS.md`.
- Enforced OpenTofu state encryption, with the state and its key backed up off-cluster, **before** any import. A remote backend with locking is the target. Parker decides whether Proxmox starts on encrypted local state, as `tofu/oracle` does, until the shared backend migration.
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
- **Accept:** `tofu plan` is a no-op; no `destroy`/`replace` appeared in any reviewed plan; the lock file is committed; state is backed up.

### Phase 5 — OpenTofu: adopt OCI resources
- **Scope:** compute instances and boot volumes, VCN networking (VCNs, subnets, gateways, route tables, security lists, DHCP options), NSGs, and Email Delivery (domain, senders, DKIM, `svc-mail` policy). Out of scope: identity-domain apps/users/groups, Oracle-created policies and tag defaults, `ManagedCompartmentForPaaS`, the OS Management Hub profile, the DNS resolvers/views/private zones VCNs create automatically, and boot-volume backups themselves (data, not configuration).
- Inventory with the read-only `oci` CLI, then adopt in `tofu/oracle` through `import {}` blocks and `tofu plan -generate-config-out`. `oracle/oci` is published on the OpenTofu registry. Refactor the generated configuration into readable HCL (`AGENTS.md` conventions).
- Reconcile until `tofu plan` is a no-op.
- **Accept:** `tofu plan` is a no-op, and no plan showed a destroy or replace.
- **Remaining:** the remote backend with locking, deferred until the rest of the repository is ready. The adopted boot volumes are not a from-scratch recreation recipe: creating a new volume needs a separately reviewed source.

### Phase 6 — OpenTofu: tailnet (highest lockout risk)
- Separate root `tofu/tailnet`. **Plan-only until Parker confirms** a LAN/console path to every Proxmox node.
- Import the current ACL policy first (no changes). Add tagged, pre-authorized key generation for new guests only afterward.
- Any ACL diff goes to Parker for line-by-line review before apply.
- **Accept:** the current policy is imported with a no-op plan; key minting works for a test tag.

### Phase 7 — Inventory handoff
- Each root exports the same output shape:
  ```hcl
  output "ansible_hosts" {
    value = {
      for name, g in local.guests : name => {
        address = g.tailnet_name   # MagicDNS name, so it works from the laptop
        groups  = g.groups         # e.g. ["podman_hosts", "proxmox"]
      }
    }
  }
  ```
- `ansible/inventory/inventory.py`: executable dynamic inventory. For each root, run `tofu -chdir=<root> output -json ansible_hosts`; merge; emit Ansible's `--list` JSON including `_meta.hostvars`; support `--host`. Cache nothing; fail loudly if a root is unreadable.
- Keep the inventory **minimal** (name, address, groups). Services and other variables stay in `host_vars/` in git.
- Optional later: the Ansible Terraform provider (`ansible_host`/`ansible_group` resources) with the `cloud.terraform.terraform_provider` inventory plugin (requires initialized roots; shells out to a `terraform` binary, so verify `tofu` compatibility).
- **Accept:** `ansible-inventory --graph` shows every guest in its expected groups; `ansible all -m ping` succeeds over the tailnet from the laptop.
- `tofu/oracle` gets its `ansible_hosts` output once the Ansible phases choose host identities.

### Phase 8 — Portability proof
- Pick one stateless-ish service. Move it by deleting its entry from host A's `services.yml`, adding it to host B (including an OCI host), and running `services.yml` for both with `--check` first.
- Document, per service, a data strategy (restic restore, shared mount, or stateless) in `docs/runbooks/move-a-service.md`.
- **Accept:** the service runs on host B, is gone from host A, and the runbook reflects exactly what was done.

### Phase 9 — Optional: drift and CI
- Scheduled `tofu plan -detailed-exitcode` and `ansible-playbook --check` from a runner on the tailnet, alerting on drift. Plans only; never auto-apply.
- Needs a non-expiring OCI credential; the current session token lasts at most 24 hours.

## Known uncertainties (verify, do not assume)
- bpg/proxmox: current resource type names and the import ID format (believed `node/vmid`; resource naming has been shifting). The provider uses SSH for some actions; HA-managed guests can migrate without the provider knowing.
- `-generate-config-out`: documented as potentially changing output format between minor versions; no config generation for `for_each` imports; may emit plaintext secrets.
- `cloud.terraform` inventory plugins: `terraform_state` supports only AWS/Azure/GCP per its docs; `terraform_provider` needs initialized project dirs; `tofu` binary support unconfirmed.
- Podman-in-LXC: requires `nesting=1` (sometimes `keyctl=1`); rootless inside unprivileged LXC can be fiddly with subuid/subgid ranges.
- Third-party MCP server `mcp-proxmox` (`proxmox_generate_terraform`) is unevaluated and includes mutating operations; use it only with a read-only token and after reading its source.

## Risks and rollback

| Risk | Mitigation / rollback |
|---|---|
| State loss | Enforced state encryption with off-repo backups of state and key; a remote backend with locking once the repository is ready |
| Import produces a plan that wants to replace a guest | Stop; adjust config (not the guest) until the plan is a no-op; ask Parker |
| Bad Ansible change on a prod host | `--check --diff` first, `--limit` to one host, keep the old container until verified |
| Tailnet ACL lockout | Separate root, plan-only without approval, retain the LAN/console path |
| Secrets leak | `.gitignore` and privacy pre-commit hooks; SOPS only |
| Quadlet migration data loss | Side-by-side migration; snapshot/backup before cutover; Parker approves old-container removal |

## Definition of done
- Every in-scope guest is in OpenTofu state with a **no-op plan** in all three roots.
- Every in-scope container runs as a pinned, Ansible-rendered Quadlet; a second playbook run reports no changes.
- The dynamic inventory is built from OpenTofu outputs, with services defined only in `host_vars/`.
- At least one service has been moved between hosts by changing data only, with a written runbook.
- No secrets, state, or generated state files in git history.
