# i2p: container, its HA resource and its Ansible host: i2pd, an I2P router
# whose SAM bridge serves the qBittorrents on the LAN as i2p.regulad.internal.
# Its router identity and network database are its own, made at first start.

locals {
  # The port both of I2P's transports listen on, NTCP2 over TCP and SSU2 over
  # UDP; Ansible writes it into i2pd's configuration from the Ansible host.
  i2p_transport_port = "27656"
}

resource "proxmox_virtual_environment_container" "i2p" {
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
    hostname = "i2p"

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

resource "proxmox_haresource" "i2p" {
  resource_id = "ct:${proxmox_virtual_environment_container.i2p.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: SAM from the LAN alone, I2P's transports from anywhere, and the CR1000B's
# UPnP answers.
resource "proxmox_virtual_environment_firewall_rules" "i2p" {
  node_name    = proxmox_virtual_environment_container.i2p.node_name
  container_id = proxmox_virtual_environment_container.i2p.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  # SAM has no authentication: whoever reaches it opens I2P destinations
  # through this router, so only the LAN may.
  rule {
    type   = "in"
    action = "ACCEPT"
    source = local.dual_stack_lan_cidrs.ipv4
    proto  = "tcp"
    dport  = "7656" # SAM
  }

  # Over IPv6, clients reach SAM on its GUA from theirs: the qBittorrents' musl
  # ranks a GUA above IPv4 and a ULA below both (RFC 6724), and the LAN's DNS
  # publishes guests' GUAs.
  rule {
    type   = "in"
    action = "ACCEPT"
    source = "${local.dual_stack_lan_cidrs.ipv6},${var.lan_ipv6_cidr}"
    proto  = "tcp"
    dport  = "7656" # SAM
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    proto  = "tcp"
    dport  = local.i2p_transport_port # NTCP2
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    proto  = "udp"
    dport  = local.i2p_transport_port # SSU2
  }

  # i2pd's UPnP asks the multicast group, and the CR1000B answers from its own
  # address, which conntrack does not match to the question.
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
resource "proxmox_virtual_environment_firewall_options" "i2p" {
  node_name     = proxmox_virtual_environment_container.i2p.node_name
  container_id  = proxmox_virtual_environment_container.i2p.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.i2p]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "i2p" {
  count = proxmox_haresource.i2p.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_container.i2p.initialization[0].hostname}.${local.guest_domain}"
  groups = ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"]

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.i2p.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.i2p.vm_id
    # For i2pd's configuration, which listens where the firewall admits.
    i2pd_port = local.i2p_transport_port
  }
}
