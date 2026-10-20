# Import blocks for the first, descriptive adoption pass, which mirrors the live
# configuration exactly. Remove them after the approved apply that records them.

# --- Guests -----------------------------------------------------------------

import {
  to = proxmox_virtual_environment_vm.aboriginal
  id = "prodingus/100"
}

import {
  to = proxmox_virtual_environment_vm.dodo
  id = "prodingus/101"
}

import {
  to = proxmox_virtual_environment_vm.unifi
  id = "prodingus/102"
}

import {
  to = proxmox_virtual_environment_container.openclaw
  id = "prodingus/103"
}

import {
  to = proxmox_virtual_environment_container.timemachine
  id = "prodingus/104"
}

import {
  to = proxmox_virtual_environment_container.mastodon
  id = "prodingus/105"
}

import {
  to = proxmox_virtual_environment_container.procontainer
  id = "prodingus/106"
}

import {
  to = proxmox_virtual_environment_vm.matrix
  id = "prodingus/107"
}

import {
  to = proxmox_virtual_environment_vm.arawi
  id = "prodingus/108"
}

import {
  to = proxmox_virtual_environment_vm.authentik
  id = "prodingus/109"
}

import {
  to = proxmox_virtual_environment_vm.git
  id = "prodingus/110"
}

import {
  to = proxmox_virtual_environment_vm.urbackup
  id = "prodingus/111"
}

import {
  to = proxmox_virtual_environment_container.pihole
  id = "prodingus/112"
}

import {
  to = proxmox_virtual_environment_vm.freeipa
  id = "prodingus/113"
}

import {
  to = proxmox_virtual_environment_vm.softether
  id = "prodingus/114"
}

import {
  to = proxmox_virtual_environment_container.openwebui
  id = "prodingus/115"
}

import {
  to = proxmox_virtual_environment_container.immich
  id = "prodingus/116"
}

import {
  to = proxmox_virtual_environment_container.uptime
  id = "prodingus/117"
}

import {
  to = proxmox_virtual_environment_container.cordpepperer
  id = "prodingus/118"
}

import {
  to = proxmox_virtual_environment_container.llamarpcmaster
  id = "prodingus/119"
}

import {
  to = proxmox_virtual_environment_container.pterodactyl
  id = "prodingus/120"
}

import {
  to = proxmox_virtual_environment_container.ingress
  id = "prodingus/121"
}

import {
  to = proxmox_virtual_environment_container.tailscalerouter
  id = "prodingus/122"
}

import {
  to = proxmox_virtual_environment_container.act
  id = "prodingus/123"
}

import {
  to = proxmox_virtual_environment_container.tsexit
  id = "prodingus/124"
}

import {
  to = proxmox_virtual_environment_container.ncsusplitt
  id = "prodingus/125"
}

import {
  to = proxmox_virtual_environment_container.peppercord
  id = "prodingus/126"
}

import {
  to = proxmox_virtual_environment_container.tvheadend
  id = "prodingus/127"
}

import {
  to = proxmox_virtual_environment_container.vaultwarden
  id = "prodingus/128"
}

import {
  to = proxmox_virtual_environment_vm.vkasm
  id = "prodingus/129"
}

import {
  to = proxmox_virtual_environment_container.aameter
  id = "prodingus/130"
}

import {
  to = proxmox_virtual_environment_vm.resolute_template
  id = "prodingus/8000"
}

# --- Guest firewalls --------------------------------------------------------

import {
  to = proxmox_virtual_environment_firewall_options.aboriginal
  id = "vm/prodingus/100"
}

# --- High availability ------------------------------------------------------

import {
  to = proxmox_haresource.unifi
  id = "vm:102"
}

import {
  to = proxmox_haresource.openclaw
  id = "ct:103"
}

import {
  to = proxmox_haresource.timemachine
  id = "ct:104"
}

import {
  to = proxmox_haresource.mastodon
  id = "ct:105"
}

import {
  to = proxmox_haresource.matrix
  id = "vm:107"
}

import {
  to = proxmox_haresource.arawi
  id = "vm:108"
}

import {
  to = proxmox_haresource.authentik
  id = "vm:109"
}

import {
  to = proxmox_haresource.git
  id = "vm:110"
}

import {
  to = proxmox_haresource.urbackup
  id = "vm:111"
}

import {
  to = proxmox_haresource.pihole
  id = "ct:112"
}

import {
  to = proxmox_haresource.freeipa
  id = "vm:113"
}

import {
  to = proxmox_haresource.softether
  id = "vm:114"
}

import {
  to = proxmox_haresource.openwebui
  id = "ct:115"
}

import {
  to = proxmox_haresource.immich
  id = "ct:116"
}

import {
  to = proxmox_haresource.uptime
  id = "ct:117"
}

import {
  to = proxmox_haresource.cordpepperer
  id = "ct:118"
}

import {
  to = proxmox_haresource.llamarpcmaster
  id = "ct:119"
}

import {
  to = proxmox_haresource.pterodactyl
  id = "ct:120"
}

import {
  to = proxmox_haresource.ingress
  id = "ct:121"
}

import {
  to = proxmox_haresource.tailscalerouter
  id = "ct:122"
}

import {
  to = proxmox_haresource.act
  id = "ct:123"
}

import {
  to = proxmox_haresource.tsexit
  id = "ct:124"
}

import {
  to = proxmox_haresource.ncsusplitt
  id = "ct:125"
}

import {
  to = proxmox_haresource.peppercord
  id = "ct:126"
}

import {
  to = proxmox_haresource.tvheadend
  id = "ct:127"
}

import {
  to = proxmox_haresource.vaultwarden
  id = "ct:128"
}

import {
  to = proxmox_haresource.aameter
  id = "ct:130"
}

import {
  to = proxmox_harule.freeipa_on_prodingus
  id = "ha-rule-3da3198c-de3b"
}

import {
  to = proxmox_harule.uptime_on_jondingus
  id = "ha-rule-157366ac-952c"
}

# --- Datacenter -------------------------------------------------------------

import {
  to = proxmox_cluster_options.cluster
  id = "cluster"
}

import {
  to = proxmox_custom_cpu_model.ryzen_vermeer_v3
  id = "RYZEN-Vermeer-v3"
}

import {
  to = proxmox_virtual_environment_cluster_firewall.cluster
  id = "cluster"
}

# --- Storage ----------------------------------------------------------------

import {
  to = proxmox_storage_directory.local
  id = "local"
}

import {
  to = proxmox_storage_lvmthin.local_lvm
  id = "local-lvm"
}

import {
  to = proxmox_storage_rbd.rbd
  id = "rbd"
}

import {
  to = proxmox_storage_rbd.rbd_cmr
  id = "rbd_cmr"
}

import {
  to = proxmox_storage_cephfs.cephfs
  id = "cephfs"
}

# --- Ceph -------------------------------------------------------------------

import {
  to = proxmox_ceph_pool.rbd_ssd
  id = "prodingus/rbd_ssd"
}

import {
  to = proxmox_ceph_pool.rbd_cmr
  id = "prodingus/rbd_cmr"
}

import {
  to = proxmox_ceph_fs.cephfs
  id = "prodingus/cephfs"
}

import {
  to = proxmox_ceph_mds.prodingus
  id = "prodingus/prodingus"
}

import {
  to = proxmox_ceph_mds.prodingus1
  id = "prodingus/prodingus1"
}

import {
  to = proxmox_ceph_mds.prodingus2
  id = "prodingus/prodingus2"
}

# --- Resource mappings ------------------------------------------------------

import {
  to = proxmox_hardware_mapping_pci.ax200
  id = "AX200"
}

import {
  to = proxmox_hardware_mapping_pci.rx6800
  id = "RX6800"
}

import {
  to = proxmox_hardware_mapping_usb.back_ups
  id = "Back-UPS"
}

import {
  to = proxmox_hardware_mapping_usb.ax200
  id = "AX200"
}

import {
  to = proxmox_hardware_mapping_usb.cps
  id = "CPS"
}

import {
  to = proxmox_hardware_mapping_usb.tubeszb
  id = "TubesZB"
}

import {
  to = proxmox_hardware_mapping_dir.cephfs
  id = "cephfs"
}

# --- Backup -----------------------------------------------------------------

import {
  to = proxmox_backup_job.weekly
  id = "backup-1599bab8-f41c"
}

# --- Access -----------------------------------------------------------------

import {
  to = proxmox_realm_ldap.home_arpa
  id = "home.arpa"
}

import {
  to = proxmox_acl.admins_administrator
  id = "/?admins-home.arpa?Administrator"
}
