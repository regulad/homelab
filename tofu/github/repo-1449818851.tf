# Repository 1449818851, named RosellaView when written: the Sentry token its build uploads with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1449818851 = local.personal ? jsondecode(data.github_rest_api.repository_1449818851.body).name : ""
  repository_1449818851_actions_secrets = {
    SENTRY_AUTH_TOKEN = var.sentry_auth_tokens.rosellaview
  }
}

data "github_rest_api" "repository_1449818851" {
  endpoint = "repositories/1449818851"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_actions_secret" "repository_1449818851" {
  for_each = local.personal ? toset(keys(local.repository_1449818851_actions_secrets)) : toset([])

  repository  = local.repository_1449818851
  secret_name = each.key
  value       = local.repository_1449818851_actions_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
