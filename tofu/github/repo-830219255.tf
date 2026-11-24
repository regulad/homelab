# Repository 830219255, named http-docker-cron when written: the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_830219255 = local.personal ? jsondecode(data.github_rest_api.repository_830219255.body).name : ""
}

data "github_rest_api" "repository_830219255" {
  endpoint = "repositories/830219255"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_dependabot_secret" "repository_830219255" {
  repository  = local.repository_830219255
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats["terraform-dependabot--http---docker---cr"]

  lifecycle {
    enabled = local.personal
  }
}
