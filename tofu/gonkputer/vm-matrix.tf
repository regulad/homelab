# matrix: VM 107 and its HA resource.

resource "proxmox_virtual_environment_vm" "matrix" {
  name      = "matrix"
  vm_id     = 107
  node_name = "prodingus"
  description = chomp(<<EOT
MAINTENANCE TASKS AT 5:45

Needs >6.00GiB

Because this image was taken from that weird Russian VPS website, it boots using MBR/BIOS instead of uEFI like the rest of the VMs on this host.

The next time Matrix needs to be reconfigured, a new VM needs to be made. There is too much weirdness on this one.
EOT
  )
  boot_order    = ["virtio0"]
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  network_device {
    firewall    = true
    mac_address = "BC:24:11:B3:AB:5D"
    vlan_id     = 1
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 4
    flags = []
    numa  = true
    type  = proxmox_custom_cpu_model.ryzen_vermeer_v3.cputype
  }

  disk {
    datastore_id      = "rbd"
    discard           = "on"
    file_format       = "raw"
    interface         = "virtio0"
    iothread          = true
    path_in_datastore = "vm-107-disk-1"
    size              = 100
  }

  disk {
    datastore_id      = "rbd"
    discard           = "on"
    file_format       = "raw"
    interface         = "virtio1"
    iothread          = true
    path_in_datastore = "vm-107-disk-0"
    size              = 100
  }

  memory {
    dedicated = 4096
  }

  operating_system {
    type = "l26"
  }

  rng {
    source = "/dev/urandom"
  }

  serial_device {}

  vga {
    type = "serial0"
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

resource "proxmox_haresource" "matrix" {
  resource_id = "vm:${proxmox_virtual_environment_vm.matrix.vm_id}"
  type        = "vm"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
