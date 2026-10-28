# git: container, its HA resource and its Ansible host: Forgejo and its Cloudflare
# tunnel, moved here from the git VM (vm-git.tf).

resource "proxmox_virtual_environment_container" "git" {
  node_name = "prodingus"
  # HA starts the container, not Proxmox's own start on boot.
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.amd64v3, local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 2
  }

  disk {
    datastore_id  = "rbd"
    mount_options = ["discard", "lazytime"]
    size          = 32
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "git"

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
    swap      = 1048576 # 1 TiB in MiB: effectively unlimited swap
  }

  network_interface {
    firewall = true
    # The git VM's, so the DHCP lease and git.regulad.internal follow it.
    mac_address = "BC:24:11:1D:D0:17"
    name        = "eth0"
    vlan_id     = 1
  }

  operating_system {
    template_file_id = "cephfs:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
    type             = "ubuntu"
  }
}

resource "proxmox_haresource" "git" {
  resource_id = "ct:${proxmox_virtual_environment_container.git.vm_id}"
  type        = "ct"
  state       = "started"
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "git" {
  count = proxmox_haresource.git.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.git.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.git.tags, local.ansible_group_tags),
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.git.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.git.vm_id
  }
}
