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
    # Served only by the mirror that tofu.rc lists; see README.md.
    ga4 = {
      source  = "himanoa/ga4"
      version = "= 0.1.0-remaining.2"
    }
  }
}
