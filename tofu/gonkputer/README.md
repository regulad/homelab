# gonkputer (Proxmox VE and Ceph)

The `.tf` files are the source of truth for the `gonkputer` cluster: its guests and the
cluster-wide settings, including Ceph, that `bpg/proxmox` supports. This is the first, descriptive pass. It
mirrors the live configuration, including its known warts, so that adoption changes nothing.
Fixes follow as separate, reviewed changes. `gonkputer` has one node, `prodingus`.

| Location | Configuration |
|---|---|
| `vm-<name>.tf`, `lxc-<name>.tf` | One file per guest: the VM or container, then its HA resource and firewall options where present |
| `cluster.tf` | Datacenter options and the custom CPU model `RYZEN-Vermeer-v3` |
| `firewall.tf` | Cluster-wide firewall options |
| `ha.tf` | HA rules; each HA resource lives with its guest |
| `ceph.tf` | The Ceph pools `rbd_ssd` and `rbd_cmr`, the CephFS `cephfs`, and the MDS daemons `prodingus`, `prodingus1` and `prodingus2` |
| `storage.tf` | The storages: `local` and `local-lvm` on the node, and `rbd`, `rbd_cmr` and `cephfs` on Ceph |
| `mappings.tf` | PCI, USB and directory resource mappings |
| `backup.tf` | The weekly backup job |
| `access.tf` | The LDAP realm `home.arpa` and its single ACL |
| `snippets.tf`, `snippets/<storage>/` | Hookscripts and cloud-init vendor files, byte for byte |
| `imports.tf` | Import blocks for the adoption apply; removed afterwards |
| `providers.tf`, `versions.tf`, `tofu.rc` | Provider auth, pinned versions, and the CLI configuration with the provider mirror |
| `state.tf`, `variables.tf` | Enforced state encryption and the sensitive inputs |

A `-` inside a guest name is written as `--` (`vm-resolute--template.tf`).

## Writing the configuration

- **References over literals:** VMs reference the custom CPU model's `cputype` and the
  hardware mappings by name. HA resources reference their guest's `vm_id`, and HA rules
  reference the HA resources they cover.
- **Snippet IDs stay literal.** `vendor_data_file_id` forces replacement, and a reference to a
  file that is still to be created is unknown at plan time. Guests that use a snippet name its
  file resource in `depends_on` instead.
- **Proxmox's defaults, not the provider's.** Where a setting is unset live and the provider's
  default differs from Proxmox's effective value, the configuration writes Proxmox's value
  explicitly, with a comment. This covers VM 100's firewall options (the provider defaults
  `ndp` off and `radv` on), the cluster firewall's output and forward policies, and VM 129's
  `scsi_hardware = "lsi"` (the provider defaults to `virtio-scsi-pci`).
- **Containers state their `vm_id`.** The container importer records none, and the HA
  references need it.
- **Firewall bypass:** VMs 100 and 101 have `firewall = false` on their NICs, so their traffic
  never passes a firewall bridge. VM 100's firewall options stay disabled.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/gonkputer/prepare.sh       # selects tofu.rc, exports the API token, decrypts inputs
tofu -chdir=tofu/gonkputer init -backend=false -input=false -lockfile=readonly
tofu -chdir=tofu/gonkputer validate
tofu -chdir=tofu/gonkputer plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs
`tofu`. It needs `sops`, `jq` and `git`. It exports `PROXMOX_VE_ENDPOINT` and
`PROXMOX_VE_API_TOKEN` from `provider.sops.env` into that shell only, and sets
`TF_CLI_CONFIG_FILE` to this root's `tofu.rc`. It decrypts `secrets.sops.json` into the ignored
`secrets.auto.tfvars.json`. That file holds the state passphrase, the node's SSH address
(the provider uploads snippets over SSH as root, through the operator's SSH agent), and the
datacenter notes, which name internal hosts and networks.

The provider is a build pinned in `versions.tf` and served by the mirror in `tofu.rc`.
`tofu providers lock` ignores the CLI configuration, so lock with
`-net-mirror=https://opentofu.regulad.xyz/`.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`gonkputer/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports.

## Adoption

The adoption plan imports 86 resources, including the 9 Ceph objects, which import with no
changes. It changes nothing live except:

- the 7 snippet files, uploaded over their identical live copies (an import records neither
  content nor mode, so the files are created instead);
- `100.fw` and `cluster.fw`, which gain explicit lines for Proxmox's effective defaults;
- VM 129's config, which gains `scsihw: lsi`, its current default.

The 20 containers also show an in-place update that only records `vm_id` and `timeout_start`
in state; it makes no API call. Every adopted resource carries `prevent_destroy = true`.

## Not managed here

| What | Why, or who owns it |
|---|---|
| Node network, DNS, hosts, time, APT, node options, host firewall | Ansible, with the hardware hosts |
| Users and groups | The `home.arpa` realm sync |
| The `root@pam!homelab` API token | A credential, rotated by hand |
| LDAP bind password, cloud-init passwords | Never returned by Proxmox; kept out of the repository |
| `.mgr` and the RGW pools | Created outside Proxmox; not described |
| Ceph monitors, managers and OSDs, Ceph configuration, and CRUSH rules | No provider resource; CRUSH rules can only be observed in Proxmox |
| Notification endpoint `mail-to-root` and `default-matcher` | No provider resource |
| The scheduled realm-sync job | `proxmox_realm_sync` only triggers a one-off sync |
| Datacenter `location`, `registered-tags`, `user-tag-access`, `webauthn` | Not in `proxmox_cluster_options` |

Discovery output, including `SUMMARY.md`, stays local in `docs/snapshot/gonkputer/`. Every
mutation or state change needs Parker's explicit approval. Cluster firewall, network and Ceph
changes also wait for a confirmed LAN or console path to the node.
