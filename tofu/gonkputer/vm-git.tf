# git: VM 110 and its HA resource.

resource "proxmox_virtual_environment_vm" "git" {
  name      = "git"
  vm_id     = 110
  node_name = "prodingus"
  description = chomp(<<EOT
⚠️ USES EARLYOOM

MAINTAINENCE TASKS AT 4:55

## Update History

1. Oracle Linux 8.10
2. Alma Linux 8.10
3. Alma Linux 9.7
4. Alma Linux 10.1
EOT
  )
  tags          = ["rhel"]
  protection    = true
  bios          = "ovmf"
  boot_order    = ["virtio0"]
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  network_device {
    firewall    = true
    mac_address = "BC:24:11:1D:D0:17"
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
    path_in_datastore = "vm-110-disk-2"
    size              = 46
  }

  efi_disk {
    datastore_id      = "rbd"
    file_format       = "raw"
    pre_enrolled_keys = true
    type              = "4m"
  }

  memory {
    dedicated = 8192
    floating  = 4096
  }

  operating_system {
    type = "l26"
  }

  rng {
    source = "/dev/urandom"
  }

  serial_device {}

  tpm_state {
    datastore_id = "rbd"
  }

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

resource "proxmox_haresource" "git" {
  resource_id = "vm:${proxmox_virtual_environment_vm.git.vm_id}"
  type        = "vm"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
