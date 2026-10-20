# cordpepperer: container 118 and its HA resource.

resource "proxmox_virtual_environment_container" "cordpepperer" {
  vm_id         = 118
  node_name     = "prodingus"
  description   = "amd64v3\n"
  start_on_boot = false
  unprivileged  = true

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
    hostname = "cordpepperer"

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
    mac_address = "BC:24:11:6D:6F:D5"
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

resource "proxmox_haresource" "cordpepperer" {
  resource_id = "ct:${proxmox_virtual_environment_container.cordpepperer.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
