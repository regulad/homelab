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
