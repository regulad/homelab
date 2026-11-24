# Repository 1362143050, named aaoracled when written: the nexus-ios environment's Nexus login.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1362143050 = local.personal ? jsondecode(data.github_rest_api.repository_1362143050.body).name : ""
  repository_1362143050_environment_secrets = {
    NEXUS_USERNAME = local.nexus_users["nx-aaoracled"].userId
    NEXUS_PASSWORD = var.nexus_passwords["nx-aaoracled"]
  }
}

data "github_rest_api" "repository_1362143050" {
  endpoint = "repositories/1362143050"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_actions_environment_secret" "repository_1362143050" {
  for_each = local.personal ? toset(keys(local.repository_1362143050_environment_secrets)) : toset([])

  repository  = local.repository_1362143050
  environment = "nexus-ios"
  secret_name = each.key
  value       = local.repository_1362143050_environment_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
