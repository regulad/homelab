# vaultwarden: container 128, its HA resource and its Ansible host.

resource "proxmox_virtual_environment_container" "vaultwarden" {
  node_name     = "prodingus"
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.amd64v3, local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 1
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
    hostname = "vaultwarden"

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
    swap = 1048576 # 1 TiB in MiB: effectively unlimited swap
  }

  network_interface {
    firewall    = true
    mac_address = "BC:24:11:81:6C:A0"
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

resource "proxmox_haresource" "vaultwarden" {
  resource_id = "ct:${proxmox_virtual_environment_container.vaultwarden.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "vaultwarden" {
  count = proxmox_haresource.vaultwarden.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.vaultwarden.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.vaultwarden.tags, local.ansible_group_tags),
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.vaultwarden.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.vaultwarden.vm_id
  }
}
