# TODO: hosts to declarativize

Every host still configured by hand. Check one off once its configuration is
captured as code and a run against it reports no changes (`changed=0` for
Ansible, including the network switches). See
[`.claude/PLAN.md`](.claude/PLAN.md) for each phase.
What to add once everything here is declarative is in [`NEW.md`](NEW.md).

## Hardware hosts (`ansible-hardware/`)

- [ ] `prodingus`: the Proxmox VE node of `gonkputer`
- [ ] `turk`: Ubuntu 24.04 with VMware Workstation
- [ ] `overture`: macOS

## Network switches (`ansible-hardware/`, the `switches` group)

- [x] Cisco SG300 `switch45f304`: `ansible-hardware`'s `ciscosmb` role
- [x] Cisco SG300 `switch070e26`: `ansible-hardware`'s `ciscosmb` role
- [x] Arista 7010T `JPE18280417`: `ansible-hardware`'s `eos` role, its interfaces annotated from LLDP and DHCP leases

## Access points

- [ ] AirPort Extreme
- [ ] CR1000B

## OCI instances (`ansible-generated/`, from `tofu/oracle`)

- [ ] `bailout`
- [ ] `doppelgangerhq.com` (legacy `web`)
- [ ] `livekit`
- [ ] `mail`
- [ ] `tailscalerouter`

## gonkputer VMs (`ansible-generated/`, from `tofu/gonkputer`)

- [x] `arawi` (108)
- [ ] `vkasm` (129)

## gonkputer containers (`ansible-generated/`, from `tofu/gonkputer`)

- [x] `aameter` (130)
- [x] `authentik` (201): authentik 2026.8 in podman-compose, served by Caddy on ingress; moved from the authentik VM (109)
- [ ] `act` (123): low priority; currently dormant (HA state `disabled`), so not in the inventory
- [x] `cordpepperer` (118): a mirror of `peppercord`
- [x] `immich` (116)
- [x] `git` (200): Forgejo, served by Caddy on ingress, with its Cloudflare tunnel for SSH; moved from the git VM (110)
- [x] `ingress` (121)
  - [ ] Inbound IPv6: on 2026-10-24 Matrix's federation tester passed over ingress's IPv4 address but timed out on its IPv6 one; Caddy listens on both. Cause not yet found
- [x] `matrix` (202): Synapse 1.163 and its bridges as native units, the database on `/mnt/synapse`, served by Caddy on ingress; moved from the matrix VM (107)
- [ ] `llamarpcmaster` (119): low priority; currently dormant (HA state `disabled`), so not in the inventory
- [ ] `mastodon` (105): low priority; currently dormant (HA state `disabled`), so not in the inventory
- [x] `ncsusplitt` (125)
- [ ] `openclaw` (103): low priority
  - [x] Baseline from the shared roles: mail relay as `null-openclaw`, automatic updates, CA trust
  - [ ] Its application, not to be described declaratively for now
- [x] `openwebui` (115)
- [x] `peppercord` (126): a mirror of `cordpepperer`
- [x] `pihole` (112)
- [ ] `procontainer` (106): low priority; currently dormant (stopped, not started at boot), so not in the inventory
- [x] `pterodactyl` (120)
- [x] `tailscalerouter` (122)
- [x] `timemachine` (104)
- [x] `tsexit` (124)
- [x] `tvheadend` (127)
- [x] `uptime` (117)
- [x] `vaultwarden` (128)

## gonkputer quasi-hardware VMs (`ansible-generated/`, from `tofu/gonkputer`)

First installed on hardware and later imaged into VMs, so each carries a
hardware install rather than a cloud image. Ansible configures them, not
cloud-init.

- [ ] `aboriginal` (100)
  - [x] Add its `ansible_host` to `tofu/gonkputer`
  - [x] Baseline from the shared roles: mail relay, automatic updates, CA trust
  - [ ] Describe its own services
- [ ] `dodo` (101)
  - [x] Add its `ansible_host` to `tofu/gonkputer`
  - [x] Baseline from the shared roles: mail relay, automatic updates, CA trust
  - [ ] Describe its own services

## gonkputer VMs to move into containers

Services to move off their VMs into containers.

- [x] `authentik` (109): moved to the `authentik` container (201); the VM is destroyed
- [x] `git` (110): moved to the `git` container (200); the VM is destroyed
- [x] `matrix` (107): moved to the `matrix` container (202); the VM is destroyed

## gonkputer VMs with cloud-init (`tofu/gonkputer` vendor files)

**Precondition:** [bpg/terraform-provider-proxmox#2901](https://github.com/bpg/terraform-provider-proxmox/issues/2901).
The provider replaces a VM whenever its `*_data_file_id` changes, although
Proxmox changes `cicustom` in place. Move no further VMs to cloud-init until
it is resolved.

Configured by a cloud-init vendor file instead of Ansible, so they need no SSH.

- [ ] `freeipa` (113)
  - [ ] Add a vendor file
- [ ] `softether` (114)
- [ ] `unifi` (102)
- [ ] `urbackup` (111)

Not listed: the template `resolute-template` (8000), which is not a host.

- [ ] A vendor file for new Ubuntu 26.04 VMs, as a new snippet rather than an
  edit of `ubuntu-vendor.yaml`, which would replace the VMs using it: drop
  `linux-image-generic` (26.04's base modules carry `i6300esb`, and Ubuntu has
  no package tracking only the extra modules), and preseed the debconf answer
  `watchdog/module` as `i6300esb` instead of editing `/etc/default/watchdog`,
  so package upgrades keep it.

## MAC addresses

Each hardware host's and switch's management interface, as `mac` - Name.

- `3c:7c:3f:22:33:b3` - prodingus (`vmbr0`, on `eth0`)
- overture
- pending - turk (unreachable on 2026-10-20)
- `08:cc:68:45:f3:04` - Cisco SG300 `switch45f304`
- `f8:7b:20:07:0e:26` - Cisco SG300 `switch070e26`
- `28:99:3a:fa:31:fa` - Arista 7010T
