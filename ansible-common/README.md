# Ansible: shared roles

Roles that both [`ansible-hardware/`](../ansible-hardware/README.md) and
[`ansible-generated/`](../ansible-generated/README.md) apply. This folder has no
inventory, playbooks or `ansible.cfg` of its own: each stage's `ansible.cfg`
lists `../ansible-common/roles` after its own `roles/`.

| Role | Purpose |
|---|---|
| `base` | Packages, admin user, time sync, and sshd hardening only where it is already policy |
| `tailscale` | Tailscale client: checks each node's tags, converges its settings and Serve/Funnel, and joins a new node with a one-off tagged key only when `tailscale_join` is set; `tailscale_protected` nodes are never joined or re-authenticated |
| `ca_trust` | Root certificates distrusted in the system trust store, by OS group |
| `auto_updates` | The distribution's automatic updater (unattended-upgrades or dnf-automatic), by OS group |
| `kdump` | Kernel crash dumps through kdump-tools: the crash kernel's memory reservation, kdump-tools' settings, and the sysctls that turn hangs and oopses into panics |
| `mail_relay` | Postfix relaying every message to regulad@regulad.xyz through mail.regulad.xyz, as the host's FreeIPA `null-` account, plus `/usr/bin/mail` |

A role here runs against both hardware and generated hosts, so it must handle
both. Any collection it needs is pinned in both stages' `requirements.yml`.
