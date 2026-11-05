# authentik: container, its HA resource, its firewall and its Ansible host:
# authentik, moved here from the authentik VM (vm-authentik.tf), behind Caddy on
# ingress.

resource "proxmox_virtual_environment_container" "authentik" {
  node_name = "prodingus"
  # HA starts the container, not Proxmox's own start on boot.
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
    size          = 16
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "authentik"

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
    dedicated = 4096
    swap      = 1048576 # 1 TiB in MiB: effectively unlimited swap
  }

  network_interface {
    firewall = true
    # The authentik VM's, so the DHCP lease and authentik.regulad.internal follow it.
    mac_address = "BC:24:11:17:1A:E6"
    name        = "eth0"
    vlan_id     = 1
  }

  operating_system {
    template_file_id = "cephfs:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
    type             = "ubuntu"
  }
}

resource "proxmox_haresource" "authentik" {
  resource_id = "ct:${proxmox_virtual_environment_container.authentik.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: authentik from ingress alone (authentik.regulad.xyz), over HTTP and, though
# nothing uses it yet, HTTPS.
resource "proxmox_virtual_environment_firewall_rules" "authentik" {
  node_name    = proxmox_virtual_environment_container.authentik.node_name
  container_id = proxmox_virtual_environment_container.authentik.vm_id

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
    dport  = "9000" # authentik HTTP
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    source = local.ingress_ipv4
    proto  = "tcp"
    dport  = "9443" # authentik HTTPS
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
resource "proxmox_virtual_environment_firewall_options" "authentik" {
  node_name     = proxmox_virtual_environment_container.authentik.node_name
  container_id  = proxmox_virtual_environment_container.authentik.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.authentik]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "authentik" {
  count = proxmox_haresource.authentik.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.authentik.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.authentik.tags, local.ansible_group_tags),
    [proxmox_virtual_environment_container.authentik.unprivileged ? "unprivileged_containers" : "privileged_containers"],
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.authentik.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.authentik.vm_id
  }
}
