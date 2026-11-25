# Repository 1403621188, named lime when written: the Sentry token its release workflow creates releases with,
# and the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1403621188 = local.personal ? jsondecode(data.github_rest_api.repository_1403621188.body).name : ""
  repository_1403621188_actions_secrets = {
    SENTRY_AUTH_TOKEN = var.sentry_auth_tokens["terraform-lime"]
  }
}

data "github_rest_api" "repository_1403621188" {
  endpoint = "repositories/1403621188"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_actions_secret" "repository_1403621188" {
  for_each = local.personal ? toset(keys(local.repository_1403621188_actions_secrets)) : toset([])

  repository  = local.repository_1403621188
  secret_name = each.key
  value       = local.repository_1403621188_actions_secrets[each.key]
}

resource "github_dependabot_secret" "repository_1403621188" {
  repository  = local.repository_1403621188
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats.fine_grained["terraform-dependabot--lime"]

  lifecycle {
    enabled = local.personal
  }
}
