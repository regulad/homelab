# orchard: container, its HA resource and its Ansible host: the Orchard
# controller, which serves Orchard's API and schedules Tart VMs onto the Orchard
# worker on overture. Its database, on the root disk, is the controller's only
# state.

resource "proxmox_virtual_environment_container" "orchard" {
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
    hostname = "orchard"

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "auto"
      }
    }
  }

  # One Go process with an embedded BadgerDB, for one worker and its VMs.
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

resource "proxmox_haresource" "orchard" {
  resource_id = "ct:${proxmox_virtual_environment_container.orchard.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: Orchard's API, from the homelab's own hosts and the tailnet, where its
# worker and its clients are.
resource "proxmox_virtual_environment_firewall_rules" "orchard" {
  node_name    = proxmox_virtual_environment_container.orchard.node_name
  container_id = proxmox_virtual_environment_container.orchard.vm_id

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
      dport  = "6120" # Orchard controller
    }
  }

  # mDNS, which systemd-resolved resolves and answers here (resolved role).
  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.mdns.name
  }
}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "orchard" {
  node_name     = proxmox_virtual_environment_container.orchard.node_name
  container_id  = proxmox_virtual_environment_container.orchard.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.orchard]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "orchard" {
  count = proxmox_haresource.orchard.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.orchard.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "orchard_controllers", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.orchard.tags, local.ansible_group_tags),
    [proxmox_virtual_environment_container.orchard.unprivileged ? "unprivileged_containers" : "privileged_containers"],
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.orchard.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.orchard.vm_id
  }
}
