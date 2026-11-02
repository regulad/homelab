# OpenTofu authenticates as Parker with an API signing key. His user OCID, the
# key's fingerprint and the private key come from provider.sops.env
# (OCI_USER_OCID, OCI_FINGERPRINT and OCI_PRIVATE_KEY), which sourcing
# prepare.sh exports, so the key never reaches .terraform/ or a saved plan.
# Deleting the key from his user in the OCI console revokes it.
provider "oci" {
  auth         = "ApiKey"
  tenancy_ocid = var.tenancy_ocid
  region       = "us-ashburn-1"
}
