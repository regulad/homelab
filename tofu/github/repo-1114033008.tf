# Repository 1114033008, named dotfiles when written: the token its Dependabot auto-merge merges with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1114033008 = local.personal ? jsondecode(data.github_rest_api.repository_1114033008.body).name : ""
}

data "github_rest_api" "repository_1114033008" {
  endpoint = "repositories/1114033008"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_dependabot_secret" "repository_1114033008" {
  repository  = local.repository_1114033008
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats.fine_grained["terraform-dependabot--dotfiles"]

  lifecycle {
    enabled = local.personal
  }
}
