# Credentials remain in the operator's OCI CLI profile.
provider "oci" {
  auth                = "SecurityToken"
  config_file_profile = "DEFAULT"
  region              = "us-ashburn-1"
}
