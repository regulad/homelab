# Homelab IaC history

Chronological record of approvals, applies, results, and superseded decisions.
It was moved verbatim out of `AGENTS.md` § 11 on 2026-10-12. `AGENTS.md` now
holds only the decisions that currently apply. Append new entries at the end.

## 2026-10-12

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
- **OCI cleanup (2026-10-12):** Parker authorized cleanup tasks 1–5, then explicitly approved applying the resulting sensitivity-metadata updates and committing the changes. The verified saved plan applied with 0 additions, 34 updates, and 0 deletions; deferred IPv6 lookups resolved without changes. The fresh post-apply plan is a no-op. Import IDs and historical creation tags are no longer runtime inputs, empty attributes and redundant shape settings are omitted, and the existing agent plugin policy is shared in HCL. This approval does not authorize further infrastructure mutations.
- **Network input sensitivity:** Parker explicitly classified the listed network CIDRs, host IPs, and route next-hop IDs as non-sensitive except for the GUA IPv6 `/64` prefixes. Keep those two prefixes SOPS-encrypted; derive full GUA host addresses and the enclosing `/56` from them. IPv4, ULA/Tailscale ranges, host suffixes, and the listed next-hop OCIDs may be plaintext HCL. This classification does not change the treatment of other credentials or sensitive inputs, and does not authorize apply.
- **OCID ownership classification (supersedes the next-hop exception above):** Parker approved plaintext OCIDs for verified stock images, with their exact image names in comments above `source_id`. OCIDs owned by our tenancy/compartments remain sensitive, including the router next-hop IDs; the shared backup-policy ID also remains SOPS-encrypted. The five current image lookups have null compartment IDs and platform-image names; four additionally match Oracle's public regional catalog exactly. Livekit's exact revision was not found in the catalog, so its classification relies on the image API metadata. IPv4, ULA/Tailscale ranges, and host suffixes remain plaintext; GUA `/64` prefixes remain encrypted.

- **Readability cleanup applied (2026-10-12):** Parker authorized cleanup items 1–4, verification, apply, and commit. The saved plan preserved all known values; apply recorded module/rule address moves and 13 sensitivity-metadata updates, with 0 additions or deletions. All 74 managed resources retain identical IDs and values, and the fresh plan is a no-op. Shared Tailscale ranges live in the resource-free `tofu/shared` module. Item 5 (presentation/order cleanup) remains a proposal for review. Further infrastructure mutations require separate approval.
- **Tooling (2026-10-12):** `uv` is the Python/tool manager. Agents must not install anything themselves, including tools, Python packages (`uv sync`, `uv tool install`), pre-commit hook environments, and OpenTofu providers. Parker manages tools declaratively; ask him to install what is needed.
- **Remote state deferred (2026-10-12):** OCI state stays local on Parker's backed-up laptop until the rest of the repository is ready. Remote-backend migration comes after that, not before.
- **Presentation cleanup (2026-10-12):** Parker requested item 5, with each subnet in its own `subnet-<name>.tf` (subnet first, then the DHCP options, route table, and security list only it uses). The VCN-created defaults stay in `network.tf`. ICMP `type`/`code` values gained comments, and so did ports. Parker identified 7881 and both UDP ranges as standard LiveKit ports (TURN relay for 30000–40000) and router UDP 39127 as Tailscale peer relay. Bailout's 51820/51821 were named later (WireGuard; see below). Parker then approved applying the verified saved plan, plus one commit as the final OCI cleanup pass that also adds the pre-commit configuration. That plan was a no-op for all 74 resources. Apply recorded **0 added, 0 changed, 0 destroyed**, and the fresh post-apply plan is a no-op. Encrypted before/after state backups are under `%LOCALAPPDATA%/homelab/oracle-backups/final-cleanup-*`. This approval does not authorize further infrastructure mutations.
- **Pre-commit (2026-10-12):** Parker approved `pre-commit install` and pinned `pre-commit/pre-commit-hooks`; gitleaks is not wanted. Other hooks use installed tools (`language: unsupported`) or `pygrep`.
- **OCI follow-ups triaged (2026-10-12):**
  - Bailout's UDP 51820/51821 are WireGuard.
  - Rules restricted to a single source port are fixed now; Parker first deferred them, then asked for the fix. Mail TCP 80 drops the source-port restriction. Legacy's Minecraft Voice Chat rule (UDP 24454) is removed as unused. Legacy's four DNS 53 rules are removed, because the same sources' all-protocol rules already allow DNS. Applying this changes OCI and needs Parker's approval.
  - Managing the VCN defaults through `oci_core_default_*` resource types is wontfix. They stay ordinary adopted resources guarded by `prevent_destroy`.
  - Every OCI instance carries the freeform tag `managed-by=opentofu`, per § 6. Adding it changes OCI and needs Parker's approval to apply.
  - The OCI root's `ansible_hosts` output waits for the Ansible phases.
- **Tags and firewall fixes (2026-10-12, applied):** Bailout UDP 51820/51821 were named as WireGuard. Parker first deferred the single-source-port rules as `FIXME`s, then asked for them to be fixed now, and for legacy's unused Minecraft Voice Chat rule to be removed. The saved plan `docs/snapshot/oci/tags-firewall.tfplan` adds the `managed-by=opentofu` tag to the five instances, drops mail TCP 80's source-port restriction, and removes legacy's Minecraft and four DNS 53 rules: 0 to add, 13 to change, 0 to destroy. Five IPv6 updates are deferred VNIC lookups only. Parker approved the apply, which completed with **0 added, 8 changed, 0 destroyed**: the five IPv6 updates resolved without change. The fresh post-apply plan reports **No changes**. Encrypted state backups are under `%LOCALAPPDATA%/homelab/oracle-backups/tags-firewall-{before,after}-*`; logs are in `docs/snapshot/oci/tags-firewall-{plan,apply,post-apply-plan}.log`.

## Moved from `tofu/oracle/README.md` (2026-10-12)

On 2026-10-12, Parker authorized adoption. The exact verified plan applied
successfully: **74 imported, 0 added, 0 changed, 0 destroyed**, using OpenTofu
1.13.1 and oracle/oci 9.9.0. A fresh post-adoption plan reports **No changes**
(exit code 0). Completed import blocks are archived locally in
`docs/snapshot/oci/adopted-imports.tf`. The original encrypted inputs, including
import IDs, are archived in `docs/snapshot/oci/cleanup-1-5-before/secrets.sops.json`
and the adoption backup outside the repository. Import IDs are no longer runtime
inputs. No Oracle resource mutations were performed.

The subsequent configuration cleanup removes historical creation tags, empty
attributes, and redundant shape settings, and shares the existing plugin policy
without changing plugin states or order. Oracle-created tags are left to the
provider rather than asserted as desired configuration.

**Cleanup applied (2026-10-12):** Parker authorized the sensitivity-metadata
updates and the cleanup commit. A fresh saved plan matched the reviewed changes:
34 resources retained their values but lost the sensitivity mark on historical
tags; five dependent IPv6 resources had deferred VNIC lookups. The verified plan
applied successfully: **0 added, 34 changed, 0 destroyed**. The IPv6 lookups
resolved without resource changes. A fresh post-apply plan reports **No changes**
(exit code 0). Formatting and validation pass. Local evidence is in
`docs/snapshot/oci/cleanup-approved-apply.log` and
`docs/snapshot/oci/cleanup-post-apply-plan.log`.

**Reorganization and readability cleanup applied (2026-10-12):** Parker
approved the module/address moves, host-centered files, dual-stack rule and route
helpers, shared Tailscale constants, input naming, redundant network-argument
removal, and sensitivity changes. Both VCNs use `cidr_blocks`; each subnet uses
one IPv4 CIDR, an IPv6 CIDR list, and `prohibit_internet_ingress`.

The verified saved plan had 0 additions, 18 updates, and 0 deletions: 13 resources
had sensitivity-metadata changes only, and five IPv6 resources awaited VNIC
lookups. Apply completed with **0 added, 13 changed, 0 destroyed**; the IPv6
lookups resolved without changes. All 74 managed resource IDs and values match
the pre-apply state exactly. The fresh live plan reports **No changes** (exit 0).
Formatting, validation, encrypted-input consistency, and the public-file privacy
audit pass. Keep both `moved.tf` files to support older states and backups.
Local evidence is in `docs/snapshot/oci/readability-{plan,apply,post-apply-plan}.log`
and `readability-{before,after}-verification.json`.

**Final cleanup pass applied (2026-10-12):** per-subnet files, consistent
resource and argument order, and comments naming ICMP type/code values and ports. Parker approved
applying the verified saved plan, which was a no-op for all 74 resources. Apply
completed with **0 added, 0 changed, 0 destroyed**, and the fresh post-apply plan
reports **No changes**. Local evidence is in
`docs/snapshot/oci/final-cleanup-{plan,apply,post-apply-plan}.log`.

Also from that README: an encrypted state copy and SOPS-encrypted inputs were
backed up outside the repository; recovery of the backup was verified by reading
all 74 managed resources. No OCI bucket or locking resource was created during
adoption. The provider generated an invalid empty `server_type` on a SearchDomain
DHCP option, so the configuration omits that inapplicable field.

## Moved from `README.md` (2026-10-12)

The existing OCI infrastructure is represented by 74 explicit OpenTofu resources
in `tofu/oracle/`. Adoption imported those resources with zero additions, changes, or deletions. The post-adoption plan reports no changes.

## Documentation restructure (2026-10-12)

Parker asked for the plan's phases to move from `AGENTS.md` into `.claude/PLAN.md`, for
`AGENTS.md` to become a cheat sheet for agents new to the repository, and for all
history to leave `AGENTS.md` and the READMEs for this file. `.claude/PLAN.md` states the
current intent: instructions that later decisions superseded are replaced rather
than annotated. These were exporter-based OCI discovery, committed discovery
snapshots, a read-only OCI profile, and per-phase commits and PRs. The original
wording is in Git history before this restructure and in the verbatim § 11 entries
above.

## Published to GitHub (2026-10-12)

Before the first push, a scan of every commit found no OCIDs other than images, no
GUA IPv6 literals, no private or age keys, no state, plan, tfvars or snapshot
files, and only encrypted SOPS files. `phase-0-scaffold` was renamed to `master`;
the old local `master` held only the initial commit, an ancestor. `gh repo create`
made the public `regulad/homelab` with `origin` and pushed `master`. A follow-up
commit added `.github/settings.yml` for the Probot Settings app (description,
topics, and the disabled features used in `regulad/tailscale-acls`).

## Scope change (2026-10-12)

Parker moved two areas out of this repository because they are already
declarative elsewhere: tailnet configuration (ACL policy and DNS) in
`regulad/tailscale-acls`, and workstations in `regulad/dotfiles`. The plan's
tailnet root (`tofu/tailnet`, ACL import, auth-key minting) was dropped. Parker
also brought Proxmox cluster-wide and Ceph cluster-wide settings into scope; the
plan previously listed them as a non-goal because `bpg/proxmox` does not cover
them all. Phase 6 now covers those settings, using OpenTofu where the provider
supports a setting and Ansible on the nodes otherwise.

## OCI input cleanup (2026-10-18)

Parker reviewed `tofu/oracle`'s inputs and retired four of them from
`secrets.sops.json`. Each replacement keeps the value it replaces:

- `backup_policy_id` was Oracle's predefined `bronze` policy: a realm-wide OCID
  (`oc1..`) with no compartment, not a tenancy-owned OCID. The tenancy has no
  user-defined backup policies. Managing it as an `oci_core_volume_backup_policy`
  resource was ruled out, because that resource requires a compartment and
  Oracle owns the policy. A lookup by name was drafted, then replaced at Parker's
  direction with the plaintext OCID. This supersedes the 2026-10-12
  classification that kept the backup-policy ID encrypted.
- Plaintext Oracle OCIDs moved into per-module `backup_policy_ids` and
  `platform_image_ids` maps, keyed by exact Oracle name. They replace the
  name-comment convention for stock images. The privacy hook now requires that
  keyed form for image and backup-policy OCIDs.
- `availability_domains` is looked up from `tenancy_ocid` in the root and still
  reaches the modules as a sensitive input.
- `instance_metadata` and `shared_ssh_metadata` held only one SSH public key per
  instance, with no `user_data`. Parker had the keys moved to plaintext HCL.
- `ipv6_subnet_cidrs` stays encrypted at Parker's direction, although each `/64`
  could be derived from its VCN's Oracle-allocated `/56`, so that a full
  redeploy keeps the same subnets.

## `bronze` backups on every boot volume (2026-10-18)

Parker extended `bronze` to every boot volume: web and bailout, which had no
policy, gained new assignments. One apply covered this and the input cleanup
above. Parker approved it on condition that the plan showed only those two
assignments plus sensitivity changes.

The saved plan `docs/snapshot/oci/input-cleanup.tfplan` had 2 to add, 13 to
change, and 0 to destroy. The 13 were 8 sensitivity-only updates, whose values
were unchanged (five instances' `metadata` and three assignments' `policy_id`),
and five IPv6 resources awaiting deferred VNIC lookups. Apply completed with
**2 added, 8 changed, 0 destroyed**. The IPv6 lookups resolved without change,
and the fresh post-apply plan reports **No changes** for 76 managed resources.
Encrypted state backups are under
`%LOCALAPPDATA%/homelab/oracle-backups/input-cleanup-{before,after}-*`. Logs are in
`docs/snapshot/oci/input-cleanup-{plan,apply,post-apply-plan}.log`.

## Remote state brought forward; OCI lock test (2026-10-18)

Parker brought the remote state backend forward from "after the rest of the
repository": he now switches between workstations, all of which share one age
identity. The backend itself is not configured yet.

Research found three things:
- OpenTofu 1.13.1 has no native OCI backend.
- Its `s3` backend works with OCI's S3 Compatibility API using Oracle's
  documented settings.
- `use_lockfile` depends on `If-None-Match: *`, which Oracle does not document
  for the S3-compatible path.

Parker approved a test with a scratch versioned bucket, `homelab-tofu-locktest`,
and a temporary Customer Secret Key on his own user:

- **Raw requests:** a repeated conditional create returned 412, and a create
  over a delete marker returned 200. A wrong `If-Match` was ignored and returned
  200; OpenTofu does not send that header.
- **Held lock:** while an apply held the lock, a second run was refused with 412
  `PreconditionFailed`. The lock object was removed afterwards, and the next
  apply took the lock again.
- **Race:** in 20 of 20 rounds of two simultaneous applies, exactly one got the
  lock. All 20 refusals were 412s, and no lock object was left behind.

The bucket and its 71 object versions were deleted afterwards.
Parker then deleted the test key.

## State backend resources (2026-10-18)

Parker had the bucket and the backend's service identity managed in
`tofu/oracle`, as the new `state-backend` module:
- `homelab-tofu-state` is private and versioned. Parker ruled out
  `prevent_destroy`, because the bucket is created declaratively rather than
  adopted.
- `svc-tofu-state@regulad.xyz` is limited to customer secret keys. Parker
  created that mailbox, so the identity domain's activation mail is delivered.
- The `svc-tofu-state` group and policy grant `read buckets` and the five object
  permissions the backend uses, scoped to that bucket. They omit
  `OBJECT_VERSION_DELETE`.

Identity-domain users and groups stay out of Phase 5's adoption scope; these were
created by OpenTofu. The classic IAM resources were used, as with `svc-mail`.

The plan Parker reviewed was re-planned after removing `prevent_destroy`. The new
plan had the same 6 creates with identical values. Apply completed with **6
added, 0 changed, 0 destroyed**, and the fresh plan was a no-op. Backups are
under `oracle-backups/state-backend-{before,after}-*`. Logs are in
`docs/snapshot/oci/state-backend-*.log`.

## Remote state migration (2026-10-18)

**Key.** Parker approved creating the customer secret key with the CLI, outside
OpenTofu, so the key never lives in the state it unlocks. The first key's secret
was lost: encrypting it failed on a newline, and the script had already discarded
the secret. That key was never usable, and Parker approved deleting it. After a
dummy-value round trip, the second key (`tofu-state-backend-20261018`) was
encrypted straight from memory into `tofu/oracle/backend.sops.env`, with the
endpoint. The new key failed intermittently with `SignatureDoesNotMatch` for
about 15 minutes after creation, then succeeded on every request.

**Migration.** Parker approved the migration.
- The local state was backed up to
  `oracle-backups/migrate-state-before-20261018-163215/`, and
  `tofu init -migrate-state -force-copy` moved it to `oracle/terraform.tfstate`.
- The remote object is the encrypted envelope, and holds all 82 managed
  resources.
- OpenTofu gave the remote state a new lineage (serial 1), so restoring a
  pre-migration local backup needs `tofu state push -force`.
- A fresh plan against the remote state reports **No changes**, and its lock
  object was removed afterwards.
- The emptied local `terraform.tfstate` and the stale `.backup` were moved into
  the backup folder.

Parker then dropped the rule to copy state, inputs, and the lock file to
`%LOCALAPPDATA%/homelab/oracle-backups/` before each apply, because bucket
versioning now keeps every earlier state version.

Logs are in `docs/snapshot/oci/migrate-state*.log`.

## Plan restructured around two Ansible phases (2026-10-18)

Parker asked for two Ansible phases on either side of OpenTofu:
- hardware hosts, from a hand-written inventory, before OpenTofu;
- generated hosts, from an inventory fed by OpenTofu outputs, after it.

The plan went from ten phases to seven. Entries above this one use the old
numbers:

| Old | New |
|---|---|
| 0 Scaffold, 1 Discovery | 0, 1. Discovery now also covers hardware hosts, and picks an owner for each cluster and Ceph setting. |
| 2 Ansible baseline | Split: Proxmox nodes and other hardware go to 2 (Ansible: hardware hosts); guests go to 4 (Ansible: generated hosts) |
| 3 Quadlet services | 4 |
| 4 Proxmox OpenTofu, 5 OCI OpenTofu | 3 (OpenTofu), as its Proxmox-guest and OCI parts |
| 6 Cluster and Ceph settings | Discovery to 1; Ansible-owned settings to 2; OpenTofu-owned settings to 3 |
| 7 Inventory handoff | 4 |
| 8 Portability, 9 Drift and CI | 5, 6 |

## Ansible stages scaffolded (2026-10-18)

Parker asked for the two Ansible stages to be scaffolded:
- `ansible.cfg` at the repository root.
- Inventories: the hand-written `hardware.yml` (groups `hardware` and
  `proxmox_nodes`, no hosts yet), and `inventory.py`, which reads OpenTofu
  outputs, puts every host in `generated`, and lists no roots yet.
- One playbook per stage (`hardware.yml`, then `base.yml` and `services.yml`),
  plus `site.yml`.
- Skeleton roles with knobs in `defaults/`.

Two choices came out of `ansible-lint`. The Quadlet role is named `quadlet`
instead of `quadlet_services`, because role variables must carry the role's
prefix and the plan's `quadlet_services` host_vars key is kept. Role metadata
carries `license: AGPL-3.0`, after the repository's AGPLv3 `LICENSE.md`.

Checks used the tools already in WSL `regulad-fedora` (ansible-core 2.21.5,
ansible-lint 26.10.1, OpenTofu 1.13.1); nothing was installed.
- `ansible-inventory --graph` and the `site.yml` syntax check pass.
- `ansible-lint --offline` passes under its `production` profile.
- Ansible ignores `ansible.cfg` in the world-writable `/mnt/d` checkout, so WSL
  runs set `ANSIBLE_CONFIG`.

## Repository moved into WSL; hardware hosts seeded (2026-10-18)

Ansible's control node is Linux-only, so Parker moved the repository into WSL:
- **Clone:** `~/repositories/homelab` in `regulad-fedora`, cloned after the
  push. Its gitignored `docs/snapshot/` was copied from the Windows checkout.
  The checkout is not world-writable, so Ansible reads `ansible.cfg` without
  `ANSIBLE_CONFIG`.
- **Worktree:** agent work happens in the `homelab_ansible` worktree, on branch
  `ansible`.
- **pve material:** the on-hold `tofu/gonkputer` work stays in the Windows
  `homelab_pve` worktree, on branch `pve`. At Parker's direction, the
  gitignored gonkputer files left in the main Windows checkout were moved
  there: `.terraform/`, the decrypted inputs, and the discovery snapshot.

**Hardware hosts.** At Parker's direction, the hardware inventory was seeded from
`~/.ssh/config.d/99-hardware`, plus `overture`, which that file points to in
`99-osx`.
- `prodingus` (Proxmox VE 9.2.22 on Debian 13) answered Ansible's `ping`. Its
  facts are in the local snapshot.
- `turk` was unreachable from WSL because it happened to be down; like the other
  hardware hosts, it normally runs around the clock. Parker identified it as a
  separate computer, not part of the `gonkputer` Proxmox cluster. It runs VMware
  instead of QEMU/KVM, so Windows guests get hardware-accelerated graphics.
  Bringing those guests into OpenTofu is a far-future idea.
- Parker dropped `longitude` (mobile) and `minintosh`.
- `overture` gets `-o RemoteCommand=none -o RequestTTY=no`, because its SSH
  login wrapper cannot coexist with Ansible's commands. This is untested.

**Network switches.** The two Cisco SG300s and the Arista 7010T run no Python.
Parker kept them out of the Ansible inventory and added a Phase 2 step to manage
them with the repository's own bash scripts.

## overture reachable through Ansible (2026-10-18)

- The `RemoteCommand=none` / `RequestTTY=no` override now works: Ansible's
  `ping` to `overture` succeeded with it and failed without it ("Cannot execute
  command-line and remote command").
- At Parker's direction, `overture` pins `ansible_python_interpreter` to
  `/usr/bin/python3`, the interpreter macOS ships (Python 3.9.6 on macOS 27.0.1),
  instead of relying on interpreter discovery.

## Unix-only tooling (2026-10-18)

At Parker's direction, the repository became Unix-only: Linux (including WSL)
or macOS, with a POSIX shell. Native Windows is no longer supported.
- `tofu/oracle/prepare.ps1` was replaced by `prepare.sh`, which is sourced
  (`. tofu/oracle/prepare.sh`) and runs in sh, bash and zsh. It keeps the old
  behaviour: it refuses an un-ignored destination and refuses to overwrite a
  `secrets.auto.tfvars.json` whose data differs. It checks every backend name
  before exporting any, and writes the decrypted inputs with mode 600. `jq`
  replaces PowerShell's JSON comparison.
- Documented commands moved from PowerShell to bash. The Windows-only
  `OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING` setting was dropped.
- The `ANSIBLE_CONFIG` workaround for world-writable `/mnt/` checkouts was
  removed from `ansible.cfg`, `AGENTS.md` and `ansible/README.md`, and so was the
  `WSLENV` route for backend credentials.
- The pre-migration state copies are still on the former Windows workstation,
  under `%LOCALAPPDATA%/homelab/oracle-backups/`.

## Ansible split into per-stage folders (2026-10-18)

At Parker's direction, `ansible/` became three folders, so each stage reads
only its own inventory:
- `ansible-hardware/`: Phase 2. It reads only the hand-written
  `inventory/hardware.yml`, with `overture`'s host variables beside it. The old
  `hardware.yml` playbook became its `playbooks/site.yml`. It owns the
  `proxmox_cluster` role.
- `ansible-generated/`: Phase 4. It reads only `inventory/inventory.py`, built
  from OpenTofu outputs, and keeps `base.yml`, `services.yml` and a `site.yml`
  that no longer imports the hardware stage. It owns `podman`, `avahi` and
  `quadlet`.
- `ansible-common/roles/`: `base` and `tailscale`, which both stages apply.
  Parker chose a shared folder over copying the roles into each stage.

Each stage has its own `ansible.cfg` (`roles_path = roles:../ansible-common/roles`),
`requirements.yml` and gitignored `collections/`, and runs from inside its
folder. The root `ansible.cfg` was removed. Both stages pass `--syntax-check` and
`ansible-lint --offline`, and `overture` still answers Ansible's `ping` from
`ansible-hardware/`.

## Windows checkout removed (2026-10-18)

The repository now lives only on Unix-like systems. The on-hold `homelab_pve`
worktree moved into WSL as `~/repositories/homelab_pve`, on branch `pve`, with
all of its uncommitted and ignored files verified by checksum. Parker then
approved deleting the Windows checkout `D:\repositories\homelab` and its
`homelab_pve` worktree. Before deletion, every branch and remote ref was
confirmed present in WSL, there were no stashes or uncommitted changes, and the
ignored `docs/` and decrypted inputs matched WSL's. The only objects lost were
four draft commits from 2026-10-12 that had already been reset away and redone
as `bb36843`. The pre-migration OCI state copies under Windows
`%LOCALAPPDATA%/homelab/oracle-backups/` were outside the checkout and remain.

## One converging playbook per stage (2026-10-18)

Parker decided that each Ansible stage has only `playbooks/site.yml`, whose
plays converge hosts and are safe to rerun. No deliberate operations, such as
rolling reboots or release upgrades, go into Ansible. Package updates come from
each host's own automatic updater (unattended-upgrades, dnf-automatic).
`ansible-generated`'s `base.yml` and `services.yml` were folded into its
`site.yml`. Parker also identified `turk` as Ubuntu 24.04 running VMware
Workstation.

## Generated inventory from OpenTofu state (2026-10-18)

Parker compared three ways to feed `ansible-generated/` from OpenTofu: the
`inventory.py` script reading an `ansible_hosts` output; the `ansible/ansible`
provider with `cloud.terraform.terraform_provider`; and
`cloud.terraform.terraform_state` reading instances straight from state. He chose
`terraform_state` because it scales to more roots and resource types without
HCL changes. `inventory.py` was removed.
- `inventory/oracle.terraform_state.yml` maps tofu/oracle's five
  `oci_core_instance` resources, named by display name. Parker identified each
  wahlecloud instance's VCN DNS name (`<label>.pubsub.wahlecloud.oraclevcn.com`)
  and legacy `web`'s public name (`doppelgangerhq.com`) as their addresses.
  Short names are ambiguous on the tailnet: `tailscalerouter` resolved elsewhere
  first.
- The plugin pulls state in a scratch directory with no `encryption` block, so
  its `binary_path` is a wrapper, `bin/tofu-oracle`, that sets `TF_ENCRYPTION`
  for its own process. The plugin reads `binary_path` raw and runs it from the
  scratch directory, so a relative path fails there; it is the bare name
  `tofu-oracle`, and sourcing `prepare.sh` puts `ansible-generated/bin` on `PATH`.
- With Parker's approval, `cloud.terraform` 4.0.0 was installed into the
  stage's gitignored `collections/`.
- With Parker approving each SSH agent prompt, `ansible generated -m ping -f 1`
  reached all five hosts. Ansible connects by VCN DNS name, which the operator's
  SSH configuration does not match for `bailout`, so its `host_vars` set
  `ansible_user: opc`.
- Each stage gained an `.ansible-lint` that excludes the installed
  `collections/`. With it, a stage's lint no longer follows `../ansible-common`,
  so AGENTS.md now lints the shared roles separately.
- Proxmox guests do not feed `ansible-generated/` yet. That needs a
  `tofu/proxmox` root, which waits on the `bpg/proxmox` provider work, and then
  a `proxmox.terraform_state.yml` source beside the oracle one.

## The gonkputer draft rebased onto master (2026-10-19)

The on-hold `pve` worktree moved to `.claude/worktrees/pve`, and its uncommitted
work was replayed onto `master`. Its rewrite of this file into a "pivots and
findings" format was dropped in favour of `master`'s append-only log; what it had
learned is kept here. Parker kept the root name `tofu/gonkputer`, so the docs
that said `tofu/proxmox` now use it. No existing gonkputer state carries over:
the provider has had several fixes since the draft, so its imports will be redone
from scratch. Where that root's state lives is undecided.

Decisions carried over, updated where later ones replaced them:
- **Read/write credentials, approval-gated (2026-10-12).** `gonkputer` uses a
  `root@pam` API token plus root SSH, because OpenTofu will write back; per-action
  approval is the safeguard.
- **Own provider mirror (2026-10-13).** Provider builds are served by the static
  network mirror `regulad/opentofu-registry` at `https://opentofu.regulad.xyz/`,
  under the `bpg/proxmox` address, so changing builds needs no state migration.
- **Explicit Proxmox defaults, not `ignore_changes` (2026-10-14).** Where a
  setting is unset live and the provider's default differs from Proxmox's
  effective value, `tofu/gonkputer` writes Proxmox's value.
- **Ceph narrowed to RBD (2026-10-14), then widened again (2026-10-19).** The
  draft's plan to manage CephFS and move MDS daemons to OpenTofu was first
  narrowed to the RBD pools and storages, with CephFS and MDS unmanaged. The
  provider build adopted below covers every Ceph object, so all of them are in
  scope again.
- The draft's "containers, then VMs, then hardware hosts" Ansible order was
  dropped; `master`'s hardware-first phase order stands.

Findings about `gonkputer` (Proxmox and Ceph):
- `prodingus` is a standalone pmxcfs node with no corosync configuration, yet the
  HA manager runs with single-node quorum and armed fencing.
- Proxmox VE 9 replaced HA groups with HA rules; one rule references a node,
  `jondingus`, that is not part of the cluster.
- pveproxy's certificate is self-signed by the PVE cluster CA and lacks the
  tailnet name. `tailscale serve` publishes port 8006 on the node's tailnet name
  to the tailnet only, with a Tailscale-issued certificate, so provider TLS
  verification stays on.
- Users and groups are owned by the LDAP realm `home.arpa` and its sync job,
  which removes vanished entries.
- `bpg/proxmox` 0.116.0 renamed its resources to short `proxmox_*` names; the long
  names are deprecated (removal planned for v1.0), and some resources have no
  short name yet. `proxmox_vm` is not the short name of
  `proxmox_virtual_environment_vm` but the experimental former `vm2`, without
  import support.
- Proxmox documents an API for custom CPU models,
  `/cluster/qemu/custom-cpu-models`, which `pvesh ls /cluster` does not show. The
  provider can only reference custom models from `cpu.type`.
- An API token with privilege separation and no ACLs has effectively no
  permissions, while `/version` still answers. `root@pam!homelab` had this until
  privilege separation was disabled.
- The provider has no resources for RBD or CephFS storage, notification endpoints
  and matchers, Ceph configuration, CRUSH rules or CephFS, or the scheduled
  realm-sync job. `proxmox_ceph_pool` exists but is experimental.
- Importing a `proxmox_virtual_environment_file` records only node, storage and
  content type, so an imported snippet plans as a replacement. Creating the
  resource over the live file adopts it in place. Edits on the node are not
  detected.
- PVE returns `number` options as text, so the seven containers that set only
  `cpulimit` report `"cpus": "2"`, which `bpg/proxmox` could not read. Fixed in the
  fork (bpg/terraform-provider-proxmox#3170) and reported to Proxmox as bug 8162.
- `-generate-config-out` emits empty strings and zeros that fail the provider's
  own validators; dropping nulls, provider defaults and empty values left only
  meaningful settings.
- Several provider defaults differ from Proxmox's: the guest firewall's `ndp` and
  `radv`, the cluster and guest output and forward policies, and a VM's
  `scsi_hardware`, which would have swapped the controller under VM 129's boot
  disk.
- The container importer records no `vm_id` and no `timeout_start`, so the first
  plan shows an in-place update that sends no request.
- A force-new attribute that references a resource still to be created forces
  replacement (`vendor_data_file_id` on the cloud-init VMs); literal volume IDs
  with `depends_on` avoid it.
- Plugin Framework defaults are applied during planning, after `ignore_changes`,
  so `ignore_changes` cannot hide a missing default in state.
- `proxmox_ceph_pool` after an import plans an update, and its `add_storages`
  forces replacement. Its update resends every property, including `application`,
  which Proxmox's API cannot set to `mgr`.
- The provider never sends an empty cloud-init password, so an unconfigured one
  stays unmanaged.
- Proxmox's Ceph objects form three layers: Ceph objects (pools, filesystems,
  MDS), storage entries that refer to them by name, and one-shot bridges between
  them. "Add as storage" registers an RBD storage named after the pool; CephFS
  creation makes new `<name>_data` and `<name>_metadata` pools and needs a standby
  MDS.
- `storage.cfg` does not record how an entry was created; the missing `krbd 0`
  lines reflect upgrades from Proxmox VE 7 through 9.
- `prodingus1` was a test MDS at first. By 2026-10-19 Parker had made it a real hot
  spare on the same host, and a second spare, `prodingus2`, had been added.
- The snippet storages hold two scripts no guest references:
  `local:snippets/lxc-bindfs-hook.sh` and `cephfs:snippets/block-ula.sh`.
- Ceph was in HEALTH_WARN at discovery: `osd.1` down, 32 PGs inactive, the `rbd`
  storage unlistable, and stale per-OSD mClock settings for removed OSDs.

Tooling findings:
- OpenTofu selects a provider version across all matching installation methods
  but installs from the first one listed. A network mirror listed before
  `direct {}` answers 404 for official releases, and the install fails, so
  `direct {}` comes first.
- `tofu providers lock` ignores the CLI configuration's installation methods;
  lock mirrored builds with `-net-mirror=<url>`.
- A GitHub Pages custom domain set before its DNS record existed never got a
  certificate. Clearing and re-setting it after DNS resolved fixed that.
- The GUA guard's `\b` boundary also matched later hextets of link-local EUI-64
  addresses; a `(?<![0-9a-f:])` lookbehind fixes it.

Unix port of the draft, approved by Parker:
- `tofu/gonkputer/prepare.ps1` became a sourced `prepare.sh`, like
  `tofu/oracle/prepare.sh`. It exports only `PROXMOX_VE_ENDPOINT` and
  `PROXMOX_VE_API_TOKEN`, rejects any other key, and sets `TF_CLI_CONFIG_FILE` to
  the root's `tofu.rc`. The README, `tofu.rc` and `providers.tf` comments dropped
  their Windows references.
- The decrypted `secrets.auto.tfvars.json`, written on Windows, was converted from
  CRLF to LF; its data did not change.
- The worktree's `tofu/oracle/.terraform/` was copied from the main checkout, so
  nothing was downloaded.
- The draft's `.tf` files were never run through `tofu fmt`; they are left as
  they are, since the imports will be redone.

## gonkputer provider build with full Ceph support (2026-10-19)

- `tofu/gonkputer` now pins `bpg/proxmox` `0.118.0-pr3204.pr3207.pr3209.1` from
  the mirror. Beyond the official `v0.117.0`, which already includes the custom CPU
  model and the string `cpus` fix, this build adds:
  - `proxmox_ceph_pool` fixes: imports plan no changes, `pool_id`, erasure-coded
    pools. Pools no longer create storages; `add_storages`, `remove_storages` and
    `remove_ecprofile` are gone.
  - `proxmox_storage_rbd`.
  - `proxmox_ceph_mds`.
  - `proxmox_ceph_fs`, whose destroy is a manual procedure the provider refuses
    to run, and `proxmox_storage_cephfs`.
- Parker put every Ceph object created through Proxmox in scope: the pools, the
  CephFS, their storages and the `prodingus` MDS. `AGENTS.md`'s Ceph scope
  replaces the RBD-only and unmanaged-MDS decisions.
- Work on the provider itself happens outside this repository, so the docs no
  longer describe it.
- The lock file was regenerated for `linux_amd64` with
  `-net-mirror=https://opentofu.regulad.xyz/`, after removing the old version's
  entry, which `providers lock` refuses to replace. With Parker's approval,
  `tofu init -backend=false` fetched the `linux_amd64` build, and the draft
  validates against it.

## gonkputer re-described from live, with Ceph (2026-10-19)

Proxmox remains authoritative; `tofu/gonkputer` still describes it, not the
other way round.
- A fresh read-only crawl (`docs/snapshot/gonkputer-2026-10-19/`, local only)
  was compared with the first one. Configuration changes since the draft:
  containers 103, 106 and 115 gained the description `amd64v3`; Parker started
  containers 103 and 115 through HA, so their HA state became `started`; and the
  MDS `prodingus1` and `prodingus2` were added as hot spares. The RGW pool
  `default.rgw.buckets.non-ec` went from size 3 to 2, outside this root's scope.
  No VM settings changed, and the 7 snippets still match the live files.
- The draft's guests were updated to match, and `ceph.tf` now describes the
  pools `rbd_ssd` and `rbd_cmr`, the CephFS `cephfs` and the three MDS daemons.
  `storage.tf` gained the storages `rbd`, `rbd_cmr` and `cephfs`, and there are
  9 new import blocks (86 in all). The PG autoscaler is on for every pool, so
  `pg_num` is left to it.
- The first plans stalled for 15 minutes. VM 100's QEMU guest agent answered
  every `network-get-interfaces` call with HTTP 500, and the provider retries
  until its agent timeout (15 minutes by default) runs out. The agent had not
  restarted when Parker re-rooted the VM without a reboot; he started it, and a
  plan then took seconds.
- A 1-minute `agent.timeout` was tried and removed again. It cannot help an
  import, whose first read uses the default before the configuration applies.
  And any change to a VM's `agent` block, even this provider-side attribute,
  makes the provider rewrite the live `agent` line and mark the VM for a reboot,
  which `reboot_after_update` (default true) would carry out.
- The read-only plan then reported 86 to import, 7 to add, 23 to change and 0 to
  destroy. The 7 creates are the snippet uploads. The 23 updates are the draft's
  expected ones: the 20 containers' state-only `vm_id` and `timeout_start`, the
  explicit firewall defaults in `cluster.fw` and `100.fw`, and VM 129's
  `scsihw: lsi`. The 9 Ceph imports plan no changes.

## gonkputer state moved to the shared bucket (2026-10-19)

At Parker's direction:
- `backend.sops.env` moved from `tofu/oracle/` to `tofu/shared/`, since every
  root uses the same backend credentials. Both `prepare.sh` scripts export them
  from there. `svc-tofu-state`'s policy already covers the whole
  `homelab-tofu-state` bucket, so OCI needed no change.
- `tofu/gonkputer` got the same s3 backend as `tofu/oracle`, under the key
  `gonkputer/terraform.tfstate`, keeping its own encryption passphrase.
- The empty local `terraform.tfstate`, left by the read-only plans, was deleted,
  and `tofu init` configured the backend.
- With Parker's approval, each import block's object was imported with
  `tofu import`, one at a time. That records state only; the plan's live
  changes (snippet uploads, explicit firewall defaults, VM 129's `scsihw`) were
  not applied.
- All 86 imports succeeded. A plan against the imported state shows 7 to add,
  23 to change and 0 to destroy, the same live changes as before; the import
  blocks are now no-ops.

## gonkputer adoption applied (2026-10-20)

- The first saved plan failed with HTTP 401 on every read: the `root@pam!homelab`
  API token had expired at midnight. Parker extended it.
- With Parker's approval, the saved plan (7 to add, 23 to change, 0 to destroy)
  was applied. He chose to let the provider reboot VM 129 for `scsihw: lsi`,
  which a `scsi_hardware` change requires; it came back running with the new
  line. Every change applied, but three snippet uploads failed SSH
  authentication when the provider opened its connections as root in parallel.
  The live snippets were unharmed.
- As a workaround, `tofu/gonkputer/prepare.sh` exported
  `TF_CLI_ARGS_apply="-parallelism=1"`, so applies opened one SSH connection at a
  time. A second saved plan, the three remaining uploads, then applied cleanly.
- A fresh plan reports no changes, and all 7 live snippets match the repository
  byte for byte. The import blocks were removed, as the adoption convention says.

## gonkputer cleanup after adoption (2026-10-20)

At Parker's direction:
- Proxmox-generated values left the HCL now that state tracks them, as OCIDs did
  in `tofu/oracle`: `vm_id` on all 32 guests, and `path_in_datastore` and
  `file_format` on VM disks and EFI disks. The backup job's exclusions reference
  the two guests instead of literal `"100"` and `"101"`. MAC addresses stay. The
  plan confirmed that none of these removals changes anything.
- Every guest gets the tag `terraform`, marking it as managed by OpenTofu like
  `managed-by=opentofu` on the OCI instances. Proxmox tags cannot contain `=`, and
  Parker chose `terraform` over `managed-by-opentofu`. A tags change needs no
  reboot.
- The cluster's `next_id` gets `lower = 200`, so new guests are set apart from the
  adopted ones.
- The 14 containers whose whole description was `amd64v3` carry it as a tag
  instead, and their descriptions are removed.
- Tag names live once, in `local.tags` in a new `locals.tf`, and every guest
  references them, so later resources can use the same names.
- Every container's IPv6 method was already `auto`, in the HCL and live, so that
  needed no change.
- Containers moved from `cores` to `limit`. The provider reads a missing `cores`
  as 1 (its comment cites the API documentation), but Proxmox treats it as every
  core. It also sends `cores` on every `cpu` change, 1 when unset. So the seven
  containers with only `cpulimit` were recorded as `cores = 1`, and converting
  `cores = 2` to `limit = 2` would have pinned containers to one core. Parker chose
  an explicit `cores = local.cpu_threads` (32, the node's logical CPUs) on all 20
  containers, with each former core count, 1 or 2, kept as `limit`.
- The "artifact of import" footers stay, as the OCI convention has them.
- With Parker's approval, the plan applied 33 in-place updates: tags on 32
  guests, the CPU change on all 20 containers, 14 descriptions removed, and the
  cluster options. Nothing rebooted, and a fresh plan is a no-op.

## gonkputer feeds ansible-generated (2026-10-20)

At Parker's direction, `ansible-generated` reads both roots as one inventory,
and `site.yml` runs once over the union.
- The `terraform_state` plugin can't filter hosts, join a guest with its HA
  resource, or read a container's nested hostname. So `tofu/gonkputer` declares
  the inventory itself: one `ansible_host` per guest, with the `ansible/ansible`
  provider (1.5.0, installed with Parker's approval). The plugin maps those
  resources, so `ansible-generated` still uses one plugin.
- Parker set which guests count as requested: a started HA resource, or, without
  an HA resource, starting on boot. That gives 30 hosts. `llamarpcmaster`, whose
  HA resource is stopped, and the template stay out.
- Every running guest resolves as `<name>.regulad.internal` from the control node,
  while only five have tailnet names. Hosts are named by that DNS name, which also
  keeps them apart from OCI hosts with the same short name (`tailscalerouter`).
- The OpenTofu registry has no signing key for `ansible/ansible`, so its install
  skipped signature validation; the lock file pins its checksum.
- The two stale PLAN lines were updated.
- With Parker's approval, the 30 `ansible_host` resources were applied, state only.
  The combined inventory lists 35 hosts in `generated`: 30 gonkputer guests and
  the 5 OCI instances. A fresh plan is a no-op.

## cloud-init VMs configured by vendor files (2026-10-20)

Parker decided that gonkputer VMs booting with cloud-init (`authentik`,
`freeipa`, `softether`, `unifi`, `urbackup`) get their whole setup from a
cloud-init vendor file, so nothing needs to SSH into them. This replaces the
earlier rule that cloud-init does only minimal bootstrap and Ansible owns
everything after it. They left `TODO.md`, and AGENTS.md and PLAN describe the
split. `freeipa` has a cloud-init drive but no vendor file yet.

Parker then widened it: every Proxmox VM that can boot with cloud-init moves to
it, and `aboriginal`, `dodo`, `git` and `matrix` lost their `ansible_host` ahead
of that move, leaving `arawi` and `vkasm` as the only VMs in Ansible. LXC
containers stay managed by Ansible, but through the
`community.proxmox.proxmox_pct_remote` connection plugin, which runs `pct` on the
Proxmox node over SSH, instead of SSH into each container. Proxmox has no
cloud-init for containers: bug 4686's patch has not been merged.

## Containers reached through proxmox_pct_remote (2026-10-20)

With Parker's approval:
- `community.proxmox` 2.1.0 is pinned in `ansible-generated/requirements.yml`
  and installed into the stage's `collections/`. `paramiko`, which the plugin
  needs, was already bundled with Homebrew's Ansible (5.0.0), so nothing else
  was installed.
- Each container's `ansible_host` gained `variables`: the node's SSH address,
  from the encrypted `node_ssh_addresses` input, so the tailnet domain stays out
  of git; and the container's `vm_id`. The plugin keeps a dynamic attribute as
  `{type, value}`, so `compose` reads `variables.value`. `group_vars` for
  `proxmox_containers` set the connection plugin and `ansible_user: root`.
- The apply for the five cloud-init VMs' `ansible_host` destroys had already run
  (0 added, 0 changed, 5 destroyed) when Parker interrupted that step to change
  course; nothing was committed then. The follow-up apply destroyed
  `aboriginal`'s, `dodo`'s, `git`'s and `matrix`'s and added the containers'
  variables: 0 added, 19 changed, 4 destroyed. A fresh plan is a no-op.
- The inventory now holds 26 generated hosts: 19 containers through
  `proxmox_pct_remote`, `arawi` and `vkasm` over SSH, and the 5 OCI instances.
- A first ping of `openclaw` through the plugin failed with an authentication
  timeout; a second, at Parker's request, returned `pong`.

## Imperative leftovers removed (2026-10-20)

A survey of `tofu/gonkputer` for leftovers found four candidates. With Parker's
approval, three were destroyed (0 added, 0 changed, 3 destroyed): the HA rule
`ha-rule-157366ac-952c`, which pinned `uptime` to `jondingus`, a node no longer
in the cluster; and the snippets `local:snippets/lxc-bindfs-hook.sh` and
`cephfs:snippets/block-ula.sh`, which no guest referenced. Their copies left
`tofu/gonkputer/snippets/`. Parker kept the USB mapping `Back-UPS`, though no
guest uses it and the device is not attached. A fresh plan is a no-op.

The survey also found that VM 100 has a USB device live in slot `usb4`,
`mapping=CPS`, since the first crawl, which the HCL lacks and no plan reported:
the provider only knows the slots `usb0` to `usb3`. That is bpg issue #3009, open
and confirmed by the maintainer, so a TODO on VM 100 links it instead of a new
issue.

## VM 100's Bluetooth adapter mapped, and root tickets (2026-10-20)

With Parker's approval:
- The ASUS Broadcom BCM20702A0 Bluetooth adapter (`0b05:17cb`) got a USB mapping,
  `BCM20702A0`, created by OpenTofu, and VM 100 uses it instead of raw host
  passthrough. The APC UPS's `usb` block sits commented out in VM 100: the UPS is
  under maintenance.
- VM 100 sets `reboot_after_update = false`. Its passed-through AMD GPU does not
  reset properly when the KVM host detaches and re-attaches it, so it is never
  rebooted on its own: it is rerooted, or restarted with a host reboot.
- The first apply created the mapping but failed on VM 100: Proxmox lets only
  `root@pam` itself set or remove USB passthrough by device ID ("only root can
  set 'usb3' config for real devices"), and the API token does not count. The
  provider's `ssh.root_ticket` is now on: node-scoped calls run as `root@pam` with
  a ticket minted over SSH. Parker asked to drop the API token as well, but calls
  outside `/nodes/` (cluster options, HA, mappings, storage, backup, access) still
  need it, so it stays. Plans now open that SSH connection too.
- The second apply changed VM 100 (0 added, 1 changed, 0 destroyed) without
  rebooting it; the provider warned that a reboot is required. Proxmox shows no
  pending changes, and VM 100's USB slots are now `usb0` AX200, `usb1` TubesZB,
  `usb2` BCM20702A0 and `usb4` CPS. A fresh plan is a no-op.

## Serial-apply workaround removed (2026-10-20)

Parker fixed the operator's SSH agent so that parallel SSH connections
authenticate. `tofu/gonkputer/prepare.sh` no longer exports
`TF_CLI_ARGS_apply="-parallelism=1"`, and the docs no longer describe it.
- Verified without the workaround: a `tofu/gonkputer` plan, which opens the
  root-ticket SSH connection, is a no-op, and `ansible generated -m ping` at the
  default 5 forks reached all 26 hosts, the 19 containers through `prodingus` at
  once. `vkasm` first refused the login as `regulad`: the operator's SSH
  configuration sets `kasm_admin` only for its short name, so its `host_vars` now
  set `ansible_user: kasm_admin`, as `bailout`'s do.

## LXC disks mount with `discard` and `lazytime` (2026-10-20)

At Parker's request, every container's root disk and RBD mount point now mounts
with `["discard", "lazytime"]` instead of `["discard", "noatime"]`;
`llamarpcmaster`'s root disk, which had no mount options, gained them. The CephFS
bind mounts are unchanged.
- Parker approved the apply: 0 added, 20 changed, 0 destroyed. A fresh plan is a
  no-op. Proxmox recorded the options as current, not pending, and `act`'s root
  filesystem showed `relatime,lazytime,discard` without a restart.

## Ansible reads secrets through SOPS (2026-10-20)

Parker chose SOPS for Ansible secrets, read by the `community.sops.sops` vars
plugin, over Ansible Vault and over decrypting to gitignored files. Both stages
pin `community.sops` 2.5.0 and enable the plugin in `ansible.cfg`; the pinned
copy is installed into each stage's `collections/` even though Homebrew's
`ansible` 14.5.0 bundles the same version. He also ruled that salted, adaptive
password hashes such as bcrypt may be committed in plaintext, and that WireGuard
private keys stay SOPS-encrypted.

## arawi discovery for pfsensible (2026-10-20)

`arawi` runs pfSense CE 2.9.0-RELEASE with `python3.11` and the sudo package;
SSH is key-only. Parker chose `pfsensible.core` for its configuration, and
`ansible-generated` pins 0.7.1 (supports pfSense 2.8.0+). He gave the
`group:admins` sudo row `NOPASSWD`, replacing the `user:root` and `user:admin`
rows, so `regulad` can become root unattended. The collection has no modules for
the GRE tunnel, WireGuard or the Cron package.

## arawi: pfsensible scaffold and route descriptions (2026-10-20)

Parker chose per-object `pfsensible.core` modules over templating the whole
`config.xml`, with sections that have no module merged into `config.xml` and
reloaded through PHP. The new `pfsense` role and `arawi`'s generated `host_vars`
check cleanly for setup, log settings, CAs, certificates, groups, users, VLANs,
interfaces, aliases and 7 of 8 gateways; rules need names first. The gaps are
listed in `ansible-generated/inventory/host_vars/arawi.regulad.internal/TODO.md`.
`secrets.sops.yml` keeps both `arawi.regulad.internal` keys and drops the other
certificate and CA keys.
- Parker declared the operator's `config.xml` snapshot authoritative over live
  `arawi`. It gained descriptions for the 6 static routes, named as in the
  role's `host_vars`, and was pushed to `/cf/conf/config.xml` with the config
  cache cleared and Unbound reconfigured. This reverted a DNS Resolver
  custom-options change made on `arawi` after the snapshot. The live file then
  matched the snapshot byte for byte, and `pfsense_route` reported all 6 routes
  unchanged.

## arawi: sections without a pfsensible module (2026-10-20)

Parker asked for the parts of `config.xml` that `pfsensible.core` cannot manage
to be merged into `config.xml` and reloaded through PHP. The `pfsense` role's
new `pfsense_config_section` module, in its `library/`, replaces the children
each section owns when they differ, ignoring whitespace. It writes `config.xml`
through pfsensible's own writer, then runs each changed section's reload from
`pfsense_config_section_reloads`, using pfSense 2.9's own functions, verified on
`arawi`. `arawi` has 15 sections, rendered from
`host_vars/arawi.regulad.internal/config/*.xml.j2`. They also cover outbound NAT,
the DNS Resolver, the two `arawi.regulad.internal` certificates and the
`tailscalerouter6` gateway, which the collection's modules fail on.
- A full `--check` run against `arawi` reported every section unchanged. What
  remains is the rule naming and two DHCP fields pfsensible fills with pfSense's
  effective defaults. No write or reload has run yet.
- A subagent searched `pfsensible/core`'s issues and PRs for the problems we
  found, read-only. The matches are linked from `arawi`'s `TODO.md`.

## Public GUAs in plaintext (2026-10-20)

Parker allowed publicly known GUAs, such as public DNS resolvers, in plaintext.
The `no-gua-ipv6` hook exempts each by an exact-match allowlist, starting with
Cloudflare's `2606:4700:4700::1111` and `::1001` and Quad9's `2620:fe::fe`, and
`AGENTS.md` rule 4 says so. `arawi`'s gateway monitors now name them directly;
`arawi_public_ipv6` left `secrets.sops.yml`.

## arawi: files outside config.xml (2026-10-20)

A read-only scan of `arawi` for files no package owns found six hand-made ones,
which the `pfsense` role now copies as `root:wheel` from
`ansible-generated/files/arawi.regulad.internal/`. They are
`u5g-gre6-sync.php` (cron, every 2 minutes), `tmpfscheck.sh` (the watchdogd
check `afterbootupshellcmd` starts), `rc.d/qemu-agent.sh`, `/etc/rc.conf.local`,
and `/root/.ssh/u5g.pub` and `known_hosts`. The `u5g` private key moved into
`secrets.sops.yml`. The files live outside `inventory/` because `host_group_vars`
loads extensionless files under `host_vars` and every file in `inventory/` is
read as an inventory source. A `--check` run reported all of them unchanged.
- `u5g-gre6-sync.php` rewrites the GRE tunnel's IPv6 addresses in `config.xml`
  when the carrier's `/64` moves. `pfsense_config_section` gained an `ignore`
  option, and the `gre` section ignores `tunnel-local-addr6` and
  `tunnel-remote-addr6`. The stale `tmobile_u5g` prefix left SOPS.
- With Parker's approval, `/root/update_dynamic_npt.php`, which nothing
  referenced, was deleted from `arawi`; the operator's snapshot keeps a copy.

## arawi: rule names, site.yml, docs (2026-10-20)

- With Parker's approval, the snapshot gained descriptions for `arawi`'s 19
  firewall rules, as in `main.yml`, and the aliases `home_ipv6` and
  `tailnet_subnet_ipv6`, which the three rules with IPv6 literal sources now use.
  It was pushed over SSH and the filter reloaded. The live file then matched the
  snapshot, and a full `--check` run left only the two DHCP fields. The WAN rule
  "Allow home IPv6 to any" is not compiled because WAN is not enabled; it was not
  before either.
- `site.yml` runs the `pfsense` role on a new `arawi` group and keeps that group
  out of the baseline play. Parker chose a group for `arawi` alone over a
  `pfsense` group, since another pfSense host would not share its
  configuration. `arawi`'s `ansible_host` gained the group. Parker approved the
  apply: 0 added, 1 changed, 0 destroyed, and a fresh plan is a no-op.
- `AGENTS.md` documents the `pfsense` role, `ansible-generated/files/`, and the
  pfSense conventions. The unused `arawi_ntopng_redis_password` left SOPS.
- `arawi`'s `main.yml` now indents sequences and writes certificates as PEM and
  authorized keys as text, except `internal-ca`, whose CRLF PEM stays base64.
  Both stages' `.ansible-lint` exclude `*.sops.yml`, whose ciphertext cannot be
  wrapped.

## arawi: pfSense release pin and packages (2026-10-20)

pfSense installs the packages `config.xml` lists only at a boot that finds
`/cf/conf/needs_package_sync`; otherwise it registers installed packages into
`config.xml`. The `pfsense` role now installs missing `pfsense_packages` through
pfSense's own `installpkg` playback and never removes any. Parker asked to pin
the role to pfSense's major version, with 2.9 as the fallback if pfSense does not
follow semantic versioning. It does not: its minor releases change the FreeBSD
base, the config revision and package builds, and pfsensible 0.7.0 needs 2.8.0
or later. So `pfsense_release` pins `arawi` to 2.9, and the role refuses any
other release. Check mode passed on `arawi`, refused a 2.8 pin, and reported a
missing package without installing it.

## arawi: the WireGuard ACL has one source (2026-10-20)

The WireGuard package deletes and recreates its "WireGuard" ACL in
`unbound/acls` on every resync, from the tunnels' addresses, while the
`dns_resolver` section owned all of `unbound`. With Parker's approval, the
section now ignores `acls[aclname='WireGuard']`. `pfsense_config_section`'s
`ignore` now keeps each ignored element's whole live subtree, at its live
position, and templates leave ignored paths out. A `--check` run against `arawi`
reported every section unchanged. Parker noted that `U5G_GRE` cannot have a static
IPv6, because pfSense manages GRE addressing elsewhere, so `u5g-gre6-sync.php`'s
interface branch never conflicts with `pfsense_interface`.

## arawi: more of config.xml in sections (2026-10-20)

Parker chose which unmanaged parts of `config.xml` to take on. New sections own
the sudo rules, SSH, the serial console, the System > Advanced settings without
a module, `afterbootupshellcmd`, the filter settings beside the rules,
`diag/ipv6nat`, and the unused features, kept empty. Each reloads as pfSense's
own page does, verified on `arawi`. Gateways and DHCP moved from pfsensible to
the `gateways` and `dhcp` sections, because `pfsense_gateway` and the DHCP
modules cannot model fields `arawi` sets; that also ended the two cosmetic DHCP
fields. Both earlyshellcmds belong to their packages (System Patches and
WireGuard), and `pkg_repo_conf_path` to pfSense's updater, so they stay
unmanaged, with the other parts Parker left to pfSense. `pfsense_shellcmd`
manages only the Shellcmd package's commands, so the watchdog command is a
section. A full `--check` run against `arawi` reported `changed=0`.

## arawi: first real run (2026-10-20)

With Parker's approval, `site.yml` ran for real against `arawi` through the real
inventory (`--limit arawi.regulad.internal`), after a `--check` run the same way.
The baseline play matched no hosts and the `Arawi` play reported `ok=15
changed=0`. `config.xml` on `arawi` was byte-identical before and after the
run, so no section wrote and no reload ran.

## arawi: end-to-end check (2026-10-20)

A `tofu/gonkputer` plan was a no-op; the inventory, read from its state, put
`arawi.regulad.internal` in the `arawi` group; and a `site.yml --check` run
through it reported `changed=0`. OpenTofu's three NICs matched `arawi`'s `vtnet0`
to `vtnet2` by MAC. The guest agent answered `qm agent 108 ping`, the IPMI
module and `tmpfscheck.sh` watchdog were running, and the console is on
`ttyu0`. `vtnet1` runs at MTU 1500 although OpenTofu and `config.xml` both say
9000, because pfSense leaves the WAN interface, which is not enabled, unconfigured.

## pfsensible.core issues filed (2026-10-20)

With Parker's approval, his GitHub account filed seven bug reports (#267–#273)
and thirteen feature requests (#274–#286) on `pfsensible/core`, each reproduced
in check mode against `arawi` with documentation addresses, and each disclosing
that Claude drafted it. Reproducing corrected two earlier findings: the
`pfsense_dns_resolver` crash comes from `sslcert` naming a description two
certificates share, and `pfsense_rule`'s IPv6 error on 0.7.1 is #219's, already
fixed on `master`. It also found that `pfsense_dns_resolver` rejects IPv6
domain-override servers. The account left a 👍 on #128, #164 and #265 and
posted no comments. `arawi`'s `TODO.md` links every issue. The project has no
policy on AI-assisted contributions; its maintainer wrote on #153 that there is
none.

## arawi: split-horizon regulad.xyz through an Unbound RPZ (2026-10-20)

Parker approved the first configuration change made through the `pfsense`
role, from a handoff by another agent. LAN clients now reach `regulad.xyz`
names at their internal addresses through CNAME chains too, which view
`local-data` could not do. A `lan`-tagged RPZ replaces the four `regulad.xyz`
view overrides. A `stub-no-cache` stub zone keeps cached public answers from
reaching LAN clients, and `module-config` adds `respip`. The zonefile's master
lives at `/usr/local/etc/unbound/`, and its copy in the chroot on the `/var`
RAM disk is recreated at boot by `unbound-rpz-restore.sh`. That script runs from
the repository's one `earlyshellcmd`, in its own `unbound_rpz_boot` section. The
role gained its first handler, which reloads changed zones through
`unbound-control`.
- Pre-flight on `arawi` found Unbound 1.26.1, not the 1.24.2 the handoff
  tested offline, and `/usr/local/etc/unbound` owned `unbound:wheel`, so it
  stays out of `pfsense_directories`. `unbound-checkconf` passed a copy of
  `unbound.conf` with the new custom options.
- The run wrote the three files and both sections, restarted Unbound, and
  reloaded `split-horizon.rpz.`. As a `lan` client, `prodingus` resolved
  `nextcloud.regulad.xyz` through `ingress.regulad.xyz` and
  `ingress.regulad.internal` to 10.23.2.31, and `ingress`, `dodo`, `mail` and
  `livekit` to their internal addresses. Untagged, `arawi` got the public chain
  to 173.54.15.27, with `ad` when it asked with DNSSEC OK. No guest client was
  tested. A second `--check` reported `changed=0`, and the snapshot was
  refreshed from live. The reboot test is still to do.

## arawi: PHP2Shell stopgap (2026-10-21)

Before PHP's 14:00 UTC release for PHP2Shell (CVE-2026-109618, CVE-2026-109619),
`arawi` ran PHP 8.5.7 with `session.upload_progress.enabled` on. The `pfsense`
role gained a `restarts_php_fpm` key for `pfsense_files`, whose handler runs
pfSense's `/etc/rc.php-fpm_restart`, and `arawi` got
`/usr/local/etc/php/99-php2shell.ini` turning upload progress off. The ini goes
in PHP's scan directory because `/etc/rc.php_ini_setup` rewrites `php.ini` on
every php-fpm restart. The setting is a partial mitigation only. With Parker's
approval, `site.yml` ran against `arawi` after a `--check` run showing only that
file: `ok=16 changed=2` (the file and the restart). Afterwards php-fpm reported
the setting `Off` from the new file, the web GUI answered, and a second
`--check` run reported `changed=0`.

## pterodactyl: PHP2Shell stopgap (2026-10-21)

With Parker's approval, and by hand because no role manages `pterodactyl` yet,
the container got `/etc/php/8.3/fpm/conf.d/99-php2shell.ini` turning
`session.upload_progress.enabled` off, and its `www` pool a
`php_admin_flag[session.upload_progress.enabled] = off` so a `.user.ini` cannot
turn it back on (none exist). php8.3-fpm (8.3.6-0ubuntu0.24.04.12) was reloaded
after a passing config test, and a request through the FPM socket read the
setting as off. nginx, stopped earlier that day, was started again; the panel
answers on `pterodactyl.regulad.xyz`, still without the client-certificate gate.
The setting is a partial mitigation until Ubuntu ships a fixed php8.3.

## pterodactyl: PHP2Shell stopgap moved into Ansible (2026-10-21)

The hand-made stopgap is now declared: a `php_fpm` role in `ansible-generated`
copies ini files into the FPM's `conf.d` from `files/<host>/` and keeps
`php_admin_flag` lines in a pool's file, testing the configuration before it
reloads php-fpm. `pterodactyl`'s `host_vars` and its copy of `99-php2shell.ini`
describe the live change byte for byte, and `site.yml` gained a play for the
`php_fpm` group. With Parker's approval, the `tofu/gonkputer` plan adding
`php_fpm` to `ansible_host.pterodactyl`'s groups was applied (0 added,
1 changed, 0 destroyed), and a fresh plan was a no-op. `site.yml` then ran
against `pterodactyl` through the real inventory, in check mode and for real,
each reporting `ok=4 changed=0`; the panel kept answering.
