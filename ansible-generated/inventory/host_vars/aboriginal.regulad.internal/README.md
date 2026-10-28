# aboriginal

VM 100 on gonkputer: a hardware install of Ubuntu imaged into a VM, and also a
remote workstation, so nothing under `/home/regulad` is managed. Its services
are Docker compose projects under `/root/compose` and a few native units. What
ties a service to this VM is the hardware passed through to it or the mounts
of the restic `nas` archive. Services with neither move to containers of their
own.

## Staying

- **jellyfin and llama-server**: the passed-through RX 6800 (`renderD129`),
  Jellyfin for VA-API transcoding and llama-server through ROCm.
- **nextcloud, bandcampsync and Samba**: the `nas` archive's overlays,
  `/mnt/media` and `/mnt/nextcloud`, with their upper layers on CephFS.
- **NUT**: the UPSes on USB; Home Assistant's `nut` integration reads upsd.
- **lime**: its credential is sealed to the VM's vTPM (`tpmstate0` on
  `local-lvm`), which `vm-aboriginal.tf` does not declare and OpenTofu's state
  does not track. The password itself is in `secrets.sops.yml`
  (`lime_passwords`), so the credential can be sealed again.
- **homeassistant, matter-server, mosquitto and ringmqtt.** They would suit a
  Home Assistant OS VM with the USB devices passed through, but Home Assistant
  needs the host's Bluetooth stack: its Bluetooth integrations reach BlueZ
  over `/run/dbus`. ZHA holds the Zigbee stick on `/dev/ttyUSB0`.

## Moved

- **rsshub**: to the `rsshub` container, a Quadlet behind Caddy on ingress,
  in place of aboriginal's Cloudflare tunnel.
  - Stateless. The four routes it serves all declare `requirePuppeteer: false`,
    and browserless served no session in a week, so the browserless container
    was dropped.
  - RSSHub's in-memory cache, its default, replaced Redis, which held 33 keys.
- **jenkins**: to the `jenkins` container, a Quadlet behind Caddy on ingress,
  in place of NPMplus and the tunnel, with `jenkins_home` on its own mount
  point. The stock image reads the container's Java keystore, which
  `ca_trust_java` keeps, in place of the `jenkins-ca` build.
  - It builds nothing: no executors, and no job but a GitHub organization
    folder whose credential is dead. Its Docker cloud `tinker` and its one
    agent, a phone, were unreachable and are removed, with aboriginal's
    `jenkins` user, which only carried the tunnel to `tinker`.

## Moving

- **docker-nexus**: to a container of its own, with `/nexus-data` (82 G, most
  of aboriginal's 93 % full root) on its own RBD mount point.
- **tor and I2P**, later: each to a container of its own. Both qBittorrents
  point I2P at `172.0.0.1`, where nothing serves it.

## Removed

- **llama-rpc**: disabled, and its cache directory empty. Its master,
  the dormant `llamarpcmaster` container, is destroyed too.
- **NFS**: the server exported only Jellyfin's config and cache, to two
  rffmpeg transcode hosts, and the stock Jellyfin image it runs has no
  rffmpeg. Nothing mounted NFS, so `nfs-common` and `rpcbind` went with it.
- **vsftpd**: cleartext FTP for local users, on no other host. Its logs, kept
  since it was installed on 2026-02-24, showed logins only on that day, and
  after that only refused anonymous logins, the last on 2026-07-21.
- **The tor snap**: it served nothing; qb-tor runs its own tor.

## Retiring

- **cloudflared**: once every route its tunnel carries has moved.

## Not yet decided

- **nginxproxymanagerlocal**: only one of its proxy hosts is live, `archive`
  (regulad's rootless `dcef`); its `ci` host died with the tunnel's `ci`
  route. Its ldap-auth guards `archive` alone and still binds to the freeipa
  stand-in.
- **qb-clearnet**: idle, with no torrents.
- **qb-tor**: seeding through its own tor, with no listening port. Its paths
  are all on CephFS.
