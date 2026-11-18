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
  }
}
