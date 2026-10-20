# urbackup: VM 111, its HA resource and its Ansible host.

resource "proxmox_virtual_environment_vm" "urbackup" {
  # The snippet IDs below are written out; this keeps the files ahead of the guest.
  depends_on = [proxmox_virtual_environment_file.vendor]

  name          = "urbackup"
  node_name     = "prodingus"
  bios          = "ovmf"
  boot_order    = ["virtio0"]
  hotplug       = "disk,network,usb"
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  tags          = [local.tags.terraform]

  network_device {
    firewall    = true
    mac_address = "BC:24:11:84:09:81"
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
  }

  disk {
    datastore_id = "rbd"
    discard      = "on"
    interface    = "virtio0"
    iothread     = true
    size         = 100
  }

  disk {
    backup       = false
    datastore_id = "rbd_cmr"
    discard      = "on"
    interface    = "virtio1"
    iothread     = true
    size         = 3072
  }

  efi_disk {
    datastore_id      = "rbd"
    pre_enrolled_keys = true
    type              = "4m"
  }

  initialization {
    datastore_id        = ""
    upgrade             = true
    vendor_data_file_id = "local:snippets/vendor.yaml"

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "dhcp"
      }
    }

    user_account {
      keys     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBpJLGTbli8J2qSzPVpBzeNpVLLMakYeREp8jRkAePuMfMcNMcSNOcPyq+MXhdZc2npKPaZgeZj1w5mQIA4I0M+yhkduWYAwg8utchrqloVGd7NDd+BphSDJ8u/4S3J0iPEj1tsmdE2PJKm7CX6jzoSS7sQwE56HgjN/9Qsc+vsndpLPb0dnepCycuJ9SnfQrK4LMLjAzGsPyM8mpmG10mzS4RNmeF2Wqs/qHGKT1jXFSAUUlpQUSvUgaP0M3UJjYclSp84S3bxEGVzl0Os1l0YQeA1iKLZlzURhE/IiRQdNgI36hTfPeTx0TE2Uw8KOla6xcyijvIWJyPAChqdC42vIIEXtZ52cFDj0mlXjcXTPxBzVMZuusakzzReol6j12nXahy9OTW9feMnRnQSAN9xXLBZjiLpAeYJlggjdscvmjYgp3AkJBNMBTi7ECOsNBr0VMtU+l/ULf2KqwTdd6fzC/AnTIZOSXj2TtOxvM4Vn6lHEKWB8nxFOG1uU5I/xE="]
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

resource "proxmox_haresource" "urbackup" {
  resource_id = "vm:${proxmox_virtual_environment_vm.urbackup.vm_id}"
  type        = "vm"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "urbackup" {
  count = proxmox_haresource.urbackup.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_vm.urbackup.name}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_vms"]
}
