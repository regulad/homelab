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
