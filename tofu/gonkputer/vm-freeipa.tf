# freeipa: VM 113 and its HA resource.

resource "proxmox_virtual_environment_vm" "freeipa" {
  name          = "freeipa"
  node_name     = "prodingus"
  protection    = true
  bios          = "ovmf"
  boot_order    = ["virtio0"]
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  tags          = [local.tags.rhel, local.tags.terraform]

  network_device {
    firewall    = true
    mac_address = "BC:24:11:7D:6F:9B"
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
    units = 200
  }

  disk {
    datastore_id = "rbd"
    discard      = "on"
    interface    = "virtio0"
    iothread     = true
    size         = 10
  }

  efi_disk {
    datastore_id      = "rbd"
    pre_enrolled_keys = true
    type              = "4m"
  }

  initialization {
    datastore_id = ""
    upgrade      = true

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "dhcp"
      }
    }

    user_account {
      keys     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBpJLGTbli8J2qSzPVpBzeNpVLLMakYeREp8jRkAePuMfMcNMcSNOcPyq+MXhdZc2npKPaZgeZj1w5mQIA4I0M+yhkduWYAwg8utchrqloVGd7NDd+BphSDJ8u/4S3J0iPEj1tsmdE2PJKm7CX6jzoSS7sQwE56HgjN/9Qsc+vsndpLPb0dnepCycuJ9SnfQrK4LMLjAzGsPyM8mpmG10mzS4RNmeF2Wqs/qHGKT1jXFSAUUlpQUSvUgaP0M3UJjYclSp84S3bxEGVzl0Os1l0YQeA1iKLZlzURhE/IiRQdNgI36hTfPeTx0TE2Uw8KOla6xcyijvIWJyPAChqdC42vIIEXtZ52cFDj0mlXjcXTPxBzVMZuusakzzReol6j12nXahy9OTW9feMnRnQSAN9xXLBZjiLpAeYJlggjdscvmjYgp3AkJBNMBTi7ECOsNBr0VMtU+l/ULf2KqwTdd6fzC/AnTIZOSXj2TtOxvM4Vn6lHEKWB8nxFOG1uU5I/xE= regulad@github/102565467 # ssh-import-id gh:regulad"]
      username = "regulad"
    }
  }

  memory {
    dedicated = 8192
  }

  operating_system {
    type = "l26"
  }

  rng {
    source = "/dev/urandom"
  }

  serial_device {}

  startup {
    order = 2
  }

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

resource "proxmox_haresource" "freeipa" {
  resource_id = "vm:${proxmox_virtual_environment_vm.freeipa.vm_id}"
  type        = "vm"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
