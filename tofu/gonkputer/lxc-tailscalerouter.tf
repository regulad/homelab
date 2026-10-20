# tailscalerouter: container 122 and its HA resource.

resource "proxmox_virtual_environment_container" "tailscalerouter" {
  vm_id         = 122
  node_name     = "prodingus"
  start_on_boot = false
  unprivileged  = true

  console {}

  cpu {
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
    hostname = "tailscalerouter"

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
    dedicated = 1024
    swap      = 1048576
  }

  network_interface {
    mac_address = "BC:24:11:53:2C:15"
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

resource "proxmox_haresource" "tailscalerouter" {
  resource_id = "ct:${proxmox_virtual_environment_container.tailscalerouter.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
