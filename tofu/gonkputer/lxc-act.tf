# act: container 123 and its HA resource.

resource "proxmox_virtual_environment_container" "act" {
  vm_id         = 123
  node_name     = "prodingus"
  start_on_boot = false
  unprivileged  = true

  console {}

  cpu {
    limit = 4
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
    hostname = "act"

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

  mount_point {
    mount_options = ["discard", "noatime"]
    path          = "/mnt/cache"
    size          = "128G"
    volume        = "rbd:vm-123-disk-1"
  }

  mount_point {
    mount_options = ["discard", "noatime"]
    path          = "/mnt/docker"
    size          = "128G"
    volume        = "rbd:vm-123-disk-2"
  }

  network_interface {
    firewall    = true
    mac_address = "BC:24:11:3A:35:3E"
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

resource "proxmox_haresource" "act" {
  resource_id = "ct:${proxmox_virtual_environment_container.act.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
