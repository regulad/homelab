# Repository 861072224, named SupIR when written: the age key its release workflow
# decrypts signing.sops.yaml, its upload keystore, with; and the token its
# Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_861072224 = local.personal ? jsondecode(data.github_rest_api.repository_861072224.body).name : ""
  repository_861072224_actions_secrets = {
    SOPS_AGE_KEY = var.supir.sops_age_key
  }
}

data "github_rest_api" "repository_861072224" {
  endpoint = "repositories/861072224"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_actions_secret" "repository_861072224" {
  for_each = local.personal ? toset(keys(local.repository_861072224_actions_secrets)) : toset([])

  repository  = local.repository_861072224
  secret_name = each.key
  value       = local.repository_861072224_actions_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_dependabot_secret" "repository_861072224" {
  repository  = local.repository_861072224
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats.fine_grained["terraform-dependabot--supir"]

  lifecycle {
    enabled = local.personal
  }
}
