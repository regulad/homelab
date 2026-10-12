# OCI infrastructure

The `.tf` files are the source of truth. They contain 74 explicitly named resources,
ordinary configuration values, nested blocks, and direct resource references.
Edit these files to change the infrastructure definition.

| File | Configuration |
|---|---|
| `instances.tf` | Five instances, shapes, CPU/memory, launch options, agent plugins and VNIC settings |
| `volumes.tf` | Boot volumes and backup-policy assignments |
| `network.tf` | VCNs, subnets, DHCP options and internet gateways |
| `routes.tf` | Route tables and routes |
| `firewall.tf` | Security lists, NSGs and individual firewall rules |
| `ipv6.tf` | Existing IPv6 assignments |
| `email.tf` | Email domain, senders, DKIM and the mail policy |
| `data.tf` | Read-only VNIC lookups for the existing instances |
| `state.tf` | Enforced encryption for local state and saved plans |

`secrets.sops.json` stores input values only: OCI identifiers, account-specific
availability-domain names, non-public network addresses/CIDRs, identity tags,
email addresses and instance metadata. It contains no HCL or resource definitions.
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
tofu '-chdir=tofu/oracle' fmt '-check'
tofu '-chdir=tofu/oracle' validate
tofu '-chdir=tofu/oracle' plan '-input=false' '-detailed-exitcode'
```

On 2026-10-12, Parker authorized adoption. The exact verified plan applied
successfully: **74 imported, 0 added, 0 changed, 0 destroyed**, using OpenTofu
1.13.1 and oracle/oci 9.9.0. A fresh post-adoption plan reports **No changes**
(exit code 0). Completed import blocks are archived locally in
`docs/snapshot/oci/adopted-imports.tf`; encrypted import IDs remain available
for recovery. No Oracle resource mutations were performed.

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
