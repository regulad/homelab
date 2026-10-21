# livekit: instance, storage, addressing, and dedicated firewall resources.

resource "oci_core_instance" "livekit" {
  display_name        = "livekit"
  compartment_id      = var.tenancy_ocid
  availability_domain = var.availability_domains.ad_1
  fault_domain        = "FAULT-DOMAIN-3"
  shape               = "VM.Standard.A1.Flex"
  metadata            = { ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCd2nNjLPxuJEWMOJJ0nfJ5C1qK/ydxbJiBQJPX+GH4SfIabQn5mfKLkX+p16k7JJj74M1zRAfhvdN/EAjIzDWt6yG1grSystxPHyN/Bt2r5UubHiVHVH/+1iktl7HankbD5vFl4A0xn8tt4gXEpUO2wZTQyuRryItsmjzl+2IXbhsGwyR60+yaZtoh2NKGhwgakT04dz9aPBHC69KJdvhZsgtE3cn2pyDUuOHkFoUHvqJHccoL168HtEi2QtXVn4ZjXw+4uLypHZJSNVcGwfG5oXtJwY5PAf004KDDNiZHIwo656FWFQIsC3kqc/8YQVLjpWCsA6lEAX1SzZa02PZP ssh-key-2025-12-19" }
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
    display_name              = "livekit"
    subnet_id                 = oci_core_subnet.services.id
    assign_ipv6ip             = false
    assign_private_dns_record = false
    assign_public_ip          = "true"
    hostname_label            = "livekit"
    nsg_ids                   = [oci_core_network_security_group.livekit.id]
    private_ip                = "10.131.80.10"
    skip_source_dest_check    = false
  }

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

  shape_config {
    baseline_ocpu_utilization = "BASELINE_1_1"
    memory_in_gbs             = 6
    ocpus                     = 1
  }

  source_details {
    is_preserve_boot_volume_enabled = false
    source_id                       = local.platform_image_ids["Oracle-Linux-9.6-aarch64-2025.11.20-1"]
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

resource "oci_core_boot_volume" "livekit" {
  display_name         = "livekit (Boot Volume)"
  compartment_id       = var.tenancy_ocid
  availability_domain  = var.availability_domains.ad_1
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

resource "oci_core_volume_backup_policy_assignment" "livekit" {
  asset_id  = oci_core_boot_volume.livekit.id
  policy_id = local.backup_policy_ids.bronze

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# This instance has one attached VNIC. one() fails if that changes.
data "oci_core_vnic_attachments" "livekit" {
  compartment_id = var.tenancy_ocid
  instance_id    = oci_core_instance.livekit.id

  filter {
    name   = "state"
    values = ["ATTACHED"]
  }
}

resource "oci_core_ipv6" "livekit" {
  display_name = "ipv620251219003930"
  subnet_id    = oci_core_subnet.services.id
  ip_address   = cidrhost(var.ipv6_subnet_cidr, parseint("000099cd7ea59801", 16))
  lifetime     = "RESERVED"
  vnic_id      = one(data.oci_core_vnic_attachments.livekit.vnic_attachments).vnic_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group" "livekit" {
  display_name   = "livekit"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_tcp_80" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range { # HTTP (TLS certificate issuance)
      max = 80
      min = 80
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_tcp_443" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range { # HTTPS and TURN/TLS
      max = 443
      min = 443
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_tcp_7881" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range { # LiveKit WebRTC over TCP (ICE/TCP)
      max = 7881
      min = 7881
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_tcp_5349" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6" # TCP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range { # TURN/TLS
      max = 5349
      min = 5349
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_udp_3478" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "17" # UDP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range { # TURN/UDP and STUN
      max = 3478
      min = 3478
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_udp_30000_40000" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "17" # UDP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range { # LiveKit TURN relay range
      max = 40000
      min = 30000
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_udp_50000_60000" {
  for_each = local.dual_stack_internet_cidrs

  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "17" # UDP
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range { # LiveKit WebRTC over UDP (ICE/UDP)
      max = 60000
      min = 50000
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
