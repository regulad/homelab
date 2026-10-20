# timemachine: container 104 and its HA resource.

resource "proxmox_virtual_environment_container" "timemachine" {
  vm_id         = 104
  node_name     = "prodingus"
  description   = "amd64v3\n"
  tags          = ["virtiofsd"]
  start_on_boot = false

  console {}

  cpu {
    cores = 2
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
    hostname = "timemachine"

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

  mount_point {
    path   = "/mnt/cephfs"
    shared = true
    volume = "/mnt/pve/cephfs"
  }

  network_interface {
    firewall    = true
    mac_address = "BC:24:11:56:66:C3"
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

resource "proxmox_haresource" "timemachine" {
  resource_id = "ct:${proxmox_virtual_environment_container.timemachine.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
