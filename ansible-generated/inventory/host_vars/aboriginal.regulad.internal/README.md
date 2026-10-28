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
  upsd runs alone: nothing is to act on a power cut for now, so upsmon is
  disabled. The APC's section in `ups.conf` is commented out while it is under
  maintenance, its passthrough removed with it.
- **lime**: its credential is sealed to the VM's vTPM (`tpmstate0` on
  `local-lvm`), which `vm-aboriginal.tf` declares with its changes ignored, as
  applying it would replace the TPM with an empty one. The password itself is
  in `secrets.sops.yml` (`lime_passwords`), so the credential can be sealed
  again.
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
- **I2P**: the `i2p` container runs i2pd, whose SAM qb-clearnet is to use in
  place of `172.0.0.1`, where nothing serves it. The old I2P's volumes and its
  tunnel route are removed.
- **docker-nexus**: to the `nexus` container, a read-only Quadlet of
  `sonatype/nexus3`, since moved from OrientDB to H2, behind Caddy on ingress,
  with its data on its own mount point. `cr.regulad.xyz` is a virtual host on Nexus's one port
  in place of a connector of its own. Compacting its blob store first gave
  back 35 G of abandoned Docker uploads, and its dead LDAP realm is gone.
  aboriginal's root went from 93 % to 62 % full.

## Removed

- **llama-rpc**: disabled, and its cache directory empty. Its master,
  the dormant `llamarpcmaster` container, is destroyed too.
- **NFS**: the server exported only Jellyfin's config and cache, to two
  rffmpeg transcode hosts, and the stock Jellyfin image it runs has no
  rffmpeg. Nothing mounted NFS, so `nfs-common` and `rpcbind` went with it.
- **vsftpd**: cleartext FTP for local users, on no other host. Its logs, kept
  since it was installed on 2026-02-24, showed logins only on that day, and
  after that only refused anonymous logins, the last on 2026-07-21.
- **The tor snap**: it served nothing; qb-tor ran its own tor.
- **qb-tor**, with its tor sidecar, its route, its DNS record and its
  downloads, kept only for seeding; what was wanted had been copied out.
  Nothing else used tor, so no tor container replaces it. The Tor Project
  calls BitTorrent over Tor unsafe, as clients leak their address outside the
  proxy, and a burden on its exits.
- **The stopped compose projects**: mollysocket, monero, timebomb and
  visualstudiocode, with their volumes. monero's held no wallet.
- **The orphaned Docker volumes**, of projects long gone or moved.
- **Leftovers**: wings, bees (built from source and never run, with no hash
  table), MariaDB's data and user, and libvirt's configuration. ollama was
  already gone.

## Retiring

- **cloudflared**: once every route its tunnel carries has moved:
  `hass-livingston`, `archive` and `qb-clearnet`.

## Not yet decided

- **nginxproxymanagerlocal**: only one of its proxy hosts is live, `archive`
  (regulad's rootless `dcef`); its `ci` host died with the tunnel's `ci`
  route. Its ldap-auth guards `archive` alone and still binds to the freeipa
  stand-in.
- **qb-clearnet**: idle, with no torrents.
