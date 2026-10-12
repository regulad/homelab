# OCI infrastructure

The `.tf` files in the `legacy` and `wahlecloud` child modules are the source of
truth. They describe 74 managed resources, ordinary configuration values,
nested blocks, and direct resource references. Run OpenTofu from this root so both
modules share the existing provider configuration and encrypted state.

| Location | Configuration |
|---|---|
| `legacy/` | Legacy VCN and networking, web instance, boot volume and IPv6 assignment (9 resources) |
| `wahlecloud/` | Wahlecloud VCN and networking, bailout/livekit/mail/router hosts, volumes, IPv6 and Email Delivery (65 resources) |
| `main.tf` | Local module calls and explicit provider/input wiring |
| `moved.tf` | Mappings from the original root addresses to their module addresses |
| `providers.tf`, `versions.tf` | Shared OCI authentication, region and pinned tool/provider versions |
| `state.tf` | Enforced encryption for local state and saved plans |

Each child module groups its resources into `instances.tf`, `volumes.tf`,
`network.tf`, `routes.tf`, `firewall.tf`, and `ipv6.tf`. Its `data.tf` looks up
VNICs, `locals.tf` declares its existing agent plugin policy, and `variables.tf`
declares its inputs. Email resources live in `wahlecloud/email.tf`. Child modules
declare the OCI provider source but inherit the root's provider instance; version
pins live only in the root `versions.tf`.

The non-sensitive sender addresses are listed in `local.email_senders` at the top
of `wahlecloud/email.tf`. One sender resource uses `for_each` over that list, keyed
by email address so reordering the list does not change resource identities.

`secrets.sops.json` stores input values only: OCI identifiers, account-specific
availability-domain names, non-public network addresses/CIDRs,
and instance metadata. It contains no HCL or resource definitions.
`variables.tf` declares these inputs. `prepare.ps1` decrypts them into the ignored
`secrets.auto.tfvars.json`; it does not generate `.tf` files.

## Local checks

From the repository root, in PowerShell 7.5 or newer:

```powershell
./tofu/oracle/prepare.ps1
$env:OCI_CLI_AUTH = 'security_token'
$env:OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING = 'True'
oci session validate --profile DEFAULT
tofu '-chdir=tofu/oracle' init '-backend=false' '-input=false'
tofu '-chdir=tofu/oracle' fmt '-check' '-recursive'
tofu '-chdir=tofu/oracle' validate
tofu '-chdir=tofu/oracle' plan '-input=false' '-detailed-exitcode'
```

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

**Module split prepared (2026-10-12):** all resources and VNIC lookups now live
under `legacy/` or `wahlecloud/`. The root retains shared provider/state setup,
input loading and module/migration wiring. Formatting and validation pass. A
fresh plan reports **0 to add, 0 to change, 0 to destroy**, with all 74 managed
resource IDs and values preserved. The plan exits with code 2 because address
moves are pending; no apply or state mutation has been performed for this split.
Keep `moved.tf` for migration of existing state and older backups. Local evidence
is in `docs/snapshot/oci/module-split-plan.log`.

The subsequent sender-list change removes the email-address input from SOPS and
maps the two original sender addresses to their new `for_each` addresses in
`moved.tf`. After renewing the OCI DEFAULT session, the fresh live plan reports
**0 to add, 2 to change, 0 to destroy**. Both updates only remove the sensitivity
label from `email_address`; the addresses themselves are unchanged. All 74
managed resources retain identical IDs and values, and all have mappings from
their original root addresses. Refreshed values also match the saved state.
Formatting and validation pass. Evidence is in
`docs/snapshot/oci/sender-list-verified-plan.log` and
`docs/snapshot/oci/sender-list-verification.json`. Nothing has been applied for
either the module split or the sender-list change; the state file is unchanged.

State is currently **local**, in the ignored `terraform.tfstate`, with enforced
AES-GCM encryption. The generated encryption passphrase is stored in
`secrets.sops.json`. Do not change or lose that passphrase. Saved plans are also
encrypted; plaintext JSON plan output must stay in `docs/snapshot/`.

An encrypted state copy and SOPS-encrypted inputs are backed up outside this
repository under `%LOCALAPPDATA%/homelab/oracle-backups/`. Recovery of the backup
was verified by reading all 74 managed resources. Keep the matching age identity
safe. A remote backend has not been configured; no OCI bucket or locking resource
was created during adoption.

## Ownership and adoption details

- All managed resources have `prevent_destroy = true`. Do not remove this to get
  an unexpected replacement through a plan.
- Image-created boot volumes expose no creation source. The provider requires a
  `source_details` block, so these existing volumes use a schema-only `bootVolume`
  type with no invented source ID and `ignore_changes = [source_details]`.
  A new volume requires a separately reviewed valid creation/restore source.
- Standalone boot-volume and IPv6 resources own those settings. Instance
  lifecycle rules ignore only the overlapping launch-time volume capacity,
  volume performance and IPv6 assignment fields.
- Router address IDs used as route next hops remain explicit encrypted inputs.
  Referencing the router resources here would create a route/subnet/instance
  dependency cycle. Gateway routes use direct resource references.
- Each discovered instance has one attached VNIC. `one()` deliberately fails if
  that changes, requiring review of primary-VNIC selection.
- Public IPv4 addresses are ephemeral. Instance VNIC configuration preserves
  allocation behavior; it does not promise the same address after recreation.
- The provider generated an invalid empty `server_type` on a SearchDomain DHCP
  option. Omitting the inapplicable field preserves the existing configuration.

Review `docs/snapshot/SUMMARY.md` locally. Remote state with shared locking remains
a follow-up. Obtain Parker's explicit approval before further Oracle mutations or
state-changing operations.
No automatic commits or infrastructure writes are part of the local workflow.

References:
- [OpenTofu import blocks](https://opentofu.org/docs/language/import/)
- [OCI provider authentication](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/configuring.htm)
- [Pinned boot-volume schema](https://github.com/oracle/terraform-provider-oci/blob/v9.9.0/internal/service/core/core_boot_volume_resource.go)
