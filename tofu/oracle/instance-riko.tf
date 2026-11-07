# riko: instance, backup-policy assignment, and dedicated firewall resources. A
# FreeIPA replica of wako, so that the directory still answers in OCI, mail
# among its clients, while the homelab is down.

resource "oci_core_instance" "riko" {
  display_name        = "riko"
  compartment_id      = var.tenancy_ocid
  availability_domain = local.availability_domains.ad_1
  fault_domain        = "FAULT-DOMAIN-1"
  shape               = "VM.Standard.A1.Flex"
  # opc's login until the first Ansible run, whose base role gives regulad the
  # keys GitHub publishes for him, this one among them.
  metadata      = { ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBpJLGTbli8J2qSzPVpBzeNpVLLMakYeREp8jRkAePuMfMcNMcSNOcPyq+MXhdZc2npKPaZgeZj1w5mQIA4I0M+yhkduWYAwg8utchrqloVGd7NDd+BphSDJ8u/4S3J0iPEj1tsmdE2PJKm7CX6jzoSS7sQwE56HgjN/9Qsc+vsndpLPb0dnepCycuJ9SnfQrK4LMLjAzGsPyM8mpmG10mzS4RNmeF2Wqs/qHGKT1jXFSAUUlpQUSvUgaP0M3UJjYclSp84S3bxEGVzl0Os1l0YQeA1iKLZlzURhE/IiRQdNgI36hTfPeTx0TE2Uw8KOla6xcyijvIWJyPAChqdC42vIIEXtZ52cFDj0mlXjcXTPxBzVMZuusakzzReol6j12nXahy9OTW9feMnRnQSAN9xXLBZjiLpAeYJlggjdscvmjYgp3AkJBNMBTi7ECOsNBr0VMtU+l/ULf2KqwTdd6fzC/AnTIZOSXj2TtOxvM4Vn6lHEKWB8nxFOG1uU5I/xE= regulad@github" }
  state         = "RUNNING"
  freeform_tags = { "managed-by" = "opentofu", "os" = "rhel" }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    dynamic "plugins_config" {
      for_each = local.agent_plugins
      content {
        name          = plugins_config.value.name
        desired_state = plugins_config.value.desired_state
      }
    }
  }

  create_vnic_details {
    display_name              = "riko"
    subnet_id                 = oci_core_subnet.services.id
    assign_ipv6ip             = true
    assign_private_dns_record = true
    # For IPv4 egress, which the internet gateway gives only to public
    # addresses: github.com, where the base role reads regulad's keys, has no
    # IPv6. The NSG admits nothing from the internet.
    assign_public_ip       = "true"
    hostname_label         = "riko"
    nsg_ids                = [oci_core_network_security_group.riko.id]
    private_ip             = "10.131.80.88"
    skip_source_dest_check = false

    ipv6address_ipv6subnet_cidr_pair_details {
      ipv6address     = cidrhost(var.ipv6_subnet_cidrs.wahlecloud, parseint("0000000000000088", 16))
      ipv6subnet_cidr = var.ipv6_subnet_cidrs.wahlecloud
    }
  }

  # Instance metadata over IMDSv2 alone, which Oracle Linux's cloud-init and
  # Oracle Cloud Agent use.
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  shape_config {
    memory_in_gbs = 2
    ocpus         = 1
  }

  # Oracle Linux 10.2, the Enterprise Linux release of wako's AlmaLinux, whose
  # AppStream carries the same FreeIPA.
  source_details {
    source_id   = local.platform_image_ids["Oracle-Linux-10.2-aarch64-2026.10.16-0"]
    source_type = "image"
  }
}

resource "oci_core_volume_backup_policy_assignment" "riko" {
  asset_id  = oci_core_instance.riko.boot_volume_id
  policy_id = local.backup_policy_ids.bronze
}

# The pubsub security list already admits the homelab's IPv4. Its IPv6 arrives
# from local.dual_stack_homelab_cidrs.ipv6, as arawi translates the LAN's
# addresses to its LAN2 address for the VCN, so these rules admit that family
# alone, to FreeIPA's ports: wako replicates to riko over them, and checks them
# while riko joins.
resource "oci_core_network_security_group" "riko" {
  display_name   = "riko"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id
}

resource "oci_core_network_security_group_security_rule" "riko_tcp_80" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.riko.id
  protocol                  = "6" # TCP
  source                    = local.dual_stack_homelab_cidrs.ipv6
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range { # HTTP
      max = 80
      min = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "riko_tcp_88" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.riko.id
  protocol                  = "6" # TCP
  source                    = local.dual_stack_homelab_cidrs.ipv6
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range { # Kerberos
      max = 88
      min = 88
    }
  }
}

resource "oci_core_network_security_group_security_rule" "riko_udp_88" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.riko.id
  protocol                  = "17" # UDP
  source                    = local.dual_stack_homelab_cidrs.ipv6
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range { # Kerberos
      max = 88
      min = 88
    }
  }
}

resource "oci_core_network_security_group_security_rule" "riko_tcp_389" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.riko.id
  protocol                  = "6" # TCP
  source                    = local.dual_stack_homelab_cidrs.ipv6
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range { # LDAP
      max = 389
      min = 389
    }
  }
}

resource "oci_core_network_security_group_security_rule" "riko_tcp_443" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.riko.id
  protocol                  = "6" # TCP
  source                    = local.dual_stack_homelab_cidrs.ipv6
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range { # HTTPS
      max = 443
      min = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "riko_tcp_464" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.riko.id
  protocol                  = "6" # TCP
  source                    = local.dual_stack_homelab_cidrs.ipv6
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range { # Kerberos password change (kpasswd)
      max = 464
      min = 464
    }
  }
}

resource "oci_core_network_security_group_security_rule" "riko_udp_464" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.riko.id
  protocol                  = "17" # UDP
  source                    = local.dual_stack_homelab_cidrs.ipv6
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range { # Kerberos password change (kpasswd)
      max = 464
      min = 464
    }
  }
}

resource "oci_core_network_security_group_security_rule" "riko_tcp_636" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.riko.id
  protocol                  = "6" # TCP
  source                    = local.dual_stack_homelab_cidrs.ipv6
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range { # LDAPS
      max = 636
      min = 636
    }
  }
}
