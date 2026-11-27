# tflint-ignore-file: terraform_required_version  # OpenTofu's version is versions.tf's language block.
# State lives in the homelab-tofu-state bucket that tofu/oracle manages, under
# this root's own key, encrypted client-side with this root's own passphrase.
# It holds the environment variables' values, as the provider keeps them there.
terraform {
  # Credentials and the endpoint, which names the tenancy, come from the
  # environment that sourcing prepare.sh exports from tofu/shared/backend.sops.env.
  backend "s3" {
    bucket         = "homelab-tofu-state"
    key            = "vercel/terraform.tfstate"
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
    key_provider "pbkdf2" "vercel" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "vercel" {
      keys = key_provider.pbkdf2.vercel
    }

    state {
      method   = method.aes_gcm.vercel
      enforced = true
    }

    plan {
      method   = method.aes_gcm.vercel
      enforced = true
    }

    # tofu/ga4's state, for ga4.tf. The key provider keeps tofu/ga4's name,
    # which its state's encryption metadata records.
    key_provider "pbkdf2" "ga4" {
      passphrase = var.ga4_state_encryption_passphrase
    }

    method "aes_gcm" "ga4" {
      keys = key_provider.pbkdf2.ga4
    }

    # tofu/sentry's state, for sentry.tf, likewise.
    key_provider "pbkdf2" "sentry" {
      passphrase = var.sentry_state_encryption_passphrase
    }

    method "aes_gcm" "sentry" {
      keys = key_provider.pbkdf2.sentry
    }

    remote_state_data_sources {
      remote_state_data_source "ga4" {
        method = method.aes_gcm.ga4
      }

      remote_state_data_source "sentry" {
        method = method.aes_gcm.sentry
      }
    }
  }
}
