# git: VM 110, its HA resource and its Ansible host.

resource "proxmox_virtual_environment_vm" "git" {
  name      = "git"
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
  protection    = true
  bios          = "ovmf"
  boot_order    = ["virtio0"]
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  tags          = [local.tags.rhel, local.tags.terraform]

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
    datastore_id = "rbd"
    discard      = "on"
    interface    = "virtio0"
    iothread     = true
    size         = 46
  }

  efi_disk {
    datastore_id      = "rbd"
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

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "git" {
  count = proxmox_haresource.git.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_vm.git.name}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_vms"]
}
