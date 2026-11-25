# Repository 1403621188, named lime when written: the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1403621188 = local.personal ? jsondecode(data.github_rest_api.repository_1403621188.body).name : ""
}

data "github_rest_api" "repository_1403621188" {
  endpoint = "repositories/1403621188"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_dependabot_secret" "repository_1403621188" {
  repository  = local.repository_1403621188
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats.fine_grained["terraform-dependabot--lime"]

  lifecycle {
    enabled = local.personal
  }
}
