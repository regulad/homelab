# Repository 1472171840, named terminal_polyfill when written: the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1472171840 = local.personal ? jsondecode(data.github_rest_api.repository_1472171840.body).name : ""
}

data "github_rest_api" "repository_1472171840" {
  endpoint = "repositories/1472171840"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_dependabot_secret" "repository_1472171840" {
  repository  = local.repository_1472171840
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats.fine_grained["terraform-dependabot--terminal_polyfill"]

  lifecycle {
    enabled = local.personal
  }
}
