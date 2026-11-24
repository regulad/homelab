# Repository 1460757822, named terraform-provider-onesignal when written: the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1460757822 = local.personal ? jsondecode(data.github_rest_api.repository_1460757822.body).name : ""
}

data "github_rest_api" "repository_1460757822" {
  endpoint = "repositories/1460757822"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_dependabot_secret" "repository_1460757822" {
  repository  = local.repository_1460757822
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats["terraform-dependabot--terraform---provid"]

  lifecycle {
    enabled = local.personal
  }
}
