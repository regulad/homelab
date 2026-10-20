# arawi: VM 108 and its HA resource.

resource "proxmox_virtual_environment_vm" "arawi" {
  # The snippet IDs below are written out; this keeps the files ahead of the guest.
  depends_on = [proxmox_virtual_environment_file.block_mac_108]

  name                = "arawi"
  vm_id               = 108
  node_name           = "prodingus"
  description         = "`vtnet1` is a dummy interface, because pfSense will freak out if the interface assigned to be WAN is NO-CARRIER. Nothing is attached to VLAN 4093."
  on_boot             = false
  boot_order          = ["virtio0", "net0"]
  hook_script_file_id = "cephfs:snippets/block-mac-108.sh"
  kvm_arguments       = "-device ipmi-bmc-sim,id=bmc0 -device isa-ipmi-kcs,bmc=bmc0"
  machine             = "q35"
  scsi_hardware       = "virtio-scsi-single"

  network_device {
    mac_address = "BC:24:11:AF:E1:CF"
    mtu         = 9000
  }

  network_device {
    mac_address = "BC:24:11:42:3A:8E"
    mtu         = 9000
    vlan_id     = 4093
  }

  network_device {
    mac_address = "BC:24:11:08:E4:E8"
    mtu         = 9000
    vlan_id     = 1
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
    datastore_id      = "rbd"
    discard           = "on"
    file_format       = "raw"
    interface         = "virtio0"
    iothread          = true
    path_in_datastore = "vm-108-disk-2"
    size              = 32
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
