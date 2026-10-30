# ncsusplitt: container 125, its HA resource, its firewall and its Ansible host.

resource "proxmox_virtual_environment_container" "ncsusplitt" {
  node_name     = "prodingus"
  start_on_boot = false
  tags          = [local.tags.amd64v3, local.tags.terraform]

  console {}

  device_passthrough {
    path = "/dev/net/tun"
  }

  device_passthrough {
    path = "/dev/vhost-net"
  }

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
    hostname = "ncsusplitt"

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
    mac_address = "BC:24:11:D8:56:C2"
    name        = "eth0"
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

resource "proxmox_haresource" "ncsusplitt" {
  resource_id = "ct:${proxmox_virtual_environment_container.ncsusplitt.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Nothing else is admitted. tailscaled's UDP ports are random, and the tailnet's
# traffic, its DNS queries included, arrives inside WireGuard as replies to
# tailscaled's own probes, as through NAT. Ansible reaches the container through
# pct, not SSH.
resource "proxmox_virtual_environment_firewall_rules" "ncsusplitt" {
  node_name    = proxmox_virtual_environment_container.ncsusplitt.node_name
  container_id = proxmox_virtual_environment_container.ncsusplitt.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  # Unbound, which answers only NC State's names, to any client.
  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "DNS"
  }
}

resource "proxmox_virtual_environment_firewall_options" "ncsusplitt" {
  node_name     = proxmox_virtual_environment_container.ncsusplitt.node_name
  container_id  = proxmox_virtual_environment_container.ncsusplitt.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.ncsusplitt]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "ncsusplitt" {
  count = proxmox_haresource.ncsusplitt.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.ncsusplitt.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.ncsusplitt.tags, local.ansible_group_tags),
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.ncsusplitt.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.ncsusplitt.vm_id
  }
}
