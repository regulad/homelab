# Repository 876478767, named closecircuit when written: the age key its release workflow
# decrypts signing.sops.yaml, its upload keystore, with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_876478767 = jsondecode(data.github_rest_api.repository_876478767.body).name
  repository_876478767_actions_secrets = {
    SOPS_AGE_KEY = var.closecircuit.sops_age_key
  }
}

data "github_rest_api" "repository_876478767" {
  endpoint = "repositories/876478767"
}

resource "github_actions_secret" "repository_876478767" {
  for_each = toset(keys(local.repository_876478767_actions_secrets))

  repository  = local.repository_876478767
  secret_name = each.key
  value       = local.repository_876478767_actions_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
