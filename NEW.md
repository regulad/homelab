# NEW: what to add once TODO.md is done

[`TODO.md`](TODO.md) captures the configuration every host already has. This
file lists what to add on top of that, once every host there is declarative.
See [`.claude/PLAN.md`](.claude/PLAN.md) for the phases.

## Security hardening

- [ ] AIDE and auditd on every host, containers included: AIDE's file integrity
  checks and auditd's rules, each mailing regulad@regulad.xyz through the host's
  mail relay when something anomalous is detected
- [ ] ClamAV (clamscan, with freshclam keeping its signatures current) on every
  host, scanning in the background for anomalous files: implants and bad user
  data alike. Expensive, but it would have caught the implant on dodo (then
  pelican) before Parker did
- [ ] Ratchet down the firewalls, Proxmox's and firewall-cmd's inside hosts, to
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
