# OCI infrastructure

The `.tf` files in this directory are the source of truth. They describe 107
managed resources, ordinary configuration values, nested blocks, and direct
resource references. The root is one flat module: OpenTofu loads no
subdirectories into a module, so its files are grouped by name prefix instead.

| Files | Configuration |
|---|---|
| `network-legacy.tf`, `subnet-subnet--20230331--2242.tf`, `instance-web.tf` | The legacy VCN and its networking, and the web instance with its boot and data volumes, their backup-policy assignments, the data volume's attachment, and its IPv6 assignment (13 resources) |
| `network-wahlecloud.tf`, `subnet-public.tf`, `instance-{bailout,livekit,mail,pihole2,riko,router}.tf` | The wahlecloud VCN and its networking, and the bailout, livekit, mail, pihole2, riko and router hosts with their volumes, mail's data volume with its attachment and backup-policy assignment, IPv6 assignments and NSGs (77 resources) |
| `email.tf` | Email Delivery: the `regulad.xyz`, `nefumllc.com` and `regulad.net` domains, their DKIM keys and senders, and the `svc-mail` policy |
| `state-bucket.tf`, `state-identity.tf` | The `homelab-tofu-state` bucket, and the `svc-tofu-state` user, group and policy the backend authenticates with (6 resources) |
| `main.tf` | The availability-domain lookup and the `tofu/shared` module call |
| `outputs.tf` | The instances' public addresses and the DKIM key's CNAME record, which `tofu/cloudflare` reads for its DNS records |
| `locals.tf` | Values several files share |
| `moved.tf` | Every past address of each resource |
| `providers.tf`, `versions.tf` | Shared OCI authentication, region and pinned tool/provider versions |
| `state.tf` | The s3 backend, and enforced encryption for state and saved plans |

Each host has an `instance-<name>.tf` file containing, in order, any host-local
constants, its instance, boot volume, backup-policy assignment, each data
volume with its attachment and backup-policy assignment, VNIC lookup, IPv6
assignment, and dedicated firewall resources. These files are
`instance-web.tf` and `instance-{bailout,livekit,mail,pihole2,riko,router}.tf`.
Web's own agent plugin policy is at the top of its file. pihole2 and riko,
which OpenTofu created rather than adopted, take their boot volume and IPv6
address at launch, so they have no boot-volume, VNIC-lookup or IPv6 resources
of their own; their backup-policy assignments name the instance's boot volume.

Web's data volume, for the devices' data in `/opt/doppelganger`, and mail's,
for docker-mailserver's mailboxes, state and logs in `/mnt/mailserver`, are each
attached paravirtualized at Oracle's consistent device path
`/dev/oracleoci/oraclevdb`.

Each subnet has a `subnet-<name>.tf` file containing the subnet, followed by the
DHCP options, route table, and security list that only it uses:
`subnet-public.tf` (`pubsub`) and `subnet-subnet--20230331--2242.tf`. A `-`
inside a name is written as `--` because `-` already delimits the prefix. Each
VCN's `network-<vcn>.tf` contains its own locals, the VCN, its internet gateway,
and the DHCP options, route table, and security list OCI created with the VCN,
in that order. Legacy's subnet uses those VCN defaults; wahlecloud's `pubsub`
attaches the default security list alongside its own.

Within a resource, scalar arguments come before nested blocks, and the
import-artifact `lifecycle` footer (with the boot-volume `source_details`
placeholder) stays last.

`locals.tf` holds the values several files share: the Oracle Linux instances'
agent plugin policy, Oracle's backup policies and platform images, and
`local.dual_stack_internet_cidrs`. `variables.tf` declares the root's inputs,
and version pins live only in `versions.tf`.

Matching IPv4/IPv6 firewall rules and internet routes share the CIDR maps
`local.dual_stack_internet_cidrs`, in `locals.tf`, and
`local.dual_stack_wahlecloud_cidrs`, in `network-wahlecloud.tf`. An NSG rule uses
`for_each = local.dual_stack_internet_cidrs` and `source = each.value`, keeping
its ports, protocol, and other settings together in its instance file. Nested
security-list rules and internet routes use `dynamic` blocks with the same maps. The stable `ipv4`
and `ipv6` keys preserve identities independently of ordering.
`moved.tf` maps the former separate NSG rules to those keyed instances. Only
matching pairs are consolidated; bailout's different IPv4/IPv6 ports and the
distinct ICMP rules remain explicit.

`moved.tf` keeps every address each resource has had. The resources began at
this root, moved into the child modules `legacy`, `wahlecloud` and
`state_backend`, and came back. Moves chain only between addresses of the same
kind, so keyed resources move one instance at a time.

`local.dual_stack_homelab_cidrs`, at the top of `subnet-public.tf`
because the homelab is bridged to that subnet, pairs `10.23.0.0/20` with the homelab IPv6 ULA
`fd83:b84c:aa57:1::/64` (fourth hextet `0001`). Its routes select the router's
next-hop ID by IP family. The existing homelab security-list ingress rule remains
IPv4-only; the shared address pair does not implicitly add firewall permissions.

The non-sensitive sender addresses are listed in `local.email_senders` at the top
of `email.tf`. One sender resource uses `for_each` over that list, keyed
by email address so reordering the list does not change resource identities.

IPv4 addresses/CIDRs, ULA and Tailscale ranges are plaintext HCL.
`../shared/tailscale.tf` exports the common Tailscale IPv4/IPv6 ranges through a
resource-free module that every provider root can call; the network and subnet
files read its `tailscale_cidrs` output. Wahlecloud also names its repeated
home-LAN CIDR and router address in locals. GUA IPv6 `/64` prefixes remain
encrypted in `ipv6_subnet_cidrs`, keyed by VCN; our router next-hop OCIDs remain
encrypted in `router_next_hop_ids`. Instance files combine their VCN's prefix
with a plaintext 64-bit hexadecimal host suffix using `cidrhost` and
`parseint`. The enclosing wahlecloud `/56` is derived from its `/64`, so no GUA
network prefix is published in HCL.

`secrets.sops.json` stores those prefixes and the other inputs that remain
sensitive: the tenancy and router next-hop identifiers, and the state encryption
passphrase. It contains no HCL or resource definitions.
`variables.tf` declares these inputs. `prepare.sh` decrypts them into the ignored
`secrets.auto.tfvars.json`; it does not generate `.tf` files.

`tofu/shared/backend.sops.env`, shared by every root, holds what the s3 backend reads from
the environment:
`svc-tofu-state`'s customer secret key (`AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY`), and the endpoint `AWS_ENDPOINT_URL_S3`, which contains
the tenancy's namespace. Sourcing `prepare.sh` exports all three into the current
shell, so none of them reaches `.terraform/` or a saved plan. The key is created
outside OpenTofu, so it never lives in the state it unlocks.

`provider.sops.env` holds what the OCI provider reads from the environment: an
API signing key on Parker's user (`OCI_PRIVATE_KEY`, its newlines written `\n`),
its fingerprint (`OCI_FINGERPRINT`) and his user OCID (`OCI_USER_OCID`).
Sourcing `prepare.sh` exports them too, so the key also stays out of
`.terraform/` and saved plans. A session token lasts at most 24 hours; the key
lasts until it is deleted from his user in the OCI console, which revokes it.
To replace it, generate a new key, upload its public half, and update the file.

Values that are not ours, or not secret, stay out of SOPS:

- Verified Oracle platform-image IDs are plaintext in `locals.tf`'s
  `platform_image_ids` map, keyed by exact image name. Instances select theirs by
  that name. These Oracle-owned regional images are shared across tenancies.
  Custom-image IDs owned by our compartments remain sensitive.
- Every boot volume is assigned Oracle's predefined `bronze` backup policy from
  `locals.tf`'s `backup_policy_ids` map. Its realm-wide OCID belongs to no
  compartment.
- Each instance's SSH public key is plaintext in its `metadata`. Web and bailout
  share one key; pihole2 and riko carry the key GitHub publishes for regulad.
- Availability-domain names carry a tenancy-specific prefix, so `main.tf` looks
  them up from the tenancy, keyed `ad_<number>`, and marks them sensitive so
  plans redact them.

## Local checks

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/oracle/prepare.sh
tofu -chdir=tofu/oracle init -input=false -lockfile=readonly
tofu -chdir=tofu/oracle fmt -check -recursive
tofu -chdir=tofu/oracle validate
tofu -chdir=tofu/oracle plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that
runs `tofu`. It needs `sops`, `jq` and `git`, and reports failure through its
exit status without closing the shell.

State is **remote**: the s3 backend stores it as `oracle/terraform.tfstate` in
the versioned `homelab-tofu-state` bucket, through OCI's S3 Compatibility API.
`use_lockfile` takes an S3-native lock (`oracle/terraform.tfstate.tflock`) with a
conditional write, which OCI honours. That was verified on 2026-10-18 with
simultaneous applies. State is encrypted with AES-GCM before upload, so the bucket
holds only ciphertext. The generated encryption passphrase is stored in
`secrets.sops.json`. Do not change or lose that passphrase. Saved plans are also
encrypted; plaintext JSON plan output must stay in `docs/snapshot/`.

Every workstation needs only a clone and the age identity: `prepare.sh` and
`init` give it the shared state. Bucket versioning keeps each earlier state
version, so applies need no separate backups. The local state copies from before
the migration, kept on the former Windows workstation under
`%LOCALAPPDATA%/homelab/oracle-backups/`, have a different lineage than the
remote state, so restoring one needs `tofu state push -force`.

## Ownership and adoption details

- All adopted resources have `prevent_destroy = true`. Do not remove this to get
  an unexpected replacement through a plan. Resources created by OpenTofu, such
  as those in `state-bucket.tf` and `state-identity.tf`, do not, except web's and
  mail's data volumes, which hold customers' data and the mail store.
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
  `tofu/cloudflare`'s records read each address from `outputs.tf`, so after an
  apply here changes one, apply `tofu/cloudflare` for its records to follow.
- The SearchDomain DHCP option omits `server_type`, which does not apply to that
  option type.

Discovery output, including `SUMMARY.md`, stays local in `docs/snapshot/`. Every
Oracle mutation or state change needs Parker's explicit approval.

References:
- [OpenTofu import blocks](https://opentofu.org/docs/language/import/)
- [OCI provider authentication](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/configuring.htm)
- [Pinned boot-volume schema](https://github.com/oracle/terraform-provider-oci/blob/v9.9.0/internal/service/core/core_boot_volume_resource.go)
