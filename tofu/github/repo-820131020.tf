# Repository 820131020, named parkerwahle when written: the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_820131020 = local.personal ? jsondecode(data.github_rest_api.repository_820131020.body).name : ""
}

data "github_rest_api" "repository_820131020" {
  endpoint = "repositories/820131020"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_dependabot_secret" "repository_820131020" {
  repository  = local.repository_820131020
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats["terraform-dependabot--parkerwahle"]

  lifecycle {
    enabled = local.personal
  }
}
