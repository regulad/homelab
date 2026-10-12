terraform {
  required_version = "= 1.13.1"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "= 9.9.0"
    }
  }
}
