# freeipa: container, its HA resource and its Ansible host: the old FreeIPA
# server's stand-in while its consumers move to wako. It rewrites LDAP between
# dc=home,dc=arpa and wako's dc=regulad,dc=internal.
# It took over the freeipa VM's MAC address, and with it the VM's address.

resource "proxmox_virtual_environment_container" "freeipa" {
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
    hostname = "freeipa"

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
    firewall = true
    # The freeipa VM's, so its static mapping on arawi and its address follow.
    mac_address = "BC:24:11:7D:6F:9B"
    name        = "eth0"
    vlan_id     = 1
  }

  operating_system {
    template_file_id = "cephfs:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
    type             = "ubuntu"
  }

  depends_on = [proxmox_download_file.ubuntu_26_04_standard]
}

resource "proxmox_haresource" "freeipa" {
  resource_id = "ct:${proxmox_virtual_environment_container.freeipa.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: the LDAP proxy. Not sshd, which the template ships: Ansible reaches the
# container through pct.
resource "proxmox_virtual_environment_firewall_rules" "freeipa" {
  node_name    = proxmox_virtual_environment_container.freeipa.node_name
  container_id = proxmox_virtual_environment_container.freeipa.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "LDAP"
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "LDAPS"
  }
}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "freeipa" {
  node_name     = proxmox_virtual_environment_container.freeipa.node_name
  container_id  = proxmox_virtual_environment_container.freeipa.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.freeipa]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "freeipa" {
  count = proxmox_haresource.freeipa.state == "started" ? 1 : 0

  name = "${proxmox_virtual_environment_container.freeipa.initialization[0].hostname}.${local.guest_domain}"
  groups = sort(setunion(
    ["gonkputer", "ldap_proxies", "proxmox_containers", "ubuntu"],
    setintersection(proxmox_virtual_environment_container.freeipa.tags, local.ansible_group_tags),
  ))

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.freeipa.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.freeipa.vm_id
  }
}
