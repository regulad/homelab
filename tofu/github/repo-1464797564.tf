# Repository 1464797564, named jobs when written: the Actions secrets its seed
# workflow signs in to Jenkins with, as svc-jobs, which ansible-generated's
# jenkins role keeps in FreeIPA.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1464797564 = jsondecode(data.github_rest_api.repository_1464797564.body).name
  repository_1464797564_actions_secrets = {
    JENKINS_USER     = local.jenkins_users["svc-jobs"].name
    JENKINS_PASSWORD = var.jenkins_passwords["svc-jobs"]
  }
}

data "github_rest_api" "repository_1464797564" {
  endpoint = "repositories/1464797564"
}

resource "github_actions_secret" "repository_1464797564" {
  for_each = toset(keys(local.repository_1464797564_actions_secrets))

  repository  = local.repository_1464797564
  secret_name = each.key
  value       = local.repository_1464797564_actions_secrets[each.key]
}
