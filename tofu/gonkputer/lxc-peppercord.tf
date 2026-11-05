# peppercord: container 126, its HA resource, its firewall and its Ansible host.

resource "proxmox_virtual_environment_container" "peppercord" {
  node_name     = "prodingus"
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.amd64v3, local.tags.terraform]

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
    hostname = "peppercord"

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
    firewall    = true
    mac_address = "BC:24:11:17:49:78"
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

resource "proxmox_haresource" "peppercord" {
  resource_id = "ct:${proxmox_virtual_environment_container.peppercord.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# In: nothing beyond Ping and mDNS. Not peppercord's 8080, which Podman
# publishes on every address and ingress does not proxy.
resource "proxmox_virtual_environment_firewall_rules" "peppercord" {
  node_name    = proxmox_virtual_environment_container.peppercord.node_name
  container_id = proxmox_virtual_environment_container.peppercord.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  # mDNS, which Avahi reflects between the LAN and the Podman containers here (avahi role).
  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.mdns.name
  }
}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "peppercord" {
  node_name     = proxmox_virtual_environment_container.peppercord.node_name
  container_id  = proxmox_virtual_environment_container.peppercord.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.peppercord]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "peppercord" {
  count = proxmox_haresource.peppercord.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.peppercord.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "peppercord", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.peppercord.tags, local.ansible_group_tags),
    [proxmox_virtual_environment_container.peppercord.unprivileged ? "unprivileged_containers" : "privileged_containers"],
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.peppercord.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.peppercord.vm_id
  }
}
