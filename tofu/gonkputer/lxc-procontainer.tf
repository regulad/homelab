# procontainer: container 106.

resource "proxmox_virtual_environment_container" "procontainer" {
  vm_id       = 106
  node_name   = "prodingus"
  description = "amd64v3\n"
  tags        = ["locally-backed"]

  console {}

  cpu {
    limit = 2
  }

  disk {
    datastore_id  = "local-lvm"
    mount_options = ["discard", "noatime"]
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
