resource "oci_core_instance" "web" {
  display_name        = "doppelgangerhq.com"
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
    display_name              = "doppelgangerhq.com"
    subnet_id                 = oci_core_subnet.legacy.id
    assign_ipv6ip             = false
    assign_private_dns_record = false
    assign_public_ip          = "true"
    hostname_label            = "doppelgangerhq-com"
    private_ip                = var.ip_addresses.web_create_vnic_details_1_private_ip
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
  metadata = var.instance_metadata.bailout

  shape_config {
    baseline_ocpu_utilization = "BASELINE_1_1"
    memory_in_gbs             = 6
    ocpus                     = 2
  }

  source_details {
    is_preserve_boot_volume_enabled = false
    source_id                       = var.image_ids.web
    source_type                     = "image"
  }
  state = "RUNNING"

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
