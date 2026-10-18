# web: instance, storage, addressing, and agent plugin policy.

locals {
  # Preserve the existing plugin states and provider list order.
  agent_plugins = [
    { name = "Vulnerability Scanning", desired_state = "DISABLED" },
    { name = "Management Agent", desired_state = "DISABLED" },
    { name = "Custom Logs Monitoring", desired_state = "ENABLED" },
    { name = "Compute RDMA GPU Monitoring", desired_state = "DISABLED" },
    { name = "Compute Instance Monitoring", desired_state = "ENABLED" },
    { name = "Compute HPC RDMA Auto-Configuration", desired_state = "DISABLED" },
    { name = "Compute HPC RDMA Authentication", desired_state = "DISABLED" },
    { name = "Cloud Guard Workload Protection", desired_state = "ENABLED" },
    { name = "Block Volume Management", desired_state = "DISABLED" },
    { name = "Bastion", desired_state = "DISABLED" },
  ]

  # Oracle-defined backup policies, keyed by exact name. These realm-wide IDs
  # belong to no compartment.
  backup_policy_ids = {
    "bronze" = "ocid1.volumebackuppolicy.oc1..aaaaaaaadrzfwjb5tflixtmy5axp2kx65uqakgnupfogabzjhtn5x5dfra6q"
  }

  # Oracle platform images, keyed by exact image name. These regional images are
  # shared across tenancies.
  platform_image_ids = {
    "Canonical-Ubuntu-24.04-Minimal-aarch64-2025.09.22-0" = "ocid1.image.oc1.iad.aaaaaaaaoxcb6yp3brpepe726ar3bsadhbs3mqrn6cyaeq2dneo75opgfija"
  }
}

resource "oci_core_instance" "web" {
  display_name        = "doppelgangerhq.com"
  compartment_id      = var.tenancy_ocid
  availability_domain = var.availability_domains.ad_1
  fault_domain        = "FAULT-DOMAIN-3"
  shape               = "VM.Standard.A1.Flex"
  metadata            = { ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBpJLGTbli8J2qSzPVpBzeNpVLLMakYeREp8jRkAePuMfMcNMcSNOcPyq+MXhdZc2npKPaZgeZj1w5mQIA4I0M+yhkduWYAwg8utchrqloVGd7NDd+BphSDJ8u/4S3J0iPEj1tsmdE2PJKm7CX6jzoSS7sQwE56HgjN/9Qsc+vsndpLPb0dnepCycuJ9SnfQrK4LMLjAzGsPyM8mpmG10mzS4RNmeF2Wqs/qHGKT1jXFSAUUlpQUSvUgaP0M3UJjYclSp84S3bxEGVzl0Os1l0YQeA1iKLZlzURhE/IiRQdNgI36hTfPeTx0TE2Uw8KOla6xcyijvIWJyPAChqdC42vIIEXtZ52cFDj0mlXjcXTPxBzVMZuusakzzReol6j12nXahy9OTW9feMnRnQSAN9xXLBZjiLpAeYJlggjdscvmjYgp3AkJBNMBTi7ECOsNBr0VMtU+l/ULf2KqwTdd6fzC/AnTIZOSXj2TtOxvM4Vn6lHEKWB8nxFOG1uU5I/xE=" }
  state               = "RUNNING"
  freeform_tags       = { "managed-by" = "opentofu" }

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
    private_ip                = "10.0.0.233"
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
    ocpus                     = 2
  }

  source_details {
    is_preserve_boot_volume_enabled = false
    source_id                       = local.platform_image_ids["Canonical-Ubuntu-24.04-Minimal-aarch64-2025.09.22-0"]
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

resource "oci_core_boot_volume" "web" {
  display_name         = "doppelgangerhq.com (Boot Volume)"
  compartment_id       = var.tenancy_ocid
  availability_domain  = var.availability_domains.ad_1
  is_auto_tune_enabled = false
  size_in_gbs          = "100"
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

resource "oci_core_volume_backup_policy_assignment" "web" {
  asset_id  = oci_core_boot_volume.web.id
  policy_id = local.backup_policy_ids.bronze
}

# This instance has one attached VNIC. one() fails if that changes.
data "oci_core_vnic_attachments" "web" {
  compartment_id = var.tenancy_ocid
  instance_id    = oci_core_instance.web.id

  filter {
    name   = "state"
    values = ["ATTACHED"]
  }
}

resource "oci_core_ipv6" "web" {
  display_name = "ipv620251101052630"
  subnet_id    = oci_core_subnet.legacy.id
  ip_address   = cidrhost(var.ipv6_subnet_cidr, parseint("0000403c37ed6001", 16))
  lifetime     = "EPHEMERAL"
  vnic_id      = one(data.oci_core_vnic_attachments.web.vnic_attachments).vnic_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
