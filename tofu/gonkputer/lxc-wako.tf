# wako: container, its HA resource and its Ansible host: FreeIPA for
# regulad.internal (realm REGULAD.INTERNAL), replacing the freeipa VM
# (vm-freeipa.tf). AlmaLinux, since Ubuntu ships no FreeIPA server.

resource "proxmox_virtual_environment_container" "wako" {
  node_name = "prodingus"
  # HA starts the container, not Proxmox's own start on boot.
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 2
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
    hostname = "wako"

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
    dedicated = 4096
    swap      = 1048576 # 1 TiB in MiB: effectively unlimited swap
  }

  network_interface {
    firewall = true
    name     = "eth0"
    vlan_id  = 1
  }

  operating_system {
    template_file_id = "cephfs:vztmpl/almalinux-10-default_20250930_amd64.tar.xz"
    # Proxmox's type for the CentOS family, AlmaLinux included.
    type = "centos"
  }

  depends_on = [proxmox_download_file.almalinux_10_default]
}

resource "proxmox_haresource" "wako" {
  resource_id = "ct:${proxmox_virtual_environment_container.wako.vm_id}"
  type        = "ct"
  state       = "started"
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "wako" {
  count = proxmox_haresource.wako.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_container.wako.initialization[0].hostname}.${local.guest_domain}"
  groups = ["freeipa_servers", "freeradius_servers", "gonkputer", "proxmox_containers", "rhel"]

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the
  # container. arawi's DHCP static mapping reads the MAC Proxmox generated.
  variables = {
    ansible_host     = var.node_ssh_addresses[proxmox_virtual_environment_container.wako.node_name]
    proxmox_vmid     = proxmox_virtual_environment_container.wako.vm_id
    eth0_mac_address = lower(proxmox_virtual_environment_container.wako.network_interface[0].mac_address)
  }
}
