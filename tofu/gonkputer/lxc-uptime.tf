# uptime: container 117, its HA resource and its Ansible host.

resource "proxmox_virtual_environment_container" "uptime" {
  node_name     = "prodingus"
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.amd64v3, local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 2
  }

  device_passthrough {
    path = "/dev/net/tun"
  }

  disk {
    datastore_id  = "rbd"
    mount_options = ["discard", "noatime"]
    size          = 8
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "uptime"

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
    mac_address = "BC:24:11:3E:A1:A5"
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

resource "proxmox_haresource" "uptime" {
  resource_id = "ct:${proxmox_virtual_environment_container.uptime.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "uptime" {
  count = proxmox_haresource.uptime.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_container.uptime.initialization[0].hostname}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_containers"]
}
