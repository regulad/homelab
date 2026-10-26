# Ansible: hardware hosts

Phase 2 of [`.claude/PLAN.md`](../.claude/PLAN.md): the machines OpenTofu cannot
create, such as the Proxmox nodes. This stage runs after `tofu/backblaze` and before the
other OpenTofu roots. Its inventory is **only** the hand-written `inventory/hardware.yml`;
the one OpenTofu output it reads is `tofu/backblaze`'s `restic`, the restic role's
repository and keys. Generated hosts are configured from
[`ansible-generated/`](../ansible-generated/README.md).

| Path | Contents |
|---|---|
| `inventory/hardware.yml` | Hardware hosts by tailnet MagicDNS name, under the `hardware` group; network switches by SSH host, under the `switches` group |
| `files/<switch>/running-config`, `running-config.j2` | A network switch's whole running configuration; the SG300s' as templates taking their password hashes from SOPS |
| `bin/with-switch-keys` | Runs a command with each SG300's `svc-ansible` key in a throwaway ssh-agent and OpenSSL's security level lowered (`openssl-legacy.cnf`) |
| `plugins/` | The SG300s' cliconf (community.ciscosmb's, typing each command with one end of line, and working out and sending configuration changes), terminal and filter plugins |
| `inventory/group_vars/`, `inventory/host_vars/<host>/` | Variables |
| `playbooks/site.yml` | The stage's only playbook |
| `roles/` | Roles only this stage uses |
| `requirements.yml` | Collections, pinned to exact versions as roles first need them |

| Role | Purpose | Hosts |
|---|---|---|
| `base` (shared) | Packages, admin user, time sync, and sshd hardening only where it is already policy | `hardware` |
| `tailscale` (shared) | Tailscale client; joins only when `tailscale_join` is set | `hardware` |
| `proxmox_cluster` | Proxmox and Ceph cluster settings that `bpg/proxmox` cannot manage | `proxmox_nodes` |
| `eos` | An Arista switch's whole running configuration, replaced in one EOS configuration session | `eos` |
| `ciscosmb` | A Cisco SG300's running configuration, converged to the declared one and saved | `ciscosmb` |

Shared roles live in [`ansible-common/roles/`](../ansible-common/README.md),
which `ansible.cfg` lists after `roles/`. The roles are skeletons: their tasks
land in Phase 2.

`site.yml` is the stage's only playbook: every play converges hosts to the
declared state and is safe to rerun, and deliberate operations such as rolling
reboots or release upgrades are not playbooks. Package updates come from each
host's own automatic updater (unattended-upgrades, dnf-automatic).

## Running

Ansible reads `ansible.cfg` from the current directory, so run from this one:

```bash
. tofu/backblaze/prepare.sh    # the restic role reads tofu/backblaze's output
cd ansible-hardware
ansible-galaxy collection install -r requirements.yml -p collections
ansible-inventory --graph
ansible-playbook playbooks/site.yml --syntax-check
ansible-lint --offline
# The SG300s' plays need their keys; run them through the wrapper:
bin/with-switch-keys ansible-playbook playbooks/site.yml --limit ciscosmb --check --diff
ansible-playbook playbooks/site.yml --check --diff --limit <node>
```
