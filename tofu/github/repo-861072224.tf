# Repository 861072224, named SupIR when written: the age key its release workflow
# decrypts signing.sops.yaml, its upload keystore, with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_861072224 = jsondecode(data.github_rest_api.repository_861072224.body).name
  repository_861072224_actions_secrets = {
    SOPS_AGE_KEY = var.supir.sops_age_key
  }
}

data "github_rest_api" "repository_861072224" {
  endpoint = "repositories/861072224"
}

resource "github_actions_secret" "repository_861072224" {
  for_each = toset(keys(local.repository_861072224_actions_secrets))

  repository  = local.repository_861072224
  secret_name = each.key
  value       = local.repository_861072224_actions_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
