# State bucket: the Object Storage bucket that holds OpenTofu state for every root.

# The namespace identifies the tenancy, so it is looked up rather than written.
data "oci_objectstorage_namespace" "tenancy" {
  compartment_id = var.tenancy_ocid
}

resource "oci_objectstorage_bucket" "state" {
  name           = "homelab-tofu-state"
  compartment_id = var.tenancy_ocid
  namespace      = data.oci_objectstorage_namespace.tenancy.namespace
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
  versioning     = "Enabled"
  freeform_tags  = { "managed-by" = "opentofu" }
}
