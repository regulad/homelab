# NEW: what to add once TODO.md is done

[`TODO.md`](TODO.md) captures the configuration every host already has. This
file lists what to add on top of that, once every host there is declarative.
See [`.claude/PLAN.md`](.claude/PLAN.md) for the phases.

## Security hardening

- [ ] AIDE and auditd on every host, containers included: AIDE's file integrity
  checks and auditd's rules, each mailing regulad@regulad.xyz through the host's
  mail relay when something anomalous is detected
