# Repository 1406557576, named ml4webedit when written: the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1406557576 = local.personal ? jsondecode(data.github_rest_api.repository_1406557576.body).name : ""
}

data "github_rest_api" "repository_1406557576" {
  endpoint = "repositories/1406557576"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_dependabot_secret" "repository_1406557576" {
  repository  = local.repository_1406557576
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats.fine_grained["terraform-dependabot--ml4webedit"]

  lifecycle {
    enabled = local.personal
  }
}
