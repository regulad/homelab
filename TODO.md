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

- [x] FreeIPA: a fresh deployment on `wako`, an AlmaLinux 10 container, for `regulad.internal` (realm `REGULAD.INTERNAL`), replacing `freeipa.home.arpa` (VM 113, realm `HOME.ARPA`), whose domain and realm cannot be renamed
  - [x] `wako` itself (203), with IPA 4.13.4 as on the old server; Ubuntu ships no FreeIPA server
  - [x] `ipa-migrate` from the old server, `--dryrun` first: users, groups, hosts, services, sudo and HBAC rules carry over, and `userPassword` must too, so LDAP binds keep their passwords; Kerberos keys are generated again in migration mode, and certificates re-issued from the new CA
  - [x] `regulad`'s uid and gid, 1000 on the old server, moved into the deployment's ID range, clear of local Linux IDs
  - [x] The new CA in `ca_trust` as `freeipa-regulad.internal`, beside the old server's, renamed `freeipa-home.arpa`, while the stand-in presents the old server's certificate. FreeIPA's own tooling deletes anchors named `ipa-ca`, as `ipa-server-install` did on wako, so `ca_trust_retired` removes the old name
  - [x] A shim at the old VM's MAC, so 10.23.2.32 and `freeipa.regulad-verizon-livingston.internal` keep answering while consumers move: LDAP through OpenLDAP's `ldap` backend and `rwm` overlay, rewriting `dc=home,dc=arpa` to `dc=regulad,dc=internal` for wako, with the old server's own certificate. No Kerberos; its RADIUS proxy is retired, as softether, the last RADIUS client, uses wako directly
  - [x] The hardware stage's `mail_relay` manages its null- accounts on wako, through prodingus, as the generated stage does through wako itself
  - [ ] Consumers repointed (URI, base DN, bind DN, CA): mail's SMTP and IMAP logins, and with them every host's `mail_relay` account; the `mail_relay` role's `ipa_user` API calls; authentik; Proxmox's realm; Nextcloud, Jellyfin and NPMplus's ldap-auth on aboriginal; Synapse; Open WebUI
  - [x] A new FreeRADIUS on wako, against its directory, replacing the one set up by hand on the FreeIPA VM with three clients; softether is its one client
  - [x] Backups: the weekly vzdump, which covers wako; no `ipa-backup`
  - [x] Anonymous LDAP read closed: anonymous clients get only the root DSE
  - [x] Migration mode off. Users who had not logged in since the migration keep their LDAP passwords, and get Kerberos keys at their next password change
  - [x] VM 113 retired; its last vzdump backups stay on cephfs

## Hardware hosts (`ansible-hardware/`)

- [ ] `prodingus`: the Proxmox VE node of `gonkputer`
- [ ] `turk`: Ubuntu 24.04 with VMware Workstation
- [ ] `overture`: macOS
  - [ ] lime's side, by lime's README: the hidden FileVault unlock account, and the sshd drop-in `50-lime-unlock.conf` that leaves it nowhere once the Mac is booted

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
    - [x] jenkins: to the `jenkins` container (207), a Quadlet behind Caddy on ingress, with `jenkins_home` on its own RBD mount point; its compose project, image, build context, data and host user removed from aboriginal
      - [x] Its LDAP realm on wako, bound as `svc-jenkins`, admitting only the `jenkinsusers` group
      - [ ] Its GitHub organization folder: a working credential, or the folder deleted
    - [x] docker-nexus: to the `nexus` container (209), a read-only Quadlet behind Caddy on ingress, with `/nexus-data` on its own RBD mount point and `cr` as a virtual host; its compose project, images and data removed from aboriginal
      - [x] Its LDAP realm on wako, bound as `svc-nexus`, with the `nx-admin` group as Nexus's `nx-admin` role
      - [x] From OrientDB to H2, with 3.70.5's database migrator: `maintenance.yml`'s `nexus-h2`
      - [x] A pinned release, 3.97.3, upgraded by `maintenance.yml`'s `nexus-upgrade`, which keeps a copy to roll back to
      - [x] The OrientDB files left in `db/`, which Nexus warned about at each start, and the migration's `h2-migration` directory, removed
    - [x] I2P: the `i2p` container (208), i2pd from upstream's image on its release channel, SAM for the LAN only
      - [x] qBittorrent's I2P through `i2p.regulad.internal`, in place of qb-clearnet's `172.0.0.1`
      - [x] The old I2P's Docker volumes and the tunnel's dead `i2p` route, with its DNS record, removed from aboriginal
    - [x] qb-clearnet: to the `qb` container (210), privileged for its downloads in regulad's CephFS home, the lab's one qBittorrent, a Quadlet with its settings seeded from qb-clearnet's and its web UI on the tailnet through Tailscale Serve; the compose project, its volumes and image removed from aboriginal
  - [x] Remove llama-rpc, vsftpd, the tor snap, and the NFS server with its exports
  - [x] Retire qb-tor with its tor sidecar: the compose project, its volumes and image, the tunnel's `qb-tor` route with its DNS record, and its downloads in `/mnt/cephfs/homes/regulad/downloads-tor`
  - [x] Remove the stopped compose projects (mollysocket, monero, timebomb, visualstudiocode) with their volumes, and the leftovers: wings, bees, MariaDB's data and user, libvirt's configuration; ollama was already gone
  - [x] Remove Jellyfin's rffmpeg remains (its mounts, `/etc/rffmpeg`, `/var/lib/rffmpeg`) and root's old tooling: `/root/b2`, `.b2_account_info`, `nullclient.sh`, `error.txt`, `vda-gpt-backup.bin`, `.ipa`, `nextcloud-ca`, `jellyfin-rffmpeg`
  - [x] Its vTPM (`tpmstate0` on `local-lvm`), which lime's credential is sealed to: declared in `vm-aboriginal.tf`, its changes ignored while the provider leaves a TPM at its defaults out of state
  - [ ] Describe its own services
    - [ ] Off Docker onto Podman, with secrets in SOPS and images pinned
      - [ ] mosquitto and ring-mqtt: Quadlets on the host's network, with Podman's auto-update in place of ring-mqtt's own watchtower
      - [ ] homeassistant, jellyfin and nextcloud: podman-compose stacks of the compose projects under `/root/compose`
        - [ ] nextcloud: the stock image with the host's CA bundle, in place of the local `nextcloud-ca` build, whose context is removed
      - [ ] bandcampsync: to regulad's own rootless Podman, by hand and not managed, its Bandcamp session cookies being volatile
      - [ ] nginxproxymanagerlocal: not yet decided (README)
      - [ ] Docker removed once nothing runs on it, with root's prune cron jobs and `docker.service.d`'s override
    - [x] Remove the orphaned volumes: api-docker's, aternos's, cordpepperer's, `dcef_cache`, immich's, invidious's, `mariadb_mariadb`, minio's, nextcloud's `data` and `db-logs`, peppercord's, pepperfriend's, `portainer_data`, and qb-clearnet's old `tor-*`
    - [x] cloudflared and winbind uninstalled, with cloudflared's units, apt source and key, and winbind's hand-edited unit
      - [x] The `aboriginal` tunnel and its routes' DNS records (`hass-livingston`, `archive`, `qb-clearnet`) deleted from Cloudflare
    - [ ] Native services: llama-server, Samba, NUT, lime
      - [x] lime: the `lime` role, building `regulad/lime` at a pinned commit on the host, with overture's password sealed to the vTPM from SOPS; enabled at boot
      - [x] NUT: upsd alone, for Home Assistant; upsmon disabled, as nothing is to act on a power cut for now, and the APC's section in `ups.conf` commented out while it is under maintenance
    - [x] logrotate: the obsolete `/etc/logrotate.d/cloud-init` removed, which repeated `cloud-init-base`'s `/var/log/cloud-init*.log` and failed every run
    - [ ] firewalld, with `eth0` in the `trusted` zone today
  - [x] Remove the old `HOME.ARPA` client's remains: `freeipa-client`, the SSSD suite and the packages only they needed, their PAM profile and `nsswitch.conf` entries, `krb5.conf` with its debconf realm, `/etc/krb5.keytab`, `ldap.conf`'s additions, `/etc/ipa`, `/var/lib/sss` and `/var/log/sssd`; the `HOME.ARPA` CA stays trusted, from `ca_trust`
  - [x] Disk: the root btrfs is 62 % full with Nexus moved, from 93 %
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
