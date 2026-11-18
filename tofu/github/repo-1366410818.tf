# Repository 1366410818, named Blackb0x-- when written: the PAT that reads the Xcode mirror.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1366410818 = jsondecode(data.github_rest_api.repository_1366410818.body).name
  repository_1366410818_actions_secrets = {
    PAT = var.github_pats["terraform-blackb0x--xcode--mirror"]
  }
}

data "github_rest_api" "repository_1366410818" {
  endpoint = "repositories/1366410818"
}

resource "github_actions_secret" "repository_1366410818" {
  for_each = toset(keys(local.repository_1366410818_actions_secrets))

  repository  = local.repository_1366410818
  secret_name = each.key
  value       = local.repository_1366410818_actions_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
