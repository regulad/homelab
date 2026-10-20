# vkasm: VM 129 and its Ansible host.

resource "proxmox_virtual_environment_vm" "vkasm" {
  name       = "vkasm"
  node_name  = "prodingus"
  boot_order = ["scsi0"]
  # Proxmox's default, written out: the provider's own default is virtio-scsi-pci.
  scsi_hardware = "lsi"
  tags          = [local.tags.terraform]

  network_device {
    mac_address = "BC:24:11:01:36:F9"
    model       = "vmxnet3"
    vlan_id     = 1
  }

  cpu {
    cores = 4
    flags = []
    type  = proxmox_custom_cpu_model.ryzen_vermeer_v3.cputype
  }

  disk {
    interface = "scsi0"
    size      = 200
  }

  memory {
    dedicated = 8192
  }

  operating_system {
    type = "l26"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# No HA resource, so listed in the Ansible inventory while it starts on boot.
resource "ansible_host" "vkasm" {
  count = proxmox_virtual_environment_vm.vkasm.on_boot ? 1 : 0

  name   = "${proxmox_virtual_environment_vm.vkasm.name}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_vms"]
}
