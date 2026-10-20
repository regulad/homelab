# dodo: VM 101.

resource "proxmox_virtual_environment_vm" "dodo" {
  # The snippet IDs below are written out; this keeps the files ahead of the guest.
  depends_on = [proxmox_virtual_environment_file.hook_101]

  name                = "dodo"
  node_name           = "prodingus"
  description         = "MAINTENANCE TASKS AT 5:15"
  bios                = "ovmf"
  hook_script_file_id = "local:snippets/101.sh"
  hotplug             = "disk,network,usb"
  machine             = "q35"
  scsi_hardware       = "virtio-scsi-single"
  tags                = [local.tags.locally_backed, local.tags.terraform]

  network_device {
    mac_address = "BC:24:11:0B:76:9E"
    vlan_id     = 1
    # Bypasses the firewall: no firewall bridge for this NIC.
    firewall = false
  }

  agent {
    enabled = true
  }

  cpu {
    affinity = "12-15,28-31"
    cores    = 8
    flags    = []
    numa     = true
    type     = "host"
    units    = 1000
  }

  disk {
    datastore_id = ""
    discard      = "on"
    interface    = "virtio0"
    iothread     = true
    size         = 238
  }

  efi_disk {
    pre_enrolled_keys = true
    type              = "4m"
  }

  memory {
    dedicated      = 32768
    hugepages      = "1024"
    keep_hugepages = true
  }

  operating_system {
    type = "l26"
  }

  rng {
    source = "/dev/urandom"
  }

  startup {
    order    = 1
    up_delay = 120
  }

  vga {
    type = "virtio-gl"
  }

  watchdog {
    action  = "reset"
    enabled = true
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
