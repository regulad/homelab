# openwebui: container 115, its HA resource and its Ansible host.

resource "proxmox_virtual_environment_container" "openwebui" {
  node_name     = "prodingus"
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.amd64v3, local.tags.terraform]

  console {}

  device_passthrough {
    path = "/dev/net/tun"
  }

  cpu {
    cores = local.cpu_threads
    limit = 1
  }

  disk {
    datastore_id  = "rbd"
    mount_options = ["discard", "noatime"]
    size          = 16
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "openwebui"

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
    swap = 1048576
  }

  network_interface {
    firewall    = true
    mac_address = "BC:24:11:16:5D:C6"
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

resource "proxmox_haresource" "openwebui" {
  resource_id = "ct:${proxmox_virtual_environment_container.openwebui.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "openwebui" {
  count = proxmox_haresource.openwebui.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_container.openwebui.initialization[0].hostname}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_containers"]
}
