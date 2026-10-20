# llamarpcmaster: container 119 and its HA resource.

resource "proxmox_virtual_environment_container" "llamarpcmaster" {
  node_name = "prodingus"
  started   = false
  tags      = [local.tags.terraform, local.tags.virtiofsd]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 4
  }

  disk {
    datastore_id = "rbd"
    size         = 64
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "llamarpcmaster"

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
    path   = "/mnt/cephfs"
    shared = true
    volume = "/mnt/pve/cephfs"
  }

  network_interface {
    firewall    = true
    mac_address = "BC:24:11:13:9C:6A"
    name        = "eth0"
    vlan_id     = 1
  }

  operating_system {
    template_file_id = ""
    type             = "ubuntu"
  }

  startup {
    up_delay = 180
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_haresource" "llamarpcmaster" {
  resource_id = "ct:${proxmox_virtual_environment_container.llamarpcmaster.vm_id}"
  type        = "ct"
  state       = "stopped"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
