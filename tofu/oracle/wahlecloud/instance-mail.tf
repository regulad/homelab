# mail: instance, storage, addressing, and dedicated firewall resources.

resource "oci_core_instance" "mail" {
  display_name        = "mail"
  compartment_id      = var.tenancy_ocid
  availability_domain = var.availability_domains.ad_1
  shape               = "VM.Standard.A1.Flex"

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
    display_name              = "mail"
    subnet_id                 = oci_core_subnet.services.id
    assign_ipv6ip             = false
    assign_private_dns_record = false
    assign_public_ip          = "true"
    hostname_label            = "mail"
    nsg_ids                   = [oci_core_network_security_group.mail.id]
    private_ip                = "10.131.80.15"
    skip_source_dest_check    = false
  }
  fault_domain = "FAULT-DOMAIN-3"

  instance_options {
    are_legacy_imds_endpoints_disabled = false
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
  metadata = var.instance_metadata.mail

  shape_config {
    baseline_ocpu_utilization = "BASELINE_1_1"
    memory_in_gbs             = 6
    ocpus                     = 1
  }

  source_details {
    is_preserve_boot_volume_enabled = false
    # Oracle-Linux-9.6-aarch64-2025.11.20-0
    source_id   = "ocid1.image.oc1.iad.aaaaaaaaa53zducgjvcstvpe76ctctt6ddw5bloq2wvhvboggfs5usyd47za"
    source_type = "image"
  }
  state = "RUNNING"

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

resource "oci_core_boot_volume" "mail" {
  display_name         = "mail (Boot Volume)"
  compartment_id       = var.tenancy_ocid
  availability_domain  = var.availability_domains.ad_1
  is_auto_tune_enabled = false
  size_in_gbs          = "47"

  vpus_per_gb = "10"

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

resource "oci_core_volume_backup_policy_assignment" "mail" {
  asset_id  = oci_core_boot_volume.mail.id
  policy_id = var.backup_policy_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# This instance has one attached VNIC. one() fails if that changes.
data "oci_core_vnic_attachments" "mail" {
  compartment_id = var.tenancy_ocid
  instance_id    = oci_core_instance.mail.id

  filter {
    name   = "state"
    values = ["ATTACHED"]
  }
}

resource "oci_core_ipv6" "mail" {
  display_name = "ipv620251208230834"
  subnet_id    = oci_core_subnet.services.id
  ip_address   = cidrhost(var.ipv6_subnet_cidr, parseint("0000e075c8d7eb01", 16))
  lifetime     = "RESERVED"
  vnic_id      = one(data.oci_core_vnic_attachments.mail.vnic_attachments).vnic_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group" "mail" {
  display_name   = "mail"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_tcp_25" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 25
      min = 25
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_tcp_143" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 143
      min = 143
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_tcp_465" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 465
      min = 465
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_tcp_587" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 587
      min = 587
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_tcp_993" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 993
      min = 993
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_tcp_4190" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 4190
      min = 4190
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_tcp_80" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 80
      min = 80
    }

    source_port_range {
      max = 80
      min = 80
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
