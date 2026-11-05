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

# tofu/oracle's own state passphrase, which prepare.sh reads from
# tofu/oracle/secrets.sops.json, to decrypt the outputs oracle.tf reads.
variable "oracle_state_encryption_passphrase" {
  type      = string
  sensitive = true
  nullable  = false
}

terraform {
  # Credentials and the endpoint, which names the tenancy, come from the
  # environment that sourcing prepare.sh exports from tofu/shared/backend.sops.env.
  backend "s3" {
    bucket         = "homelab-tofu-state"
    key            = "cloudflare/terraform.tfstate"
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
    key_provider "pbkdf2" "cloudflare" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "cloudflare" {
      keys = key_provider.pbkdf2.cloudflare
    }

    state {
      method   = method.aes_gcm.cloudflare
      enforced = true
    }

    plan {
      method   = method.aes_gcm.cloudflare
      enforced = true
    }

    # tofu/oracle's state, for oracle.tf. The key provider keeps tofu/oracle's
    # name, which its state's encryption metadata records.
    key_provider "pbkdf2" "oracle" {
      passphrase = var.oracle_state_encryption_passphrase
    }

    method "aes_gcm" "oracle" {
      keys = key_provider.pbkdf2.oracle
    }

    remote_state_data_sources {
      remote_state_data_source "oracle" {
        method = method.aes_gcm.oracle
      }
    }
  }
}
