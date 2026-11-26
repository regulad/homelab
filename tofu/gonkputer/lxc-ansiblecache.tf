# ansiblecache: the Valkey that holds ansible-generated's fact cache (its
# ansible.cfg), reached over the tailnet alone, with its HA resource, its
# firewall and its Ansible host.

resource "proxmox_virtual_environment_container" "ansiblecache" {
  node_name = "prodingus"
  # HA starts the container, not Proxmox's own start on boot.
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
    hostname = "ansiblecache"

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
    dedicated = 256
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
}

resource "proxmox_haresource" "ansiblecache" {
  resource_id = "ct:${proxmox_virtual_environment_container.ansiblecache.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: nothing but ping, tailscaled's UDP and mDNS. Valkey listens on loopback
# alone, and Tailscale Serve offers it to the tailnet over TLS, inside
# tailscaled's traffic.
resource "proxmox_virtual_environment_firewall_rules" "ansiblecache" {
  node_name    = proxmox_virtual_environment_container.ansiblecache.node_name
  container_id = proxmox_virtual_environment_container.ansiblecache.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
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
resource "proxmox_virtual_environment_firewall_options" "ansiblecache" {
  node_name     = proxmox_virtual_environment_container.ansiblecache.node_name
  container_id  = proxmox_virtual_environment_container.ansiblecache.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.ansiblecache]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "ansiblecache" {
  count = proxmox_haresource.ansiblecache.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.ansiblecache.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.ansiblecache.tags, local.ansible_group_tags),
    [proxmox_virtual_environment_container.ansiblecache.unprivileged ? "unprivileged_containers" : "privileged_containers"],
  ))

  # Reached through pct_ssh: SSH to the node, then lxc-attach into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.ansiblecache.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.ansiblecache.vm_id
  }
}
