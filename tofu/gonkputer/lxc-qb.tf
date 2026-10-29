# qb: container, its HA resource and its Ansible host: qBittorrent, the lab's
# one BitTorrent client, saving into regulad's CephFS home and reaching I2P
# through i2p's SAM bridge. Its settings are state, seeded from qb-clearnet's.
# Its web UI is on the tailnet alone, through Tailscale Serve.

locals {
  # qBittorrent's listening port, for TCP and uTP; its settings hold it, and
  # Ansible passes it to the image's first start.
  qb_torrent_port = "26975"
}

resource "proxmox_virtual_environment_container" "qb" {
  node_name = "prodingus"
  # HA starts the container, not Proxmox's own start on boot.
  start_on_boot = false
  # Privileged, so its downloads on CephFS belong to regulad (UID 1000), as
  # Samba serves them; the lxc_guest role removes AppArmor, which a privileged
  # container cannot run.
  tags = [local.tags.amd64v3, local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 2
  }

  # For tailscaled.
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
    hostname = "qb"

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

  # The downloads directory alone, rather than all of CephFS: qBittorrent
  # faces the internet, and the rest of regulad's home is none of its business.
  mount_point {
    path   = "/mnt/cephfs/homes/regulad/downloads"
    shared = true
    volume = "/mnt/pve/cephfs/homes/regulad/downloads"
  }

  network_interface {
    firewall = true
    name     = "eth0"
    vlan_id  = 1
  }

  operating_system {
    template_file_id = "cephfs:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
    type             = "ubuntu"
  }

  depends_on = [proxmox_download_file.ubuntu_26_04_standard]
}

resource "proxmox_haresource" "qb" {
  resource_id = "ct:${proxmox_virtual_environment_container.qb.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: the torrent port from anywhere, and the CR1000B's UPnP answers, which map
# it on IPv4. The firewall sees eth0 alone, so the web UI, served on
# tailscale0, needs no rule.
resource "proxmox_virtual_environment_firewall_rules" "qb" {
  node_name    = proxmox_virtual_environment_container.qb.node_name
  container_id = proxmox_virtual_environment_container.qb.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    proto  = "tcp"
    dport  = local.qb_torrent_port # BitTorrent
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    proto  = "udp"
    dport  = local.qb_torrent_port # uTP and DHT
  }

  # qBittorrent's UPnP asks the multicast group, and the CR1000B answers from
  # its own address, which conntrack does not match to the question.
  rule {
    type   = "in"
    action = "ACCEPT"
    source = "10.23.0.1" # The CR1000B
    proto  = "udp"
    sport  = "1900" # SSDP
  }
}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "qb" {
  node_name     = proxmox_virtual_environment_container.qb.node_name
  container_id  = proxmox_virtual_environment_container.qb.vm_id
  enabled       = true
  dhcp          = true
  input_policy  = "DROP"
  ipfilter      = false
  log_level_in  = "nolog"
  log_level_out = "nolog"
  macfilter     = true
  ndp           = true
  output_policy = "ACCEPT"
  radv          = false

  depends_on = [proxmox_virtual_environment_firewall_rules.qb]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "qb" {
  count = proxmox_haresource.qb.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.qb.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.qb.tags, local.ansible_group_tags),
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.qb.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.qb.vm_id
    # For the image's first start, which writes it into the settings.
    qbittorrent_torrent_port = local.qb_torrent_port
  }
}
