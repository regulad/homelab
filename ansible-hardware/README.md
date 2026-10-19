# Ansible: hardware hosts

Phase 2 of [`.claude/PLAN.md`](../.claude/PLAN.md): the machines OpenTofu cannot
create, such as the Proxmox nodes. This stage runs before OpenTofu and reads
**only** the hand-written `inventory/hardware.yml`; it never sees OpenTofu
outputs. Generated hosts are configured from
[`ansible-generated/`](../ansible-generated/README.md).

| Path | Contents |
|---|---|
| `inventory/hardware.yml` | Hardware hosts by tailnet MagicDNS name, under the `hardware` group |
| `inventory/group_vars/`, `inventory/host_vars/<host>/` | Variables |
| `playbooks/site.yml` | The stage's only playbook |
| `roles/` | Roles only this stage uses |
| `requirements.yml` | Collections, pinned to exact versions as roles first need them |

| Role | Purpose | Hosts |
|---|---|---|
| `base` (shared) | Packages, admin user, time sync, and sshd hardening only where it is already policy | `hardware` |
| `tailscale` (shared) | Tailscale client; joins only when `tailscale_join` is set | `hardware` |
| `proxmox_cluster` | Proxmox and Ceph cluster settings that `bpg/proxmox` cannot manage | `proxmox_nodes` |

Shared roles live in [`ansible-common/roles/`](../ansible-common/README.md),
which `ansible.cfg` lists after `roles/`. The roles are skeletons: their tasks
land in Phase 2.

## Running

Ansible reads `ansible.cfg` from the current directory, so run from this one:

```bash
cd ansible-hardware
ansible-inventory --graph
ansible-playbook playbooks/site.yml --syntax-check
ansible-lint --offline
ansible-playbook playbooks/site.yml --check --diff --limit <node>
```
