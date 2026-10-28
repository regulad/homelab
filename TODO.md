# TODO: hosts to declarativize

Every host still configured by hand. Check one off once its configuration is
captured as code and a run against it reports no changes (`changed=0` for
Ansible, including the network switches). See
[`.claude/PLAN.md`](.claude/PLAN.md) for each phase.
What to add once everything here is declarative is in [`NEW.md`](NEW.md).
Discovery for each host is in the operator's local `docs/snapshot/<host>-index.md`.

## Migration to `regulad.net` and `regulad.internal`

`regulad.net` supersedes `regulad.xyz` for external-facing services, service by
service; inner services live under `regulad.internal`. FreeIPA moves first.

- [ ] FreeIPA: a fresh deployment on `wako`, an AlmaLinux 10 container, for `regulad.internal` (realm `REGULAD.INTERNAL`), replacing `freeipa.home.arpa` (VM 113, realm `HOME.ARPA`), whose domain and realm cannot be renamed
  - [x] `wako` itself (203), with IPA 4.13.4 as on the old server; Ubuntu ships no FreeIPA server
  - [x] `ipa-migrate` from the old server, `--dryrun` first: users, groups, hosts, services, sudo and HBAC rules carry over, and `userPassword` must too, so LDAP binds keep their passwords; Kerberos keys are generated again in migration mode, and certificates re-issued from the new CA
  - [x] `regulad`'s uid and gid, 1000 on the old server, moved into the deployment's ID range, clear of local Linux IDs
  - [x] The new CA in `ca_trust` as `freeipa-regulad.internal`, beside the old server's, renamed `freeipa-home.arpa`, while the stand-in presents the old server's certificate. FreeIPA's own tooling deletes anchors named `ipa-ca`, as `ipa-server-install` did on wako, so `ca_trust_retired` removes the old name
  - [x] A shim at the old VM's MAC, so 10.23.2.32 and `freeipa.regulad-verizon-livingston.internal` keep answering while consumers move: LDAP through OpenLDAP's `ldap` backend and `rwm` overlay, rewriting `dc=home,dc=arpa` to `dc=regulad,dc=internal` for wako, with the old server's own certificate. No Kerberos; its RADIUS proxy is retired, as softether, the last RADIUS client, uses wako directly
  - [x] The hardware stage's `mail_relay` manages its null- accounts on wako, through prodingus, as the generated stage does through wako itself
  - [ ] Consumers repointed (URI, base DN, bind DN, CA): mail's SMTP and IMAP logins, and with them every host's `mail_relay` account; the `mail_relay` role's `ipa_user` API calls; authentik; Proxmox's realm; Nextcloud, Jellyfin, Jenkins and NPMplus's ldap-auth on aboriginal; Synapse; Open WebUI
  - [x] A new FreeRADIUS on wako, against its directory, replacing the one set up by hand on the FreeIPA VM with three clients; softether is its one client
  - [x] Backups: the weekly vzdump, which covers wako; no `ipa-backup`
  - [x] Anonymous LDAP read closed: anonymous clients get only the root DSE
  - [x] Migration mode off. Users who had not logged in since the migration keep their LDAP passwords, and get Kerberos keys at their next password change
  - [x] VM 113 retired; its last vzdump backups stay on cephfs

## Hardware hosts (`ansible-hardware/`)

- [ ] `prodingus`: the Proxmox VE node of `gonkputer`
- [ ] `turk`: Ubuntu 24.04 with VMware Workstation
- [ ] `overture`: macOS

## Network switches (`ansible-hardware/`, the `switches` group)

- [x] Cisco SG300 `switch45f304`: `ansible-hardware`'s `ciscosmb` role
- [x] Cisco SG300 `switch070e26`: `ansible-hardware`'s `ciscosmb` role
- [x] Arista 7010T `JPE18280417`: `ansible-hardware`'s `eos` role, its interfaces annotated from LLDP and DHCP leases

## Access points

- [ ] AirPort Extreme
- [ ] CR1000B

## OCI instances (`ansible-generated/`, from `tofu/oracle`)

- [x] `bailout`: WireGuard to arawi, rendered from the tunnels both hosts read
- [ ] `doppelgangerhq.com` (legacy `web`): a special case, its network configuration (hostname and `/etc/hosts` included) furnished by Oracle at install time and left as Oracle wrote it
  - [ ] The miner and its tunnel removed, as on tailscalerouter
  - [ ] Doppelganger's compose project, with `.env.local` from SOPS, and `web-latest` pinned; the per-device projects under `/opt/doppelganger` are the app's
  - [ ] Docker CE from Docker's repository, where the `docker` role installs `docker.io`
  - [ ] nginx's site, and its TLS (the certbot snap today)
  - [ ] `binder_linux`, loaded by `/etc/rc.local` today
  - [ ] GRUB pinned to 6.8.0-87 (`GRUB_DEFAULT=saved`), so reboots never reach newer kernels
  - [ ] `logrotate`, which Ubuntu Minimal leaves out
  - [ ] IPv6: an AAAA record is published, but the legacy VCN has no IPv6 route
- [x] `livekit`: LiveKit, lk-jwt-service, nginx and certbot
- [ ] `mail`: docker-mailserver 15, authenticating against FreeIPA
  - [ ] The miner and its tunnel removed, as on tailscalerouter
  - [ ] docker-mailserver as a Quadlet, where `docker compose` drives Podman today, with its env file and config overrides declared and their secrets in SOPS
  - [ ] Certificate renewal: neither scheduled path has the Cloudflare plugin, and nothing reloads Postfix and Dovecot after one
  - [ ] Backups: restic for the mail store, the DKIM keys and the SRS secret, which only boot-volume backups cover today
  - [ ] `/var/log/messages` at 7.9 GB, from setroubleshoot: SELinux is permissive and the bind mounts under `/root` are unlabelled, and logrotate does not compress
  - [ ] Bounces after acceptance: Postfix accepts the LDAP `mail` addresses that Dovecot's `uid` lookup rejects
  - [ ] DKIM signing for `nefumllc.com`, and the malformed MTA-STS record
  - [ ] webhookd: unpinned, its TLS key world-readable
- [x] `tailscalerouter`: subnet router, peer relay and the VCN's dnsmasq resolver
- [ ] bailout and tailscalerouter off the 1 GiB E2.1.Micro shape: kdump's 448 MiB reservation succeeds or fails from boot to boot

## gonkputer VMs (`ansible-generated/`, from `tofu/gonkputer`)

- [x] `arawi` (108)
- [ ] `vkasm` (129): a special case, a self-contained VM image from Kasm; only the shared baseline is declared

## gonkputer containers (`ansible-generated/`, from `tofu/gonkputer`)

- [x] `aameter` (130)
- [x] `authentik` (201): authentik 2026.8 in podman-compose, served by Caddy on ingress; moved from the authentik VM (109)
- [ ] `act` (123): low priority; currently dormant (HA state `disabled`), so not in the inventory
- [x] `cordpepperer` (118): a mirror of `peppercord`
- [x] `immich` (116)
- [x] `git` (200): Forgejo, served by Caddy on ingress, with its Cloudflare tunnel for SSH; moved from the git VM (110)
- [x] `ingress` (121)
  - [x] Inbound IPv6: Matrix's federation tester passes over both families since the CR1000B's firewall was changed on 2026-10-27
  - [ ] From OCI over IPv6: bailout's connections to ingress's GUA time out. tailscalerouter's router advertisements route OCI's /64 through the tailnet, so ingress's replies take another path than the requests
- [x] `matrix` (202): Synapse 1.163 and its bridges as native units, the database on `/mnt/synapse`, served by Caddy on ingress; moved from the matrix VM (107)
- [ ] `mastodon` (105): low priority; currently dormant (HA state `disabled`), so not in the inventory
- [x] `ncsusplitt` (125)
- [ ] `openclaw` (103): low priority
  - [x] Baseline from the shared roles: mail relay as `null-openclaw`, automatic updates, CA trust
  - [ ] Its application, not to be described declaratively for now
- [x] `openwebui` (115)
- [x] `peppercord` (126): a mirror of `cordpepperer`
- [x] `pihole` (112)
- [ ] `procontainer` (106): low priority; currently dormant (stopped, not started at boot), so not in the inventory
- [x] `pterodactyl` (120)
- [x] `tailscalerouter` (122)
- [x] `timemachine` (104)
- [x] `tsexit` (124)
- [x] `tvheadend` (127)
- [x] `uptime` (117)
- [x] `vaultwarden` (128)

## gonkputer quasi-hardware VMs (`ansible-generated/`, from `tofu/gonkputer`)

First installed on hardware and later imaged into VMs, so each carries a
hardware install rather than a cloud image. Ansible configures them, not
cloud-init.

- [ ] `aboriginal` (100): also a remote workstation, so nothing under `/home/regulad` is managed. What stays and what moves is in its [README](ansible-generated/inventory/host_vars/aboriginal.regulad.internal/README.md)
  - [x] Add its `ansible_host` to `tofu/gonkputer`
  - [x] Baseline from the shared roles: mail relay, automatic updates, CA trust
  - [ ] Move to containers of their own
    - [x] rsshub: to the `rsshub` container (206), a Quadlet without browserless or Redis, behind Caddy on ingress in place of the tunnel; the compose project, its images and its clone removed
    - [ ] jenkins, with `jenkins_home` on its own RBD mount point
    - [ ] docker-nexus, with `/nexus-data` on its own RBD mount point
    - [ ] tor, later
    - [ ] I2P, later, for the qBittorrents' I2P, which points at `172.0.0.1` today
  - [x] Remove llama-rpc, vsftpd, the tor snap, and the NFS server with its exports
  - [ ] Its vTPM (`tpmstate0` on `local-lvm`), which lime's credential is sealed to: `vm-aboriginal.tf` does not declare it, and OpenTofu's state does not track it
  - [ ] Describe its own services
    - [ ] The Docker compose projects under `/root/compose`, with secrets in SOPS and images pinned: bandcampsync, homeassistant, jellyfin, mosquitto, nextcloud, nginxproxymanagerlocal, qb-clearnet, qb-tor, ringmqtt
    - [ ] Decide on the stopped projects (mollysocket, monero, timebomb, visualstudiocode) and the orphaned volumes
    - [ ] cloudflared: retired once every route its tunnel carries has moved
    - [ ] Native services: llama-server, Samba, NUT, lime; and the leftovers (wings, ollama, bees, libvirt, MariaDB)
    - [ ] firewalld, with `eth0` in the `trusted` zone today
  - [ ] Disk: the root btrfs is 93% full, 82 G of it Nexus's, which moves
- [x] `dodo` (101)
  - [x] Add its `ansible_host` to `tofu/gonkputer`
  - [x] Baseline from the shared roles: mail relay, automatic updates, CA trust
  - [x] Describe its own services

## gonkputer VMs to move into containers

Services to move off their VMs into containers.

- [x] `authentik` (109): moved to the `authentik` container (201); the VM is destroyed
- [x] `git` (110): moved to the `git` container (200); the VM is destroyed
- [x] `matrix` (107): moved to the `matrix` container (202); the VM is destroyed
- [x] `freeipa` (113): moved to the `wako` container (203), as the `regulad.internal` deployment above; the VM is destroyed, and the `freeipa` container (204) stands in at its address
- [x] `softether` (114): moved to the `softether` container (205), unprivileged, with the VM's MAC address; SoftEther 4.44 Stable built from source on Ubuntu 24.04. Its one hub is a local bridge onto VLAN 1, which needs no tun device or kernel modules. The VM is destroyed
  - [x] A client login through VPN Azure, with DHCP and SLAAC from the LAN through the bridge
  - [ ] A bulk transfer from the LAN to a VPN client: SoftEther turns off offloads only on its own end of the veth, and on prodingus's end segmentation offloads stay on
  - [x] The NIC's firewall off, as Proxmox's MAC filter would drop the bridged clients' frames
  - [x] `vpn_server.config` moved whole, with both servers stopped; it is state the server rewrites, not a host file
  - [x] Its RADIUS on wako directly, over IPv6, with a new shared secret; the stand-in's proxy and the old secret are retired

## gonkputer VMs with cloud-init (`tofu/gonkputer` vendor files)

**Precondition:** [bpg/terraform-provider-proxmox#2901](https://github.com/bpg/terraform-provider-proxmox/issues/2901).
The provider replaces a VM whenever its `*_data_file_id` changes, although
Proxmox changes `cicustom` in place. Move no further VMs to cloud-init until
it is resolved.

Configured by a cloud-init vendor file instead of Ansible, so they need no SSH.
`freeipa` and `softether` move into containers instead (above); cloud-init is
disabled on both.

- [ ] `unifi` (102): stays a VM, as UniFi OS requires
- [ ] `urbackup` (111): stays a VM, for its kernel modules and block devices

Not listed: the template `resolute-template` (8000), which is not a host.

- [ ] A vendor file for new Ubuntu 26.04 VMs, as a new snippet rather than an
  edit of `ubuntu-vendor.yaml`, which would replace the VMs using it: drop
  `linux-image-generic` (26.04's base modules carry `i6300esb`, and Ubuntu has
  no package tracking only the extra modules), and preseed the debconf answer
  `watchdog/module` as `i6300esb` instead of editing `/etc/default/watchdog`,
  so package upgrades keep it.

## MAC addresses

Each hardware host's and switch's management interface, as `mac` - Name.

- `3c:7c:3f:22:33:b3` - prodingus (`vmbr0`, on `eth0`)
- overture
- pending - turk (unreachable on 2026-10-20)
- `08:cc:68:45:f3:04` - Cisco SG300 `switch45f304`
- `f8:7b:20:07:0e:26` - Cisco SG300 `switch070e26`
- `28:99:3a:fa:31:fa` - Arista 7010T
