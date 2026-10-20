# vkasm: VM 129.

resource "proxmox_virtual_environment_vm" "vkasm" {
  name       = "vkasm"
  vm_id      = 129
  node_name  = "prodingus"
  boot_order = ["scsi0"]
  # Proxmox's default, written out: the provider's own default is virtio-scsi-pci.
  scsi_hardware = "lsi"

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
    file_format       = "raw"
    interface         = "scsi0"
    path_in_datastore = "vm-129-disk-0"
    size              = 200
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
