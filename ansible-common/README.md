# Ansible: shared roles

Roles that both [`ansible-hardware/`](../ansible-hardware/README.md) and
[`ansible-generated/`](../ansible-generated/README.md) apply. This folder has no
inventory, playbooks or `ansible.cfg` of its own: each stage's `ansible.cfg`
lists `../ansible-common/roles` after its own `roles/`.

`group_vars/all.sops.yml` holds the secrets both stages share, such as the
FreeIPA service account's password and `wifi_psks`. Each stage's
`inventory/group_vars/all.sops.yml` is a symbolic link to it, so the stages'
SOPS vars plugin loads the one file.

| Role | Purpose |
|---|---|
| `apt_amd64v3` | APT's `amd64v3` architecture variant on Ubuntu 25.10 and later where the CPU supports x86-64-v3, removed elsewhere; refreshes the lists but never upgrades |
| `base` | Packages, admin user, time sync, and sshd hardening only where it is already policy; and, through `playbooks/maintenance.yml --tags hostname`, the hostname and its installer-style `/etc/hosts` line where `base_hostname_managed` is set (Ubuntu hardware installs) |
| `tailscale` | Tailscale client: checks each node's tags, converges its settings and Serve/Funnel, and joins a new node with a one-off tagged key only when `tailscale_join` is set; `tailscale_protected` nodes are never joined or re-authenticated |
| `ca_trust` | The homelab's roots of trust (arawi's two CAs, FreeIPA's and the Proxmox cluster's, from `files/trusted/`) trusted, and compromised roots distrusted, in the system trust store, by OS group |
| `auto_updates` | The distribution's automatic updater (unattended-upgrades or dnf-automatic), by OS group |
| `kdump` | Kernel crash dumps through kdump-tools: the crash kernel's memory reservation, kdump-tools' settings, and the sysctls that turn hangs and oopses into panics |
| `kernel_params` | Sysctl drop-ins in `/etc/sysctl.d` and GRUB kernel-argument drop-ins in `/etc/default/grub.d`, as each host declares, plus per-task delay accounting on every host with its own kernel and IP forwarding for hosts that route |
| `mail_relay` | Postfix relaying every message to regulad@regulad.xyz through mail.regulad.xyz, as the host's FreeIPA `null-` account, plus `/usr/bin/mail` |

A role here runs against both hardware and generated hosts, so it must handle
both. Any collection it needs is pinned in both stages' `requirements.yml`.
