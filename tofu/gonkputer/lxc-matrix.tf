# matrix: container, its HA resource, its firewall and its Ansible host: Synapse
# and its bridges, moved here from the matrix VM (vm-matrix.tf), behind Caddy on
# ingress.

resource "proxmox_virtual_environment_container" "matrix" {
  node_name = "prodingus"
  # HA starts the container, not Proxmox's own start on boot.
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.amd64v3, local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 4
  }

  disk {
    datastore_id  = "rbd"
    mount_options = ["discard", "lazytime"]
    size          = 32
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "matrix"

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
    dedicated = 8192
    swap      = 1048576 # 1 TiB in MiB: effectively unlimited swap
  }

  # Synapse's database: the Postgres cluster's data directory. Proxmox's backups
  # leave a volume mount point out unless backup is set.
  mount_point {
    backup        = true
    mount_options = ["discard", "lazytime"]
    path          = "/mnt/synapse"
    size          = "128G"
    volume        = "rbd"
  }

  network_interface {
    firewall = true
    # The matrix VM's, so the DHCP lease and matrix.regulad.internal follow it.
    mac_address = "BC:24:11:B3:AB:5D"
    name        = "eth0"
    vlan_id     = 1
  }

  operating_system {
    template_file_id = "cephfs:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
    type             = "ubuntu"
  }
}

resource "proxmox_haresource" "matrix" {
  resource_id = "ct:${proxmox_virtual_environment_container.matrix.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: Synapse, behind nginx, from ingress alone (matrix.regulad.xyz). Synapse
# reaches its bridges over localhost.
resource "proxmox_virtual_environment_firewall_rules" "matrix" {
  node_name    = proxmox_virtual_environment_container.matrix.node_name
  container_id = proxmox_virtual_environment_container.matrix.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    source = local.ingress_ipv4
    macro  = "HTTP"
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
resource "proxmox_virtual_environment_firewall_options" "matrix" {
  node_name     = proxmox_virtual_environment_container.matrix.node_name
  container_id  = proxmox_virtual_environment_container.matrix.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.matrix]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "matrix" {
  count = proxmox_haresource.matrix.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.matrix.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "matrix", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.matrix.tags, local.ansible_group_tags),
    [proxmox_virtual_environment_container.matrix.unprivileged ? "unprivileged_containers" : "privileged_containers"],
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.matrix.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.matrix.vm_id
  }
}
