# NEW: what to add once TODO.md is done

[`TODO.md`](TODO.md) captures the configuration every host already has. This
file lists what to add on top of that, once every host there is declarative.
See [`.claude/PLAN.md`](.claude/PLAN.md) for the phases.

## Security hardening

- [x] AIDE on every Linux host, containers included: aide-report checks the
  host's files daily, at a time of each host's own, against a baseline held
  until `maintenance.yml --tags aide-accept` moves it, and mails root, through
  the host's mail relay, the changes its packages do not explain (`rpm
  --verify`, or dpkg's checksums). Each `site.yml` run moves the baseline for
  the files it wrote. Not yet on turk, which was unreachable
- [x] auditd on every Linux host with its own kernel, to instrument an
  intrusion should one occur: its rules record what happened for the
  investigation. Containers cannot run it, and prodingus's records their
  processes. It detects and notifies nothing, and sends no mail; that is
  AIDE's job
- [x] `/tmp` a tmpfs mounted `noexec` on every Linux host, containers
  included, by systemd's own `tmp.mount` with a drop-in adding `noexec` (the
  `noexec` role). Where `/tmp` was on the root filesystem, the tmpfs comes at
  each host's next boot, and `tmp-erase.service` erases what was left there
  before each mount
- [x] `/var/log` bound over itself `noexec` on every Linux host, containers
  included, by a mount unit of its own (the `noexec` role): AIDE does not watch
  it, so nothing put there can be run from there either. Not yet on turk, which
  was unreachable
- [x] ClamAV on-access on the hardware hosts and every other Linux host with
  its own kernel, scanning for anomalous files: implants and bad user data
  alike. Each host's clamonacc scans files as they are opened and written, and
  streams them to one shared clamd, the `clamd` container, whose freshclam keeps
  the signatures current; doppelgangerhq.com, outside the homelab, runs a clamd
  of its own. Runs on prodingus, aboriginal, dodo and the OCI instances.
  Expensive, but it would have caught the implant on dodo (then pelican) before
  Parker did
- [x] ClamAV on-access in the privileged containers (immich, ncsusplitt, qb,
  timemachine, tsexit, tvheadend), streaming to the shared
  clamd over the same directories as the hosts with their own kernel. Their
  root holds `CAP_SYS_ADMIN` in the initial user namespace, which clamonacc's
  fanotify group needs. Unprivileged containers cannot run clamonacc at all; the
  inventory's `unprivileged_containers` group, from each container's
  `unprivileged`, keeps the play off them
- [x] Scheduled ClamAV scans on every Linux host, containers included:
  clamav-scan, the `clamav` role's `scan` entry point, run weekly by a systemd
  timer at a delay of the host's own (`RandomizedDelaySec=1w` with
  `FixedRandomDelay=`). It sends each file to the shared clamd, or to the
  host's own where it runs one, over the on-access directories, `/var` and each
  host's additions, and quarantines and mails what it finds through the host's
  mail relay; prodingus alone scans the CephFS. On-access scanning is
  best-effort: it misses files written while clamonacc is not running, events
  it drops when it falls behind, and files nothing opens again, and the
  unprivileged containers have none. A scheduled scan catches what is already
  on disk
  - [x] The backups scheduled the same way: each `restic_jobs` job sets a
    `period`, daily or weekly, and its timer runs it at a delay of the host's
    own within that period (`RandomizedDelaySec=` with `FixedRandomDelay=`),
    in place of the fixed times in host_vars; the guest descriptions that
    announced those times are gone from tofu/gonkputer. Every job runs
    weekly, the host backups no longer daily
- [x] ClamAV in qBittorrent on qb: qb-clamav, its hooks for torrents added and
  finished, stages each new torrent in the `unscanned` category, scans it
  through the shared clamd once finished, and releases a clean one to
  `/downloads` or stops, quarantines and mails an infected one; the qbittorrent
  role declares the hooks and the settings they depend on. A file over clamd's
  2047 MiB is scanned in its first 2047 MiB, its torrent tagged
  `clamav-partial`. Incomplete and staged torrents stay visible over
  aboriginal's Samba share of regulad's home
- [x] Ratchet down the firewalls, Proxmox's and firewall-cmd's inside hosts, to
  block superfluous traffic
- [ ] Proxmox firewalls for the guests created before AGENTS.md required one of
  every new guest: firewall options and rules for each, as a new guest gets
- [ ] Egress firewalls everywhere, to contain a compromise such as a botnet's spam
  attempts should one occur

## Resilience

- [ ] Cross-site replication of services such as uptime

## Additional cloud providers

- [x] AWS: `tofu/aws`, signed in through IAM Roles Anywhere with a certificate whose key
  is in SOPS. The account was cleaned out, and what it keeps is adopted: the IAM users
  and roles, and the Lambda behind Home Assistant's Alexa Smart Home skill
- [x] GCP: `tofu/gcp`, one root for every project, signed in as a service account whose
  uploaded key Google holds only the public half of. Eleven projects were deleted, and
  the four kept are adopted with their APIs, service accounts and reCAPTCHA keys
- [x] Cloudflare: `tofu/cloudflare`, signed in with an account-owned API token, as the
  API offers no key pair. Its five zones and their records, `regulad.xyz`'s DNSSEC and
  settings, the `git` tunnel and two hosts' API tokens are adopted; the OCI hosts'
  records read their addresses from `tofu/oracle`'s outputs
- [ ] Azure

## Additional declarative configuration of services

- [ ] nexus
- [ ] immich
- [ ] authentik
- [ ] jenkins: its LDAP realm and other settings live in `config.xml`, Jenkins's own state
- [ ] etc. (not yet thoroughly probed)
