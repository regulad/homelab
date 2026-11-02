# NEW: what to add once TODO.md is done

[`TODO.md`](TODO.md) captures the configuration every host already has. This
file lists what to add on top of that, once every host there is declarative.
See [`.claude/PLAN.md`](.claude/PLAN.md) for the phases.

## Security hardening

- [ ] AIDE and auditd on every host, containers included: AIDE's file integrity
  checks and auditd's rules, each mailing regulad@regulad.xyz through the host's
  mail relay when something anomalous is detected
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
  mail relay; prodingus alone scans the CephFS. On-access scanning is best-effort: it misses files written while
  clamonacc is not running, events it drops when it falls behind, and files
  nothing opens again, and the unprivileged containers have none. A scheduled
  scan catches what is already on disk
  - [ ] Once the scans are done, the backups scheduled the same way: each
    `restic_jobs` timer at a delay of the host's own (`RandomizedDelaySec=`
    with `FixedRandomDelay=`) in place of the fixed times in host_vars, and the
    guest descriptions that announce those times removed: "MAINTENENCE TASKS
    AT 5:35" on aboriginal and "MAINTENANCE TASKS AT 5:15" on dodo, in
    tofu/gonkputer. Once AIDE is in place, finding mutations sooner than a
    backup could, the daily backups run weekly
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

- [ ] AWS
- [ ] GCP
- [ ] Azure

## Additional declarative configuration of services

- [ ] nexus
- [ ] immich
- [ ] authentik
- [ ] jenkins: its LDAP realm and other settings live in `config.xml`, Jenkins's own state
- [ ] etc. (not yet thoroughly probed)
