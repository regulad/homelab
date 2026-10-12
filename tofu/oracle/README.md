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

Each host has an `instance-<name>.tf` file containing, in order, any host-local
constants, its instance, boot volume, backup-policy assignment where present, VNIC
lookup, IPv6 assignment, and dedicated firewall resources. These files are
`legacy/instance-web.tf` and `wahlecloud/instance-{bailout,livekit,mail,router}.tf`.
The web-only agent policy is grouped with the web instance.

Each subnet has a `subnet-<name>.tf` file containing the subnet, followed by the
DHCP options, route table, and security list that only it uses:
`wahlecloud/subnet-public.tf` (`pubsub`) and
`legacy/subnet-subnet--20230331--2242.tf`. A `-` inside a name is written as `--`
because `-` already delimits the prefix. Each module's `network.tf` contains its
network-wide locals, VCN, internet gateway, and the DHCP options, route table, and
security list OCI created with the VCN, in that order. Legacy's subnet uses those
VCN defaults; wahlecloud's `pubsub` attaches the default security list alongside
its own.

Within a resource, scalar arguments come before nested blocks, and the
import-artifact `lifecycle` footer (with the boot-volume `source_details`
placeholder) stays last.

Wahlecloud's shared agent plugin policy remains in `wahlecloud/locals.tf`. `variables.tf` declares
each module's inputs. Email resources live in `wahlecloud/email.tf`. Child modules
declare the OCI provider source but inherit the root's provider instance; version
pins live only in the root `versions.tf`.

Matching IPv4/IPv6 firewall rules and internet routes share the CIDR maps in
`wahlecloud/network.tf`: `local.dual_stack_internet_cidrs` and
`local.dual_stack_vcn_sources`. An NSG rule uses
`for_each = local.dual_stack_internet_cidrs` and `source = each.value`, keeping
its ports, protocol, and other settings together in its instance file. Nested
security-list rules and internet routes use `dynamic` blocks with the same maps. The stable `ipv4`
and `ipv6` keys preserve identities independently of ordering.
`wahlecloud/moved.tf` maps the former separate NSG rules to those keyed instances
and chains after the root's module moves. Only matching pairs are consolidated;
bailout's different IPv4/IPv6 ports and the distinct ICMP rules remain explicit.

`local.dual_stack_homelab_cidrs`, at the top of `wahlecloud/subnet-public.tf`
because the homelab is bridged to that subnet, pairs `10.23.0.0/20` with the homelab IPv6 ULA
`fd83:b84c:aa57:1::/64` (fourth hextet `0001`). Its routes select the router's
next-hop ID by IP family. The existing homelab security-list ingress rule remains
IPv4-only; the shared address pair does not implicitly add firewall permissions.

The non-sensitive sender addresses are listed in `local.email_senders` at the top
of `wahlecloud/email.tf`. One sender resource uses `for_each` over that list, keyed
by email address so reordering the list does not change resource identities.

IPv4 addresses/CIDRs, ULA and Tailscale ranges are plaintext HCL.
`../shared/tailscale.tf` exports the common Tailscale IPv4/IPv6 ranges through a
resource-free module that future provider roots can also call. Both OCI modules
receive its `tailscale_cidrs` output. Wahlecloud also names its repeated home-LAN
CIDR and router address in locals. GUA IPv6 `/64` prefixes remain encrypted in
`ipv6_subnet_cidrs`; our router next-hop OCIDs remain encrypted in
`router_next_hop_ids`. Each module receives its own sensitive
`ipv6_subnet_cidr`; instance files combine that prefix with a plaintext 64-bit
hexadecimal host suffix using `cidrhost` and `parseint`. The enclosing wahlecloud
`/56` is derived from its `/64`, so no GUA network prefix is published in HCL.

`secrets.sops.json` stores those prefixes and the other inputs that remain
sensitive: tenancy/backup-policy/next-hop identifiers, account-specific
availability-domain names, instance metadata, and the state encryption passphrase.
`shared_ssh_metadata` holds the SSH metadata shared by web and bailout;
`backup_policy_id` is the single policy shared by livekit, mail, and router.
Verified stock image IDs are plaintext in each instance file, with the exact
image name above `source_id`. These Oracle-owned regional images are shared
across tenancies. Custom-image IDs owned by our compartments remain sensitive.
It contains no HCL or resource definitions.
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
- Router address IDs used as route next hops are explicit sensitive inputs.
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
