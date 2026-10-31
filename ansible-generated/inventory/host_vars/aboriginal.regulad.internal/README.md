# aboriginal

VM 100 on gonkputer: a hardware install of Ubuntu imaged into a VM, and also a
remote workstation, so nothing under `/home/regulad` is managed. Its services
are a few native units and containers, which are moving off Docker onto
Podman, as Parker decided, although AGENTS.md otherwise keeps a host on its
runtime. mosquitto and ring-mqtt are Quadlets (`services.yml`). The compose
projects become podman-compose stacks in `/opt/<name>`, each run by
`podman-compose@<name>.service`: jellyfin is one, and those still under
`/root/compose` are to follow.
What ties a service to this VM is the hardware passed through to it or the
mounts of the restic `nas` archive. Services with neither move to containers
of their own.

## Staying

- **jellyfin and llama-server**: the passed-through RX 6800 (`renderD129`),
  Jellyfin for VA-API transcoding and llama-server through ROCm.
  - Jellyfin's image follows `jellyfin_major` (12), which only
    `maintenance.yml`'s `jellyfin-upgrade` moves, with a copy to roll back to
    and its plugins rebuilt for the new release.
    Its LDAP plugin reads its CA from `LdapRootCaPath`, to which `ca_trust`'s
    HOME.ARPA anchor is bound while it binds to the freeipa stand-in.
  - llama-server's unit and its API key, in SOPS, are host files. The
    llama.cpp it runs is built on this host, in `/opt/llama.cpp`, by
    `maintenance.yml`'s `llama-cpp-build`, at the commit `llama_cpp_commit`
    declares on regulad/llama.cpp's `aboriginal` branch: upstream with one
    change to `ggml/src/ggml-cuda/fattn-common.cuh`, which lets a launch go
    ahead with one block where HIP's occupancy API reports none on RDNA2
    (ggml-org/llama.cpp#23310). Each build has a directory of its own, and
    `build`, from which the unit runs, points at the current one. It listens
    on IPv4 only.
  - Its model, `llama_server_model`, is on CephFS in
    `/mnt/cephfs/application/llama-models`. Where either of its files is
    missing, the unit downloads both from Hugging Face before it starts, with
    the `hf` of a global pipx install; the repository is public, so it needs
    no token.
  - The self-built server stays, by Parker's choice, over llama.cpp's own
    `server-rocm` image. Upstream keeps the assert the change removes, and a
    diagnosis in ggml-org/llama.cpp#27674 blames distribution builds of ROCm
    7.1's `comgr`, such as the Ubuntu 7.1.1 this host links against, which
    report too few registers on gfx10. The image, built on AMD's ROCm 7.2.1,
    may not need the change, but it is rebuilt daily and not tested on GPUs.
- **nextcloud and Samba**: the `nas` archive's overlays,
  `/mnt/media` and `/mnt/nextcloud`, with their upper layers on CephFS.
  - Samba's whole `smb.conf` is a host file; its one passdb user, regulad, is
    Samba's own state. smbd requires the mounts, which wait for restic:
    `mnt-restic.service` has no start timeout, so at a cold boot of the whole
    cluster, when B2 is out of reach until arawi's DHCP answers, the units that
    need the mounts wait for them instead of failing. nmbd, which timed out at
    such a boot before aboriginal had its IPv4 lease, retries until it starts.
- **NUT**: the UPSes on USB; Home Assistant's `nut` integration reads upsd.
  upsd runs alone: nothing is to act on a power cut for now, so upsmon is
  masked, as `nut.target` would start it to fail. The APC's section in
  `ups.conf` is commented out while it is under maintenance, its passthrough
  removed with it. Its configuration is host files; NUT keeps hass's password
  in plain text in `upsd.users`, so it is in SOPS.
- **lime**, which unlocks overture's FileVault at its pre-boot SSH unlock:
  the `lime` role builds it on this host and runs it at boot. Its credential
  is sealed to the VM's vTPM (`tpmstate0` on `local-lvm`), which
  `vm-aboriginal.tf` declares with its changes ignored, as applying it would
  replace the TPM with an empty one. The password itself is in
  `secrets.sops.yml` (`lime_passwords`), and the role seals it again wherever
  the credential no longer decrypts.
- **homeassistant, matter-server, mosquitto and ring-mqtt.** They would suit a
  Home Assistant OS VM with the USB devices passed through, but Home Assistant
  needs the host's Bluetooth stack: its Bluetooth integrations reach BlueZ
  over `/run/dbus`. ZHA holds the Zigbee stick on `/dev/ttyUSB0`.
  - mosquitto and ring-mqtt share the host's network, as Home Assistant does,
    which reaches mosquitto on localhost. Their configuration is host files,
    and ring-mqtt's Ring refresh token is state in its volume. Podman's
    auto-update replaces the watchtower ring-mqtt had of its own.

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
- **I2P**: the `i2p` container runs i2pd, whose SAM qb uses. The old I2P's
  volumes and its tunnel route are removed.
- **qb-clearnet**: to the `qb` container, the lab's one qBittorrent, a Quadlet
  saving into `/mnt/cephfs/homes/regulad/downloads`, renamed from
  `downloads-clearnet`, with its settings seeded from qb-clearnet's and its web
  UI on the tailnet through Tailscale Serve.
- **docker-nexus**: to the `nexus` container, a read-only Quadlet of
  `sonatype/nexus3`, since moved from OrientDB to H2, behind Caddy on ingress,
  with its data on its own mount point. `cr.regulad.xyz` is a virtual host on Nexus's one port
  in place of a connector of its own. Compacting its blob store first gave
  back 35 G of abandoned Docker uploads, and its dead LDAP realm is gone.
  aboriginal's root went from 93 % to 62 % full.
- **bandcampsync**: to regulad, a rootless Quadlet of his own in
  `~/.config/containers/systemd`, set up by hand and not managed here, as its
  Bandcamp session cookies are volatile and renewed by hand. It still saves
  into `/mnt/media/Bandcamp`.

## Removed

- **llama-rpc**: disabled, and its cache directory empty. Its master,
  the dormant `llamarpcmaster` container, is destroyed too.
- **NFS**: the server exported only Jellyfin's config and cache, to two
  rffmpeg transcode hosts, and the stock Jellyfin image it runs has no
  rffmpeg. Nothing mounted NFS, so `nfs-common` and `rpcbind` went with it,
  and so did rffmpeg's configuration, key and mounts.
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
- **The HOME.ARPA FreeIPA client**: its packages, the SSSD suite and what
  only they needed, with their PAM profile, NSS entries, Kerberos and LDAP
  client configuration, and state. The HOME.ARPA CA stays trusted, from
  `ca_trust`.
- **winbind**: a standalone Samba does not use it.
- **Old tooling in root's home**: a B2 pruning script with an account file
  holding no key, the mail null-client script, an old backup run's output, a
  GPT backup of the original, larger disk, the IPA client's directory, and
  the `nextcloud-ca` build context.
- **cloudflared**, ahead of its last routes, `hass-livingston`, `archive` and
  `qb-clearnet`, none of them needed, with the tunnel and those routes' DNS
  records.
- **nginxproxymanagerlocal**: NPMplus, its MariaDB and its ldap-auth. Every
  proxy host was reached only through the tunnel; the one still wanted,
  `archive` (regulad's rootless `dcef`), is now Caddy's on ingress, behind an
  ldap-auth of ingress's own, bound to wako as `svc-ingress`. Its bind
  account on the freeipa stand-in, `svc-nginxproxymanager`, is deleted.
