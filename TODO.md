# TODO: hosts to declarativize

Every host still configured by hand. Check one off once its configuration is
captured as code and a run against it reports no changes (`changed=0` for
Ansible, an identical configuration for the switch scripts). See
[`.claude/PLAN.md`](.claude/PLAN.md) for each phase.

## Hardware hosts (`ansible-hardware/`)

- [ ] `prodingus`: the Proxmox VE node of `gonkputer`
- [ ] `turk`: Ubuntu 24.04 with VMware Workstation
- [ ] `overture`: macOS

## Network switches (repository scripts)

- [ ] Cisco SG300 `switch45f304`
- [ ] Cisco SG300 `switch070e26`
- [ ] Arista 7010T

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
- [ ] `act` (123)
- [ ] `cordpepperer` (118): a mirror of `peppercord`
- [ ] `immich` (116)
- [ ] `ingress` (121)
- [ ] `llamarpcmaster` (119): in the inventory only while its HA resource is requested. Low priority
- [ ] `mastodon` (105)
- [ ] `ncsusplitt` (125)
- [ ] `openclaw` (103): low priority
- [ ] `openwebui` (115)
- [ ] `peppercord` (126): a mirror of `cordpepperer`
- [x] `pihole` (112)
- [ ] `procontainer` (106): low priority
- [ ] `pterodactyl` (120)
- [ ] `tailscalerouter` (122)
- [x] `timemachine` (104)
- [ ] `tsexit` (124)
- [x] `tvheadend` (127)
- [x] `uptime` (117)
- [x] `vaultwarden` (128)

## gonkputer VMs with cloud-init (`tofu/gonkputer` vendor files)

**Precondition:** [bpg/terraform-provider-proxmox#2901](https://github.com/bpg/terraform-provider-proxmox/issues/2901).
The provider replaces a VM whenever its `*_data_file_id` changes, although
Proxmox changes `cicustom` in place. Move no further VMs to cloud-init until
it is resolved.

Configured by a cloud-init vendor file instead of Ansible, so they need no SSH.

- [ ] `aboriginal` (100)
  - [ ] Boot with cloud-init
- [ ] `authentik` (109)
- [ ] `dodo` (101)
  - [ ] Boot with cloud-init
- [ ] `freeipa` (113)
  - [ ] Add a vendor file
- [ ] `git` (110)
  - [ ] Boot with cloud-init
- [ ] `matrix` (107)
  - [ ] Boot with cloud-init
- [ ] `softether` (114)
- [ ] `unifi` (102)
- [ ] `urbackup` (111)

Not listed: the template `resolute-template` (8000), which is not a host.

## MAC addresses

Each hardware host's and switch's management interface, as `mac` - Name.

- `3c:7c:3f:22:33:b3` - prodingus (`vmbr0`, on `eth0`)
- overture
- pending - turk (unreachable on 2026-10-20)
- `08:cc:68:45:f3:04` - Cisco SG300 `switch45f304`
- `f8:7b:20:07:0e:26` - Cisco SG300 `switch070e26`
- `28:99:3a:fa:31:fa` - Arista 7010T
