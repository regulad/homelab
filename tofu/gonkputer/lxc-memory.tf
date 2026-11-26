# memory: container 213, its HA resource, its firewall and its
# Ansible host: basic-memory, the memory store Parker's AI clients share,
# behind mcp-auth-proxy and a token-checking Caddy, which Caddy on ingress
# serves as memory.regulad.xyz.

resource "proxmox_virtual_environment_container" "memory" {
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
    size          = 16
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "memory"

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

  # The services' state: Podman's named volumes, basic-memory's notes and its
  # index and mcp-auth-proxy's clients, tokens and keys, at Podman's default
  # volume path, so the images on the root disk cannot fill them. Proxmox's
  # backups leave a volume mount point out unless backup is set.
  mount_point {
    backup        = true
    mount_options = ["discard", "lazytime"]
    path          = "/var/lib/containers/storage/volumes"
    size          = "4G"
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
}

resource "proxmox_haresource" "memory" {
  resource_id = "ct:${proxmox_virtual_environment_container.memory.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: from ingress alone (memory.regulad.xyz), mcp-auth-proxy for OAuth clients
# and the token-checking Caddy for clients with the static token, each over
# IPv4, as ingress's GUA rotates with the delegated prefix. basic-memory itself
# listens on loopback alone.
resource "proxmox_virtual_environment_firewall_rules" "memory" {
  node_name    = proxmox_virtual_environment_container.memory.node_name
  container_id = proxmox_virtual_environment_container.memory.vm_id

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
    dport  = "8080" # mcp-auth-proxy
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    source = local.ingress_ipv4
    proto  = "tcp"
    dport  = "8081" # the token-checking Caddy
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
resource "proxmox_virtual_environment_firewall_options" "memory" {
  node_name     = proxmox_virtual_environment_container.memory.node_name
  container_id  = proxmox_virtual_environment_container.memory.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.memory]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "memory" {
  count = proxmox_haresource.memory.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.memory.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["basic_memory_servers", "gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.memory.tags, local.ansible_group_tags),
    [proxmox_virtual_environment_container.memory.unprivileged ? "unprivileged_containers" : "privileged_containers"],
  ))

  # Reached through its node: Mitogen runs lxc-attach there (ansible-generated's
  # group_vars/proxmox_containers.yml).
  variables = {
    proxmox_node = ansible_host.node[proxmox_virtual_environment_container.memory.node_name].name
    proxmox_vmid = proxmox_virtual_environment_container.memory.vm_id
  }
}
