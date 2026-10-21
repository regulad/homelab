# procontainer: container 106 and its Ansible host.

resource "proxmox_virtual_environment_container" "procontainer" {
  node_name = "prodingus"
  tags      = [local.tags.amd64v3, local.tags.locally_backed, local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 2
  }

  disk {
    datastore_id  = "local-lvm"
    mount_options = ["discard", "lazytime"]
    size          = 128
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "procontainer"

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "auto"
      }
    }
  }

  memory {
    dedicated = 2048
    swap      = 1048576
  }

  network_interface {
    mac_address = "BC:24:11:95:F6:CD"
    name        = "eth0"
    vlan_id     = 1
  }

  operating_system {
    template_file_id = ""
    type             = "ubuntu"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# No HA resource, so listed in the Ansible inventory while it starts on boot.
resource "ansible_host" "procontainer" {
  count = proxmox_virtual_environment_container.procontainer.start_on_boot ? 1 : 0

  name   = "${proxmox_virtual_environment_container.procontainer.initialization[0].hostname}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_containers", "ubuntu"]

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.procontainer.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.procontainer.vm_id
  }
}
