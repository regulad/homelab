# tofu/oracle's outputs: the OCI instances' public addresses, and the Email
# Delivery DKIM record, for the records that name them. state.tf decrypts its
# state with tofu/oracle's passphrase.

# The same bucket and options as the backend in state.tf, under tofu/oracle's key.
data "terraform_remote_state" "oracle" {
  backend = "s3"

  config = {
    bucket         = "homelab-tofu-state"
    key            = "oracle/terraform.tfstate"
    region         = "us-ashburn-1"
    use_path_style = true

    skip_credentials_validation = true # No STS
    skip_region_validation      = true # Not an AWS region
    skip_requesting_account_id  = true # No IAM or STS
    skip_metadata_api_check     = true # No instance metadata
    skip_s3_checksum            = true # No flexible-checksum headers
  }
}
