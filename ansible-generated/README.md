# Ansible: generated hosts

Phase 4 of [`.claude/PLAN.md`](../.claude/PLAN.md): the Proxmox guests and OCI
instances that OpenTofu creates or adopts. This stage runs after OpenTofu and
reads **only** OpenTofu state, through the `cloud.terraform.terraform_state`
inventory plugin; it never sees the hand-written hardware inventory. Hardware hosts are
configured from [`ansible-hardware/`](../ansible-hardware/README.md).

| Path | Contents |
|---|---|
| `inventory/<root>.terraform_state.yml` | One inventory source per OpenTofu root; every host joins the `generated` group |
| `bin/tofu-<root>` | The `tofu` each source runs, with that root's state encryption settings |
| `inventory/group_vars/`, `inventory/host_vars/<host>/` | Variables, including each host's `services.yml` |
| `playbooks/site.yml` | The stage's only playbook |
| `roles/` | Roles only this stage uses |
| `requirements.yml` | Collections, pinned to exact versions as roles first need them |

| Role | Purpose | Hosts |
|---|---|---|
| `base` (shared) | Packages, admin user, time sync, and sshd hardening only where it is already policy | `generated` |
| `tailscale` (shared) | Tailscale client; joins only when `tailscale_join` is set | `generated` |
| `podman` | Installs Podman | `podman_hosts` |
| `host_files` | Native files, templates, links, packages, pinned pipx applications and systemd units from `host_vars` and `files/<host>/`; secret content from SOPS; files shared by several hosts from `files/shared/`; optional validation before a file is replaced, and reload instead of restart | generated hosts except `arawi` |
| `watchdog` | The watchdog daemon pinging the VM's virtual watchdog device, with the package's debconf answers kept in step so upgrades keep the module | `watchdog`, the VMs whose watchdog device OpenTofu enables |
| `avahi` | mDNS reflection between the podman bridge and the LAN | `podman_hosts` |
| `quadlet` | Quadlet units rendered from each host's `quadlet_services` | `podman_hosts` |
| `pterodactyl` | Installs the Pterodactyl panel where none exists and keeps its `.env`; `playbooks/maintenance.yml` upgrades it to `pterodactyl_version` | `pterodactyl` |

Shared roles live in [`ansible-common/roles/`](../ansible-common/README.md),
which `ansible.cfg` lists after `roles/`. The roles are skeletons: their tasks
land in Phase 4.

`site.yml` is the stage's only playbook: every play converges hosts to the
declared state and is safe to rerun, and deliberate operations such as rolling
reboots or release upgrades are not playbooks. Package updates come from each
host's own automatic updater (unattended-upgrades, dnf-automatic).

## Inventory

Each `inventory/<root>.terraform_state.yml` reads one root's state. The plugin
runs `tofu init` and `tofu state pull` in a scratch directory holding only a
bare `backend "s3" {}`, so:

- each source file mirrors its root's backend settings, and the credentials come
  from the environment that sourcing a root's `prepare.sh` exports;
- the scratch directory has no `encryption` block, so `binary_path` names the
  wrapper `tofu-<root>` from `bin/`. That wrapper sets `TF_ENCRYPTION` for its
  own process from the root's decrypted inputs, keeping one root's encryption
  settings away from the others. Its names must match the root's `encryption`
  block.
- the plugin runs `binary_path` from the scratch directory, so it is a bare name
  found on `PATH`. Sourcing either root's `prepare.sh` puts `bin/` on `PATH`.
- each wrapper reads its root's decrypted inputs, so source both roots'
  `prepare.sh` once before the first run.

Every attribute of a mapped resource becomes a host variable, so
`ansible-inventory --vars` shows instance metadata such as SSH keys.

| Source | Hosts | `ansible_host` |
|---|---|---|
| `oracle.terraform_state.yml` | Each `oci_core_instance`, named by display name; an OS group from its `os` freeform tag | `<hostname label>.pubsub.wahlecloud.oraclevcn.com`; legacy `web` uses its public name, `doppelgangerhq.com` |
| `gonkputer.terraform_state.yml` | Each `ansible_host` in `tofu/gonkputer`: the requested guests Ansible manages (containers, and the VMs that can't use cloud-init), named by DNS name; groups `gonkputer`, `proxmox_vms` or `proxmox_containers`, and an OS group | VMs: the host name, `<name>.regulad.internal`. Containers: their Proxmox node, reached through `proxmox_pct_remote` (`inventory/group_vars/proxmox_containers.yml`), with `proxmox_vmid` from state |

Both sources load as one inventory, and `site.yml` runs once over the union.

## Running

Ansible reads `ansible.cfg` from the current directory, so run from this one,
after installing the pinned collections into the gitignored `collections/`:

```bash
. tofu/oracle/prepare.sh
. tofu/gonkputer/prepare.sh
cd ansible-generated
ansible-galaxy collection install -r requirements.yml -p collections
ansible-inventory --graph
ansible-playbook playbooks/site.yml --syntax-check
ansible-lint --offline
ansible-playbook playbooks/site.yml --check --diff --limit <host>
```

A source that cannot be read fails the whole inventory, because `ansible.cfg`
sets `any_unparsed_is_failed`.
