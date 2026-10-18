# OCI infrastructure

The `.tf` files in the `legacy` and `wahlecloud` child modules are the source of
truth. They describe 76 managed resources, ordinary configuration values,
nested blocks, and direct resource references. Run OpenTofu from this root so both
modules share the existing provider configuration and encrypted state.

| Location | Configuration |
|---|---|
| `legacy/` | Legacy VCN and networking, web instance, boot volume, backup-policy assignment and IPv6 assignment (10 resources) |
| `wahlecloud/` | Wahlecloud VCN and networking, bailout/livekit/mail/router hosts, volumes, IPv6 and Email Delivery (66 resources) |
| `main.tf` | Local module calls, the availability-domain lookup, and explicit provider/input wiring |
| `moved.tf` | Mappings from the original root addresses to their module addresses |
| `providers.tf`, `versions.tf` | Shared OCI authentication, region and pinned tool/provider versions |
| `state.tf` | Enforced encryption for local state and saved plans |

Each host has an `instance-<name>.tf` file containing, in order, any host-local
constants, its instance, boot volume, backup-policy assignment, VNIC
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

Wahlecloud's shared agent plugin policy, backup policies, and platform images are in `wahlecloud/locals.tf`. `variables.tf` declares
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
sensitive: the tenancy and router next-hop identifiers, and the state encryption
passphrase. It contains no HCL or resource definitions.
`variables.tf` declares these inputs. `prepare.ps1` decrypts them into the ignored
`secrets.auto.tfvars.json`; it does not generate `.tf` files.

Values that are not ours, or not secret, stay out of SOPS:

- Verified Oracle platform-image IDs are plaintext in each module's
  `platform_image_ids` map, keyed by exact image name. Instances select theirs by
  that name. These Oracle-owned regional images are shared across tenancies.
  Custom-image IDs owned by our compartments remain sensitive.
- Every boot volume is assigned Oracle's predefined `bronze` backup policy from
  each module's `backup_policy_ids` map. Its realm-wide OCID belongs to no
  compartment.
- The maps live in `wahlecloud/locals.tf` and at the top of
  `legacy/instance-web.tf`, the only file in `legacy` that uses them.
- Each instance's SSH public key is plaintext in its `metadata`. Web and bailout
  share one key.
- Availability-domain names carry a tenancy-specific prefix, so `main.tf` looks
  them up from the tenancy and passes them to both modules, keyed `ad_<number>`.

## Local checks

From the repository root, in PowerShell 7.5 or newer:

```powershell
./tofu/oracle/prepare.ps1
$env:OCI_CLI_AUTH = 'security_token'
$env:OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING = 'True'
oci session validate --profile DEFAULT
tofu '-chdir=tofu/oracle' init '-backend=false' '-input=false' '-lockfile=readonly'
tofu '-chdir=tofu/oracle' fmt '-check' '-recursive'
tofu '-chdir=tofu/oracle' validate
tofu '-chdir=tofu/oracle' plan '-input=false' '-detailed-exitcode'
```

State is **local**, in the ignored `terraform.tfstate`, with enforced AES-GCM
encryption. The generated encryption passphrase is stored in `secrets.sops.json`.
Do not change or lose that passphrase. Saved plans are also
encrypted; plaintext JSON plan output must stay in `docs/snapshot/`.

Encrypted state copies and SOPS-encrypted inputs are backed up outside this
repository under `%LOCALAPPDATA%/homelab/oracle-backups/`. Keep the matching age
identity safe. No remote backend is configured; it is deferred until the rest of
the repository is ready.

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
- The SearchDomain DHCP option omits `server_type`, which does not apply to that
  option type.

Discovery output, including `SUMMARY.md`, stays local in `docs/snapshot/`. Every
Oracle mutation or state change needs Parker's explicit approval.

References:
- [OpenTofu import blocks](https://opentofu.org/docs/language/import/)
- [OCI provider authentication](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/configuring.htm)
- [Pinned boot-volume schema](https://github.com/oracle/terraform-provider-oci/blob/v9.9.0/internal/service/core/core_boot_volume_resource.go)
