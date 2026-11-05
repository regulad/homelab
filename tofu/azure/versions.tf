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
    azuread = {
      source  = "hashicorp/azuread"
      version = "= 3.10.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.12.0"
    }
  }
}
