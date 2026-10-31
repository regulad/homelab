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
- [ ] ClamAV on-access in the privileged containers (immich, ncsusplitt,
  procontainer, qb, timemachine, tsexit, tvheadend), streaming to the shared
  clamd. Their root holds `CAP_SYS_ADMIN` in the initial user namespace, which
  clamonacc's fanotify marks need; whether Proxmox's container confinement still
  refuses them is untested. Unprivileged containers cannot run clamonacc at all
- [ ] Scheduled ClamAV scans on every host, containers included: a systemd timer
  running `clamdscan --stream` against the shared clamd, mailing detections
  through the host's mail relay. On-access scanning is best-effort: it misses
  files written while clamonacc is not running, events it drops when it falls
  behind, and files nothing opens again, and the unprivileged containers have
  none. A scheduled scan catches what is already on disk
- [ ] ClamAV in qBittorrent on qb: its "Run external program on torrent
  finished" scans each completed download through the shared clamd, and
  quarantines and mails a detection before anything else opens the files
- [x] Ratchet down the firewalls, Proxmox's and firewall-cmd's inside hosts, to
  block superfluous traffic
- [ ] Proxmox firewalls for the guests created before AGENTS.md required one of
  every new guest: firewall options and rules for each, as a new guest gets
- [ ] Egress firewalls everywhere, to contain a compromise such as a botnet's spam
  attempts should one occur

## Resilience

- [ ] Cross-site replication of services such as uptime and aameter

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
