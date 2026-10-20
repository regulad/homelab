# openwebui: container 115 and its HA resource.

resource "proxmox_virtual_environment_container" "openwebui" {
  vm_id         = 115
  node_name     = "prodingus"
  description   = "amd64v3\n"
  start_on_boot = false
  unprivileged  = true

  console {}

  device_passthrough {
    path = "/dev/net/tun"
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
