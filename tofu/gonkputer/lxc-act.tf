# act: container 123, its HA resource and its Ansible host.

resource "proxmox_virtual_environment_container" "act" {
  node_name     = "prodingus"
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 4
  }

  disk {
    datastore_id  = "rbd"
    mount_options = ["discard", "lazytime"]
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
    mount_options = ["discard", "lazytime"]
    path          = "/mnt/cache"
    size          = "128G"
    volume        = "rbd:vm-123-disk-1"
  }

  mount_point {
    mount_options = ["discard", "lazytime"]
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

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "act" {
  count = proxmox_haresource.act.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_container.act.initialization[0].hostname}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_containers"]

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.act.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.act.vm_id
  }
}
