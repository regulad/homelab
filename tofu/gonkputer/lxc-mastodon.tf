# mastodon: container 105, its HA resource and its Ansible host.

resource "proxmox_virtual_environment_container" "mastodon" {
  node_name     = "prodingus"
  start_on_boot = false
  # Dormant: HA keeps it stopped.
  started      = false
  unprivileged = true
  tags         = [local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 4
  }

  disk {
    datastore_id  = "rbd"
    mount_options = ["discard", "lazytime"]
    size          = 64
  }

  features {
    keyctl  = true
    nesting = true
  }

  initialization {
    hostname = "mastodon"

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
    swap      = 1048576 # 1 TiB in MiB: effectively unlimited swap
  }

  network_interface {
    firewall    = true
    mac_address = "BC:24:11:A8:F1:4D"
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

resource "proxmox_haresource" "mastodon" {
  resource_id = "ct:${proxmox_virtual_environment_container.mastodon.vm_id}"
  type        = "ct"
  # Dormant: kept, but neither run nor restarted by HA.
  state = "disabled"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "mastodon" {
  count = proxmox_haresource.mastodon.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.mastodon.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.mastodon.tags, local.ansible_group_tags),
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.mastodon.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.mastodon.vm_id
  }
}
