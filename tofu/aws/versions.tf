# tflint-ignore-file: terraform_required_version
# OpenTofu's own version constraint. Since 1.12, OpenTofu reads required_version
# in a .tf file as its predecessor's and ignores it; it enforces this block.
language {
  compatible_with {
    opentofu = "~> 1.13.1"
  }
}

terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "= 2.8.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.71.0"
    }
  }
}
