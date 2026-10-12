# tflint-ignore-file: terraform_required_version, terraform_required_providers
# Version pins live only in the root's versions.tf; this module inherits them.
terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}
