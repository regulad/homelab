# Repository 1417462382, named opentofu-registry when written: the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1417462382 = local.personal ? jsondecode(data.github_rest_api.repository_1417462382.body).name : ""
}

data "github_rest_api" "repository_1417462382" {
  endpoint = "repositories/1417462382"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_dependabot_secret" "repository_1417462382" {
  repository  = local.repository_1417462382
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats.fine_grained["terraform-dependabot--opentofu---registr"]

  lifecycle {
    enabled = local.personal
  }
}
