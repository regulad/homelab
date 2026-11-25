# Repository 1330474776, named tinyxnb when written: the Sentry token its release workflow creates releases with,
# and the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1330474776 = local.personal ? jsondecode(data.github_rest_api.repository_1330474776.body).name : ""
  repository_1330474776_actions_secrets = {
    SENTRY_AUTH_TOKEN = var.sentry_auth_tokens["terraform-tinyxnb"]
  }
}

data "github_rest_api" "repository_1330474776" {
  endpoint = "repositories/1330474776"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_actions_secret" "repository_1330474776" {
  for_each = local.personal ? toset(keys(local.repository_1330474776_actions_secrets)) : toset([])

  repository  = local.repository_1330474776
  secret_name = each.key
  value       = local.repository_1330474776_actions_secrets[each.key]
}

resource "github_dependabot_secret" "repository_1330474776" {
  repository  = local.repository_1330474776
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats.fine_grained["terraform-dependabot--tinyxnb"]

  lifecycle {
    enabled = local.personal
  }
}
