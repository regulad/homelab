# jenkins: container, its HA resource and its Ansible host: the Jenkins
# controller, moved here from aboriginal's compose project, behind Caddy on
# ingress. jenkins_home is on its own mount point.

resource "proxmox_virtual_environment_container" "jenkins" {
  node_name = "prodingus"
  # HA starts the container, not Proxmox's own start on boot.
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
    size          = 8
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "jenkins"

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

  # jenkins_home, bind-mounted into the Jenkins container. Declared at creation,
  # because adding a mount point replaces the container. Proxmox's backups skip
  # a volume mount point unless backup is set.
  mount_point {
    backup        = true
    mount_options = ["discard", "lazytime"]
    path          = "/mnt/jenkins"
    size          = "16G"
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

resource "proxmox_haresource" "jenkins" {
  resource_id = "ct:${proxmox_virtual_environment_container.jenkins.vm_id}"
  type        = "ct"
  state       = "started"
}

# In: Jenkins's web UI, for Caddy on ingress. Its agents are reached outbound,
# so the inbound agent port stays closed.
resource "proxmox_virtual_environment_firewall_rules" "jenkins" {
  node_name    = proxmox_virtual_environment_container.jenkins.node_name
  container_id = proxmox_virtual_environment_container.jenkins.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  rule {
    type   = "in"
    action = "ACCEPT"
    proto  = "tcp"
    dport  = "8080" # Jenkins
  }
}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "jenkins" {
  node_name     = proxmox_virtual_environment_container.jenkins.node_name
  container_id  = proxmox_virtual_environment_container.jenkins.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.jenkins]
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "jenkins" {
  count = proxmox_haresource.jenkins.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_container.jenkins.initialization[0].hostname}.${local.guest_domain}"
  groups = ["gonkputer", "podman_hosts", "proxmox_containers", "ubuntu"]

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.jenkins.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.jenkins.vm_id
  }
}
