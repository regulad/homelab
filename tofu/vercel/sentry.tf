# tofu/sentry's outputs: each project's DSN, which parkerwahle's project gets as
# NEXT_PUBLIC_SENTRY_DSN. state.tf decrypts its state with tofu/sentry's
# passphrase.

# The same bucket and options as the backend in state.tf, under tofu/sentry's key.
data "terraform_remote_state" "sentry" {
  backend = "s3"

  config = {
    bucket         = "homelab-tofu-state"
    key            = "sentry/terraform.tfstate"
    region         = "us-ashburn-1"
    use_path_style = true

    skip_credentials_validation = true # No STS
    skip_region_validation      = true # Not an AWS region
    skip_requesting_account_id  = true # No IAM or STS
    skip_metadata_api_check     = true # No instance metadata
    skip_s3_checksum            = true # No flexible-checksum headers
  }
}
