# tflint-ignore-file: terraform_required_version  # OpenTofu's version is versions.tf's language block.
# State lives in the homelab-tofu-state bucket that tofu/oracle manages, under
# this root's own key, encrypted client-side with this root's own passphrase.
# It holds every secret's value, as the provider has no write-only argument.
terraform {
  # Credentials and the endpoint, which names the tenancy, come from the
  # environment that sourcing prepare.sh exports from tofu/shared/backend.sops.env.
  backend "s3" {
    bucket         = "homelab-tofu-state"
    key            = "github/terraform.tfstate"
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
    key_provider "pbkdf2" "github" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "github" {
      keys = key_provider.pbkdf2.github
    }

    state {
      method   = method.aes_gcm.github
      enforced = true
    }

    plan {
      method   = method.aes_gcm.github
      enforced = true
    }

    # tofu/tailscale's state, for tailscale.tf. The key provider keeps
    # tofu/tailscale's name, which its state's encryption metadata records.
    key_provider "pbkdf2" "tailscale" {
      passphrase = var.tailscale_state_encryption_passphrase
    }

    method "aes_gcm" "tailscale" {
      keys = key_provider.pbkdf2.tailscale
    }

    # tofu/azure's state, for azure.tf, likewise under tofu/azure's name.
    key_provider "pbkdf2" "azure" {
      passphrase = var.azure_state_encryption_passphrase
    }

    method "aes_gcm" "azure" {
      keys = key_provider.pbkdf2.azure
    }

    remote_state_data_sources {
      remote_state_data_source "tailscale" {
        method = method.aes_gcm.tailscale
      }

      remote_state_data_source "azure" {
        method = method.aes_gcm.azure
      }
    }
  }
}
