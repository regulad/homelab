# Repository 832239288, named redroid-script when written: the Nexus login that pushes to the cr repository.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_832239288 = jsondecode(data.github_rest_api.repository_832239288.body).name
  repository_832239288_actions_secrets = {
    NEXUS_USERNAME = local.nexus_users["svc-redroid"].userId
    NEXUS_PASSWORD = var.nexus_passwords["svc-redroid"]
  }
}

data "github_rest_api" "repository_832239288" {
  endpoint = "repositories/832239288"
}

resource "github_actions_secret" "repository_832239288" {
  for_each = toset(keys(local.repository_832239288_actions_secrets))

  repository  = local.repository_832239288
  secret_name = each.key
  value       = local.repository_832239288_actions_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
