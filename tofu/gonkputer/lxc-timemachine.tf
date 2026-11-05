# timemachine: container 104, its HA resource, its firewall and its Ansible host.

resource "proxmox_virtual_environment_container" "timemachine" {
  node_name     = "prodingus"
  start_on_boot = false
  tags          = [local.tags.amd64v3, local.tags.terraform, local.tags.virtiofsd]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 2
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
    hostname = "timemachine"

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

  mount_point {
    path   = "/mnt/cephfs"
    shared = true
    volume = "/mnt/pve/cephfs"
  }

  network_interface {
    firewall    = true
    mac_address = "BC:24:11:56:66:C3"
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

resource "proxmox_haresource" "timemachine" {
  resource_id = "ct:${proxmox_virtual_environment_container.timemachine.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# In: SMB from the homelab's own ranges, for Time Machine. Not nmbd's NetBIOS
# (137, 138): Macs find the share over mDNS.
resource "proxmox_virtual_environment_firewall_rules" "timemachine" {
  node_name    = proxmox_virtual_environment_container.timemachine.node_name
  container_id = proxmox_virtual_environment_container.timemachine.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  dynamic "rule" {
    for_each = local.dual_stack_internal_sources
    iterator = sources

    content {
      type   = "in"
      action = "ACCEPT"
      source = sources.value
      proto  = "tcp"
      dport  = "445" # SMB
    }
  }

  # mDNS, which systemd-resolved answers here (resolved role), and over which the image's Avahi advertises the share.
  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.mdns.name
  }
}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "timemachine" {
  node_name     = proxmox_virtual_environment_container.timemachine.node_name
  container_id  = proxmox_virtual_environment_container.timemachine.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.timemachine]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "timemachine" {
  count = proxmox_haresource.timemachine.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.timemachine.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.timemachine.tags, local.ansible_group_tags),
    [proxmox_virtual_environment_container.timemachine.unprivileged ? "unprivileged_containers" : "privileged_containers"],
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.timemachine.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.timemachine.vm_id
  }
}
