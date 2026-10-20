# pihole: container 112 and its HA resource.

resource "proxmox_virtual_environment_container" "pihole" {
  vm_id         = 112
  node_name     = "prodingus"
  description   = "amd64v3\n"
  start_on_boot = false
  unprivileged  = true

  console {}

  cpu {
    cores = 2
    units = 10000
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
    hostname = "pihole"

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
    mac_address = "BC:24:11:C8:9B:09"
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

resource "proxmox_haresource" "pihole" {
  resource_id = "ct:${proxmox_virtual_environment_container.pihole.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
