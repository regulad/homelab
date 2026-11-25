# Repository 364397477, named PepperCord when written: its Actions secrets and its Dependabot secret.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_364397477 = local.personal ? jsondecode(data.github_rest_api.repository_364397477.body).name : ""
  repository_364397477_actions_secrets = {
    PAT = var.github_pats.fine_grained["terraform-peppercord--resources"]

    SENTRY_AUTH_TOKEN = var.sentry_auth_tokens["terraform-peppercord"]

    TS_AUDIENCE = data.terraform_remote_state.tailscale.outputs.audiences.peppercord
    TS_OAUTH_ID = data.terraform_remote_state.tailscale.outputs.oauth_client_ids.peppercord
  }
}

data "github_rest_api" "repository_364397477" {
  endpoint = "repositories/364397477"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_actions_secret" "repository_364397477" {
  for_each = local.personal ? toset(keys(local.repository_364397477_actions_secrets)) : toset([])

  repository  = local.repository_364397477
  secret_name = each.key
  value       = local.repository_364397477_actions_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_dependabot_secret" "repository_364397477" {
  repository  = local.repository_364397477
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats.fine_grained["terraform-dependabot--peppercord"]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    enabled         = local.personal
    prevent_destroy = true
  }
}
