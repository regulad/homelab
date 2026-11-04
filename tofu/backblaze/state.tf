# tflint-ignore-file: terraform_required_version  # OpenTofu's version is versions.tf's language block.
# State lives in the homelab-tofu-state bucket that tofu/oracle manages, under
# this root's own key, encrypted client-side with this root's own passphrase.
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
    key            = "backblaze/terraform.tfstate"
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
    key_provider "pbkdf2" "backblaze" {
      passphrase = var.state_encryption_passphrase
      # State under the passphrase set on 2026-11-04 stores its salt under
      # this name, apart from the previous passphrase's default name,
      # key_provider.pbkdf2.backblaze. Never change it.
      encrypted_metadata_alias = "backblaze-2026-11-04"
    }

    method "aes_gcm" "backblaze" {
      keys = key_provider.pbkdf2.backblaze
    }

    state {
      method   = method.aes_gcm.backblaze
      enforced = true
    }

    plan {
      method   = method.aes_gcm.backblaze
      enforced = true
    }
  }
}
