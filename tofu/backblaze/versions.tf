terraform {
  required_version = "= 1.13.2"
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "= 0.14.1"
    }
  }
}
