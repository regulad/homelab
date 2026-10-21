# bailout: instance, storage, addressing, and dedicated firewall resources.

resource "oci_core_instance" "bailout" {
  display_name        = "bailout"
  compartment_id      = var.tenancy_ocid
  availability_domain = var.availability_domains.ad_3
  fault_domain        = "FAULT-DOMAIN-3"
  shape               = "VM.Standard.E2.1.Micro"
  metadata            = { ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBpJLGTbli8J2qSzPVpBzeNpVLLMakYeREp8jRkAePuMfMcNMcSNOcPyq+MXhdZc2npKPaZgeZj1w5mQIA4I0M+yhkduWYAwg8utchrqloVGd7NDd+BphSDJ8u/4S3J0iPEj1tsmdE2PJKm7CX6jzoSS7sQwE56HgjN/9Qsc+vsndpLPb0dnepCycuJ9SnfQrK4LMLjAzGsPyM8mpmG10mzS4RNmeF2Wqs/qHGKT1jXFSAUUlpQUSvUgaP0M3UJjYclSp84S3bxEGVzl0Os1l0YQeA1iKLZlzURhE/IiRQdNgI36hTfPeTx0TE2Uw8KOla6xcyijvIWJyPAChqdC42vIIEXtZ52cFDj0mlXjcXTPxBzVMZuusakzzReol6j12nXahy9OTW9feMnRnQSAN9xXLBZjiLpAeYJlggjdscvmjYgp3AkJBNMBTi7ECOsNBr0VMtU+l/ULf2KqwTdd6fzC/AnTIZOSXj2TtOxvM4Vn6lHEKWB8nxFOG1uU5I/xE=" }
  state               = "RUNNING"
  freeform_tags       = { "managed-by" = "opentofu", "os" = "rhel" }

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

  availability_config {
    is_live_migration_preferred = false
    recovery_action             = "RESTORE_INSTANCE"
  }

  create_vnic_details {
    display_name              = "bailout"
    subnet_id                 = oci_core_subnet.services.id
    assign_ipv6ip             = false
    assign_private_dns_record = false
    assign_public_ip          = "true"
    hostname_label            = "bailout"
    nsg_ids                   = [oci_core_network_security_group.bailout.id]
    private_ip                = "10.131.80.201"
    skip_source_dest_check    = false
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    is_consistent_volume_naming_enabled = true
    is_encryption_in_transit_enabled    = false
    is_pv_encryption_in_transit_enabled = true
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
  }

  source_details {
    is_preserve_boot_volume_enabled = false
    source_id                       = local.platform_image_ids["Oracle-Linux-9.8-2026.07.20-1"]
    source_type                     = "image"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
    # Standalone volume and IPv6 resources own these post-launch settings.
    ignore_changes = [
      source_details[0].boot_volume_size_in_gbs,
      source_details[0].boot_volume_vpus_per_gb,
      create_vnic_details[0].ipv6address_ipv6subnet_cidr_pair_details,
    ]
  }
}

resource "oci_core_boot_volume" "bailout" {
  display_name         = "bailout (Boot Volume)"
  compartment_id       = var.tenancy_ocid
  availability_domain  = var.availability_domains.ad_3
  is_auto_tune_enabled = false
  size_in_gbs          = "47"
  vpus_per_gb          = "10"

  # The following exists as an artifact of import from the imperative setup.
  source_details {
    type = "bootVolume"
  }

  lifecycle {
    prevent_destroy = true
    # Image-created volumes expose no clone/restore source. This required
    # schema placeholder is ignored for adoption; it is not a creation recipe.
    ignore_changes = [source_details]
  }
}

resource "oci_core_volume_backup_policy_assignment" "bailout" {
  asset_id  = oci_core_boot_volume.bailout.id
  policy_id = local.backup_policy_ids.bronze
}

# This instance has one attached VNIC. one() fails if that changes.
data "oci_core_vnic_attachments" "bailout" {
  compartment_id = var.tenancy_ocid
  instance_id    = oci_core_instance.bailout.id

  filter {
    name   = "state"
    values = ["ATTACHED"]
  }
}

resource "oci_core_ipv6" "bailout" {
  display_name = "ipv620260809235715"
  subnet_id    = oci_core_subnet.services.id
  ip_address   = cidrhost(var.ipv6_subnet_cidr, parseint("0000e821108db201", 16))
  lifetime     = "RESERVED"
  vnic_id      = one(data.oci_core_vnic_attachments.bailout.vnic_attachments).vnic_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group" "bailout" {
  display_name   = "bailout"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "bailout_rule_01" {
  description               = "bailout646"
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.bailout.id
  protocol                  = "17" # UDP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range { # WireGuard
      max = 51820
      min = 51820
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "bailout_rule_02" {
  description               = "bailout464"
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.bailout.id
  protocol                  = "17" # UDP
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range { # WireGuard
      max = 51821
      min = 51821
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
