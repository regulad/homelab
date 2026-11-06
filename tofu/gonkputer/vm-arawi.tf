# arawi: VM 108, its HA resource and its Ansible host.

locals {
  # arawi's own addresses on VLAN 1, by IP family, as its pfSense configuration
  # fixes them: the LAN interface's IPv4 and LAN2's ULA, whose suffix is net2's
  # MAC as an EUI-64. The LAN's hosts resolve through both.
  dual_stack_arawi_lan_addresses = {
    ipv4 = cidrhost(local.dual_stack_lan_cidrs.ipv4, 254)
    ipv6 = cidrhost(local.dual_stack_lan_cidrs.ipv6, parseint("be2411fffe08e4e8", 16))
  }
}

resource "proxmox_virtual_environment_vm" "arawi" {
  # The snippet IDs below are written out; this keeps the files ahead of the guest.
  depends_on = [proxmox_virtual_environment_file.block_mac_108]

  name                = "arawi"
  node_name           = "prodingus"
  description         = "`vtnet1` is a dummy interface, because pfSense will freak out if the interface assigned to be WAN is NO-CARRIER. Nothing is attached to VLAN 4093."
  on_boot             = false
  boot_order          = ["virtio0", "net0"]
  hook_script_file_id = "cephfs:snippets/block-mac-108.sh"
  kvm_arguments       = "-device ipmi-bmc-sim,id=bmc0 -device isa-ipmi-kcs,bmc=bmc0"
  machine             = "q35"
  scsi_hardware       = "virtio-scsi-single"
  tags                = [local.tags.terraform]

  network_device {
    mac_address = "BC:24:11:AF:E1:CF"
    mtu         = 9000
    # Bypasses the firewall: no firewall bridge for this NIC, nor the others.
    # pfSense filters what arawi routes; a guest firewall would filter it as
    # arawi's own traffic, drop its router advertisements unless radv were on,
    # and admit no DHCP requests to its server.
    firewall = false
  }

  network_device {
    mac_address = "BC:24:11:42:3A:8E"
    mtu         = 9000
    vlan_id     = 4093
    # Bypasses the firewall, as net0's comment says.
    firewall = false
  }

  network_device {
    mac_address = "BC:24:11:08:E4:E8"
    mtu         = 9000
    vlan_id     = 1
    # Bypasses the firewall, as net0's comment says.
    firewall = false
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    flags = []
    numa  = true
    type  = proxmox_custom_cpu_model.ryzen_vermeer_v3.cputype
    units = 10000
  }

  disk {
    datastore_id = "rbd"
    discard      = "on"
    interface    = "virtio0"
    iothread     = true
    size         = 32
  }

  memory {
    dedicated = 4096
  }

  serial_device {}

  startup {
    order    = 0
    up_delay = 240
  }

  vga {
    type = "serial0"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_haresource" "arawi" {
  resource_id = "vm:${proxmox_virtual_environment_vm.arawi.vm_id}"
  type        = "vm"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "arawi" {
  count = proxmox_haresource.arawi.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_vm.arawi.name}.${local.guest_domain}"
  groups = ["arawi", "freebsd", "gonkputer", "proxmox_vms"]
}
