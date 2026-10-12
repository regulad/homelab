resource "oci_core_boot_volume" "bailout" {
  display_name         = "bailout (Boot Volume)"
  compartment_id       = var.tenancy_ocid
  availability_domain  = var.availability_domains.ad_3
  defined_tags         = var.creation_tags.boot_volumes_bailout
  freeform_tags        = {}
  is_auto_tune_enabled = false
  size_in_gbs          = "47"

  source_details {
    type = "bootVolume"
  }
  vpus_per_gb = "10"

  lifecycle {
    prevent_destroy = true
    # Image-created volumes expose no clone/restore source. This required
    # schema placeholder is ignored for adoption; it is not a creation recipe.
    ignore_changes = [source_details]
  }
}

resource "oci_core_boot_volume" "livekit" {
  display_name         = "livekit (Boot Volume)"
  compartment_id       = var.tenancy_ocid
  availability_domain  = var.availability_domains.ad_1
  defined_tags         = var.creation_tags.boot_volumes_livekit
  freeform_tags        = {}
  is_auto_tune_enabled = false
  size_in_gbs          = "47"

  source_details {
    type = "bootVolume"
  }
  vpus_per_gb = "10"

  lifecycle {
    prevent_destroy = true
    # Image-created volumes expose no clone/restore source. This required
    # schema placeholder is ignored for adoption; it is not a creation recipe.
    ignore_changes = [source_details]
  }
}

resource "oci_core_boot_volume" "mail" {
  display_name         = "mail (Boot Volume)"
  compartment_id       = var.tenancy_ocid
  availability_domain  = var.availability_domains.ad_1
  defined_tags         = var.creation_tags.boot_volumes_mail
  freeform_tags        = {}
  is_auto_tune_enabled = false
  size_in_gbs          = "47"

  source_details {
    type = "bootVolume"
  }
  vpus_per_gb = "10"

  lifecycle {
    prevent_destroy = true
    # Image-created volumes expose no clone/restore source. This required
    # schema placeholder is ignored for adoption; it is not a creation recipe.
    ignore_changes = [source_details]
  }
}

resource "oci_core_boot_volume" "router" {
  display_name         = "tailscalerouter (Boot Volume)"
  compartment_id       = var.tenancy_ocid
  availability_domain  = var.availability_domains.ad_3
  defined_tags         = var.creation_tags.boot_volumes_router
  freeform_tags        = {}
  is_auto_tune_enabled = false
  size_in_gbs          = "47"

  source_details {
    type = "bootVolume"
  }
  vpus_per_gb = "10"

  lifecycle {
    prevent_destroy = true
    # Image-created volumes expose no clone/restore source. This required
    # schema placeholder is ignored for adoption; it is not a creation recipe.
    ignore_changes = [source_details]
  }
}

resource "oci_core_boot_volume" "web" {
  display_name         = "doppelgangerhq.com (Boot Volume)"
  compartment_id       = var.tenancy_ocid
  availability_domain  = var.availability_domains.ad_1
  defined_tags         = var.creation_tags.boot_volumes_web
  freeform_tags        = {}
  is_auto_tune_enabled = false
  size_in_gbs          = "100"

  source_details {
    type = "bootVolume"
  }
  vpus_per_gb = "10"

  lifecycle {
    prevent_destroy = true
    # Image-created volumes expose no clone/restore source. This required
    # schema placeholder is ignored for adoption; it is not a creation recipe.
    ignore_changes = [source_details]
  }
}

resource "oci_core_volume_backup_policy_assignment" "livekit" {
  asset_id  = oci_core_boot_volume.livekit.id
  policy_id = var.backup_policy_ids.livekit

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_volume_backup_policy_assignment" "mail" {
  asset_id  = oci_core_boot_volume.mail.id
  policy_id = var.backup_policy_ids.livekit

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_volume_backup_policy_assignment" "router" {
  asset_id  = oci_core_boot_volume.router.id
  policy_id = var.backup_policy_ids.livekit

  lifecycle {
    prevent_destroy = true
  }
}
