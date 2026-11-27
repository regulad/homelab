# tofu/ga4's outputs: each property's measurement ID, which parkerwahle's
# project gets as NEXT_PUBLIC_GA_TAG. state.tf decrypts its state with
# tofu/ga4's passphrase.

# The same bucket and options as the backend in state.tf, under tofu/ga4's key.
data "terraform_remote_state" "ga4" {
  backend = "s3"

  config = {
    bucket         = "homelab-tofu-state"
    key            = "ga4/terraform.tfstate"
    region         = "us-ashburn-1"
    use_path_style = true

    skip_credentials_validation = true # No STS
    skip_region_validation      = true # Not an AWS region
    skip_requesting_account_id  = true # No IAM or STS
    skip_metadata_api_check     = true # No instance metadata
    skip_s3_checksum            = true # No flexible-checksum headers
  }
}
