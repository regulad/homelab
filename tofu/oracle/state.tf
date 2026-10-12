# State stays on the operator machine for this import-only adoption.
# Configure a remote backend separately; do not create OCI resources implicitly.
variable "state_encryption_passphrase" {
  type      = string
  sensitive = true
  nullable  = false

  validation {
    condition     = length(var.state_encryption_passphrase) >= 32
    error_message = "Use the generated state passphrase from the encrypted inputs."
  }
}

terraform {
  encryption {
    key_provider "pbkdf2" "oracle" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "oracle" {
      keys = key_provider.pbkdf2.oracle
    }

    state {
      method   = method.aes_gcm.oracle
      enforced = true
    }

    plan {
      method   = method.aes_gcm.oracle
      enforced = true
    }
  }
}
