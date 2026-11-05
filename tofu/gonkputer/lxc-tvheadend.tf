# tvheadend: container 127, its HA resource, its firewall and its Ansible host.

resource "proxmox_virtual_environment_container" "tvheadend" {
  node_name     = "prodingus"
  start_on_boot = false
  tags          = [local.tags.amd64v3, local.tags.terraform, local.tags.virtiofsd]

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
    hostname = "tvheadend"

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
    mac_address = "BC:24:11:83:46:4B"
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

resource "proxmox_haresource" "tvheadend" {
  resource_id = "ct:${proxmox_virtual_environment_container.tvheadend.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# In: the web UI from ingress alone (tvheadend-livingston.regulad.xyz), HTSP
# from the homelab's own ranges, for Jellyfin on aboriginal, and UDP from
# anywhere, for the HDHomeRun tuner.
resource "proxmox_virtual_environment_firewall_rules" "tvheadend" {
  node_name    = proxmox_virtual_environment_container.tvheadend.node_name
  container_id = proxmox_virtual_environment_container.tvheadend.vm_id

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
    dport  = "9981" # Tvheadend web UI
  }

  dynamic "rule" {
    for_each = local.dual_stack_internal_sources
    iterator = sources

    content {
      type   = "in"
      action = "ACCEPT"
      source = sources.value
      proto  = "tcp"
      dport  = "9982" # HTSP
    }
  }

  # UDP, for the HDHomeRun tuner's streams, which it sends to a port tvheadend
  # picks at random, and its answers to tvheadend's discovery broadcasts, which
  # come from its own address; conntrack matches neither to anything tvheadend
  # sent. It covers SSDP too, and mDNS, which systemd-resolved resolves and
  # answers here (resolved role).
  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.udp.name
  }
}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "tvheadend" {
  node_name     = proxmox_virtual_environment_container.tvheadend.node_name
  container_id  = proxmox_virtual_environment_container.tvheadend.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.tvheadend]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "tvheadend" {
  count = proxmox_haresource.tvheadend.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.tvheadend.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.tvheadend.tags, local.ansible_group_tags),
    [proxmox_virtual_environment_container.tvheadend.unprivileged ? "unprivileged_containers" : "privileged_containers"],
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.tvheadend.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.tvheadend.vm_id
  }
}
