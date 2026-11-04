locals {
  region = "us-east-1"
}

# The credentials are arguments, not the environment's AWS_* variables, which
# belong to the state backend (OCI's S3 Compatibility API). Arguments take
# precedence over them.
provider "aws" {
  region     = local.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  token      = var.aws_session_token

  use_dualstack_endpoint = true

  # The backend's AWS_ENDPOINT_URL_S3 would otherwise send this provider's S3
  # calls to OCI. A custom endpoint ignores use_dualstack_endpoint, so it names
  # S3's dual-stack endpoint itself.
  endpoints {
    s3 = "https://s3.dualstack.${local.region}.amazonaws.com"
  }
}
