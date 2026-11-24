# Repository 1330474776, named tinyxnb when written: the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1330474776 = local.personal ? jsondecode(data.github_rest_api.repository_1330474776.body).name : ""
}

data "github_rest_api" "repository_1330474776" {
  endpoint = "repositories/1330474776"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_dependabot_secret" "repository_1330474776" {
  repository  = local.repository_1330474776
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats["terraform-dependabot--tinyxnb"]

  lifecycle {
    enabled = local.personal
  }
}
