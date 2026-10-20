# aameter: container 130 and its HA resource.

resource "proxmox_virtual_environment_container" "aameter" {
  vm_id         = 130
  node_name     = "prodingus"
  description   = "amd64v3\n"
  start_on_boot = false
  unprivileged  = true

  console {}

  cpu {
    cores = 2
    units = 1000
  }

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
    hostname = "aameter"

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
    firewall    = true
    mac_address = "BC:24:11:B3:83:A4"
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

resource "proxmox_haresource" "aameter" {
  resource_id = "ct:${proxmox_virtual_environment_container.aameter.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
