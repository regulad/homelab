# pihole2: instance and backup-policy assignment. The tailnet's second global
# DNS resolver: blocky, as on pihole, with tailscalerouter's Unbound as its
# upstream, as pihole has arawi. It serves only the tailnet, which the pubsub
# security list admits, so it has no NSG.

resource "oci_core_instance" "pihole2" {
  display_name        = "pihole2"
  compartment_id      = var.tenancy_ocid
  availability_domain = local.availability_domains.ad_1
  fault_domain        = "FAULT-DOMAIN-2"
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
    display_name              = "pihole2"
    subnet_id                 = oci_core_subnet.services.id
    assign_ipv6ip             = true
    assign_private_dns_record = true
    # For IPv4 egress, which the internet gateway gives only to public
    # addresses: ghcr.io, blocky's registry, and github.com, where the base
    # role reads regulad's keys, have no IPv6.
    assign_public_ip       = "true"
    hostname_label         = "pihole2"
    private_ip             = "10.131.80.53"
    skip_source_dest_check = false

    ipv6address_ipv6subnet_cidr_pair_details {
      ipv6address     = cidrhost(var.ipv6_subnet_cidrs.wahlecloud, parseint("0000000000000053", 16))
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

  # Oracle Linux 10.2, as riko runs.
  source_details {
    source_id   = local.platform_image_ids["Oracle-Linux-10.2-aarch64-2026.10.16-0"]
    source_type = "image"
  }
}

resource "oci_core_volume_backup_policy_assignment" "pihole2" {
  asset_id  = oci_core_instance.pihole2.boot_volume_id
  policy_id = local.backup_policy_ids.bronze
}
