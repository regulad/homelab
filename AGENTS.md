# Plan: Migrate pet containers to IaC (`regulad/homelab`)

Audience: an agent working in a fresh clone of `regulad/homelab`, supervised by a human (Parker).
Goal: replace hand-configured "pet" containers with declarative, relocatable services across a home Proxmox cluster and an OCI tenancy.

## § 1 — Goal and non-goals

**Goal**
- Machines (Proxmox LXC/VM, OCI instances, tailnet keys/ACLs) are declared in **OpenTofu** and tracked in state.
- Host configuration (podman, Tailscale, Avahi, service definitions) is applied by **Ansible**.
- Each containerized service is a **Podman Quadlet** (systemd-native), rendered from data, so moving a service between hosts is a `host_vars` edit plus a playbook run.
- Existing infrastructure is **adopted** (imported), not recreated.

**Non-goals (for now)**
- Kubernetes, Nix/NixOS, Flux/Argo, or any GitOps controller.
- Managing Proxmox/Ceph cluster-level settings (not supported by the `bpg/proxmox` provider).
- Migrating data inside containers automatically. Data movement is planned per service by the human.
- CI/drift automation (optional Phase 9).

## § 2 — Operating rules for the agent (hard constraints)

1. **Never run mutating commands without explicit human approval in chat.** Forbidden unless approved per-action: `tofu apply`, `tofu destroy`, `tofu state rm|mv|push`, `tofu import` (CLI form), `ansible-playbook` without `--check`, `pct|qm destroy|stop|set`, `podman rm|stop`, `oci ... delete|update`, anything that edits Tailscale ACLs.
2. **Read-only first.** Use read-only credentials for discovery (Proxmox `PVEAuditor` token, OCI read-only policy). Do not create broader credentials yourself; ask the human.
3. **No secrets in git.** Never commit tokens, keys, `*.tfvars` with secrets, state files, `.terraform/`, or generated state. Secrets live in `sops`+`age` files; the repo must contain only encrypted forms. Add ignore rules in Phase 0 before anything else.
4. **Do not invent facts about the infrastructure.** Discover via read-only commands and record results in `docs/snapshot/`. If something is unknown, list it under "Open questions" and ask.
5. **Verify provider/tool details against current docs before relying on them** (resource names, import ID formats, flags). Several are listed in § 8 as unverified.
6. **Small, reviewable commits**, one logical change each, conventional-commit messages. One branch/PR per phase.
7. **Pin everything**: provider versions (and commit `.terraform.lock.hcl`), Ansible collection versions in `requirements.yml`, container image tags (never `latest`).
8. **Stop and ask** when a plan shows any destroy/replace, when an Ansible `--check` shows unexpected changes on a production host, or when you hit an auth/permission wall.
9. **Commit attribution:** Every commit must include a `Co-authored-by: <agent name> <agent email>` trailer with the proper attribution for the LLM agent that contributed to the change. Use that agent's designated attribution identity; do not invent an identity or attribute one agent's work to another. An LLM agent must never add a `Signed-off-by` trailer using the user's name or email unless the user explicitly instructs it to do so.

## § 3 — Target architecture

```
homelab/
├── README.md
├── AGENTS.md                      # this file
├── ansible.cfg                  # inventory, roles_path, collections_path -> ansible/
├── .sops.yaml                   # age recipients
├── .gitignore                   # state, .terraform/, *.tfvars (unencrypted), vault pw, .env
├── .pre-commit-config.yaml      # tofu fmt/validate, ansible-lint, yamllint, secret scan
├── docs/
│   ├── snapshot/                # read-only discovery output (Phase 1)
│   └── runbooks/                # move-a-service, rotate-keys, restore-state
├── tofu/
│   ├── modules/
│   │   ├── lxc-guest/           # child module: one LXC with defaults
│   │   └── vm-guest/
│   ├── proxmox/                 # root module (own state)
│   ├── oracle/                  # root module (own state)
│   └── tailnet/                 # root module (own state; ACLs + tagged auth keys)
└── ansible/
    ├── inventory/
    │   ├── inventory.py         # dynamic inventory: merges `tofu output` from each root
    │   ├── group_vars/{all,podman_hosts,proxmox,oracle}/
    │   └── host_vars/<host>/{main.yml,services.yml}
    ├── playbooks/{site.yml,base.yml,services.yml}
    ├── roles/{base,podman,tailscale,avahi,quadlet_services}/
    └── requirements.yml         # collections: containers.podman, community.general
```

**Layer boundaries**
- OpenTofu owns *which machines exist*. It must not manage containers or in-guest files.
- cloud-init (set by OpenTofu) does only minimal bootstrap: admin user, SSH key, tailnet join with a pre-authorized, tagged key.
- Ansible owns everything inside a guest after bootstrap.
- Service lifecycle lives in Ansible data (`host_vars`), never in OpenTofu state.

**Why multiple roots:** separate state per provider limits blast radius; an OCI API problem or bad plan can't touch Proxmox state. Cross-root sharing goes through explicit outputs only.

## § 4 — Inputs the human must supply (ask before the phase that needs them)

| Needed by | Input |
|---|---|
| Phase 0 | `age` public key(s) for `.sops.yaml`; preferred Python/tool manager (`uv`/`mise`) |
| Phase 1 | SSH access from this machine to Proxmox nodes and guests (over tailnet); read-only Proxmox API token; OCI CLI config with a read-only profile; OCI compartment OCID(s) |
| Phase 4 | Remote state backend choice and credentials (S3-compatible, e.g. OCI Object Storage or MinIO); state-encryption passphrase handling |
| Phase 4 | A scoped Proxmox API token/role for management (human creates it) |
| Phase 6 | Confirmation of an out-of-band path (LAN/console) to Proxmox nodes before touching tailnet ACLs |

## § 5 — Phases

Each phase ends with its acceptance criteria met, a PR, and a human check-in. Do not start the next phase without it.

### Phase 0 — Scaffold and tooling
- Create the tree from § 3 with placeholder READMEs.
- `.gitignore` first, then `.sops.yaml`, pre-commit config, `ansible.cfg` (inventory = `ansible/inventory`, `roles_path = ansible/roles`, `collections_path = ansible/collections`).
- Tooling versions pinned (OpenTofu, Python deps for `ansible-core`, `ansible-lint`).
- **Accept:** `pre-commit run --all-files` passes on the empty scaffold; `git status` shows no ignored-class files tracked.

### Phase 1 — Read-only discovery snapshot
Record, under `docs/snapshot/`, what actually exists. Never modify anything.
- Proxmox (run on a node, read-only):
  ```bash
  pvesh get /cluster/resources --type vm --output-format json
  pct config <vmid>
  qm config <vmid>
  pvesh get /nodes/<node>/storage --output-format json
  ```
- Per guest (over SSH): OS release, `podman ps -a --format json`, `podman inspect` of each container, `podman network ls`/`inspect`, `systemctl list-units --state=running`, Avahi config (`/etc/avahi/avahi-daemon.conf`), `tailscale status --json`, listening ports, mounts/volumes.
- Compose files / `podman run` histories where they exist.
- OCI (read-only): list compartments, instances, VCNs, subnets, security lists/NSGs, volumes, reserved IPs.
- Produce `docs/snapshot/SUMMARY.md`: one table per host (guest ID, role, containers, volumes, ports, networks, tailnet name) and an **Open questions** list.
- **Accept:** snapshot committed (with secrets and tokens scrubbed); human has reviewed SUMMARY.md and answered open questions.

### Phase 2 — Ansible baseline (non-destructive)
- Static inventory first (`inventory/hosts.yml`) matching the snapshot; groups: `podman_hosts`, `proxmox`, `oracle`.
- Roles:
  - `base`: packages, admin user, sshd hardening only if already the current policy, time sync.
  - `podman`: install podman; configure registries; enable `podman.socket` only if currently used.
  - `tailscale`: install and enable; join logic gated on a variable so existing members are untouched.
  - `avahi`: template `avahi-daemon.conf` (`enable-reflector=yes`, `allow-interfaces=` the podman bridge + LAN interface, as discovered). Pin the podman network subnet/bridge name so this is deterministic.
- Run against **one** low-risk host first: `ansible-playbook ansible/playbooks/base.yml --check --diff --limit <host>`.
- **Accept:** `--check --diff` output reviewed by the human; after an approved real run, a **second run reports `changed=0`** (idempotency); no service restarts occurred unexpectedly.

### Phase 3 — Quadlet service model
- Convert the first low-stakes service with `podlet` (compose or `podman run` input), then review/hand-edit the output.
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
- Migrate one service **side by side**: stand up the Quadlet version on a spare port or host, verify, cut over, and only then retire the old container (human approves the removal).
- **Accept:** service runs as a systemd-managed Quadlet; restart/reboot test passes; data persists; old container retired only after human sign-off; second playbook run is idempotent.

### Phase 4 — OpenTofu: adopt Proxmox guests
- `tofu/proxmox`: `versions.tf` (pin `bpg/proxmox`), `providers.tf`, `backend.tf`, `variables.tf`, `locals.tf` (topology), `main.tf`, `outputs.tf`.
- Remote backend with locking, plus OpenTofu state encryption. Back up the state and its key off-cluster. Do this **before** any import.
- Auth: API token via environment variables only; SSH for the provider via ssh-agent.
- Adoption:
  1. Generate one `import {}` block per guest. Draft (verify ID format and resource names against the provider docs first):
     ```bash
     pvesh get /cluster/resources --type vm --output-format json | jq -r '.[] | select(.template==0) | "import {\n  to = proxmox_virtual_environment_\(if .type=="lxc" then "container" else "vm" end).g\(.vmid)\n  id = \"\(.node)/\(.vmid)\"\n}\n"' > tofu/proxmox/imports.tf
     ```
  2. `tofu -chdir=tofu/proxmox plan -generate-config-out=generated.tf` (target file must not already exist; the output format is not stable across versions).
  3. Refactor `generated.tf` into `locals.tf` + the `lxc-guest`/`vm-guest` modules: remove computed attributes and plaintext secrets, parameterize repeated values, keep names stable.
  4. Iterate until `tofu plan` shows **no changes**. Add `lifecycle { ignore_changes = [...] }` only where justified (e.g., HA-managed guests that may migrate between nodes) and comment why.
  5. Remove the `import` blocks after the human-approved apply that records them.
- **Accept:** `tofu plan` is a no-op; no `destroy`/`replace` ever appeared in any plan reviewed; lock file committed; state backed up.

### Phase 5 — OpenTofu: adopt OCI resources
- Prefer scoped discovery (specific compartment and `-services`) over tenancy-wide export:
  ```bash
  terraform-provider-oci -command=export -compartment_id=<OCID> -output_path=./oci-export -services=core
  ```
  The exporter shells out to a `terraform` binary (not confirmed to work with `tofu`). Use the output directory only as a **reference for HCL**; discard its state file.
- Re-adopt through `import` blocks and `-generate-config-out` in `tofu/oracle`; refactor into modules as in Phase 4.
- Missing attributes in the export are expected; reconcile via `tofu plan` until it is a no-op.
- **Accept:** `tofu plan` no-op; any attribute the exporter omitted is documented in `docs/`.

### Phase 6 — OpenTofu: tailnet (highest lockout risk)
- Separate root `tofu/tailnet`. **Plan-only until the human confirms** a LAN/console path to every Proxmox node.
- Import the current ACL policy first (no changes). Add tagged, pre-authorized key generation for new guests only afterward.
- Any ACL diff goes to the human for line-by-line review before apply.
- **Accept:** current policy imported with a no-op plan; key minting works for a test tag.

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
- Keep inventory **minimal** (name, address, groups). Services and other variables stay in `host_vars/` in git.
- Optional later: the Ansible Terraform provider (`ansible_host`/`ansible_group` resources) with the `cloud.terraform.terraform_provider` inventory plugin (requires initialized roots; shells out to a `terraform` binary, so verify `tofu` compatibility).
- **Accept:** `ansible-inventory --graph` shows every guest in its expected groups; `ansible all -m ping` succeeds over the tailnet from the laptop.

### Phase 8 — Portability proof
- Pick one stateless-ish service. Move it by deleting its entry from host A's `services.yml`, adding it to host B (including an OCI host), and running `services.yml` for both with `--check` first.
- Document, per service, a data strategy (restic restore, shared mount, or stateless) in `docs/runbooks/move-a-service.md`.
- **Accept:** the service runs on host B, is gone from host A, and the runbook reflects exactly what was done.

### Phase 9 — Optional: drift and CI
- Scheduled `tofu plan -detailed-exitcode` and `ansible-playbook --check` from a runner on the tailnet, alerting on drift. Plans only; never auto-apply.

## § 6 — Conventions
- Guest names: lowercase, hyphenated, stable (`svc-<name>`, `host-<role>`); the tailnet MagicDNS name equals the hostname.
- Tags: every guest carries `managed-by=opentofu`; tailnet tags map to ACL groups.
- OpenTofu: one root per provider; `locals.tf` holds desired topology; modules take explicit inputs; no secrets in `locals`.
- Ansible: roles expose knobs in `defaults/`, avoid `vars/`; handlers for restarts; every role passes `ansible-lint`.
- Quadlets: one file per unit; image tags pinned; volumes named, not bind-mounted from ad hoc paths.

## § 7 — Verification checklist (run before every PR)
```bash
pre-commit run --all-files
tofu -chdir=tofu/<root> fmt -check -recursive
tofu -chdir=tofu/<root> validate
tofu -chdir=tofu/<root> plan -detailed-exitcode
ansible-lint ansible/
ansible-playbook ansible/playbooks/site.yml --check --diff --limit <host>
ansible-inventory -i ansible/inventory/inventory.py --graph
```
Also confirm: no secrets staged (`git diff --cached`), lock files committed, plans show no unintended destroy/replace.

## § 8 — Known uncertainties (verify, do not assume)
- bpg/proxmox: current resource type names and the import ID format (believed `node/vmid`; resource naming has been shifting). Provider uses SSH for some actions; HA-managed guests can migrate without the provider knowing.
- `-generate-config-out`: documented as potentially changing output format between minor versions; no config generation for `for_each` imports; may emit plaintext secrets.
- OCI resource discovery: needs a `terraform` binary; unknown whether it works with `tofu`; exported state references the Terraform registry provider address; omitted attributes expected.
- `cloud.terraform` inventory plugins: `terraform_state` supports only AWS/Azure/GCP per its docs; `terraform_provider` needs initialized project dirs; `tofu` binary support unconfirmed.
- Podman-in-LXC: requires `nesting=1` (sometimes `keyctl=1`); rootless inside unprivileged LXC can be fiddly with subuid/subgid ranges.
- Third-party MCP server `mcp-proxmox` (`proxmox_generate_terraform`) is unevaluated and includes mutating operations; use only with a read-only token and after reading its source.

## § 9 — Risks and rollback
| Risk | Mitigation / rollback |
|---|---|
| State loss | Remote backend with locking, encrypted, with off-site backup of state and key |
| Import produces a plan that wants to replace a guest | Stop; adjust config (not the guest) until the plan is a no-op; ask the human |
| Bad Ansible change on a prod host | `--check --diff` first, `--limit` to one host, keep the old container until verified |
| Tailnet ACL lockout | Separate root, plan-only without approval, retain LAN/console path |
| Secrets leak | `.gitignore` and secret-scanning pre-commit first; sops only |
| Quadlet migration data loss | Side-by-side migration; snapshot/backup before cutover; human approves old-container removal |

## § 10 — Definition of done
- Every in-scope guest is in OpenTofu state with a **no-op plan** in all three roots.
- Every in-scope container runs as a pinned, Ansible-rendered Quadlet; a second playbook run reports no changes.
- The dynamic inventory is built from OpenTofu outputs, with services defined only in `host_vars/`.
- At least one service has been moved between hosts by changing data only, with a written runbook.
- No secrets, state, or generated state files in git history.

## § 11 — Decision log

Decisions made by the human after this plan was written. Where they conflict with the sections above, this section wins.

**2026-10-12**
- **Order:** Phase 1 discovery starts with OCI; Proxmox discovery comes later.
- **OCI auth (supersedes the OCI parts of § 2 rule 2 and § 4 Phase 1):** Parker's own user via `oci session authenticate`, a read/write session token in the `DEFAULT` profile, instead of a dedicated read-only user, because OpenTofu will write back to OCI. § 2 rule 1 is unchanged: every OCI write still needs per-action approval. The token lasts 60 minutes, refreshable to 24 hours with `oci session refresh`; Phase 9 will need a non-expiring credential.
- **Public repository:** nothing sensitive is committed in plaintext. Anything sensitive that must be committed (e.g. values OpenTofu needs) goes in sops-encrypted `*.sops.*` files.
- **Discovery snapshots are local only (supersedes "snapshot committed" in Phase 1):** `docs/snapshot/` is gitignored. Raw discovery output and `SUMMARY.md` stay on the operator's machine; only the OpenTofu configuration derived from them is committed. Human review of `SUMMARY.md` still gates the adoption phases.
- **OCI scope:** compute instances and boot volumes, VCN networking (VCNs, subnets, gateways, route tables, security lists, DHCP options), NSGs, and Email Delivery (domain, senders, DKIM, `svc-mail` policy) go into `tofu/oracle`. Out of scope: identity-domain apps/users/groups, Oracle-created policies and tag defaults, `ManagedCompartmentForPaaS`, the OS Management Hub profile, the DNS resolvers/views/private zones VCNs create automatically, and boot-volume backups themselves (data, not configuration).
- **Phase 5 discovery (supersedes the exporter step):** skip `terraform-provider-oci -command=export`. Its docs say it always needs a `terraform` binary and list only Terraform 0.12/0.13. Inventory with the `oci` CLI instead, then adopt with `import {}` blocks and `tofu plan -generate-config-out`. `oracle/oci` is published on the OpenTofu registry.
- **Known non-issues:** the Email Delivery DKIM key shows `NEEDS_ATTENTION` for about a week after the mail server power-cycles; this is cosmetic. The tenancy is pay-as-you-go, so resources beyond Always Free limits (e.g. extra boot-volume backups) are expected.

- **Handoff / commits:** Parker requested a soft reset to the empty initial commit, renamed this plan to AGENTS.md, and asked to continue OCI decompilation. Leave all work uncommitted until it is ready for review; this supersedes automatic per-phase commits and PRs. Read-only configuration generation may proceed before a backend exists, but no state import/apply is authorized.
- **Existing creation-only settings:** Parker requested that existing resources ignore creation state rather than fabricate clone/restore sources. For image-created OCI boot volumes, ignore only `source_details`; keep other volume drift visible. OCI writes and state-changing operations still require explicit per-action approval.

- **Write approval clarification:** Parker clarified that local file writes and edits are authorized. The instruction to ask before writes refers to operations that push changes to Oracle, not local drafting, encryption, validation, or read-only planning. Existing explicit approval requirements for state-changing import/apply and other infrastructure mutations still apply.
- **HCL-first configuration:** Parker requires ordinary, readable `.tf` resource definitions with inline non-sensitive settings and direct references. SOPS holds sensitive input values only, not encrypted HCL, resource definitions, or an entire topology/configuration data model.

- **OCI adoption (2026-10-12):** Parker explicitly authorized applying an import-only plan with no Oracle-side changes. The verified saved plan imported 74 resources with zero additions, changes, or deletions; the subsequent plan is a no-op. Execution used encrypted local state because no remote backend was configured, with an encrypted backup outside the repository on the operator machine. Remote backend migration remains outstanding. Completed import blocks are archived under the ignored discovery directory. Further mutating operations still need explicit authorization.
