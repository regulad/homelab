# nexus: container, its HA resource and its Ansible host: Sonatype Nexus
# Repository, moved here from aboriginal's compose project, behind Caddy on
# ingress. Its data directory is on its own RBD mount point.

resource "proxmox_virtual_environment_container" "nexus" {
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
    size          = 12
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "nexus"

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "auto"
      }
    }
  }

  # Nexus's default JVM: a 2703 MiB heap and up to as much direct memory. It
  # peaked at 2.6 GiB resident on aboriginal.
  memory {
    dedicated = 6144
    swap      = 1048576 # 1 TiB in MiB: effectively unlimited swap
  }

  # Nexus's data directory, /mnt/nexus/data: its blob store, OrientDB and logs,
  # 47 GiB once compacted. Declared at creation, since adding a mount point
  # later replaces the container; sized for the ghcr-io proxy's growth. Proxmox's
  # backups skip a volume mount point unless backup is set.
  mount_point {
    backup        = true
    mount_options = ["discard", "lazytime"]
    path          = "/mnt/nexus"
    size          = "256G"
    volume        = "rbd"
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

resource "proxmox_haresource" "nexus" {
  resource_id = "ct:${proxmox_virtual_environment_container.nexus.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: Nexus, for Caddy on ingress, which serves cr.regulad.xyz from the cr
# repository's path on the same port.
resource "proxmox_virtual_environment_firewall_rules" "nexus" {
  node_name    = proxmox_virtual_environment_container.nexus.node_name
  container_id = proxmox_virtual_environment_container.nexus.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    proto  = "tcp"
    dport  = "8081" # Nexus
  }

}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "nexus" {
  node_name     = proxmox_virtual_environment_container.nexus.node_name
  container_id  = proxmox_virtual_environment_container.nexus.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.nexus]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "nexus" {
  count = proxmox_haresource.nexus.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.nexus.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "nexus_servers", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.nexus.tags, local.ansible_group_tags),
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.nexus.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.nexus.vm_id
  }
}
