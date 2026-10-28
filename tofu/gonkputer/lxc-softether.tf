# softether: container, its HA resource and its Ansible host: SoftEther VPN
# Server, whose one hub is a local bridge onto VLAN 1, so VPN clients appear on
# the LAN as hosts of their own. The bridge is a packet socket in promiscuous
# mode on eth0, which container root may open on its own veth, so it needs no
# tun device, kernel module or privilege. It took over the softether VM's MAC
# address, and with it the VM's IPv6 addresses.

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
    # Off, as its firewall options say why.
    firewall = false
    # The softether VM's, so its SLAAC addresses followed.
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

resource "proxmox_haresource" "softether" {
  resource_id = "ct:${proxmox_virtual_environment_container.softether.vm_id}"
  type        = "ct"
  state       = "started"
}

# Disabled, and bypassed anyway: net0 has no firewall flag. The hub bridges the
# VPN clients onto VLAN 1 through this NIC, so a guest firewall would filter
# their traffic as the container's own, its MAC filter would drop their frames,
# and SoftEther's NAT traversal answers on random UDP ports no rule can name. The
# clients are LAN hosts, behind arawi like the rest. The other options repeat
# Proxmox's effective defaults, because the provider's own ndp and radv
# defaults differ.
resource "proxmox_virtual_environment_firewall_options" "softether" {
  node_name     = proxmox_virtual_environment_container.softether.node_name
  container_id  = proxmox_virtual_environment_container.softether.vm_id
  enabled       = false
  dhcp          = true
  input_policy  = "DROP"
  log_level_in  = "nolog"
  log_level_out = "nolog"
  macfilter     = true
  ndp           = true
  output_policy = "ACCEPT"
  radv          = false
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "softether" {
  count = proxmox_haresource.softether.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_container.softether.initialization[0].hostname}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_containers", "softether_servers", "ubuntu"]

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.softether.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.softether.vm_id
  }
}
