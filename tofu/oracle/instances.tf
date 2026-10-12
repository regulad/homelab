resource "oci_core_instance" "bailout" {
  display_name        = "bailout"
  compartment_id      = var.tenancy_ocid
  availability_domain = var.availability_domains.ad_3
  shape               = "VM.Standard.E2.1.Micro"

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      name          = "WebLogic Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Vulnerability Scanning"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Oracle Java Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "OS Management Hub Agent"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Management Agent"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Fleet Application Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Custom Logs Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute RDMA GPU Monitoring"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Compute Instance Run Command"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute Instance Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute HPC RDMA Auto-Configuration"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Compute HPC RDMA Authentication"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Cloud Guard Workload Protection"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Block Volume Management"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Bastion"
      desired_state = "DISABLED"
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
    defined_tags              = var.creation_tags.instances_bailout
    freeform_tags             = {}
    hostname_label            = "bailout"
    nsg_ids                   = [oci_core_network_security_group.bailout.id]
    private_ip                = var.ip_addresses.bailout_create_vnic_details_1_private_ip
    security_attributes       = {}
    skip_source_dest_check    = false
  }
  defined_tags      = var.creation_tags.instances_bailout_2
  extended_metadata = {}
  fault_domain      = "FAULT-DOMAIN-3"
  freeform_tags     = {}

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
  metadata            = var.instance_metadata.bailout
  security_attributes = {}

  shape_config {
    local_volume_size_in_gbs = 0
    memory_in_gbs            = 1
    nvmes                    = 0
    ocpus                    = 1
    vcpus                    = 2
  }

  source_details {
    is_preserve_boot_volume_enabled = false
    source_id                       = var.image_ids.bailout
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

resource "oci_core_instance" "livekit" {
  display_name        = "livekit"
  compartment_id      = var.tenancy_ocid
  availability_domain = var.availability_domains.ad_1
  shape               = "VM.Standard.A1.Flex"

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      name          = "WebLogic Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Vulnerability Scanning"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Oracle Java Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "OS Management Hub Agent"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Management Agent"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Fleet Application Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Custom Logs Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute RDMA GPU Monitoring"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Compute Instance Run Command"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute Instance Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute HPC RDMA Auto-Configuration"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Compute HPC RDMA Authentication"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Cloud Guard Workload Protection"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Block Volume Management"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Bastion"
      desired_state = "DISABLED"
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
    defined_tags              = var.creation_tags.instances_livekit
    freeform_tags             = {}
    hostname_label            = "livekit"
    nsg_ids                   = [oci_core_network_security_group.livekit.id]
    private_ip                = var.ip_addresses.livekit_create_vnic_details_1_private_ip
    security_attributes       = {}
    skip_source_dest_check    = false
  }
  defined_tags      = var.creation_tags.instances_livekit_2
  extended_metadata = {}
  fault_domain      = "FAULT-DOMAIN-3"
  freeform_tags     = {}

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
  metadata            = var.instance_metadata.livekit
  security_attributes = {}

  shape_config {
    baseline_ocpu_utilization = "BASELINE_1_1"
    local_volume_size_in_gbs  = 0
    memory_in_gbs             = 6
    nvmes                     = 0
    ocpus                     = 1
    vcpus                     = 1
  }

  source_details {
    is_preserve_boot_volume_enabled = false
    source_id                       = var.image_ids.livekit
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

resource "oci_core_instance" "mail" {
  display_name        = "mail"
  compartment_id      = var.tenancy_ocid
  availability_domain = var.availability_domains.ad_1
  shape               = "VM.Standard.A1.Flex"

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      name          = "WebLogic Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Vulnerability Scanning"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Oracle Java Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "OS Management Hub Agent"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Management Agent"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Fleet Application Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Custom Logs Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute RDMA GPU Monitoring"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Compute Instance Run Command"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute Instance Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute HPC RDMA Auto-Configuration"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Compute HPC RDMA Authentication"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Cloud Guard Workload Protection"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Block Volume Management"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Bastion"
      desired_state = "DISABLED"
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
    defined_tags              = var.creation_tags.instances_mail
    freeform_tags             = {}
    hostname_label            = "mail"
    nsg_ids                   = [oci_core_network_security_group.mail.id]
    private_ip                = var.ip_addresses.mail_create_vnic_details_1_private_ip
    security_attributes       = {}
    skip_source_dest_check    = false
  }
  defined_tags      = var.creation_tags.instances_mail_2
  extended_metadata = {}
  fault_domain      = "FAULT-DOMAIN-3"
  freeform_tags     = {}

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
  metadata            = var.instance_metadata.mail
  security_attributes = {}

  shape_config {
    baseline_ocpu_utilization = "BASELINE_1_1"
    local_volume_size_in_gbs  = 0
    memory_in_gbs             = 6
    nvmes                     = 0
    ocpus                     = 1
    vcpus                     = 1
  }

  source_details {
    is_preserve_boot_volume_enabled = false
    source_id                       = var.image_ids.mail
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

resource "oci_core_instance" "router" {
  display_name        = "tailscalerouter"
  compartment_id      = var.tenancy_ocid
  availability_domain = var.availability_domains.ad_3
  shape               = "VM.Standard.E2.1.Micro"

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      name          = "WebLogic Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Vulnerability Scanning"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Oracle Java Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "OS Management Hub Agent"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Management Agent"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Fleet Application Management Service"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Custom Logs Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute RDMA GPU Monitoring"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Compute Instance Run Command"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute Instance Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute HPC RDMA Auto-Configuration"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Compute HPC RDMA Authentication"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Cloud Guard Workload Protection"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Block Volume Management"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Bastion"
      desired_state = "DISABLED"
    }
  }

  availability_config {
    is_live_migration_preferred = false
    recovery_action             = "RESTORE_INSTANCE"
  }

  create_vnic_details {
    display_name              = "tailscalerouter"
    subnet_id                 = oci_core_subnet.services.id
    assign_ipv6ip             = false
    assign_private_dns_record = false
    assign_public_ip          = "true"
    defined_tags              = var.creation_tags.instances_router
    freeform_tags             = {}
    hostname_label            = "tailscalerouter"
    nsg_ids                   = [oci_core_network_security_group.router.id]
    private_ip                = var.ip_addresses.router_create_vnic_details_1_private_ip
    security_attributes       = {}
    skip_source_dest_check    = true
  }
  defined_tags      = var.creation_tags.instances_router_2
  extended_metadata = {}
  fault_domain      = "FAULT-DOMAIN-1"
  freeform_tags     = {}

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
  metadata            = var.instance_metadata.router
  security_attributes = {}

  shape_config {
    local_volume_size_in_gbs = 0
    memory_in_gbs            = 1
    nvmes                    = 0
    ocpus                    = 1
    vcpus                    = 2
  }

  source_details {
    is_preserve_boot_volume_enabled = false
    source_id                       = var.image_ids.router
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

resource "oci_core_instance" "web" {
  display_name        = "doppelgangerhq.com"
  compartment_id      = var.tenancy_ocid
  availability_domain = var.availability_domains.ad_1
  shape               = "VM.Standard.A1.Flex"

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      name          = "Vulnerability Scanning"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Management Agent"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Custom Logs Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute RDMA GPU Monitoring"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Compute Instance Monitoring"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Compute HPC RDMA Auto-Configuration"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Compute HPC RDMA Authentication"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Cloud Guard Workload Protection"
      desired_state = "ENABLED"
    }

    plugins_config {
      name          = "Block Volume Management"
      desired_state = "DISABLED"
    }

    plugins_config {
      name          = "Bastion"
      desired_state = "DISABLED"
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
    defined_tags              = var.creation_tags.instances_web
    freeform_tags             = {}
    hostname_label            = "doppelgangerhq-com"
    nsg_ids                   = []
    private_ip                = var.ip_addresses.web_create_vnic_details_1_private_ip
    security_attributes       = {}
    skip_source_dest_check    = false
  }
  defined_tags      = var.creation_tags.instances_web_2
  extended_metadata = {}
  fault_domain      = "FAULT-DOMAIN-3"
  freeform_tags     = {}

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
  metadata            = var.instance_metadata.bailout
  security_attributes = {}

  shape_config {
    baseline_ocpu_utilization = "BASELINE_1_1"
    local_volume_size_in_gbs  = 0
    memory_in_gbs             = 6
    nvmes                     = 0
    ocpus                     = 2
    vcpus                     = 2
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
