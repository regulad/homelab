# ingress: container 121, its HA resource, its firewall and its Ansible host.

resource "proxmox_virtual_environment_container" "ingress" {
  node_name     = "prodingus"
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 2
  }

  disk {
    datastore_id  = "rbd"
    mount_options = ["discard", "lazytime"]
    size          = 24
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "ingress"

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

  network_interface {
    firewall    = true
    mac_address = "BC:24:11:4A:25:FA"
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

resource "proxmox_haresource" "ingress" {
  resource_id = "ct:${proxmox_virtual_environment_container.ingress.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# In: Caddy from anywhere: HTTP, HTTPS, and HTTP/3 for when Caddy serves it
# again (its servers take only h1 and h2 for now).
resource "proxmox_virtual_environment_firewall_rules" "ingress" {
  node_name    = proxmox_virtual_environment_container.ingress.node_name
  container_id = proxmox_virtual_environment_container.ingress.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "HTTP"
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "HTTPS"
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    proto  = "udp"
    dport  = "443" # HTTP/3
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
resource "proxmox_virtual_environment_firewall_options" "ingress" {
  node_name     = proxmox_virtual_environment_container.ingress.node_name
  container_id  = proxmox_virtual_environment_container.ingress.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.ingress]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "ingress" {
  count = proxmox_haresource.ingress.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.ingress.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.ingress.tags, local.ansible_group_tags),
    [proxmox_virtual_environment_container.ingress.unprivileged ? "unprivileged_containers" : "privileged_containers"],
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.ingress.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.ingress.vm_id
  }
}
