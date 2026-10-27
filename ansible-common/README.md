# Ansible: shared roles and plays

Roles and plays that both [`ansible-hardware/`](../ansible-hardware/README.md) and
[`ansible-generated/`](../ansible-generated/README.md) apply. This folder has no
inventory or `ansible.cfg` of its own: each stage's `ansible.cfg` lists
`../ansible-common/roles` after its own `roles/`.

`playbooks/site.yml` and `playbooks/maintenance.yml` hold the plays both stages run.
Each stage's playbook of the same name imports them before its own, so they run
from inside a stage, with its inventory. Shared plays target OS groups, which both
inventories have; a stage-only play stays in its stage. `playbooks/roles` links to
`../roles`, so the plays resolve their roles when linted from the repository root.

`group_vars/all.sops.yml` holds the secrets both stages share, such as the
FreeIPA service account's password and `wifi_psks`. Each stage's
`inventory/group_vars/all.sops.yml` is a symbolic link to it, so the stages'
SOPS vars plugin loads the one file.

| Role | Purpose |
|---|---|
| `apt_amd64v3` | APT's `amd64v3` architecture variant on Ubuntu 25.10 and later where the CPU supports x86-64-v3, removed elsewhere; refreshes the lists but never upgrades |
| `base` | Packages, admin user, time sync, and sshd hardening only where it is already policy: so far each OS group's `base_packages`, every host's `base_timezone` (America/New_York, with `/etc/timezone` kept in step where it is a file), and the `base_admin_user` (in the OS's admin group, sudo without a password, its GitHub keys as its whole `authorized_keys`) where a group names one; and, through `playbooks/maintenance.yml --tags hostname`, the hostname and its installer-style `/etc/hosts` line where `base_hostname_managed` is set (Ubuntu hardware installs) |
| `tailscale` | Tailscale client, from Tailscale's dnf repository on Enterprise Linux: checks each node's tags, converges its settings and Serve/Funnel, and joins a new node with a one-off tagged key only when `tailscale_join` is set; `tailscale_protected` nodes are never joined or re-authenticated |
| `ca_trust` | The homelab's roots of trust (arawi's two CAs, wako's and the old FreeIPA server's, and the Proxmox cluster's, from `files/trusted/`) trusted, compromised roots distrusted, and the anchors of retired names removed, in the system trust store, by OS group |
| `auto_updates` | The distribution's automatic updater (unattended-upgrades or dnf-automatic), by OS group |
| `kdump` | Kernel crash dumps. On Debian and Ubuntu, through kdump-tools: the crash kernel's memory reservation, kdump-tools' settings, and the sysctls that turn hangs and oopses into panics. On Enterprise Linux, the image's kdump service, with kexec-tools keeping its default reservation |
| `kernel_params` | Sysctl drop-ins in `/etc/sysctl.d` and GRUB kernel-argument drop-ins in `/etc/default/grub.d`, as each host declares, plus per-task delay accounting on every host with its own kernel and IP forwarding for hosts that route |
| `netplan` | Netplan as the only network configuration where a host declares `netplan_config` (`30-homelab.yaml`, other files removed), plus networkd drop-ins for what netplan cannot express; changes go through `netplan try`, accepted only once Ansible reconnects, with a timer restoring the previous files otherwise |
| `restic` | Access to the restic repository on Backblaze B2: restic (0.16 or later), `/etc/restic-password` and `/etc/restic-env` (a systemd environment file, mode 0400, naming the cache), from the repository and the host's own key in `tofu/backblaze`'s `restic` output and the shared password; then the host's `restic_jobs`, each a `restic-<job>.service` started by its timer: `simple`, `snapshot` (btrfs snapshots), `cephfs` and `rbd` (each from a snapshot, by a script in `/usr/local/bin` that also removes any snapshot an interrupted run left), `rgw` and `forget`, replacing the crontab scripts in `restic_retired_scripts`; hosts without a key there are left alone; `restic_env_units`, such as a restic mount, restart when the environment or password changes. `maintenance.yml --tags restic-password` and `restic-password-prune` rotate the shared repository password |
| `swap` | zram through systemd-zram-generator at `swap_zram_size` (default half the RAM), replacing zram-config and zram-tools once their service stops, and disk swapfiles from `swap_files`, listed in `fstab`; `playbooks/maintenance.yml --tags zram` sets zram up again where its contents fit back into RAM |
| `mail_relay` | Postfix relaying every message to regulad@regulad.xyz through mail.regulad.xyz, as the host's FreeIPA `null-` account, plus `/usr/bin/mail` |

A role here runs against both hardware and generated hosts, so it must handle
both. Any collection it needs is pinned in both stages' `requirements.yml`.
