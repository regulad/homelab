# unifi: VM 102, its HA resource and its firewall.

resource "proxmox_virtual_environment_vm" "unifi" {
  # The snippet IDs below are written out; this keeps the files ahead of the guest.
  depends_on = [proxmox_virtual_environment_file.ubuntu_vendor]

  name          = "unifi"
  node_name     = "prodingus"
  on_boot       = false
  bios          = "ovmf"
  boot_order    = ["virtio0"]
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  tags          = [local.tags.terraform]

  network_device {
    firewall    = true
    mac_address = "BC:24:11:97:27:33"
    vlan_id     = 1
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 4
    flags = []
    numa  = true
    type  = proxmox_custom_cpu_model.ryzen_vermeer_v3.cputype
  }

  disk {
    datastore_id = "rbd"
    discard      = "on"
    interface    = "virtio0"
    iothread     = true
    size         = 32
  }

  efi_disk {
    datastore_id      = "rbd"
    pre_enrolled_keys = true
    type              = "4m"
  }

  initialization {
    datastore_id        = "rbd"
    interface           = "ide2"
    upgrade             = true
    vendor_data_file_id = "cephfs:snippets/ubuntu-vendor.yaml"

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "auto"
      }
    }

    user_account {
      keys     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBpJLGTbli8J2qSzPVpBzeNpVLLMakYeREp8jRkAePuMfMcNMcSNOcPyq+MXhdZc2npKPaZgeZj1w5mQIA4I0M+yhkduWYAwg8utchrqloVGd7NDd+BphSDJ8u/4S3J0iPEj1tsmdE2PJKm7CX6jzoSS7sQwE56HgjN/9Qsc+vsndpLPb0dnepCycuJ9SnfQrK4LMLjAzGsPyM8mpmG10mzS4RNmeF2Wqs/qHGKT1jXFSAUUlpQUSvUgaP0M3UJjYclSp84S3bxEGVzl0Os1l0YQeA1iKLZlzURhE/IiRQdNgI36hTfPeTx0TE2Uw8KOla6xcyijvIWJyPAChqdC42vIIEXtZ52cFDj0mlXjcXTPxBzVMZuusakzzReol6j12nXahy9OTW9feMnRnQSAN9xXLBZjiLpAeYJlggjdscvmjYgp3AkJBNMBTi7ECOsNBr0VMtU+l/ULf2KqwTdd6fzC/AnTIZOSXj2TtOxvM4Vn6lHEKWB8nxFOG1uU5I/xE= regulad@github/102565467 # ssh-import-id gh:regulad"]
      username = "regulad"
    }
  }

  memory {
    dedicated = 8192
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  tpm_state {
    datastore_id = "rbd"
  }

  vga {
    type = "serial0"
  }

  watchdog {
    action  = "reset"
    enabled = true
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_haresource" "unifi" {
  resource_id = "vm:${proxmox_virtual_environment_vm.unifi.vm_id}"
  type        = "vm"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# In: SSH and UniFi OS Server's web UI, device inform, STUN and discovery, from
# the homelab's own ranges. Not its optional services, the mobile speed
# test (6789), Identity Hub (9543), remote syslog (5514) and hotspot
# portals (8444, 8880 to 8882), nor its 5671 and 28082.
resource "proxmox_virtual_environment_firewall_rules" "unifi" {
  node_name = proxmox_virtual_environment_vm.unifi.node_name
  vm_id     = proxmox_virtual_environment_vm.unifi.vm_id

  rule {
    type   = "in"
    action = "ACCEPT"
    macro  = "Ping"
  }

  dynamic "rule" {
    for_each = local.dual_stack_internal_sources
    iterator = sources

    content {
      type   = "in"
      action = "ACCEPT"
      source = sources.value
      macro  = "SSH"
    }
  }

  dynamic "rule" {
    for_each = local.dual_stack_internal_sources
    iterator = sources

    content {
      type   = "in"
      action = "ACCEPT"
      source = sources.value
      proto  = "tcp"
      dport  = "11443" # UniFi OS Server's web UI
    }
  }

  dynamic "rule" {
    for_each = local.dual_stack_internal_sources
    iterator = sources

    content {
      type   = "in"
      action = "ACCEPT"
      source = sources.value
      proto  = "tcp"
      dport  = "8080" # Device inform
    }
  }

  dynamic "rule" {
    for_each = local.dual_stack_internal_sources
    iterator = sources

    content {
      type   = "in"
      action = "ACCEPT"
      source = sources.value
      proto  = "udp"
      dport  = "3478" # STUN
    }
  }

  dynamic "rule" {
    for_each = local.dual_stack_internal_sources
    iterator = sources

    content {
      type   = "in"
      action = "ACCEPT"
      source = sources.value
      proto  = "udp"
      dport  = "10001" # Device discovery
    }
  }

  dynamic "rule" {
    for_each = local.dual_stack_internal_sources
    iterator = sources

    content {
      type   = "in"
      action = "ACCEPT"
      source = sources.value
      proto  = "udp"
      dport  = "10003" # Adoption discovery
    }
  }

  # mDNS, which systemd-resolved resolves and answers here (its vendor file).
  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.mdns.name
  }
}

# Enabled after its rules exist, so the guest is never cut off. Proxmox applies
# its DHCP rules unless dhcp is 0, although its schema calls 0 the default; the
# guest takes its addresses by DHCP and SLAAC, which ndp's router advertisements
# carry.
resource "proxmox_virtual_environment_firewall_options" "unifi" {
  node_name     = proxmox_virtual_environment_vm.unifi.node_name
  vm_id         = proxmox_virtual_environment_vm.unifi.vm_id
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

  depends_on = [proxmox_virtual_environment_firewall_rules.unifi]
}
