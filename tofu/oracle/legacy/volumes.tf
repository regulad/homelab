resource "oci_core_boot_volume" "web" {
  display_name         = "doppelgangerhq.com (Boot Volume)"
  compartment_id       = var.tenancy_ocid
  availability_domain  = var.availability_domains.ad_1
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
