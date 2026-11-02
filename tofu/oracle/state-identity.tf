# svc-tofu-state: the service user and policy OpenTofu's s3 backend authenticates with.
# Its customer secret key is created outside OpenTofu and kept in SOPS, so the key
# never lives in the state it unlocks.

resource "oci_identity_group" "state" {
  name           = "svc-tofu-state"
  compartment_id = var.tenancy_ocid
  description    = "OpenTofu remote state access"
  freeform_tags  = { "managed-by" = "opentofu" }
}

resource "oci_identity_user" "state" {
  name           = "svc-tofu-state@regulad.xyz"
  compartment_id = var.tenancy_ocid
  description    = "OpenTofu remote state backend"
  # Identity domains require a unique email for every user.
  email         = "svc-tofu-state@regulad.xyz"
  freeform_tags = { "managed-by" = "opentofu" }
}

# The S3 Compatibility API accepts only customer secret keys.
resource "oci_identity_user_capabilities_management" "state" {
  user_id                      = oci_identity_user.state.id
  can_use_api_keys             = false
  can_use_auth_tokens          = false
  can_use_console_password     = false
  can_use_customer_secret_keys = true
  can_use_smtp_credentials     = false
}

resource "oci_identity_user_group_membership" "state" {
  group_id = oci_identity_group.state.id
  user_id  = oci_identity_user.state.id
}

# Only the object operations the s3 backend uses. Without OBJECT_VERSION_DELETE
# the key cannot purge earlier state versions.
resource "oci_identity_policy" "state" {
  name           = "svc-tofu-state"
  compartment_id = var.tenancy_ocid
  description    = "OpenTofu remote state access"
  statements = [
    "allow group ${oci_identity_group.state.name} to read buckets in tenancy where target.bucket.name = '${oci_objectstorage_bucket.state.name}'",
    "allow group ${oci_identity_group.state.name} to manage objects in tenancy where all {target.bucket.name = '${oci_objectstorage_bucket.state.name}', any {request.permission = 'OBJECT_INSPECT', request.permission = 'OBJECT_READ', request.permission = 'OBJECT_CREATE', request.permission = 'OBJECT_OVERWRITE', request.permission = 'OBJECT_DELETE'}}",
  ]
  freeform_tags = { "managed-by" = "opentofu" }
}
