# Ansible: shared roles

Roles that both [`ansible-hardware/`](../ansible-hardware/README.md) and
[`ansible-generated/`](../ansible-generated/README.md) apply. This folder has no
inventory, playbooks or `ansible.cfg` of its own: each stage's `ansible.cfg`
lists `../ansible-common/roles` after its own `roles/`.

| Role | Purpose |
|---|---|
| `base` | Packages, admin user, time sync, and sshd hardening only where it is already policy |
| `tailscale` | Tailscale client; joins only when `tailscale_join` is set |
| `ca_trust` | Root certificates distrusted in the system trust store, by OS group |
| `auto_updates` | The distribution's automatic updater (unattended-upgrades or dnf-automatic), by OS group |
| `mail_relay` | Postfix relaying every message to regulad@regulad.xyz through mail.regulad.xyz, as the host's FreeIPA `null-` account |

A role here runs against both hardware and generated hosts, so it must handle
both. Any collection it needs is pinned in both stages' `requirements.yml`.
