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

# tofu/gcp's own state passphrase, which prepare.sh reads from
# tofu/gcp/secrets.sops.yaml, to decrypt the outputs gcp.tf reads.
variable "gcp_state_encryption_passphrase" {
  type      = string
  sensitive = true
  nullable  = false
}

terraform {
  # Credentials and the endpoint, which names the tenancy, come from the
  # environment that sourcing prepare.sh exports from tofu/shared/backend.sops.env.
  backend "s3" {
    bucket         = "homelab-tofu-state"
    key            = "ga4/terraform.tfstate"
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
    key_provider "pbkdf2" "ga4" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "ga4" {
      keys = key_provider.pbkdf2.ga4
    }

    state {
      method   = method.aes_gcm.ga4
      enforced = true
    }

    plan {
      method   = method.aes_gcm.ga4
      enforced = true
    }

    # tofu/gcp's state, for gcp.tf. The key provider keeps tofu/gcp's name,
    # which its state's encryption metadata records.
    key_provider "pbkdf2" "gcp" {
      passphrase = var.gcp_state_encryption_passphrase
    }

    method "aes_gcm" "gcp" {
      keys = key_provider.pbkdf2.gcp
    }

    remote_state_data_sources {
      remote_state_data_source "gcp" {
        method = method.aes_gcm.gcp
      }
    }
  }
}
