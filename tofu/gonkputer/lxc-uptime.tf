# uptime: container 117, its HA resource, its firewall and its Ansible host.

resource "proxmox_virtual_environment_container" "uptime" {
  node_name     = "prodingus"
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.amd64v3, local.tags.terraform]

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
    hostname = "uptime"

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
    mac_address = "BC:24:11:3E:A1:A5"
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

resource "proxmox_haresource" "uptime" {
  resource_id = "ct:${proxmox_virtual_environment_container.uptime.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# In: Uptime Kuma from ingress alone (uptime.regulad.xyz), and UDP from
# anywhere, for tailscaled's NAT traversal.
resource "proxmox_virtual_environment_firewall_rules" "uptime" {
  node_name    = proxmox_virtual_environment_container.uptime.node_name
  container_id = proxmox_virtual_environment_container.uptime.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    source = local.ingress_ipv4
    proto  = "tcp"
    dport  = "3001" # Uptime Kuma
  }

  # UDP, for tailscaled's NAT traversal, and mDNS, which systemd-resolved
  # resolves and answers here (resolved role).
  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.udp.name
  }
}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "uptime" {
  node_name     = proxmox_virtual_environment_container.uptime.node_name
  container_id  = proxmox_virtual_environment_container.uptime.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.uptime]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "uptime" {
  count = proxmox_haresource.uptime.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.uptime.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.uptime.tags, local.ansible_group_tags),
    [proxmox_virtual_environment_container.uptime.unprivileged ? "unprivileged_containers" : "privileged_containers"],
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.uptime.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.uptime.vm_id
  }
}
