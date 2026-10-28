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

  tpm_state {
    datastore_id = "local-lvm"
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
    # FIXME: the provider puts a TPM on local-lvm at v2.0, its defaults, into
    # state only once state holds one, so it reads this one as absent, and
    # applying tpm_state could swap it for a new, empty TPM. Revisit once the
    # provider reads it, pending
    # https://github.com/bpg/terraform-provider-proxmox/issues/3229.
    ignore_changes = [tpm_state]
  }
}

# Listed in the Ansible inventory while it starts on boot. A quasi-hardware VM:
# first installed on hardware, then imaged into a VM, so Ansible configures it.
resource "ansible_host" "dodo" {
  count = proxmox_virtual_environment_vm.dodo.on_boot ? 1 : 0

  name = "${proxmox_virtual_environment_vm.dodo.name}.${local.guest_domain}"
  # The watchdog group, for the watchdog daemon, follows the VM's watchdog device.
  groups = sort(concat(
    ["certbot", "docker_hosts", "gonkputer", "kdump", "podman_hosts", "proxmox_vms", "ubuntu", "wings"],
    [for device in proxmox_virtual_environment_vm.dodo.watchdog : "watchdog" if device.enabled],
  ))

  # For its netplan configuration, which matches eth0 by MAC address.
  variables = {
    eth0_mac_address = lower(proxmox_virtual_environment_vm.dodo.network_device[0].mac_address)
  }
}
