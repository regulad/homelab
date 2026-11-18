# Repository 1417443341, named nssm when written: the PAT that reads the private toolchain in regulad/vs.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1417443341 = jsondecode(data.github_rest_api.repository_1417443341.body).name
  repository_1417443341_actions_secrets = {
    PAT = var.github_pats["terraform-nssm--toolchain"]
  }
}

data "github_rest_api" "repository_1417443341" {
  endpoint = "repositories/1417443341"
}

resource "github_actions_secret" "repository_1417443341" {
  for_each = toset(keys(local.repository_1417443341_actions_secrets))

  repository  = local.repository_1417443341
  secret_name = each.key
  value       = local.repository_1417443341_actions_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
