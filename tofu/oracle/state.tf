# State lives in the homelab-tofu-state bucket (see state-backend/), encrypted
# client-side before upload, so the bucket only ever holds ciphertext.
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
  # Credentials and the endpoint, which names the tenancy, come from the
  # environment that sourcing prepare.sh exports from tofu/shared/backend.sops.env.
  backend "s3" {
    bucket         = "homelab-tofu-state"
    key            = "oracle/terraform.tfstate"
    region         = "us-ashburn-1"
    use_path_style = true
    use_lockfile   = true

    skip_credentials_validation = true # No STS
    skip_region_validation      = true # Not an AWS region
    skip_requesting_account_id  = true # No IAM or STS
    skip_metadata_api_check     = true # No instance metadata
    skip_s3_checksum            = true # No flexible-checksum headers
  }

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
