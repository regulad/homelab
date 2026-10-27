# softether: container, its HA resource and its Ansible host: SoftEther VPN
# Server, whose one hub is a local bridge onto VLAN 1, so VPN clients appear on
# the LAN as hosts of their own. The bridge is a packet socket in promiscuous
# mode on eth0, which container root may open on its own veth, so it needs no
# tun device, kernel module or privilege. It takes over the softether VM's MAC
# address, and with it the VM's address.

resource "proxmox_virtual_environment_container" "softether" {
  node_name = "prodingus"
  # HA starts the container, not Proxmox's own start on boot.
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.terraform]

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
    hostname = "softether"

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
    # Off: Proxmox's MAC filter would drop the frames of the VPN clients the
    # hub bridges onto the LAN, each with a MAC of its own.
    firewall = false
    # The softether VM's, so its address follows.
    mac_address = "BC:24:11:04:C4:A0"
    name        = "eth0"
    vlan_id     = 1
  }

  # Ubuntu 24.04, whose GCC 13 builds SoftEther 4.44 Stable as written: GCC 14
  # and later reject its C.
  operating_system {
    template_file_id = "cephfs:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  depends_on = [proxmox_download_file.ubuntu_24_04_standard]
}

# FIXME: labelled apart from the softether VM's HA resource while both guests
# exist. Revisit once the VM is destroyed: rename it softether, with a moved block.
resource "proxmox_haresource" "softether_container" {
  resource_id = "ct:${proxmox_virtual_environment_container.softether.vm_id}"
  type        = "ct"
  state       = "started"
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "softether" {
  count = proxmox_haresource.softether_container.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_container.softether.initialization[0].hostname}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_containers", "softether_servers", "ubuntu"]

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.softether.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.softether.vm_id
  }
}
