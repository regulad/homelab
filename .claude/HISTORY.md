# Homelab IaC history

What was done, in order, with the technical findings worth knowing later.
Current rules and intent live in `AGENTS.md` and `.claude/PLAN.md`; this file
keeps how they came about. Each entry is a title saying what was done and the
findings that would help a future session. Append new entries at the end.

## OCI adopted into `tofu/oracle`; first decisions (2026-10-12)

- 74 resources imported with no changes (OpenTofu 1.13.1, oracle/oci 9.9.0); later cleanups were sensitivity-metadata or address moves only. `moved.tf` keeps every move so old states still plan.
- OCI auth is Parker's own user through `oci session authenticate`, read/write, because OpenTofu writes back; a read-only user was dropped.
- Discovery snapshots stay local (`docs/snapshot/`, gitignored); review of `SUMMARY.md` gates adoption.
- `terraform-provider-oci -command=export` was skipped: it needs a `terraform` binary (0.12/0.13). Inventory with the `oci` CLI, then `import {}` with `-generate-config-out`.
- OCI scope excludes identity-domain apps/users/groups, Oracle-created policies and tag defaults, `ManagedCompartmentForPaaS`, the OS Management Hub profile, VCN-created DNS resolvers/views/zones, and boot-volume backups (data).
- Image-created boot volumes ignore only `source_details`; never fabricate a clone or restore source.
- The provider generated an invalid empty `server_type` on a SearchDomain DHCP option; the field is omitted.
- Port names Parker gave: LiveKit 7881 and UDP 30000-40000 (TURN relay), router UDP 39127 (Tailscale peer relay), bailout UDP 51820/51821 (WireGuard).
- Single-source-port rules were fixed, mail TCP 80's source port dropped, legacy's Minecraft voice chat (UDP 24454) and four redundant DNS 53 rules removed, and every instance tagged `managed-by=opentofu`.
- Deferred IPv6 assignments show as updates whenever their VNIC lookup is deferred; they resolve without change.

## Documentation restructure (2026-10-12)

- Phases moved to `.claude/PLAN.md`, `AGENTS.md` became the agent cheat sheet, and all history moved here. Superseded instructions are replaced, not annotated.

## Published to GitHub (2026-10-12)

- A scan of every commit found no tenancy OCIDs, GUAs, keys, state, plans or tfvars before the first push of the public `regulad/homelab`.
- `.github/settings.yml` configures the repository through the Probot Settings app.

## Scope change (2026-10-12)

- Tailnet ACLs and DNS live in `regulad/tailscale-acls`, workstations in `regulad/dotfiles`; the planned `tofu/tailnet` root was dropped.
- Proxmox and Ceph cluster-wide settings came into scope: OpenTofu where `bpg/proxmox` covers them, Ansible on the nodes otherwise.

## OCI input cleanup (2026-10-18)

- `bronze` is a realm-wide Oracle OCID (`oc1..`) with no compartment, so it is plaintext in a `backup_policy_ids` map; it cannot be an `oci_core_volume_backup_policy` resource, which requires a compartment.
- Oracle OCIDs live in per-module `backup_policy_ids` and `platform_image_ids` maps keyed by exact Oracle name; the privacy hook enforces that form.
- `availability_domains` is looked up from `tenancy_ocid`. Instance SSH keys moved to plaintext HCL.
- `ipv6_subnet_cidrs` stays encrypted although derivable from each VCN's `/56`, so a redeploy keeps the same subnets.

## `bronze` backups on every boot volume (2026-10-18)

- web and bailout gained `bronze` assignments; every boot volume now has one.

## Remote state on OCI's S3 API; locking tested (2026-10-18)

- OpenTofu has no OCI backend; its `s3` backend works against OCI's S3 Compatibility API with Oracle's documented settings.
- `use_lockfile` relies on `If-None-Match: *`, undocumented by Oracle, so it was tested on a scratch bucket: a repeated conditional create returns 412, a create over a delete marker 200, and 20 of 20 races gave exactly one lock holder. A wrong `If-Match` is ignored (OpenTofu does not send it).

## State backend resources (2026-10-18)

- `homelab-tofu-state` (private, versioned, no `prevent_destroy` since it was created, not adopted) and `svc-tofu-state`, limited to customer secret keys, whose policy grants `read buckets` and five object permissions, not `OBJECT_VERSION_DELETE`.
- Classic IAM resources, as with `svc-mail`; the identity user needs a real mailbox for its activation mail.

## Remote state migration (2026-10-18)

- The backend's customer secret key is made with the CLI, outside OpenTofu, so it never lives in the state it unlocks. Encrypt a new secret straight from memory; a first key was lost to a newline in the pipeline.
- A new key fails intermittently with `SignatureDoesNotMatch` for about 15 minutes after creation.
- `-migrate-state` gave the remote state a new lineage, so restoring a pre-migration backup needs `tofu state push -force`.
- Bucket versioning replaced the copy-state-before-apply rule.

## Plan restructured around two Ansible phases (2026-10-18)

- Hardware hosts get Ansible before OpenTofu, from a hand-written inventory; generated hosts after it, from OpenTofu. Ten phases became seven; entries above use the old numbers.

## Ansible stages scaffolded (2026-10-18)

- The Quadlet role is `quadlet`, not `quadlet_services`: ansible-lint requires role variables to carry the role's prefix. Role metadata says `license: AGPL-3.0`.
- Ansible ignores `ansible.cfg` in a world-writable directory (such as `/mnt/d` in WSL).

## Repository moved into WSL; hardware hosts seeded (2026-10-18)

- Hardware hosts came from `~/.ssh/config.d/99-hardware` plus overture. prodingus runs Proxmox VE 9 on Debian 13. turk is a separate machine running VMware so Windows guests get accelerated graphics, not part of gonkputer.
- overture needs `-o RemoteCommand=none -o RequestTTY=no`, because its SSH login wrapper cannot coexist with Ansible's commands.

## overture reachable through Ansible (2026-10-18)

- Without the override, ping fails with "Cannot execute command-line and remote command". overture pins `ansible_python_interpreter: /usr/bin/python3` (macOS's 3.9.6).

## Unix-only tooling (2026-10-18)

- `prepare.ps1` became a sourced `prepare.sh` (sh, bash, zsh): it refuses an un-ignored destination or an overwrite with different data, checks every backend name before exporting, and writes inputs 0600.

## Ansible split into per-stage folders (2026-10-18)

- `ansible-hardware/`, `ansible-generated/` and `ansible-common/roles/`, each stage with its own `ansible.cfg` (`roles_path = roles:../ansible-common/roles`), `requirements.yml` and gitignored `collections/`, run from inside its folder.

## Windows checkout removed (2026-10-18)

- The only objects lost were four draft commits already redone as `bb36843`. Pre-migration OCI state copies remain under the old Windows `%LOCALAPPDATA%/homelab/oracle-backups/`.

## One converging playbook per stage (2026-10-18)

- Each stage's `site.yml` converges and is safe to rerun; deliberate operations (rolling reboots, release upgrades) stay out of Ansible, and package updates come from each host's own updater.

## Generated inventory from OpenTofu state (2026-10-18)

- `cloud.terraform.terraform_state` was chosen over an `inventory.py` output reader and `terraform_provider`, since it scales across roots without HCL changes.
- The plugin pulls state into a scratch directory with no `encryption` block, so `binary_path` is a wrapper (`bin/tofu-<root>`) that sets `TF_ENCRYPTION`. It reads `binary_path` raw from that directory, so it must be a bare name on `PATH` (sourcing `prepare.sh` adds `ansible-generated/bin`).
- OCI hosts are named by VCN DNS name (`<label>.pubsub.wahlecloud.oraclevcn.com`), legacy `web` by `doppelgangerhq.com`; short names are ambiguous on the tailnet. Names the operator's SSH config does not match need `ansible_user` in `host_vars` (bailout `opc`).
- Each stage's `.ansible-lint` excludes `collections/`, which also stops it following `../ansible-common`, so the shared roles are linted separately.

## The gonkputer draft rebased onto master (2026-10-19)

- `gonkputer` uses a `root@pam` API token plus root SSH, read/write; per-action approval is the safeguard.
- Provider builds come from the static mirror `regulad/opentofu-registry` under the `bpg/proxmox` address, so changing builds needs no state migration.
- Proxmox and Ceph findings:
  - prodingus is a standalone pmxcfs node with no corosync configuration, yet HA runs with single-node quorum and armed fencing.
  - Proxmox VE 9 replaced HA groups with HA rules.
  - pveproxy's certificate is self-signed and lacks the tailnet name, so `tailscale serve` publishes 8006 with a Tailscale certificate and provider TLS verification stays on.
  - Users and groups belong to the LDAP realm `home.arpa`, whose sync removes vanished entries.
  - Custom CPU models have an API (`/cluster/qemu/custom-cpu-models`) that `pvesh ls /cluster` does not list.
  - An API token with privilege separation and no ACLs has no permissions, yet `/version` still answers.
  - "Add as storage" registers an RBD storage named after the pool; creating a CephFS makes `<name>_data` and `<name>_metadata` pools and needs a standby MDS. `storage.cfg` does not record how an entry was made (missing `krbd 0` lines come from upgrades since PVE 7).
- Provider findings:
  - 0.116.0 renamed resources to short `proxmox_*` names. `proxmox_vm` is the experimental former `vm2`, not `proxmox_virtual_environment_vm`, and cannot import.
  - An imported `proxmox_virtual_environment_file` records only node, storage and content type, so it plans a replacement; creating it over the live file adopts it in place. Edits on the node go undetected.
  - PVE returns number options as text (`"cpus": "2"`), which the provider could not read (fixed in bpg#3170; Proxmox bug 8162).
  - `-generate-config-out` emits empty strings and zeros that fail the provider's validators; drop nulls, defaults and empties.
  - Several provider defaults differ from Proxmox's: the guest firewall's `ndp` and `radv`, the cluster and guest output and forward policies, and a VM's `scsi_hardware`.
  - The container importer records no `vm_id` or `timeout_start`, so the first plan shows an in-place update that sends nothing.
  - A force-new attribute referencing a resource still to be created forces replacement (`vendor_data_file_id`); literal volume IDs with `depends_on` avoid it.
  - Plugin Framework defaults apply during planning, after `ignore_changes`, so `ignore_changes` cannot hide a missing default.
  - The provider never sends an empty cloud-init password.
- Tooling findings:
  - OpenTofu picks a version across all installation methods but installs from the first listed; a mirror before `direct {}` returns 404 for official releases, so `direct {}` comes first.
  - `tofu providers lock` ignores the CLI configuration's installation methods; lock mirrored builds with `-net-mirror=<url>`, after removing the old version's entry, which it will not replace.
  - A GitHub Pages custom domain set before its DNS record existed never got a certificate until it was cleared and set again.
  - The GUA hook's `\b` matched later hextets of link-local EUI-64 addresses; a `(?<![0-9a-f:])` lookbehind fixes it.

## gonkputer provider build with full Ceph support (2026-10-19)

- `bpg/proxmox` `0.118.0-pr3204.pr3207.pr3209.1` adds `proxmox_ceph_pool` fixes (clean imports, `pool_id`, erasure coding; pools no longer create storages), `proxmox_storage_rbd`, `proxmox_ceph_mds`, `proxmox_ceph_fs` (destroy refused, manual) and `proxmox_storage_cephfs`, so every Ceph object made through Proxmox is in scope.

## gonkputer re-described from live, with Ceph (2026-10-19)

- Plans stalled 15 minutes because VM 100's guest agent answered `network-get-interfaces` with HTTP 500 and the provider retries until its agent timeout; the agent had not restarted after a reroot.
- Do not set `agent.timeout`: it cannot help an import's first read, and any change to the `agent` block rewrites the live line and marks the VM for a reboot.
- The PG autoscaler is on for every pool, so `pg_num` is left to it.

## gonkputer state moved to the shared bucket (2026-10-19)

- Backend credentials moved to `tofu/shared/backend.sops.env`; gonkputer's state is `gonkputer/terraform.tfstate` with its own passphrase. All 86 resources were imported one at a time with `tofu import`.

## gonkputer adoption applied (2026-10-20)

- The `root@pam!homelab` token can expire (HTTP 401 on every read). Changing `scsi_hardware` reboots the VM (VM 129).
- Parallel snippet uploads failed SSH auth through the operator's agent at the time; see "Serial-apply workaround removed".

## gonkputer cleanup after adoption (2026-10-20)

- Proxmox-generated values (`vm_id`, `path_in_datastore`, `file_format`) left the HCL once state tracked them. Guests are tagged `terraform` (Proxmox tags cannot contain `=`), tag names live in `local.tags`, and `next_id` starts at 200.
- The provider reads a missing `cores` as 1 and sends 1 on any `cpu` change, while Proxmox treats it as every core; containers therefore set `cores = local.cpu_threads` and cap CPU with `limit`. Tag changes need no reboot.

## gonkputer feeds ansible-generated (2026-10-20)

- `terraform_state` cannot filter hosts, join a guest with its HA resource, or read a container's nested hostname, so `tofu/gonkputer` declares `ansible_host` resources (`ansible/ansible` provider) for the plugin to map.
- A guest is requested when its HA resource is started or, with none, it starts on boot.
- Guests are named `<name>.regulad.internal`, which also keeps them apart from OCI hosts with the same short name.
- The registry has no signing key for `ansible/ansible`; the lock file pins its checksum.

## cloud-init VMs configured by vendor files (2026-10-20)

- VMs that boot with cloud-init get their whole setup from a vendor file, so nothing SSHes into them; containers stay with Ansible through `proxmox_pct_remote`, since Proxmox has no cloud-init for containers (bug 4686's patch unmerged).

## Containers reached through proxmox_pct_remote (2026-10-20)

- `community.proxmox` 2.1.0; paramiko came bundled with Homebrew's Ansible.
- Each container's `ansible_host` carries the node's SSH address (from the encrypted `node_ssh_addresses`) and `vm_id`; the plugin keeps a dynamic attribute as `{type, value}`, so `compose` reads `variables.value`.
- A first connection through the plugin can fail with an authentication timeout and succeed on retry.

## Imperative leftovers removed (2026-10-20)

- An HA rule pinning `uptime` to `jondingus` (a node no longer in the cluster) and two unreferenced snippets were destroyed; the USB mapping `Back-UPS` stays.
- VM 100 has a USB device in slot `usb4` that no plan shows: the provider knows only `usb0` to `usb3` (bpg#3009).

## VM 100's Bluetooth adapter mapped, and root tickets (2026-10-20)

- Only `root@pam` itself may set USB passthrough by device ID; the token does not count. `ssh.root_ticket` runs node-scoped calls as `root@pam`, while calls outside `/nodes/` (cluster options, HA, mappings, storage, backup, access) still use the token.
- VM 100's passed-through AMD GPU does not survive a detach and reattach, so it sets `reboot_after_update = false` and is never rebooted on its own.

## Serial-apply workaround removed (2026-10-20)

- With the operator's agent fixed, parallel SSH works and `-parallelism=1` is gone. vkasm's user is `kasm_admin`, which the operator's SSH config sets only for its short name.

## LXC disks mount with `discard` and `lazytime` (2026-10-20)

- The option change applies live: Proxmox records it as current, not pending.

## Ansible reads secrets through SOPS (2026-10-20)

- `community.sops` 2.5.0's vars plugin, over Ansible Vault and decrypted copies. Salted adaptive hashes (bcrypt) may be plaintext; WireGuard private keys stay encrypted.

## arawi discovery for pfsensible (2026-10-20)

- arawi runs pfSense CE 2.9.0 with `python3.11` and sudo; `pfsensible.core` 0.7.1 needs 2.8.0+ and has no modules for GRE, WireGuard or Cron. The `group:admins` sudo row is `NOPASSWD`.

## arawi: pfsensible scaffold and route descriptions (2026-10-20)

- The operator's `config.xml` snapshot is authoritative over live arawi. A fix is edited into it, pushed to `/cf/conf/config.xml`, the config cache cleared, and the affected service reloaded.

## arawi: sections without a pfsensible module (2026-10-20)

- `pfsense_config_section` (in the role's `library/`) replaces the children each section owns when they differ, ignoring whitespace, writes through pfsensible's writer, and runs pfSense 2.9's own reload functions for changed sections.
- The collection fails on outbound NAT, the DNS Resolver, arawi's two certificates and the `tailscalerouter6` gateway, so those are sections.

## Public GUAs in plaintext (2026-10-20)

- Publicly known GUAs (Cloudflare `2606:4700:4700::1111`/`::1001`, Quad9 `2620:fe::fe`) are allowed through an exact-match allowlist in the `no-gua-ipv6` hook.

## arawi: files outside config.xml (2026-10-20)

- Six hand-made files are copied from `files/arawi.regulad.internal/`, including `u5g-gre6-sync.php` (every 2 minutes, rewrites the GRE tunnel's IPv6 addresses when the carrier's `/64` moves, so the `gre` section ignores them) and the watchdog's `tmpfscheck.sh`.
- Files live outside `inventory/` because `host_group_vars` loads extensionless files under `host_vars` and every file in `inventory/` is read as a source.

## arawi: rule names, site.yml, docs (2026-10-20)

- arawi has a group of its own, not `pfsense`, since another pfSense host would not share its configuration.
- The WAN rule "Allow home IPv6 to any" is not compiled because WAN is not enabled.
- `internal-ca`'s CRLF PEM stays base64. `.ansible-lint` excludes `*.sops.yml`, whose ciphertext cannot be wrapped.

## arawi: pfSense release pin and packages (2026-10-20)

- pfSense installs `config.xml`'s packages only at a boot that finds `/cf/conf/needs_package_sync`; otherwise it registers installed packages into `config.xml`. The role installs missing ones through pfSense's `installpkg` playback and never removes any.
- pfSense does not follow semantic versioning (minor releases change the FreeBSD base, config revision and package builds), so `pfsense_release` pins `<major>.<minor>` and the role refuses any other.

## arawi: the WireGuard ACL has one source (2026-10-20)

- The WireGuard package recreates its "WireGuard" ACL in `unbound/acls` on every resync, so the DNS resolver section ignores it; `ignore` keeps an ignored element's whole live subtree at its live position.
- `U5G_GRE` cannot have a static IPv6 (pfSense manages GRE addressing elsewhere), so `u5g-gre6-sync.php` never conflicts with `pfsense_interface`.

## arawi: more of config.xml in sections (2026-10-20)

- Gateways and DHCP moved to sections because pfsensible cannot model fields arawi sets. Both earlyshellcmds belong to their packages (System Patches, WireGuard) and `pkg_repo_conf_path` to pfSense's updater, so they stay unmanaged. `pfsense_shellcmd` manages only the Shellcmd package's commands.

## arawi: first real run (2026-10-20)

- `config.xml` was byte-identical before and after, so no section wrote and no reload ran.

## arawi: end-to-end check (2026-10-20)

- `vtnet1` runs at MTU 1500 although OpenTofu and `config.xml` say 9000, because pfSense leaves the disabled WAN interface unconfigured. The console is on `ttyu0`.

## pfsensible.core issues filed (2026-10-20)

- Seven bugs (#267-#273) and thirteen feature requests (#274-#286), each disclosing that Claude drafted it; arawi's `TODO.md` links them.
- The `pfsense_dns_resolver` crash comes from `sslcert` naming a description two certificates share; `pfsense_rule`'s IPv6 error on 0.7.1 is #219, fixed on `master`; `pfsense_dns_resolver` rejects IPv6 domain-override servers.

## arawi: split-horizon regulad.xyz through an Unbound RPZ (2026-10-20)

- View `local-data` cannot answer through CNAME chains, so a `lan`-tagged RPZ replaced the four view overrides, with a `stub-no-cache` stub zone so cached public answers do not reach LAN clients and `respip` in `module-config`.
- The zone's master is in `/usr/local/etc/unbound/` (owned `unbound:wheel`, so not in `pfsense_directories`); its copy in the chroot on the `/var` RAM disk is recreated at boot by `unbound-rpz-restore.sh` from the repository's one `earlyshellcmd`. Zones reload through `unbound-control`.
- arawi runs Unbound 1.26.1. The reboot test is still to do.

## arawi: PHP2Shell stopgap (2026-10-21)

- Upload progress off goes in `/usr/local/etc/php/99-php2shell.ini`, because `/etc/rc.php_ini_setup` rewrites `php.ini` on every php-fpm restart; restart with `/etc/rc.php-fpm_restart`.

## pterodactyl: PHP2Shell stopgap (2026-10-21)

- A `php_admin_flag` in the FPM pool keeps a `.user.ini` from turning upload progress back on.

## pterodactyl: PHP2Shell stopgap moved into Ansible (2026-10-21)

- The `php_fpm` role copies ini files into `conf.d`, keeps `php_admin_*` lines in a pool, and tests the configuration before reloading.

## freeipa: sudo through the Admins rule (2026-10-21)

- FreeIPA's `Admins` sudo rule overrode the local cloud-init grant; adding `!authenticate` to it took SSSD about 3.5 minutes to pick up. IPA does not manage DNS here.

## eMudhra: distrusted roots through ca_trust (2026-10-21)

- The compromised eMudhra intermediates chain to emSign ECC Root CA - G3 and Comodo AAA Services root. `ca_trust` negates their lines in `/etc/ca-certificates.conf` on Debian and Ubuntu and copies them into p11-kit's blocklist on Enterprise Linux; the PEMs match by SHA-256 across distributions.
- OS groups were introduced for this: `ubuntu` on gonkputer's Linux `ansible_host`s, an `os` freeform tag on OCI instances, and groups in `hardware.yml`.

## eMudhra: distrusted roots on the cloud-init VMs, by hand (2026-10-21)

- The six cloud-init VMs got the same change by hand; their vendor files do not carry it yet.

## arawi: emSign distrusted through ca_trust (2026-10-21)

- FreeBSD: copy into certctl's untrusted directory and `certctl rehash`. FreeBSD already distrusted Comodo AAA. `/etc/ssl/cert.pem` (PHP, Unbound, LDAP) is fixed; `ca_root_nss`'s bundle in `/usr/local/share/certs` keeps emSign until that package updates.

## bpg/proxmox: cloud-init replacement reported upstream (2026-10-21)

- Commented on bpg#2901 that Proxmox changes `cicustom` in place and a vendor-data-only change keeps the nocloud instance-id. It gates moving more VMs to cloud-init.

## pterodactyl: second PHP2Shell stopgap, gated on the fix (2026-10-21)

- `php_admin_value[memory_limit] = -1` closes another attack path. Stopgaps are removed automatically once the installed `php8.3-fpm` reaches `php_fpm_stopgap_until` (compared by dpkg).

## Automatic updates converged in Ansible (2026-10-21)

- `auto_updates` rebuilds `50unattended-upgrades` from the package's copy in `/usr/share/unattended-upgrades/`, validated with `apt-config` before replacing it, and sets keys in `automatic.conf`.
- Every host takes all updates from every repository, removes unused kernels and dependencies, and reboots automatically.
- prodingus excludes only `pve-test`: its patterns allow every component not starting with `p`, plus `pve-no-subscription`. Apply in stages with prodingus last, since it going down cuts off every guest.

## Mail relayed through FreeIPA null- accounts (2026-10-21)

- sudo mails as the invoking user, whose address the host's login does not own, so relays rewrite every sender to the account's address. prodingus's relay had logged in as `null-prodingus.home.arpa` and failed `535 5.7.8`.
- `mail_relay` creates `null-<short hostname>` through FreeIPA's API, delegated to freeipa (the only host that resolves `freeipa.home.arpa` and trusts its CA), and sets Postfix to loopback only, implicit TLS to `[mail.regulad.xyz]:465`, with every recipient rewritten to regulad@regulad.xyz.
- `svc-ansible` in FreeIPA holds only the User Administrator role. `svc-mail`'s bind password was rotated after it was printed in a session.
- With 30 forks, prodingus's sshd dropped container connections at `MaxStartups 10:30:100`; both stages run 10 forks. Each task on a container costs several `pct exec` round trips.

## arawi: second PHP2Shell stopgap, gated on the fix (2026-10-21)

- PHP reads the scan directory after pfSense's generated `php.ini`. Stopgap files stay while `PHP_VERSION` is older than `pfsense_php_stopgap_until` (compared by `pkg version -t`).

## Mail client on every relaying host (2026-10-21)

- smartd mails through `/etc/smartmontools/run.d/10mail`, which needs `/usr/bin/mail`, so `mail_relay` installs `bsd-mailx` (Debian, Ubuntu) or `s-nail` (Enterprise Linux).

## Containers surveyed; vaultwarden's Quadlet adopted (2026-10-21)

- Hosts already on Podman move to Quadlets; others keep their runtime. vaultwarden stays on `testing`, which tracks upstream Bitwarden's API.
- The `quadlet` role restarts only services whose files changed and keeps podman-auto-update on.

## Tailscale described in Ansible (2026-10-21)

- A role of our own over `artis3n.tailscale`, which re-runs `tailscale up` and has no Serve support. Nodes get tags by joining with a one-off tagged key minted through the API; `tailscale_protected` (aameter) refuses any join, and aameter and aboriginal are never re-authenticated.

## Avahi reflecting mDNS onto Podman bridges (2026-10-21)

- Hosts with containers on Podman bridges reflect mDNS, with `allow-interfaces` set to the LAN interface plus the bridge interfaces read at run time.

## uptime's Uptime Kuma moved to a Quadlet (2026-10-21)

- The `quadlet` role reloads systemd before starting a newly written unit and tolerates the missing unit in check mode.

## uptime and vaultwarden cleared of leftovers (2026-10-21)

- Removing a Podman network changes Avahi's `allow-interfaces`. An SSH agent timeout can drop a run before its handlers, leaving a restart to do by hand.

## timemachine and tvheadend moved to Quadlets (2026-10-22)

- Both use `latest`: mbentley/timemachine's other tags are `smb` (the same image) and dated builds, and tvheadend publishes only builds of `master`. That case is the only one where AGENTS.md allows `latest`.
- Check-mode tolerance for a not-yet-written unit is a `failed_when` matching systemd's "Could not find the requested service" (`ignore_errors` fails lint).
- tvheadend's DVR log lists July recordings whose files were never in its recordings directory.

## timemachine and tvheadend cleared of leftovers (2026-10-22)

- Privileged containers must run without AppArmor; it was removed from every running one. dpkg leaves `/etc/apparmor.d/local`, whose stubs other packages' scripts create.

## prodingus's pveproxy lost 8006 to Tailscale Serve (2026-10-22)

- After an automatic reboot, tailscaled's Serve took 8006 on the tailnet address before pveproxy, which failed five times and stopped retrying, taking down the API and UI (guests unaffected). `tailscale_after` orders tailscaled after pveproxy with a drop-in.

## aameter's aameterd moved to a Quadlet, its tunnel described (2026-10-22)

- aameterd's CI publishes only `latest`, `master` and `sha-*`. The `host_files` role places byte copies from `files/<host>/` and secrets from SOPS and keeps listed units running.

## git (VM 110) stuck in GRUB after the automatic reboots (2026-10-22)

- dracut was still building the new kernel's initramfs when prodingus rebooted itself, so git came back to a missing initramfs.
- The previous kernel did not boot either: boot entries still carried the OCI image's `netroot=iscsi:…` and `ip=dhcp,dhcp6` options. They were removed with `grubby --update-kernel=ALL --remove-args` and from `GRUB_CMDLINE_LINUX`.
- RHEL's guest agent ships with `guest-exec` disabled.
- prodingus now reboots at 02:00, so a host reboot no longer lands in the guests' morning update window.

## pihole: Pi-hole replaced by blocky (2026-10-22)

- blocky is an idiomatic forwarder: arawi upstream; conditional forwarding of `regulad.internal`, `tail11540.ts.net` and the OCI pubsub zone with their reverse zones; StevenBlack's lists answered with `0.0.0.0`/`::`; empty answers for Firefox's DoH canary and iCloud Private Relay (both vendors treat no answer as NXDOMAIN); no query log. Unqualified names get arawi's NXDOMAIN.
- blocky needs `bootstrapDns` through arawi, or it resolves its list URLs through itself. It rejects a duplicate key, which took tailnet DNS down for six minutes; Ansible needs DNS to read OpenTofu state.
- The OCI resolver has no IPv6 PTR records, so no IPv6 reverse zone is forwarded there. The config is checked with `blocky validate` in its own image.
- AGENTS.md's Priorities (IPv6-first, DRY from OpenTofu state) come from this work.

## openwebui moved to a Quadlet on upstream 0.12 (2026-10-22)

- Upstream converts tool_result images, documents and search results itself since v0.9.0, so Parker's fork image was dropped for the `0.12` tag (no major-only tag exists). Its LDAP login reads the FreeIPA root CA, placed at `/etc/ipa/ca.crt`.

## ingress described; cloudflare-ddns moved from Docker to a Quadlet (2026-10-22)

- Caddy is rebuilt with xcaddy (cache-handler, caddy-dns/cloudflare, caddy-l4) at every start. `caddy validate` needs the Cloudflare token sourced, which its DNS provider reads.
- cloudflare-ddns uses `DELETE_ON_STOP=false`, so restarts and auto-updates keep the record.
- Caddy's build cache is `/var/lib/caddy/go` and `/var/cache/caddy`.

## Coraza WAF for PHP2Shell on Caddy; pterodactyl's stopgaps pruned (2026-10-22)

- Caddy cannot inspect request bodies, so the OWASP Coraza module carries Abstract Security's PHP2Shell rules (CVE-2026-109619, CVE-2026-109618), with `coraza_waf` ordered first. Bodies are inspected up to 12.5 MB; larger ones pass partially inspected.
- Only `nextcloud.regulad.xyz`, whose PHP is on stopgaps, imports the rules; pterodactyl's PHP is fixed.
- `caddy reload` skips a reload when the Caddyfile is unchanged, even if an included file changed, so `ExecReload` passes `--force`.

## tsexit and ncsusplitt described and checked off (2026-10-22)

- vpn-slice is not packaged by Ubuntu; `host_files` pins it through pipx's global install.
- Each NCSU tunnel login is a Duo push, so `ncsu-tun` waits in `ExecStartPre` until `vpn.ncsu.edu` resolves (no start timeout), its start limit is 3, and unit changes do not restart it.
- Proxmox ignores startup order and delays for HA-managed guests (qm(1)).
- `tpm-udev` cannot be removed (openconnect needs libtss2), so drop-ins with `ConditionVirtualization=!container` skip its failing units.

## tailscalerouter (gonkputer) described and checked off (2026-10-22)

- radvd advertises the tailnet's `fd7a:115c:a1e0::/48` and the OCI pubsub `/64` to the LAN; the `/64` comes from OpenTofu state through an `ip_network` filter, checked with `radvd --configtest`.

## pterodactyl described and checked off (2026-10-22)

- The panel code (from a release tarball) and its database stay host data; panel upgrades are Pterodactyl's manual procedure.

## Pterodactyl panel managed by a role; maintenance.yml; upgraded to 1.15.2 (2026-10-22)

- Maintenance that cannot be automated goes in `playbooks/maintenance.yml`, one tagged play per task. Its first play runs the panel's official update procedure in maintenance mode, which is always lifted.

## cordpepperer and peppercord: PepperCord run by podman-compose (2026-10-23)

- A shared `podman-compose@.service` runs `podman-compose up` from `/opt/%i`. podman-compose labels containers with that unit, so `podman-auto-update` restarts it on new images.
- podman-auto-update needs fully qualified image names. `x-podman: in_pod: false` keeps the compose networks separate.
- The mongo image's anonymous `/data/configdb` volume is recreated with every container, so orphans accumulate with auto-updates.

## mastodon, procontainer and llamarpcmaster made dormant (2026-10-23)

- Dormant means an HA state of `disabled` (or no start on boot without HA) plus `started = false`, which also removes the guest's `ansible_host`. act followed as unused.

## openclaw kept to the baseline (2026-10-23)

- Its application will not be described for now; it gets only the shared roles.

## immich moved from Docker Compose to podman-compose (2026-10-23)

- Immich says to use the current release's compose file; its maintainers allow dropping digest pins, so Valkey tracks `9` and Postgres a `14-vectorchord…` tag. Postgres 14 leaves support on 2026-11-12, and moving on is Immich's manual upgrade.
- Podman ignores health checks from OCI images' config, so only Valkey reports health.
- Pre-pulling filled the 16 GB root disk; it was grown to 32 GB online in OpenTofu.

## aboriginal and dodo: quasi-hardware VMs, now in the Ansible inventory (2026-10-23)

- aboriginal answers LAN SSH over `tailscale0`, so its entry connects by tailnet name (`local.tailnet_domain`). dodo's FreeIPA account is `null-pelican`, after its legacy name. Their own services are still to be described.

## git: Forgejo moved from VM 110 to the git container (200) (2026-10-23)

- Forgejo's built-in SSH server on 2222 reuses the VM's host keys, so clients' known_hosts still match.
- A `moved` block for a renamed HA resource cannot stay when the new guest takes the old address; an old state needs a manual `state mv`.
- DHCP gave the container a new address despite the VM's MAC.

## git.regulad.xyz behind Caddy; the git VM destroyed (2026-10-23)

- Forgejo trusts `X-Forwarded-For` from the LAN ranges (`REVERSE_PROXY_LIMIT = 1`).
- A VM's own protection flag blocks destroy (`qm set <id> --protection 0`).
- `qmdestroy` fails when listing the `rbd` storage fails: an image stuck in `rbd_ssd`'s trash since 2026-03 had to be removed with `rbd trash rm --force`. An expired `vm-111-disk-0` remains in the trash.

## unattended-upgrades mails only on errors (2026-10-23)

- `MailReport "only-on-error"` in all six places it is set; dnf-automatic has no such mode.

## authentik: moved from VM 109 to the authentik container (201) (2026-10-23)

- Upstream's compose file with auto-update labels, the release tag, named volumes, and no Docker socket or `/certs`. Stepping the release tag one release at a time with a dump before each (2026.2 → 2026.5 → 2026.8) migrated cleanly.
- A restore needs the stack's fresh empty database dropped first.
- ingress's systemd-resolved cached the VM's old address (502) until flushed.
- The git.regulad.xyz CNAME had never existed; Cloudflare accepts a DNS-only CNAME beside the JitPack TXT and Caddy's ECH HTTPS record.

## matrix: Synapse and its bridges moved from VM 107 to the matrix container (202) (2026-10-24)

- Ubuntu 26.04 is the newest release Synapse builds for. Its modules are pip-installed into the package's environment; `shared_secret_authenticator` 2.0.3 exists only as a GitHub archive (PyPI stops at 2.0.1). Synapse is not held: an upgrade keeps the modules.
- Bridges come from release binaries pinned by sha256 (`host_files_downloads`). Telegram's Go bridge migrates the Python bridge's database after the legacy permission levels `relaybot` and `full` are mapped to `relay` and `user`.
- Building `synapse_auto_compressor` needs git, make and the system OpenSSL instead of the vendored build.
- A createcluster.d drop-in puts the Postgres cluster on `/mnt/synapse`. Upgrading 17 to 18 used `pg_upgradecluster --method=link`; the `postgres` database needed the `en_US.UTF-8` locale.
- Data was copied on prodingus with the container stopped through `pct mount`: krbd maps the VM's data disk read-only, but not its root disk's feature set, which `qemu-nbd --read-only` reads.
- Adding a mount point and shrinking the root disk replaced the container, and Proxmox removed its HA resource with it.
- A restart handler lost to a failed run left the package's default Synapse on SQLite.
- The federation tester passed over IPv4 but timed out on ingress's IPv6 address.

## Network switches become Ansible hosts; the Arista adopted (2026-10-24)

- Network modules drive a switch's CLI from the control node (`network_cli`), so switches need no Python; they are a `switches` group in `ansible-hardware`, outside `hardware`.
- The Arista (DCS-7010T-48, EOS 4.28.10.1M) has no password hashes: `regulad` is `privilege 15 nopassword` with Parker's key.
- `eos_config` with `replace: config` loads the whole file in one configuration session; it requires `src`, not `content`. Loading takes longer than 30 seconds, so the command timeout is 240; a timed-out run leaves a pending session to remove by hand.
- EOS drops `!` comments, so port annotations cause no diff. Ports were identified from tcpdump of LLDP on the hosts, the switch's LLDP table and arawi's Kea leases.

## Datacenter notes in plaintext (2026-10-24)

- The notes are `tofu/gonkputer/cluster-notes.md`, read by `file()` byte for byte as Proxmox stores them (trailing spaces included, so the file is exempt from the whitespace hooks).

## Arista ports, VLANs and the datacenter notes' subnets (2026-10-24)

- Device ports are access ports on VLAN 1 with port security and a static MAC entry (`Secure-up`). Unused SFP+ Ethernet51 and 52 are shut down. overture's port stays a trunk, since it hosts generated resources, as do unknown 1 GbE ports.
- VLANs are 1-16 only; VLAN 16 is the corosync and Ceph intercom.
- A VLAN ID sits in the third IPv4 octet's upper four bits (VLAN 1, native, is `0000`; VLAN 16 takes `0001`) and in hex as the homelab ULA's fourth hextet.
- The Octo4a devices on Ethernet31 and 32 send no frames and answer no ARP scan, so they cannot be bound to a MAC yet.

## The SG300s become Ansible hosts (2026-10-24)

- Each switch has a privilege-15 `svc-ansible` with its own RSA 3072 key, in SOPS, because firmware 1.4 holds one SSH key per user (`user-key` replaces it). `bin/with-switch-keys` loads the keys into a throwaway ssh-agent.
- Firmware 1.4.11.5 with OpenSSH 5.9:
  - CPUs are slow: `show running-config` can take over 30 seconds (timeout 120).
  - Attempt one connection at a time: there are only a few session slots, and a session stalled at the line-width limit never idles out. No command clears another session; a reload does.
  - They answer SSH only after a ping.
  - `terminal width` defaults to 77, and input reaching that column stalls the line editor; `terminal width 0` avoids it.
  - A second Enter arriving while they print stalls their output, so the local cliconf sends one end of line.
  - `username <name> password <password> privilege 15` works; the guide's `username <name> privilege 15 <password>` is rejected. `write` asks `(Y/N)[N] ?`, and any other key cancels.
- Crypto: they need `diffie-hellman-group1-sha1`, 1024-bit RSA host keys and SHA-1 `ssh-rsa` signatures.
  - OpenSSL 3.5 refuses SHA-1 signatures, in ssh-agent too, so `bin/openssl-legacy.cnf` lowers the security level.
  - Fedora's crypto policy sets `RequiredRSASize 2048`, which libssh reads from the user's config (found through getpwuid) and pylibssh cannot override; Parker's SSH config sets 1024 for them.
  - paramiko 5.0 has neither algorithm.
- Password hashes are unsalted SHA-1 (enable: bare MD5), so they stay in SOPS and the templates take them from `ciscosmb_password_hashes`.

## Switches: the SG300s' changes pushed by Ansible (2026-10-24)

- The local cliconf diffs `show running-config` text. `cli_config` with `diff_match: line` sends the missing lines; then `diff_match: exact`, against a fresh read, negates leftovers, so a setting a changed line overrides is never negated. User keys are resent whole; the header before the first `!` is never pushed.
- Commands are typed a character at a time: whole lines get dropped and stall the session. Characters go straight to the shell channel, because network_cli ends every send with a carriage return; the first attempt ran single letters as commands, including `w` (`write`) and `co` (`configure`).

## Switches: the SG300s' combo ports gi9 and gi10 shut down (2026-10-24)

- gi9 and gi10 are 1G combo ports (RJ45 or SFP); `shutdown` disables both sides.
- The switch prints `shutdown` above `switchport mode access`; templates must match its printing order exactly.
- The role reads startup-config every run and saves whenever it differs, so a push whose reread failed is still saved later.

## Switches: the SG300s' ports surveyed, annotated and two tied down (2026-10-24)

- Jinja comments in the templates render to nothing, so port annotations cause no diff; ports with no link carry none. Learned MACs were named from arawi's Kea leases.
- A MAC bind is `port security discard` on the port plus `mac address-table static <mac> vlan 1 interface <port> secure`, which the switch prints after the final `exit`. A secure entry needs its port locked first, so pushes follow the template's order.
- `sony-player` never answers ping.
- Automating these switches is markedly non-deterministic. The same command in the same state may succeed or stall, sessions stall at random (often on the read after a burst of commands), and a push's result must be read back rather than inferred from the task. Reruns get through.
- Parker listed the AirPort Extreme and a CR1000B as access points to declarativize.

## dodo: probed; the compromised www-data removed (2026-10-24)

- dodo (formerly pelican) ran a Pelican panel under nginx and PHP as www-data, which was compromised; Parker moved nginx to `pterodactyl` and removed the web stack on 2026-08-04, but www-data's persistence survived it (cron jobs in auth.log from at least 2026-09-20).
- The persistence was a www-data crontab running an obfuscated Perl loader in `/var/tmp` every 5 and 6 minutes. It fetched tasks from its C2 hosts, ran Perl processes named `init` (listening on 52400 and 30175) and memfd ELF processes named `/usr/bin/php`, and sent spam straight to public mail servers on port 25.
- Removed: the crontab, the processes, the loader, the packages' leftover configuration (apache2, libapache2-mod-php8.3, nginx-common), `/var/lib/nginx`, `/var/log/nginx`, `/etc/php`, `/var/www`, and the www-data user and group. Nothing respawned after a cron cycle. Nothing showed root was reached; root-only secrets were not rotated, at Parker's call.
- Exclude `/var/lib/docker` and `/var/lib/containerd` when searching by owner: uid 33 in image layers is the containers' own user.
- Left for describing dodo: `wings` fails since boot; certbot's `dodo.regulad.xyz` uses the manual plugin with no auth hook, so renewals fail; Docker runs `cloudflare-ddns` (`favonia/cloudflare-ddns:latest`) and one stopped Pterodactyl server; root's crontab runs a restic backup at 05:15 (`/root/backup.sh`) and a `certbot renew` that restarts nginx, which no longer exists.

## dodo: services inventoried (2026-10-24)

- dodo is a Pterodactyl Wings node (`/usr/local/bin/wings`, config `/etc/pterodactyl/config.yml`, panel `https://pterodactyl.regulad.xyz`). It hosts one server, `9af70676-…`: Fabric Minecraft 26.3 in `ghcr.io/pterodactyl/yolks:java_25`, 31 GB in `/var/lib/pterodactyl/volumes`, with BlueMap, on ports 45510 and 45511 (TCP and UDP). Wings serves its API on 8080 and SFTP on 2022, with TLS from the `dodo.regulad.xyz` certificate.
- Wings has been down since boot on 2026-10-22: the panel timed out, then answered 404 on `/api/remote/servers`, and systemd stopped retrying after the start limit. The panel answers now.
- `dodo.regulad.xyz` is kept current by `favonia/cloudflare-ddns` (Docker Compose in `/root/cloudflare-ddns`, host network, unproxied). Its certificate came from certbot's manual DNS-01 and cannot renew; it expires 2026-11-02.
- The 05:15 job in the VM's description is `/root/backup.sh`: restic over S3 (`/etc/restic-env`), backing up `/` and `/boot/efi`, keeping 2 weeklies.
- Postfix relays through `mail.regulad.xyz:465` as `null-pelican`; `myhostname` and `/etc/hosts` still say `pelican`. tailscaled is masked. The guest runs a watchdog daemon against the VM's watchdog, kdump, panic-on-hang sysctls, a 16 GB swapfile plus 8 GB zram, AIDE daily, and auditd with no rules.
- Leftovers from the original hardware install: open-vm-tools, ModemManager, thermald, multipathd, snapd with no snaps, lxd-installer, a disabled cloudflared-update timer with no cloudflared, and configuration from about 45 removed kernels.
- Probe output that prints compose files needs `SHOUTRRR` in its redaction pattern: the DDNS compose holds a Discord webhook URL.

## kdump: a shared role on prodingus, aboriginal and dodo (2026-10-24)

- The `kdump` role mirrors the hand setup on prodingus and dodo, whose `/etc/default/kdump-tools` were byte-identical. prodingus reserves `crashkernel=1024M` and panics on hard lockups; the Ubuntu guests use the package's sized reservation and leave hard lockups alone.
- The hand-written `99-panic.conf` set `hung_task_timeout_secs` without its `kernel.` prefix, which systemd-sysctl rejects at every boot, so the timeout stayed 120 s; the role drops the line rather than starting a 30-second hung-task panic.
- aboriginal (Ubuntu 26.04) had no kdump. Its package ships the same GRUB snippet and runs `update-grub` itself. It keeps `vm.panic_on_oom = 0`. The crash kernel loads only once a boot reserves its memory, and VM 100 boots only with the host; until then `kdump-config show` says "Not ready to kdump". The package starts the oneshot unit on install, which then shows active (exited) without loading anything.
- aboriginal answers SSH only by its tailnet name (`aboriginal.tail11540.ts.net`); its LAN name times out.

## dodo: leftovers removed and pelican renamed (2026-10-24)

- Purged open-vm-tools, ModemManager, thermald, multipath-tools, snapd, lxd-installer, lxd-agent-loader and ubuntu-fan with `--autoremove` in the same run, plus every removed package's leftover configuration. multipath-tools and snapd take the `ubuntu-server` and `ubuntu-server-minimal` metapackages with them; autoremoving in the same run leaves nothing for unattended-upgrades' `Remove-Unused-Dependencies` to remove later. Simulate with `apt-get -s purge --autoremove` first.
- Postfix had `myhostname = pelican`, which mail_relay does not manage; the line is removed, so Postfix takes `dodo.regulad.xyz` from the hostname and `mydomain`. `/etc/hosts` maps 127.0.1.1 to `dodo`. The FreeIPA account stays `null-pelican`; `root@pelican` remains only as the SSH host keys' comments and in Wings' own logrotate file.
- Rotated `null-pelican`'s relay password after it was exposed: `sops set` with a generated value, then `community.general.ipa_user` with `update_password: always`, delegated to freeipa. A standalone play must not load the role's defaults through `vars_files`, which outrank inventory and blank the SOPS passwords. mail_relay's next run restores the account's `krbpasswordexpiration` after the reset.
- dodo's IPv4 connection to mail.regulad.xyz:465 times out, so each message waits 30 s before going out over IPv6.

## Watchdog: a role for dodo and aboriginal; aboriginal pauses (2026-10-25)

- Both VMs already matched: Proxmox's i6300ESB (60 s), the `watchdog` daemon pinging `/dev/watchdog` every second with no other checks, and systemd's own watchdog off. The `watchdog` role in ansible-generated declares it; its `watchdog` group comes from each VM's own `watchdog` block in OpenTofu.
- The package's postinst rebuilds `/etc/default/watchdog` from debconf on every upgrade, and both VMs answered `watchdog/module: none`, so an upgrade would have reset `watchdog_module`; the role sets the answer. The `ubuntu-vendor.yaml` VMs (unifi) carry the same latent drift, which a future vendor file should preseed instead (TODO.md).
- `i6300esb` ships in the base modules package on Ubuntu 26.04 and in lowlatency kernels, and in `linux-modules-extra` only on 24.04 generic. Ubuntu has no package that tracks only the extra modules: `linux-image-extra-virtual` depends on the full `linux-image-generic`.
- aboriginal's watchdog action is `pause`, so a lapse leaves VM 100 frozen for inspection rather than resetting it. Proxmox holds the change as pending until the VM next starts; the running VM got it through `qm monitor 100` and `watchdog_action pause`, which QEMU cannot read back.
- aboriginal lists `linux-firmware` in `host_files_packages`. It was already installed as a dependency of `linux-image-generic`, and Ansible's `apt` does not mark it manual.

## dodo: its certificate renews by Cloudflare DNS-01; linux-firmware declared (2026-10-25)

- `dodo.regulad.xyz` had been issued with certbot's manual DNS-01 plugin, which cannot renew unattended. `certbot reconfigure --cert-name … --authenticator dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini` tests a renewal against staging before rewriting the renewal configuration; it then renewed to 2027-01-23. certbot owns `/etc/letsencrypt` except the credentials file and the deploy hook, which `host_files` writes.
- certbot uses the same Cloudflare token as cloudflare-ddns, now `cloudflare_api_token` in dodo's SOPS file; the DDNS compose file still carries its own copy until cloudflare-ddns is adopted.
- The deploy hook `try-restart`s Wings, which reads its certificate only at start, so a renewal never starts a stopped Wings. Root's old `certbot renew … restart nginx` cron line is gone; certbot's timer renews twice a day.
- dodo lists `linux-firmware` in `host_files_packages`, as aboriginal does.
- A `certbot` role in ansible-generated now owns this, on a `certbot` group from OpenTofu: it issues a listed certificate only when certbot has no renewal file for it, then keeps only `authenticator` and `dns_cloudflare_credentials` in that file (`community.general.ini_file`, section `renewalparams`) and `certbot.timer`. The package's `/etc/cron.d/certbot` does nothing under systemd. dodo's ACME accounts have no contact address, so the role registers without one unless `certbot_email` is set.

## dodo: Wings adopted at v1.13.2; Docker's boot links restored (2026-10-25)

- The `wings` role installs Wings by Pterodactyl's guide on the distribution's `docker.io`, pinned by version and the release asset's sha256, which GitHub lists per asset (`gh api repos/pterodactyl/wings/releases/tags/v<version>`). The live binary matched v1.13.2's `wings_linux_amd64`. `wings version` prints `wings vv1.13.2`.
- `/etc/pterodactyl/config.yml` is the panel's, and Ansible never writes it. Upgraded the same day to v1.13.4 through the maintenance play, with the panel already current; the Minecraft server kept running.
- `Prompt=never` in `/etc/update-manager/release-upgrades`, because Wings supports Ubuntu up to 24.04.
- `playbooks/maintenance.yml --tags wings` upgrades to the declared release, verifying the new binary before stopping Wings. Game servers keep running across a Wings restart.
- Purging the removed `docker-ce` and `containerd.io` packages' leftover configuration disabled `docker.service`, `docker.socket` and `containerd.service`, which `docker.io` ships under the same names, though Docker kept running. The role keeps them enabled. Check `systemctl is-enabled` for same-named units before purging a removed package.
- Wings had failed at boot on 2026-10-22, because the panel timed out and then answered 404 while it moved. Started again, it restored the Minecraft server to its recorded `running` state.

## dodo: cloudflare-ddns moved to a Podman quadlet; unneeded packages removed (2026-10-25)

- cloudflare-ddns is a quadlet in `podman_hosts`, as on ingress. Its env file is built in `services.yml` from `cloudflare_api_token` (shared with certbot) and `cloudflare_ddns_shoutrrr`.
- The old compose stack had `DELETE_ON_STOP=true`; it was stopped with `docker compose kill`, so its updater never ran the delete and the A and AAAA records survived. The quadlet keeps `DELETE_ON_STOP=false`.
- The `podman_hosts` plays have no `become`, because the containers they were written for are reached through `pct` as root; dodo sets `ansible_become: true`.
- Purged auditd, AIDE (171 MB database), sysstat, apport, open-iscsi, lvm2, mdadm, ufw, udisks2, fwupd, pollinate, tpm-udev and ubuntu-drivers-common, plus `docker-compose-v2` and the stale images. Afterwards `systemctl reset-failed` clears the removed units still listed as failed.
- Keep `ubuntu-pro-client`, whose removal takes `ubuntu-minimal`, and `update-notifier-common`, whose kernel hook writes `/var/run/reboot-required`, which unattended-upgrades' automatic reboots wait for.
- Wings writes `/etc/logrotate.d/wings` from its own `log_directory` when the file is missing; the old copy pointed at `/var/log/pelican`.
- prodingus's root filesystem was at 94% (5.7 GB free), raising Ceph's `MON_DISK_CRIT`; tofu plans briefly failed with HTTP 596 reading an rbd_cmr volume while osd.10 had slow ops.

## ca_trust: the homelab's four roots of trust trusted on every host (2026-10-25)

- The role's `files/trusted/` holds internal-ca and regulad.internal (arawi's pfSense CAs, extracted from `config.xml` by a script that prints only each `<ca>`'s `crt`), ipa-ca (freeipa's `/etc/ipa/ca.crt`) and pve-root-ca (`/etc/pve/pve-root-ca.pem`).
- Each family takes them where its store keeps local anchors: Debian `/usr/local/share/ca-certificates/<name>.crt`, RHEL `/etc/pki/ca-trust/source/anchors/`, FreeBSD `/usr/local/share/certs/<name>.pem`. FreeBSD's `certctl` is now a C binary that also reads `/usr/local/etc/ssl/certs`; it lists anchors by subject hash and subject name.
- pfSense trusts its own CAs from each `<ca>`'s `<trust>enabled</trust>`, as `/usr/local/etc/ssl/certs/<subject hash>.crt`, so arawi's `ca_trust_trusted` lists only ipa-ca and pve-root-ca.
- Several hosts already trusted some of the four by hand, some with CRLF copies or mode 0444. aboriginal's `ipa-ca.crt` was a directory holding `ipa-ca.crt`, which `update-ca-certificates` reads recursively; it was removed before the role wrote the file. aboriginal's `cohensstore003.internal.crt` stays unmanaged. turk was unreachable.
- With OpenSSL 4, `openssl x509 -fingerprint` without a digest flag prints SHA-256. Settle any doubt about a fingerprint with `openssl x509 -outform DER | sha256sum`.

## kernel_params: sysctl and GRUB drop-ins declared (2026-10-25)

- A shared `kernel_params` role writes `/etc/sysctl.d/<name>.conf` and `/etc/default/grub.d/<name>.cfg` from host variables, plus `99-acct.conf` (`kernel.task_delayacct = 1`) on every host outside `proxmox_containers` and `99-tailscale.conf` (forwarding) where `kernel_params_ip_forwarding` is set: aboriginal, prodingus and tsexit, though only tsexit advertises anything to Tailscale.
- prodingus's memory and CPU topology is intentional:
  - 64 boot-time 1 GB hugepages back the VMs;
  - `vm.nr_overcommit_hugepages = 2048` (2 MB) serves anonymous hugepages in containers, such as PostgreSQL's;
  - `isolcpus` and `irqaffinity` keep 8-15 and 24-31 for the pinned VMs.
- Debian 13's `systemd-sysctl` does not read `/etc/sysctl.conf`; prodingus's `ignore_routes_with_linkdown` lines there had never applied.
- `99-ping.conf`'s `ping_group_range` duplicated systemd's `50-default.conf`.
- A YAML flow list splits a kernel argument such as `isolcpus=domain,managed_irq,8-15,24-31` at its commas; write each argument as a block-list item.
- aboriginal's `cgroup_enable=memory swapaccount=1` is also in GRUB's debconf answer `grub2/linux_cmdline_default` and in ucf's copy of `/etc/default/grub`, from which GRUB's postinst rebuilds the file.
- Removed by hand afterwards: prodingus's `/etc/sysctl.conf` and `99-ping.conf`; dodo's `vm.swappiness=10` (`dpkg --verify procps` clean again, live value back to 60); aboriginal's `99-local.conf` and `cgroup_enable=memory swapaccount=1`. For the GRUB arguments, `grub2/linux_cmdline_default` was set to empty with `debconf-set-selections`, and the line was emptied in both `/etc/default/grub` and `/var/lib/ucf/cache/:etc:default:grub`, followed by `update-grub`.

## apt_amd64v3: Ubuntu's amd64v3 variant on every 25.10+ host (2026-10-25)

- `/etc/apt/apt.conf.d/99enable-amd64v3` (`APT::Architecture-Variants "amd64v3";`) was already on aboriginal and 15 containers by hand; authentik, matrix and git lacked it. The `apt_amd64v3` role sets it on Ubuntu 25.10 and later where `/lib64/ld-linux-x86-64.so.2 --help` reports `x86-64-v3 (supported`, removes it elsewhere, and refreshes the lists without upgrading.
- Every gonkputer guest reports x86-64-v3, containers included, because the loader reads the host's CPU. Of the OCI instances, doppelgangerhq.com does not; it runs 24.04 anyway.

## Hostnames: Postfix named from NSS or DHCP; Subiquity's /etc/hosts line on hardware installs (2026-10-25)

- Postfix cannot take its name from NSS or networkd: `myhostname` defaults to `gethostname()`, plus `.$mydomain` when that has no dot. `mail_relay` therefore sets it at run time:
  - to `hostname --fqdn` when that has a domain: Proxmox's `/etc/hosts` gives the containers `<name>.regulad.internal`, and cloud-init gives OCI `<name>.pubsub.wahlecloud.oraclevcn.com`;
  - otherwise to `<short>.<DHCP domain>`, from `resolvectl domain` on the first default route, by metric, whose link has one;
  - otherwise it removes `myhostname`.
  mail.regulad.xyz accepted relayed mail under both kinds of name.
- aboriginal has two default routes. eth0 (networkd, from the installer's netplan) passes no DHCP domain to resolved, because networkd's `UseDomains` defaults to off; wlan0 (NetworkManager) does. That is a netplan fix. dodo's resolver currently cannot resolve `regulad.internal` names at all: its current DNS server is the upstream router's address in the LAN's GUA /64, which does not know the internal zone.
- Ubuntu's Server installer (Subiquity) writes `127.0.1.1 <short name>`; cloud images write no such line. With it in place, `hostname -f` stops at the short name, which is why the DHCP fallback exists.
- `playbooks/maintenance.yml --tags hostname` (`base`'s `hostname.yml`) sets that line and the static hostname where `base_hostname_managed` is set: dodo, aboriginal and turk.
- aboriginal's `/etc/hosts` held a stale `10.23.0.247 dingus-server.home.arpa dingus-server`, the source of its Postfix name `dingus-server.home.arpa`; the line was removed by hand.
- Excluded from naming:
  - prodingus, which keeps `prodingus.home.arpa` pinned, its naming being Debian's and Proxmox's;
  - vkasm, a self-contained Kasm image;
  - doppelgangerhq.com, whose network configuration Oracle furnished at install time.

## netplan: dodo and aboriginal configured by netplan alone, through netplan try (2026-10-25)

- The shared `netplan` role writes `/etc/netplan/30-homelab.yaml` from `netplan_config` and removes every other netplan file, NetworkManager's `90-NM-*` included, on hosts without cloud-init networking. It also writes networkd drop-ins for what netplan cannot express: networkd's `UseGateway` (dodo ignores router advertisements' gateways) and `MulticastDNS` (aboriginal's eth0).
- `netplan try` waits for Enter on a terminal and handles SIGUSR1 as accept and SIGINT as reject; SIGTERM kills it without reverting. The role runs it under `systemd-run` and `script`, fed by `sleep` so no Enter arrives. Its revert restores only the rendered `/run` configuration, so a `systemd-run` timer restores `/etc/netplan` and `/etc/systemd/network` from a backup a minute after the try timeout unless Ansible disarms it. Ansible accepts only after reconnecting once `/run/netplan/netplan-try.ready` exists, and once every declared interface has a global address.
- Reconnecting proves only the link Ansible uses. The first aboriginal apply was accepted with wlan0 down: netplan's NetworkManager backend writes `ipv6.method=manual` unless `dhcp6` is set, and with an IPv6 nameserver but no address NetworkManager 1.54 refuses the connection ("method 'manual' requires at least an address or a route"). `accept-ra` alone does not give `method=auto`; `dhcp6: true` does. Validate a candidate with `netplan generate --root-dir <scratch>`, which renders NetworkManager's keyfiles there.
- The `cloud.terraform.terraform_state` inventory keeps an `ansible_host`'s variables under `variables.value`; each one Ansible reads needs a `compose` entry, now including `eth0_mac_address`.
- dodo routes IPv4 through the upstream router and IPv6 through it first (metric 1024) and arawi second (2048), for its port forwards, while taking DHCP and DNS from arawi. Router advertisements' DNS, the upstream router's, could not resolve `regulad.internal`; both hosts now drop it and list arawi's ULA first. aboriginal's fixed link-local DNS server, arawi's old address, never answered.
- The Wi-Fi PSK is `wifi_psks.WahleNet` in the shared SOPS file. wlan0 now uses EUI-64 SLAAC addresses rather than the privacy addresses NetworkManager's own profile gave it.

## swap: zram through systemd-zram-generator at half the RAM; disk swap only on real drives (2026-10-25)

- zram-generator's `ram` is `MemTotal` in MiB, and `zram-size` gives MiB; its expressions take `+ - * / ^ %`, `min`, `max` and more. Setting `ZRAM_GENERATOR_ROOT` to a scratch root holding `etc/systemd/zram-generator.conf` and a copy of `/proc/meminfo` runs it in test mode. It fails on a syntax error or a size of zero or less, so the role validates a candidate that way.
- `MemTotal` still counts boot-time hugepages, so prodingus's zram is `(ram - 65536) / 2` (31075 MiB), with 65536 MiB derived from `vm_hugepages_1gib`, which also feeds GRUB's `hugepages=`.
- Replacing a zram0 in use brings the new configuration up first, on a transitional zram1 from a `/run/systemd/zram-generator.conf.d/` drop-in, so the kernel has somewhere to page out while the old device empties. Then zram0 is set up from the configuration and zram1 hot-removed.
- `zram-tools`' stop turns the swap off but resets the device only by unloading the zram module, which zram1 holds, so zram0 stays initialized and `--setup-device` fails with EBUSY; the role writes `/sys/block/zram0/reset`.
- On aboriginal (systemd 259), stopping `dev-zram0.swap` was canceled and the swap came straight back. The device had alias swap units by label, UUID and diskseq, and the swapoff ran through `dev-disk-by-diskseq-*.swap`. Stopping `systemd-zram-setup@zram0.service` instead stops the swap, which requires it, and then resets the device. dodo (systemd 255) had no aliases.
- `ansible.builtin.copy` does not create a missing parent directory.
- `systemd-zram-generator`'s maintainer scripts only run `daemon-reload`, and its swap unit merely `Requires` the setup service, so installing it beside an active `zramswap` changes nothing live. Its preinst `rm_conffile`s `/etc/systemd/zram-generator.conf` when upgrading from before 1.1.2-5, as dodo's 1.1.2-3 would.
- The OCI Oracle Linux swapfiles came from cloud-init's `cc_mounts`, via Oracle's `oci-linux-config` (`99_oci.cfg`: `swap: {filename: /.swapfile, size: auto}`), sized from RAM. mail, bailout and tailscalerouter were later rebuilt at 6 GiB by hand, and their fstab lines lack cloud-init's `comment=cloudconfig`; they stay as they are.
- doppelgangerhq.com's Android container runs Android's own `init`, which writes host sysctls such as `kernel.pid_max` (65535 live, against 4194304 in `99-android.conf`).

## restic: repository access managed; doppelgangerhq.com and pelican out of the repository (2026-10-25)

- prodingus, aboriginal, dodo and (unreachable) turk back up to one Backblaze B2 repository (`s3:s3.<region>.backblazeb2.com/<bucket>`), and every host used the same B2 key and the same password.
- The `restic` role writes `/etc/restic-env` and `/etc/restic-password` at mode 0400. The env file is in systemd `EnvironmentFile=` form without `export`, so shell scripts must read it with `set -a`; dodo's `backup.sh` still uses a plain `source`, pending its rewrite. Bucket, region and password are shared in `ansible-common/group_vars/all.sops.yml`; each host's key is in its own `secrets.sops.yml`, so keys can be split per host.
- prodingus had both files at mode 644.
- aboriginal's `mnt-restic.service` FUSE-mounts the repository and binds the latest `nas` snapshot at `/mnt/nas`, the lower layer of `/mnt/nextcloud` and `/mnt/media`; it needs `HOME=/root` in the env file for restic's cache.
- `RESTIC_HOST` arrived in restic 0.17.0, `forget` honours it from 0.18.1, and `--host=` overrides it from 0.19.0. The scripts set it without exporting it; exported, it would have narrowed aboriginal's global `forget.sh` to aboriginal alone.
- Move secrets between a host and SOPS without printing them: a remote script prints JSON, piped into a local script that calls `sops set`; verify afterwards by comparing hashes.
- doppelgangerhq.com's backups moved to OCI's backup policy, so restic, its script, cron line and cache came off it. Its 8 snapshots and dodo's 2 from before the rename (host `pelican`, never pruned, since dodo's forget matches `--host dodo`) were forgotten by ID and pruned from aboriginal under `forget.sh`'s flock, removing 17.5 GiB of 5.78 TiB.

## restic: backups and the repository's only forget as systemd jobs; crontab scripts retired (2026-10-25)

- The `restic` role's `restic_jobs` makes each job a `restic-<job>.service` from its own template, started by `restic-<job>.timer` (`Persistent=true`). The jobs are named after the scripts they replace: `simple`, `snapshot`, `cephfs`, `rbd`, `rgw` and `forget`. The role removed the old crontab lines and the `/root` scripts.
- `snapshot`, `cephfs` and `rbd` run scripts in `/usr/local/bin` under a flock. Each removes its snapshot when it exits, again from `ExecStopPost=`, and at the start of the next run, so no snapshot outlives a killed run. The 2026-09-30 CephFS run was still going after more than 15 hours when it was killed, before its trap ran; that left `.snap/backup-20260930_043001` behind until it was removed by hand.
- restic counts stale locks as conflicts when acquiring a lock (`checkForOtherLocks` never calls `Stale()`), so every job runs `restic unlock` first.
- systemd gives root's services no `HOME`, so restic would find no cache; `/etc/restic-env` now sets `RESTIC_CACHE_DIR=/root/.cache/restic`, replacing aboriginal's `HOME=/root`.
- `--tag=`, an empty tag, selects only untagged snapshots in both 0.16.4 and 0.18.1. A `forget --no-lock --dry-run` checks a policy without locking the repository.
- Retention lives only in aboriginal's `restic-forget`: untagged host backups keep weekly 2, as the guests' vzdump job to CephFS does; `cephfs`, `urbackup` and `rgw` keep the last one; `nas` matches no policy and is never forgotten. With every job's first run in place, it pruned 78.6 GiB.
- Snapshotting the btrfs top-level subvolume works, which dodo's root needs. Each run's snapshot is a new subvolume with its own device number, so restic counts nearly every directory as changed: about 1.07 million on aboriginal, with files unmodified. That rewrites tree metadata every run, as the old `backup.sh` did.
- With `--stdin-from-command`, restic 0.18.0 took prodingus's latest `/ /boot/efi` snapshot as the parent of `/urbackup.img`, which is harmless for a stdin backup.
- First runs: prodingus `simple` 0:32; dodo `snapshot` 0:40; aboriginal `snapshot` 2:48; `rbd` 30:48 for 3 TiB; `cephfs` 39:24 for 1.888 TiB, adding 108 GiB; `forget` with its prune 3 minutes.
- `rgw` cannot work yet. rclone's `rgw:` remote authenticates as RGW user `regulad`, which owns `synapse-media` but not its 220,441 objects: `synapse` uploaded them, with ACLs granting only itself. Listing works and every read returns 403. The first run was stopped after 55 minutes without saving a snapshot, and the job stays scheduled.

## backblaze: the B2 account adopted in tofu/backblaze; restic keys per host from its output (2026-10-25)

- No Ansible collection manages B2 keys: existing roles shell out to the `b2` CLI, and B2's S3 API cannot create keys. Backblaze's own `Backblaze/b2` provider has `b2_bucket` and `b2_application_key`, both importable by ID. Its docs describe only the v4 native API now.
- B2's web UI cannot give an application key `listKeys`, `writeKeys` or `deleteKeys`; the account's master key has them, and the provider authenticates with it, from `tofu/backblaze/provider.sops.env`. The master key cannot sign S3-compatible API requests.
- OpenTofu refuses a sensitive import ID, so the adoption's ID variable came from SOPS without being marked sensitive. The IDs left SOPS with the import blocks after the adoption apply.
- All three buckets already kept only the last version (`daysFromHidingToDeleting: 1`), so restic's prunes, which only hide packs through the S3 API, free their space a day later. `regulad-urbackup` held no file versions and was deleted.
- B2 returns a key's secret only at creation. The provider keeps it in state as the sensitive `application_key`, and outputs read state, not B2, so a key OpenTofu created can be read back as often as needed; an imported key has no secret in state.
- restic's S3 operations need `listBuckets` (HeadBucket), `readBuckets` (GetBucketLocation), `listFiles` (ListObjectsV2), `readFiles` (GetObject, HeadObject), `writeFiles` (PutObject, multipart uploads, and deleting by name) and `deleteFiles` (DeleteObject), per Backblaze's S3 key documentation.
- `cloud.terraform.tf_output` runs `<binary> output -json <name>` in `project_path`, where the root's `secrets.auto.tfvars.json` supplies the state passphrase, so a sourced `prepare.sh` is all it needs. Its `binary_path` is a path option: a bare `tofu` resolves relative to the working directory and the lookup fails, so the role passes tofu's absolute path. ansible-core reports a failed lookup under `no_log` only as censored, and as `CapturedExceptionMarker` through `debug`.
- The hosts' previous keys had been deleted in B2 before the new ones were delivered. aboriginal's `mnt-restic.service` keeps its old environment, and so the deleted key, until it restarts.
- OpenTofu 1.13.2 is installed, while `tofu/oracle` and `tofu/gonkputer` still pin `= 1.13.1`; `tofu/backblaze` pins 1.13.2.

## restic: the shared repository password rotates from maintenance.yml; rotated once (2026-10-25)

- Every restic key file holds the same master keys, so every password opens all of the repository, and a password change re-encrypts nothing. A leaked master key survives any password change; only `restic copy` into a new repository changes it. One shared password is therefore kept; per-host B2 keys limit and revoke access.
- restic 0.16.4 already has `key add --new-password-file`, `key list --json` (whose `current` field marks the key that opened the repository) and `key remove`, which refuses the current key.
- `community.general.random_string` draws from `secrets.SystemRandom` unless given a seed.
- In check mode `ansible.builtin.tempfile` creates nothing and returns no `path`, so the rotation only reports, in check mode, the host it would use. Prune's key listing runs in check mode too (`check_mode: false`), so a check run shows the keys it would remove.
- A `run_once` task after per-host checks needs `any_errors_fatal`: a host failing its check drops out, and `run_once` moves on to the next host.
- A prune checks only its own stage's hosts; before the real prune from ansible-generated, a check-mode prune from ansible-hardware confirmed prodingus had the new password.
- The first rotation replaced the repository's only key, `root@gendo.home.arpa` from 2026-04-12, with `root@aboriginal`.

## ansible: the plays both stages run, shared from ansible-common/playbooks (2026-10-25)

- `ansible-common/playbooks/site.yml` and `maintenance.yml` hold the plays both stages run. Each stage's playbook of the same name imports them with `import_playbook`, whose path is relative to the importing playbook, before its own plays. Run from inside a stage, the imported plays take that stage's `ansible.cfg`: its inventory, `roles_path` and collections. `--tags` selects plays across the import.
- The shared baseline targets `debian:ubuntu:rhel:macos`, which `--list-hosts` showed is exactly `hardware` in one stage and `generated:!arawi` in the other. `ca_trust` targets `debian:ubuntu:rhel:freebsd`, the same hosts in the hardware stage, which has no FreeBSD host.
- Linted from the repository root, which has no `ansible.cfg`, the shared playbooks found no roles. A symbolic link `playbooks/roles -> ../roles` puts them beside the playbooks, where Ansible looks first.
- The zram play stays in ansible-generated's `maintenance.yml`, as the hardware hosts take a zram change at their next boot; the pterodactyl and wings plays stay there with their stage-only roles.

## aboriginal: the /mnt mounts managed as ordered mount units (2026-10-25)

- `mnt-media_nextcloud.mount` failed at boot because `mnt-media.service` was `Type=simple`: systemd counts it started when fuse-overlayfs launches, before the overlay is mounted. So `After=mnt-media.service` let bindfs open the bare `/mnt/media` directory, and the overlay mounted over it, out of its sight: the journal shows the bindfs mounted before fuse-overlayfs had logged its startup. A restart worked only because the overlay existed by then. Its implicit `After=mnt-media.mount` named a unit that only exists once the overlay is mounted.
- fuse-overlayfs works as a mount helper. `mount.fuse3` runs it as `fuse-overlayfs <source> <mountpoint> -o …`, it treats the last positional argument as the mountpoint, and it mounts before daemonizing, so a `Type=fuse.fuse-overlayfs` mount unit is up only once the overlay exists. The overlays are now such units, without `--debug`, which logged every FUSE operation. The bindfs is `BindsTo=` the media overlay.
- The chain's units set `DefaultDependencies=no`, because `mnt-restic.service` orders itself after `local-fs.target`, and a mount's default `Before=local-fs.target` would make a cycle; they add `Conflicts=` and `Before=umount.target` themselves.
- Docker's and Samba's drop-ins `Require` the mounts, so restarting a mount, or `mnt-restic.service`, from which the chain restarts, restarts Docker and every container. That is wanted: a running container keeps the mount it started with. So mount units are not restarted on change.
- `warmup-overlay@.service`, which copied archive-only files into CephFS when opened, had never run: it required the overlays' mount units, which did not exist at boot. It was removed, with `mnt-nas.automount`, whose `BindsTo=` would have stopped it for good whenever the mount went down, and the editor leftovers of interrupted `systemctl edit` sessions.
- `mnt-restic.service` had kept the deleted B2 key from its start on 2026-10-22, and reads of archive-only files hung; restarted, it read in under a second. It is now in `restic_env_units`.
- rclone 1.60.1's `rgw:` remote authenticates as RGW user `regulad`; its keys are in aboriginal's SOPS as `rclone_rgw_*`, rendered into `/root/.config/rclone/rclone.conf`.

## ceph_rgw: the RADOS Gateway on prodingus adopted, describing it as found (2026-10-26)

- The gateway is one instance, `ceph-radosgw@rgw.prodingus`, from `[client.rgw.prodingus]` in `/etc/pve/ceph.conf` (`beast endpoint=0.0.0.0:7480`, IPv4 only) and `rgw_dns_name` in Ceph's configuration database. There's no realm, only the default zonegroup and zone. ingress's Caddy proxies `s3.regulad.xyz` to it over `tcp4/`.
- Both buckets are owned by `regulad`, and each grants its application's user access by bucket policy. Objects belong to their writer, `synapse` in `synapse-media`, so the owner can list them but not read them: the bucket ACL grants only `regulad`, and the policy only `synapse`.
- `radosgw-admin` can read a bucket's ACL (`policy --bucket`) and, through `metadata get bucket.instance:<name>:<id>`, its policy (attribute `user.rgw.iam-policy`, base64), but cannot set either. The role's `rgw_bucket` module sets them through the S3 API with Signature Version 4 requests it signs itself with the Python standard library, against `http://127.0.0.1:7480` path-style, with region `default`, the zonegroup's API name; prodingus has no `boto3`.
- `radosgw-admin` takes keys only as arguments; the `rgw_user` module never returns its output, which holds every key, and names keys in its changes without their IDs.
- Proxmox writes `ceph.conf` with tab-indented options, which `ini_file` would rewrite; the role compares each setting through `ceph-conf --lookup` first and writes only those that differ.
- RGW returns a user's keys sorted by access key ID; `rgw_keys` keeps that order. `regulad`'s third key is aboriginal's rclone; its first two, `mastodon`'s and `appflowy`'s have no consumer in the repository.
- Left over from the nodes `jondingus` and `neodingus`, which left the cluster: their `client.rgw.*` cephx entities and keyrings, and a `[client.rgw.jondingus]` section in `ceph.conf`.

## ceph_rgw: svc-aboriginal reads the buckets for the rgw backup; IPv6 listener; leftovers removed (2026-10-26)

- RGW refuses a request carrying a `Content-Type` it was not asked to sign: debug level 20 logs "Signature rejected: 'content-type' supplied but not in CanonicalHeaders", and the client gets a bare `AccessDenied`. Both curl, without `-H Content-Type`, and Python's urllib add one to a request with a body. `rgw_bucket` now signs its own. Raise the level for the running process only with `ceph daemon <asok> config set debug_rgw 20`; its default is `1/5`.
- S3's ListBuckets returns only the buckets the requester owns, so a user granted access by bucket policy sees an empty account root. aboriginal's rclone names the buckets with a `combine` remote (rclone 1.60 has it), and the rgw backup's `/mnt/rgw` keeps its two bucket directories.
- A bucket policy statement granting `svc-aboriginal` `s3:GetObject` and `s3:ListBucket` lets it read objects whose ACL grants only their writer: RGW allows from the policy before the object ACL.
- beast's `endpoint=[::]:7480` listens for IPv6 alone, as Ceph documents, so IPv4 keeps its own endpoint. `prodingus.regulad.internal` has no AAAA record, so ingress's Caddy still proxies over `tcp4/`; prodingus's EUI-64 ULA on VLAN 1 answers on 7480.
- `ini_file` writes options without Proxmox's tab indentation; Proxmox re-indents `ceph.conf` whenever it writes it. The failed first apply left the frontends line changed without the handler's restart, which was done by hand.
- jondingus's and neodingus's `client.rgw.*` cephx entities and keyrings and the `[client.rgw.jondingus]` section were removed by hand, once `ceph -s` showed prodingus's gateway as the only one.
- `sops set` refuses an index path naming a key with a hyphen (`["rgw_keys"]["svc-aboriginal"]`: "Invalid --set value format"); setting the parent whole works.

## arawi: AAAA and PTR records for every named host, from the NDP table (2026-10-26)

- The LAN is SLAAC-only, so nothing registers hosts' IPv6 addresses. `/usr/local/bin/ndp-aaaa.php`, run by cron every minute, joins the NDP table to the IPv4 registry by MAC (the ARP table, Kea's reservations, and its memfile leases at `/var/db/kea/dhcp4.leases`, whose last line per address counts), then to the names whose A records point there, and publishes every non-link-local address of each MAC, ULA and GUA, stable and temporary, as AAAA records under each name, with a PTR back to the first. Each TTL is the NDP entry's remaining `expires_sec`; arawi's own entries are `permanent`, with no expiry, and are not published.
- `ndp -an` and `arp -an` give JSON with `--libxo json`. The LAN's ULAs (`fd83:…:1::/64`) are learnt on `vtnet2` and the upstream router's GUAs on `vtnet0`, VLAN 1's interface.
- An unbound view that holds a name answers every type of it from its own records and never falls back to the global zone, so a view-only AAAA blanks the name's A. The walker therefore writes into the `local` view (LAN clients; the guest view refuses `regulad.internal`) and copies each name's global records beside its AAAA. `view_local_data` creates a transparent zone per name that `view_local_data_remove` leaves behind; `view_local_zone_remove` removes zone and data, one name per call, and while a name has no view zone its queries fall back to the global zone.
- An all-nodes echo from arawi's link-local address teaches it only the neighbours' link-local addresses. Sent from each of arawi's ULAs and GUAs, it makes hosts answer from their own matching address, resolving arawi's from it first, which puts that address in the table. Hosts that never resolve arawi's ULA, such as prodingus, are known by their GUA alone.
- syslogd drops a message longer than its line, so the walker logs a line per added or removed record.

## arawi: the NDP walker's records moved to the global zone, as pfSense's A records (2026-10-26)

- Records in an unbound view answer only the name asked for: a CNAME target, such as the split-horizon RPZ's chain from `nextcloud.regulad.xyz` to `ingress.regulad.internal`, is looked up in the global zone, so view-only AAAA records left the chain with no AAAA. The custom options' own comment already said so for view local-data.
- pfSense's `kea2unbound` never calls `local_data`: on each change it writes the include file `/var/unbound/leases/leases4.conf` (hashed, rewritten only when its records change), then `unbound-control fast_reload`, falling back to `reload`; lease records' TTL is the valid lifetime / 3. `ndp-aaaa.php` does the same with `/var/unbound/ndp-aaaa.conf`, which the custom options include through the glob `ndp-aaaa*.conf`, so Unbound starts without it. It checks the whole configuration with `unbound-checkconf` before keeping a new file, and never falls back to a full reload.
- A record's TTL is the shorter of its NDP entry's remaining lifetime and what is left of the MAC's Kea lease; a host without a lease, or with an infinite one, keeps the NDP lifetime.
- pfSense's syslogd writes `*.notice` and above to `system.log` (`/var/etc/syslog.d/pfSense.conf`), so the walker logs its changes at notice.
- PTRs for GUAs are global, as A records' PTRs are; the guest view refuses only the 10.23 and ULA reverse zones, so a guest can read them.

## no-gua-ipv6 catches GUA reverse names (2026-10-26)

- The hook matched only colon-separated literals, so the OCI subnet's `ip6.arpa` reverse zone, written out in `dns_resolver.xml.j2`, passed it; the commits before cc2d016 still hold it. The template now derives the zone from the encrypted `/64`.
- A reverse name's last label before `ip6.arpa` is the address's first nibble, so the hook matches eight or more nibble labels ending in `2` or `3`: a `/32` or longer under 2000::/3. ULA (`…d.f.ip6.arpa`) and tailnet reverse zones do not match.

## restic: the rgw job succeeds on exit status 3 (2026-10-26)

- Ubuntu's rclone 1.60.1 (`1.60.1+dfsg-4ubuntu3.2`) answers every `listxattr` and `getxattr` on its FUSE mount with EIO, where 1.66 and later report none. restic ignores only ENOTSUP and ENOATTR, so it logs "incomplete metadata … xattr.list … input/output error" for every file and exits 3 with the snapshot saved. The first rgw run read 220,578 files, 22.4 GiB, in 1 h 38 min, with no other error; `SuccessExitStatus=3` makes that a success. restic 0.18.1's `backup` has no option to skip xattrs.

## tailscalerouter (OCI): the XMRig miner and its ngrok tunnel removed (2026-10-26)

- Installed by hand with the instance on 2025-12-08: `xmrig.service` (disabled) under the user `miner`, which needed `websocat-proxy.service` (enabled and running) tunnelling 127.0.0.1:3333 to an ngrok host. Both units, `/usr/local/bin/websocat`, `~regulad/install_miner.sh`, and the user with its home were removed by hand.

## tailscale: the role becomes root everywhere but macOS (2026-10-26)

- The shared baseline play runs unprivileged, because Homebrew on macOS (overture) refuses root, so the tailscale role also ran as the login user on Linux: on tailscalerouter (OCI) its package check ran dnf as regulad, leaving a non-root cache in `/var/tmp/dnf-regulad-*`. Its block now becomes root except on macOS, as `base`'s tasks each do.

## base: per-OS packages and the OCI instances' admin user (2026-10-26)

- The Oracle Linux 9.6 images (livekit, mail, tailscalerouter) leave out `rsyslog-logrotate`, which ships `/etc/logrotate.d/rsyslog` on EL9, so `/var/log/messages` and `secure` grew unrotated (693 MB and 317 MB on livekit); bailout's 9.8 image has it. `base_packages` in `group_vars/rhel.yml` installs it.
- regulad, the admin login of the OCI instances (group `oci`, from the oracle inventory source), has `https://github.com/regulad.keys` as its whole `authorized_keys`. The hand-made copies on livekit, mail and tailscalerouter matched it byte for byte, at modes 0444, 0600 and 0400, two of them with the SELinux type `user_home_t`; `setype: _default` restores `ssh_home_t`. bailout gained the user, and Ansible now logs in there as regulad rather than opc. doppelgangerhq.com, a legacy host, keeps only its image's users.

## kdump: Enterprise Linux's kdump on or off (2026-10-26)

- The Oracle Linux images ship kdump on, with kexec-tools owning `crashkernel=`: its kernel-install plugin `92-crashkernel.install` and its package's posttrans run `kdumpctl _reset-crashkernel-*`, which writes kexec-tools' default back into the boot entries unless `/etc/kdump.conf` says `auto_reset_crashkernel no`. New kernels take their arguments from `/etc/kernel/cmdline`, and `grub2-mkconfig` from `GRUB_CMDLINE_LINUX`; `grubby --update-kernel=ALL --remove-args=crashkernel` clears the existing entries.
- The E2 images' `crashkernel=1G-64G:448M,64G-:512M` reserved 448 MiB of tailscalerouter's 1 GiB (MemTotal 499 MiB) and nothing on bailout (MemTotal 946 MiB), whose kdump unit therefore failed. Both now have kdump off; the memory returns at their next boot. livekit and mail (A1, 6 GB) keep kdump, with 256 MiB reserved.
- On OCI the `kdump` group comes from state: Enterprise Linux instances with more than 1 GiB.
