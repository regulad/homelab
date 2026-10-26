# Agent cheat sheet: `regulad/homelab`

Read this first. This repository makes a home Proxmox cluster and an OCI tenancy
declarative: OpenTofu for machines, Ansible and Podman Quadlets for what runs on
them. Parker supervises and approves.

- **Plan and status:** [`.claude/PLAN.md`](.claude/PLAN.md) has the goals, phases, and each phase's current status.
- **History:** [`.claude/HISTORY.md`](.claude/HISTORY.md) records what was done, each entry a title and the technical findings likely to help a later session. Append new history there and nowhere else.
- **Directory detail:** each `README.md`, starting with [`tofu/oracle/README.md`](tofu/oracle/README.md).
- **Platform:** Unix-like systems only: Linux (WSL counts) or macOS, with a POSIX shell. Native Windows is not supported; write scripts and documented commands for `sh`/`bash`, never PowerShell or batch.
- **Managed elsewhere:** the tailnet's ACL policy and DNS live in [`regulad/tailscale-acls`](https://github.com/regulad/tailscale-acls), and workstation configuration in [`regulad/dotfiles`](https://github.com/regulad/dotfiles). Never add or change either from this repository.

Where this file and the plan disagree, this file wins.

## Priorities

- **IPv6-first.** The homelab is IPv6-first: wherever a service, route or resolver has an IPv6 address, configure it, and treat IPv4 as the fallback rather than the default.
- **DRY.** Derive values from their single source instead of restating them: compose from OpenTofu state or outputs where possible, then from another host's declared variables, and write a literal only where no source exists.
- **No security theatre.** Add a measure only for the risk it actually reduces. Something that looks like hardening but defends nothing only causes confusion, so leave it out. The textbook case is a restic password per host: every repository key opens the same master key, so per-host passwords protect nothing that one shared password does not. What limits and revokes a host's access is its own B2 key.

## Hard rules

1. **Approval for every mutation.** Never change infrastructure or state without Parker's explicit approval in chat for that specific action; an earlier approval never carries over. This covers `tofu apply|destroy|import`, `tofu state rm|mv|push`, `ansible-playbook` without `--check`, `pct|qm destroy|stop|set`, `pvesh set|create|delete`, `ceph config set` and other Ceph changes, `podman rm|stop`, and `oci ... delete|update`. Local file edits, SOPS encryption, validation, and read-only plans need no approval.
2. **Read-only discovery.** Discover with reads only. The OCI session token and the `gonkputer` `root@pam` API token and root SSH are read/write, so rule 1 is the safeguard there. Never create or broaden credentials yourself.
3. **No installs.** Never install tools, Python packages (`uv sync`, `uv tool install`), pre-commit hook environments, or OpenTofu providers (`tofu init` downloads) without Parker's approval for that install. He manages tools declaratively; `uv` is the Python/tool manager.
4. **No secrets in git; the repository is public.** Never commit tokens, keys, state, plans, `.terraform/`, plaintext `*.tfvars`, or discovery output. Sensitive values that must be committed go in SOPS-encrypted `*.sops.*` files (age recipients in `.sops.yaml`).
   - OCIDs owned by our tenancy or compartments link resources to the tenancy, so they stay encrypted, including router next-hop IDs. Verified Oracle-defined OCIDs may be plaintext as entries in a module's `platform_image_ids` or `backup_policy_ids` map, keyed by their exact Oracle name. Verify ownership before publishing an unfamiliar OCID.
   - GUA IPv6 `/64` prefixes stay encrypted; derive host addresses and enclosing prefixes from them. IPv4, ULA and Tailscale ranges, IPv6 host suffixes, and SSH public keys are plaintext, as are publicly known GUAs such as public DNS resolvers, each listed in the `no-gua-ipv6` hook's allowlist.
   - Password hashes may be plaintext when salted and from an adaptive algorithm such as bcrypt. Private keys, including WireGuard keys, stay encrypted.
5. **Don't invent facts.** Discover with read-only commands, keep raw output in the gitignored `docs/snapshot/`, and ask about anything unknown. Verify provider and tool details (resource names, import ID formats, flags) against current docs.
6. **Stop and ask** when a plan shows any destroy or replace, when an Ansible `--check` shows unexpected changes on a production host, or at an auth or permission wall.
7. **Pin everything:** providers with a committed `.terraform.lock.hcl`, Ansible collections in `requirements.yml`, container image tags (never `latest`, except where upstream publishes no version or channel tag besides dated or per-commit builds), and pre-commit hook revisions.
8. **Commits only when Parker asks.** Keep each one small and single-purpose, with a conventional-commit message. Every commit carries the contributing agent's own `Co-authored-by` trailer. Never add `Signed-off-by` with Parker's identity unless he says so for those commits, and never bypass commit signing.

## Model architecture

This model guides where new work goes. The repository itself is the
authoritative state: where they differ, the repository wins, and changing the
model is Parker's decision.

```
homelab/
├── AGENTS.md, README.md
├── .claude/                     # PLAN.md, HISTORY.md
├── .pre-commit-config.yaml      # file hygiene, OpenTofu, privacy, Ansible lint hooks
├── .sops.yaml, .gitignore
├── docs/
│   ├── snapshot/                # local-only discovery output (gitignored)
│   └── runbooks/                # move-a-service, rotate-keys, restore-state
├── tofu/
│   ├── shared/                  # resource-free constants for every root
│   ├── <root>/                  # one root per provider instance, own state (oracle, gonkputer, backblaze)
│   │   └── <child>/             # child modules split by network or concern
│   └── modules/                 # reusable child modules, e.g. lxc-guest/, vm-guest/
├── ansible-common/
│   ├── group_vars/              # all.sops.yml: secrets both stages share, linked from each stage's inventory/group_vars/
│   └── roles/                   # roles both stages apply: base, tailscale, ca_trust, auto_updates, mail_relay, kdump, kernel_params, apt_amd64v3, netplan, swap, restic
├── ansible-hardware/            # Phase 2, after tofu/backblaze, before the other roots; hand-written inventory
│   ├── ansible.cfg              # roles_path = roles:../ansible-common/roles
│   ├── bin/                     # with-switch-keys: runs a command with the SG300s' keys in a throwaway agent
│   ├── files/                   # <switch>/running-config(.j2): each network switch's whole configuration
│   ├── inventory/               # hardware.yml (by hand; hardware hosts and the switches group), group_vars/, host_vars/<host>/main.yml
│   ├── playbooks/               # site.yml; maintenance.yml
│   ├── plugins/                 # cliconf, terminal and filter plugins for the SG300s
│   ├── roles/                   # proxmox_cluster, eos, ciscosmb
│   └── requirements.yml         # pinned collections
└── ansible-generated/           # Phase 4, after OpenTofu; reads only OpenTofu outputs
    ├── ansible.cfg              # roles_path = roles:../ansible-common/roles
    ├── bin/                     # tofu-<root>: the inventory plugin's tofu, with that root's state encryption
    ├── files/                   # <host>/: byte copies roles place on a host, at their paths there; exempt from the whitespace hooks
    ├── inventory/               # <root>.terraform_state.yml (OpenTofu state), group_vars/, host_vars/<host>/{main,services}.yml
    ├── playbooks/               # site.yml; maintenance.yml
    ├── roles/                   # host_files, podman, avahi, quadlet, pfsense, php_fpm, pterodactyl, matrix
    └── requirements.yml         # pinned collections
```

- **OpenTofu** owns which machines exist, plus the Proxmox cluster-wide settings its provider supports. It never manages containers or in-guest files.
- **cloud-init**, set by OpenTofu, fully configures every Proxmox VM that can boot with it. Its whole setup lives in a cloud-init vendor file, a snippet under `tofu/gonkputer/snippets/`, so it needs no SSH and no Ansible.
- **Ansible** owns everything inside the other guests and the hardware hosts, and the Proxmox and Ceph cluster-wide settings OpenTofu cannot manage, applied on the nodes. It reaches LXC containers through the `community.proxmox.proxmox_pct_remote` connection plugin, which runs `pct` on their Proxmox node over SSH, so the containers need no SSH of their own. Everything else it reaches over SSH directly. Service lifecycle lives in Ansible data (`host_vars`), never in OpenTofu state.
- **Two Ansible stages, two inventories:** `ansible-hardware/` configures the hosts OpenTofu cannot create, listed by hand in its `hardware.yml`, after `tofu/backblaze` and before the other OpenTofu roots run; the one OpenTofu output it reads is `tofu/backblaze`'s `restic`. `ansible-generated/` configures the hosts OpenTofu creates or adopts, from OpenTofu state through the `cloud.terraform.terraform_state` inventory plugin, after. Neither stage reads the other's inventory. Roles both apply live in `ansible-common/roles/`; anything used by one stage stays in that stage's folder.
- **Separate roots per provider** limit blast radius. Cross-root sharing goes through explicit outputs, or through `tofu/shared` for constants.

## Everyday commands

From the repository root, in bash or zsh:

```bash
. tofu/oracle/prepare.sh                          # decrypt inputs; export the state backend's credentials into this shell
export OCI_CLI_AUTH=security_token
oci session validate --profile DEFAULT            # `oci session refresh` extends a still-valid token
tofu -chdir=tofu/oracle init -input=false -lockfile=readonly    # once per clone; downloads providers
tofu -chdir=tofu/oracle plan -input=false -detailed-exitcode    # 0 no changes, 2 diff, 1 error
pre-commit run --all-files
```

- Run plans from a root, never from a child module.
- Write plaintext plan output and saved plans to `docs/snapshot/`. State and saved plans are AES-GCM encrypted with the passphrase from SOPS; never change or lose it.
- Apply exactly the saved plan Parker approved, then confirm a fresh plan is a no-op. The state bucket's versioning keeps every earlier state version, so applies need no separate backups.
- The OCI session token lasts 60 minutes, and refreshing extends it up to 24 hours. After that, Parker must run `oci session authenticate` himself.

## Verification before review

```bash
pre-commit run --all-files
tofu -chdir=tofu/<root> fmt -check -recursive
tofu -chdir=tofu/<root> validate
tofu -chdir=tofu/<root> plan -detailed-exitcode
ansible-lint --offline ansible-common          # the shared roles, from the repository root
# Ansible: once per stage, from inside ansible-hardware/ or ansible-generated/
ansible-lint --offline
ansible-playbook playbooks/site.yml --syntax-check
ansible-playbook playbooks/site.yml --check --diff --limit <host>
ansible-inventory --graph
```

Each Ansible stage reads the `ansible.cfg` in the current directory, so run its
commands from inside that stage's folder.

`--offline` keeps `ansible-lint` from installing collections. Also confirm that
nothing secret is staged (`git diff --cached`), lock files are committed, and no
plan shows an unintended destroy or replace.

## Conventions

- **Docs:** `AGENTS.md`, `.claude/PLAN.md`, and every `README.md` contain only intent and current state. Record what happened by appending to `.claude/HISTORY.md`: a title saying what was done, and only the findings a later session could use, not approvals, apply counts or routine confirmations.
- **Guest names:** lowercase, hyphenated, stable (`svc-<name>`, `host-<role>`); the tailnet MagicDNS name equals the hostname.
- **Tags:** every guest is marked as managed by OpenTofu: `managed-by=opentofu` on OCI instances, and the tag `terraform` on Proxmox guests, whose tags cannot contain `=`. Tailnet tags and their ACL groups are defined in `regulad/tailscale-acls`.
- **OS groups:** every host Ansible manages is in exactly one OS group, `debian`, `ubuntu`, `rhel` (Oracle Linux, Rocky and Alma), `freebsd` (pfSense) or `macos`, which roles such as `ca_trust` key their behaviour on through `group_vars/<os>.yml`. Generated hosts get it from OpenTofu: an `os` freeform tag on OCI instances, and the group in each Proxmox guest's `ansible_host`. Hardware hosts list it in `hardware.yml`.
- **OpenTofu:** one root per provider; modules take explicit inputs; no secrets in `locals`.
- **Ansible:** roles expose knobs in `defaults/` and avoid `vars/`; handlers for restarts; every role passes `ansible-lint`.
- **pfSense:** the `pfsense` role converges `config.xml` through `pfsensible.core` modules wherever one works. Each part they cannot manage is a `pfsense_config_section` section, a template in `host_vars/<host>/config/` that replaces the elements it owns; paths something on the host rewrites are listed in its `ignore`. Every part of `config.xml` has one owner: when a module cannot model a field, the whole object type moves to a section rather than splitting ownership, and parts that pfSense or a package writes are left to them. Files outside `config.xml` come from `files/<host>/`. Each host pins its pfSense `<major>.<minor>` release in `pfsense_release`, because pfSense does not follow semantic versioning, and lists its packages in `pfsense_packages`; the role installs missing ones through pfSense's own installer and never removes any. Each host's gaps are tracked in `host_vars/<host>/TODO.md`. The operator's `config.xml` snapshot is authoritative over the live file: a fix the role cannot make is edited into the snapshot, pushed over SSH, and applied through pfSense's PHP.
- **Ansible secrets:** SOPS-encrypted `host_vars/<host>/secrets.sops.yml` or `group_vars/<group>.sops.yml`; secrets both stages need live once, in `ansible-common/group_vars/all.sops.yml`, which each stage's `group_vars/all.sops.yml` symlinks. They are loaded by the `community.sops.sops` vars plugin each stage enables in its `ansible.cfg`; never Ansible Vault or decrypted copies on disk. Plaintext vars reference secrets by name, and tasks that pass them set `no_log: true`.
- **Quadlets:** one file per unit, rendered by the `quadlet` role from `host_vars/<host>/services.yml`, with secret env files in SOPS; volumes named, not bind-mounted from ad hoc paths; shared data on the container's CephFS mount (`/mnt/cephfs`) is bind-mounted from there. Images preferably track a major-version tag (or a release channel such as vaultwarden's `testing`) with `AutoUpdate=registry`, so `podman-auto-update` brings in patch and minor releases and containers get patches the same way as the system they run on, through its automatic updater. `latest` is used only where upstream publishes no version or channel tag besides dated or per-commit builds, as for timemachine and tvheadend. Hosts not already on Podman keep their current runtime.
- **File names:** where `-` delimits parts of a file name (`instance-<name>.tf`, `subnet-<name>.tf`, `vm-<name>.tf`, `lxc-<name>.tf`), write each `-` inside a part as `--`. For example, subnet `subnet-20230331-2242` lives in `subnet-subnet--20230331--2242.tf`, and VM `resolute-template` in `vm-resolute--template.tf`.

### OpenTofu HCL (as practiced in `tofu/oracle`)
- **HCL first:** ordinary, readable `.tf` resources with inline non-sensitive settings and direct references. SOPS holds sensitive input values only, never encrypted HCL, resource definitions, or a topology data model.
- **Files:** one `instance-<name>.tf` per host and one `subnet-<name>.tf` per subnet, each opening with a `# <name>: <contents>.` header. `network.tf` holds network-wide `locals`, the VCN, gateways, and the defaults the provider creates with the VCN. A distinct concern gets its own file (`email.tf`). `locals.tf` holds only values shared across files, and `variables.tf` declares inputs. `moved.tf` keeps every past address move so old states and backups still plan cleanly.
- **Order within a file:** file-local `locals` first, then the primary resource, then what depends on it.
  - Host files: instance, boot volume, backup-policy assignment, VNIC lookup, IPv6 assignment, NSG, NSG rules.
  - Subnet files: the subnet, then its own DHCP options, route table, and security lists.
  - `network.tf`: VCN, internet gateway, DHCP options, route tables, security lists.
- **Order within a resource:** meta-arguments (`for_each`) first, followed by a blank line. Then identity (`display_name`, `compartment_id`, parent IDs), placement (`availability_domain`, `fault_domain`), other scalar arguments, and nested blocks. Blank lines separate nested blocks; none directly inside an opening brace. Keep list order the provider or service treats as meaningful.
- **Imperative leftovers:** every adopted resource ends with this footer:
  ```hcl
    # The following exists as an artifact of import from the imperative setup.
    lifecycle {
      prevent_destroy = true
    }
  ```
  Schema placeholders that exist only for adoption, such as the boot-volume `source_details { type = "bootVolume" }`, sit between that comment and `lifecycle`. `ignore_changes` stays as narrow as possible and carries a comment explaining what owns the ignored field. Image-created boot volumes ignore only `source_details`; never fabricate a clone or restore source.
- **Opaque values get a comment:** wherever possible, put a comment next to any value whose meaning is not self-evident:
  - protocol numbers: `"1" # ICMP`, `"6" # TCP`, `"17" # UDP`, `"58" # ICMPv6`, `"all" # All IP protocols`
  - ICMP `type`/`code` pairs: `type = 3 # Destination Unreachable`
  - ports, on the opening line of the block holding `max`/`min`: `destination_port_range { # SMTP`, `tcp_options { # SSH`. A rule whose existing `description` already names the port needs no comment.

  Plaintext Oracle OCIDs need no comment: their map key is their exact name (rule 4).

  Use HCL comments for this, not new `description` arguments; adding a description changes infrastructure.
- **IPv4/IPv6 pairs:** values that exist per IP family are objects keyed `ipv4`, then `ipv6`, named `dual_stack_<what>` when local (`local.dual_stack_internet_cidrs`, `var.tailscale_cidrs`, `var.router_next_hop_ids`).
  - Rules or routes identical across families iterate over the pair: `for_each` with `each.value`, or a `dynamic` block with `iterator = cidr`. The stable family keys keep resource addresses independent of ordering.
  - Rules that differ by family stay explicit.
  - A shared address pair never implies a permission for both families. Comment any family-only exception, such as an IPv4-only peering rule.
  - Constants that belong to one subnet or host live at the top of that file; network-wide pairs live in `network.tf`.
- **Addresses:** GUA host addresses are `cidrhost(var.ipv6_subnet_cidr, parseint("<64-bit hex suffix>", 16))`. Enclosing prefixes are derived from the encrypted `/64`, never written.
- **Lookups:** read a host's VNIC through a `data "oci_core_vnic_attachments"` filtered to `ATTACHED` and `one()`, so a second VNIC fails loudly instead of being guessed.
- **Inputs:** sensitive inputs are `sensitive = true` and `nullable = false` and come from `secrets.sops.json`. Non-sensitive values are inline HCL, not variables. Resource-free constants shared by several roots live in `tofu/shared`.
- **Versions:** pins live only in each root's `versions.tf`. Child modules declare provider sources only and start with `# tflint-ignore-file: terraform_required_version, terraform_required_providers`.
- **Tags:** every OCI instance sets `freeform_tags = { "managed-by" = "opentofu", "os" = "<os group>" }` as its last scalar argument.
- **Deferred problems:** a setting known to be wrong but kept for now gets `# FIXME: <what is wrong>. Revisit <when>.` on the lines directly above it.
- **Labels:** resource labels are stable identities; renaming one needs a `moved` block. NSG rules are labelled `<host>_<protocol>_<port or range>`; bailout's two family-specific rules keep their adopted `bailout_rule_NN` labels.

### Proxmox HCL (as practiced in `tofu/gonkputer`)
The rules above apply, with these additions.
- **Resource names:** use the short `proxmox_*` names. The long `proxmox_virtual_environment_*` names are deprecated; use one only where no short name exists yet (containers, firewalls, DNS/hosts/time, users/groups/roles, files). VMs stay on `proxmox_virtual_environment_vm`: the short `proxmox_vm` is a different resource, the experimental former `vm2`, which the provider marks unfit for production.
- **Files:** one `vm-<name>.tf` or `lxc-<name>.tf` per guest, holding the guest, then its HA resource and firewall resources. Cluster-wide concerns get their own files (`cluster.tf`, `firewall.tf`, `ha.tf`, `storage.tf`, `mappings.tf`, `backup.tf`, `access.tf`, `snippets.tf`). Labels are the guest name with `-` written as `_`.
- **References:** VMs reference the custom CPU model's `cputype` and hardware mappings by name; HA resources reference their guest's `vm_id`; HA rules reference HA resources. Snippet volume IDs stay literal, because `vendor_data_file_id` forces replacement and a file still to be created is unknown at plan time; the guest lists the file resource in `depends_on`.
- **Defaults:** where a setting is unset live and the provider's default differs from Proxmox's effective value, write Proxmox's value explicitly with a comment. Never hide such a diff with `ignore_changes`. Compare against the provider's source and Proxmox's API schema, and let the plan confirm.
- **Generated values stay out:** guests don't state `vm_id`, and disks don't state `path_in_datastore` or `file_format`. Proxmox generated them, and state tracks them since adoption, as with OCIDs. Anything that needs a guest's ID references its `vm_id`.
- **New containers** start from `tofu/gonkputer/lxc-TEMPLATE.tf.example`, a skeleton with the shared defaults (Ceph root disk with discard and lazytime, DHCP and SLAAC on VLAN 1, effectively unlimited swap, nesting, an HA resource and the Ansible host): copy it to `lxc-<name>.tf` and fill in its placeholders.
- **Container CPUs:** every container sets `cores = local.cpu_threads` (the node's 32 logical CPUs) and caps CPU time with `limit`. Proxmox would treat a missing `cores` as every core, but the provider cannot leave it unset: it reads a missing `cores` as 1 and sends 1 on any `cpu` change.
- **Ansible inventory:** each guest file that Ansible manages (containers, and VMs that cannot use cloud-init) ends with an `ansible_host` whose `count` is 1 while the guest is requested (a started HA resource, or no HA resource and starting on boot), named `<name>.${local.guest_domain}`. `ansible-generated` reads these from state, and reaches containers through `proxmox_pct_remote`. VMs that boot with cloud-init, or are being moved to it, get no `ansible_host`; their vendor file configures them.
- **VMIDs:** the cluster's `next_id` starts at 200, so guests created from here on are set apart from the adopted ones below it.
- **Tags:** every guest lists `terraform` among its `tags`, sorted as Proxmox stores them, as its last scalar argument. Markers such as `amd64v3` are tags, not descriptions. Tag names live once, in `local.tags` in `locals.tf`; guests reference them (`local.tags.terraform`) instead of writing the string.
- **Opaque values:** PCI and USB vendor/device IDs get the device name as a comment (`id = "8086:2723" # Intel Wi-Fi 6 AX200`), as do other opaque IDs.

## Standing decisions

- **Pre-commit:** `.pre-commit-config.yaml` runs the pinned `pre-commit/pre-commit-hooks` plus local hooks that use installed tools (`language: unsupported`) or `pygrep`. Gitleaks is not wanted.
- **Discovery snapshots** stay on the operator's machine; only configuration derived from them is committed. Parker's review of `docs/snapshot/SUMMARY.md` gates the adoption phases.
- **OCI auth:** Parker's own user, through an `oci session authenticate` read/write session token in the `DEFAULT` profile, because OpenTofu writes back to OCI.
- **OCI adoption is complete** for the scope in the OCI part of the plan's Phase 3. Never regenerate or re-import it.
- **OCI state** is remote: OpenTofu's s3 backend stores it in the versioned `homelab-tofu-state` bucket through OCI's S3 Compatibility API, with S3-native locking (`use_lockfile`, verified against OCI). It is encrypted client-side with AES-GCM before upload. The backend authenticates as `svc-tofu-state`, whose customer secret key and endpoint are in `tofu/shared/backend.sops.env`. That key is created outside OpenTofu, never in state.
- **VCN defaults** stay ordinary adopted resources guarded by `prevent_destroy`. Moving them to `oci_core_default_*` resource types is wontfix.
- **Ansible scope:** each stage's main playbook is `playbooks/site.yml`. Every play in it converges hosts to the state declared here and is safe to rerun; a second run reports `changed=0`. Package updates come from each host's own automatic updater (unattended-upgrades, dnf-automatic) and containers' `podman-auto-update`, not from a playbook. Maintenance that cannot be automated, such as upgrading the Pterodactyl panel to its declared version by its documented procedure, lives in the stage's one other playbook, `playbooks/maintenance.yml`, one play per task, each tagged and run by hand. Other deliberate operations, such as rolling reboots, release upgrades, key rotation and restores, are not Ansible playbooks. Moving a service is a `host_vars` edit plus a `site.yml` run; its data moves by hand.
- **First pass describes; later passes prescribe.** A root's first adoption pass mirrors the live configuration exactly, warts included (for example an HA rule naming a node that had left the cluster). Fixes follow as separate, reviewed changes.
- **gonkputer ownership:** node-level settings (network, DNS, hosts, time, APT, node options) belong to Ansible. Users and groups belong to the LDAP realm `home.arpa` and its sync. Ceph health warnings are known and can be ignored.
- **gonkputer API endpoint:** the node's tailnet name on port 8006, published by `tailscale serve` (tailnet only) with a Tailscale-managed certificate. Keep provider TLS verification on. The endpoint and token live in `tofu/gonkputer/provider.sops.env`.
- **gonkputer root tickets:** the provider sets `ssh.root_ticket`, so its calls under `/nodes/{node}/` run as `root@pam` with a ticket minted over its SSH connection to the node, bypassing the token's permissions. Proxmox reserves some operations, such as USB passthrough by device ID, for `root@pam` itself. Calls outside `/nodes/` still use the API token, so the token stays. Every plan and apply opens that SSH connection.
- **Provider mirror:** `tofu/gonkputer` pins a build of `bpg/proxmox`, served under the official address by [`regulad/opentofu-registry`](https://github.com/regulad/opentofu-registry) at `https://opentofu.regulad.xyz/`. The root's `tofu.rc`, selected by sourcing `tofu/gonkputer/prepare.sh`, lists `direct {}` before the mirror. Lock with `tofu providers lock -net-mirror=https://opentofu.regulad.xyz/`.
- **Snippets:** hookscripts and cloud-init vendor files live byte for byte under `tofu/gonkputer/snippets/<storage>/`, uploaded by `proxmox_virtual_environment_file` over SSH as root through the operator's agent. They are created over the live files, not imported, and are exempt from the whitespace hook.
- **Ceph scope:** `tofu/gonkputer` manages the Ceph objects created through Proxmox: the pools `rbd_ssd` and `rbd_cmr` (`proxmox_ceph_pool`) with their storages `rbd` and `rbd_cmr` (`proxmox_storage_rbd`), the CephFS `cephfs` with its pools (`proxmox_ceph_fs`) and its storage (`proxmox_storage_cephfs`), and the MDS daemons (`proxmox_ceph_mds`): `prodingus`, which serves `cephfs`, and the hot spares `prodingus1` and `prodingus2` on the same host. Storages are always separate resources, never created as a side effect of a pool or filesystem; `rbd_cmr`'s storage, which Proxmox's "Add as storage" made, is imported like any other. Destroying a CephFS is a manual procedure the provider refuses to run. Not managed: `.mgr` and the RGW pools, which were not created through Proxmox; and monitors, managers, OSDs, Ceph configuration and CRUSH rules, which have no resources.
- **Privileged containers run without AppArmor.** Every gonkputer container that does not set `unprivileged = true` (immich, llamarpcmaster, ncsusplitt, procontainer, timemachine, tsexit, tvheadend) must have AppArmor removed inside the guest, or it breaks. Never install or enable AppArmor in one; unprivileged containers keep it.
- **VM 100 is never rebooted on its own.** Its passed-through AMD GPU does not reset properly when the KVM host detaches and re-attaches it, so the VM is restarted by rerooting, or together with a host reboot. It sets `reboot_after_update = false`; a change that needs a reboot stays pending until then.
- **Swap:** every Debian and Ubuntu host with its own kernel swaps to zram through systemd-zram-generator, at half its RAM (on prodingus, half of what the VMs' 1 GiB hugepages leave). Disk swap exists only on storage backed by a real drive: OCI boot volumes, prodingus's own disks, and the SATA SSDs passed straight into aboriginal and dodo. Never put swap on Ceph RBD. The OCI instances' swapfiles stay as they are.
- **Backups:** restic jobs are systemd services and timers from the `restic` role (`restic_jobs`), never cron. Hosts with btrfs back up from read-only snapshots; prodingus, on ext4, backs up its live root. aboriginal's `restic-forget` is the repository's only forget and prune, with a policy per tag; a tag no policy names, such as `nas`, is never forgotten.
- **gonkputer firewall bypass:** VMs 100 and 101 deliberately bypass the firewall (`firewall = false` on their NICs).
- **gonkputer state** lives in the same `homelab-tofu-state` bucket under the key `gonkputer/terraform.tfstate`, with the same backend credentials and its own encryption passphrase. No state from the draft carried over; all 86 resources were imported afresh, and the import blocks removed after the adoption apply.
- **backblaze state** lives in the same bucket under `backblaze/terraform.tfstate`, with its own passphrase. The root holds the whole B2 account: its buckets and application keys. The provider authenticates with the account's master application key, from `tofu/backblaze/provider.sops.env`, which never leaves the operator's machine. It runs before both Ansible stages: the `restic` role reads its `restic` output, the repository and a key per host, through the `cloud.terraform.tf_output` lookup. A host's key rotates with `tofu apply -replace` and then `site.yml`.
- **Restic password:** one repository password, shared by every host, in `ansible-common/group_vars/all.sops.yml` (see No security theatre). To rotate it, run `maintenance.yml --tags restic-password` once from either stage, then `site.yml` in both stages, then `--tags restic-password-prune`, which removes the old repository key.
- **Known non-issues:** the Email Delivery DKIM key shows `NEEDS_ATTENTION` for about a week after the mail server power-cycles; this is cosmetic. The tenancy is pay-as-you-go, so resources beyond Always Free limits (such as extra boot-volume backups) are expected.
