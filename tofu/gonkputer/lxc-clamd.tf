# clamd: container, its HA resource and its Ansible host: ClamAV's clamd, the
# scanner the homelab's hosts and OCI's stream files to over TCP, with freshclam
# keeping its signatures current. Its only state is those signatures, which
# freshclam downloads again if they are lost.

locals {
  # The port clamd listens on for its clients; Ansible writes it into clamd's
  # configuration from the Ansible host. The image's health check pings 3310.
  clamd_port = "3310"
  # OCI's pubsub subnet, in tofu/oracle's wahlecloud VCN. Its instances reach the
  # LAN through the tailnet from their own addresses; its GUA /64 is
  # var.pubsub_ipv6_cidr.
  pubsub_ipv4_cidr = "10.131.80.0/24"
}

resource "proxmox_virtual_environment_container" "clamd" {
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
    size          = 8
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "clamd"

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "auto"
      }
    }
  }

  # ClamAV's guidance for its image: about 1.2 GiB for the signatures, twice
  # that while a reload holds the old engine beside the new one, so 4 GiB.
  memory {
    dedicated = 4096
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

resource "proxmox_haresource" "clamd" {
  resource_id = "ct:${proxmox_virtual_environment_container.clamd.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: clamd from the homelab, OCI's pubsub subnet and the tailnet. The OCI
# router itself, and any device reaching the LAN over the tailnet, comes from
# its tailnet address; the tailnet's policy decides which devices those are.
resource "proxmox_virtual_environment_firewall_rules" "clamd" {
  node_name    = proxmox_virtual_environment_container.clamd.node_name
  container_id = proxmox_virtual_environment_container.clamd.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  # clamd neither authenticates nor encrypts: any client can scan, reload or
  # shut it down, so only these ranges reach it.
  rule {
    type   = "in"
    action = "ACCEPT"
    source = "${local.dual_stack_lan_cidrs.ipv4},${local.pubsub_ipv4_cidr},${module.shared.tailscale_cidrs.ipv4}"
    proto  = "tcp"
    dport  = local.clamd_port # clamd
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    source = "${local.dual_stack_lan_cidrs.ipv6},${var.lan_ipv6_cidr},${var.pubsub_ipv6_cidr},${module.shared.tailscale_cidrs.ipv6}"
    proto  = "tcp"
    dport  = local.clamd_port # clamd
  }
}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "clamd" {
  node_name     = proxmox_virtual_environment_container.clamd.node_name
  container_id  = proxmox_virtual_environment_container.clamd.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.clamd]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "clamd" {
  count = proxmox_haresource.clamd.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.clamd.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.clamd.tags, local.ansible_group_tags),
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.clamd.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.clamd.vm_id
    # For clamd's configuration, which listens where the firewall admits.
    clamd_port = local.clamd_port
  }
}
