# tailscalerouter: container 122, its HA resource and its Ansible host.

resource "proxmox_virtual_environment_container" "tailscalerouter" {
  node_name     = "prodingus"
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.terraform]

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
    mount_options = ["discard", "lazytime"]
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

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "tailscalerouter" {
  count = proxmox_haresource.tailscalerouter.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_container.tailscalerouter.initialization[0].hostname}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_containers", "ubuntu"]

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.tailscalerouter.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.tailscalerouter.vm_id
  }
}
