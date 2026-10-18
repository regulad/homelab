# Ansible

Ansible configures hosts in two stages, one on each side of OpenTofu. See
[`.claude/PLAN.md`](../.claude/PLAN.md) for each stage's steps and acceptance.

| Stage | Hosts | Inventory | Playbooks |
|---|---|---|---|
| Phase 2: hardware hosts | Machines OpenTofu cannot create, such as the Proxmox nodes | `inventory/hardware.yml`, written by hand | `hardware.yml` |
| Phase 4: generated hosts | Proxmox guests and OCI instances that OpenTofu creates or adopts | `inventory/inventory.py`, from each root's `ansible_hosts` output | `base.yml`, then `services.yml` |

`playbooks/site.yml` imports all three playbooks in that order. Both inventories
sit in `inventory/`, which `ansible.cfg` names as the inventory, so one inventory
covers both stages. Hardware hosts are under the `hardware` group and generated
hosts under `generated`. Variables live in `inventory/group_vars/` and
`inventory/host_vars/<host>/`.

| Role | Purpose | Playbook and hosts |
|---|---|---|
| `base` | Packages, admin user, time sync, and sshd hardening only where it is already policy | `hardware.yml` (`hardware`), `base.yml` (`generated`) |
| `tailscale` | Tailscale client; joins only when `tailscale_join` is set | `hardware.yml` (`hardware`), `base.yml` (`generated`) |
| `proxmox_cluster` | Proxmox and Ceph cluster settings that `bpg/proxmox` cannot manage | `hardware.yml` (`proxmox_nodes`) |
| `podman` | Podman and its registries | `base.yml` (`podman_hosts`) |
| `avahi` | mDNS reflection between the podman bridge and the LAN | `base.yml` (`podman_hosts`) |
| `quadlet` | Quadlet units rendered from each host's `quadlet_services` | `services.yml` (`podman_hosts`) |

The roles are skeletons: their tasks land in the phases above. Each role keeps
its knobs in `defaults/`. Collections are pinned in `requirements.yml` as roles
first need them.

## Running

The control node is Linux, so on Windows run Ansible from WSL. Ansible ignores
an `ansible.cfg` in a world-writable directory, which a checkout under `/mnt/`
is, so name the file explicitly. From the repository root:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-inventory --graph
ansible-playbook ansible/playbooks/site.yml --syntax-check
ansible-lint --offline ansible/
ansible-playbook ansible/playbooks/hardware.yml --check --diff --limit <node>
```

`inventory.py` runs `tofu output` for each root it lists. The state backend's
credentials therefore have to reach the WSL environment, for example through
`WSLENV` after `tofu/oracle/prepare.ps1` sets them in PowerShell. The script
lists no roots yet; each root joins in Phase 4, once it exports `ansible_hosts`.
A root that cannot be read fails the whole inventory, because `ansible.cfg` sets
`any_unparsed_is_failed`.
