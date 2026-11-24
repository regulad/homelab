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
    # A build from the provider mirror that tofu.rc selects, with
    # github_user_ssh_signing_key and import for github_user_gpg_key.
    github = {
      source  = "integrations/github"
      version = "= 6.14.0-pr2366.pr3747.1"
    }
  }
}
