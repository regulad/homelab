# Repository 823433320, named doppelganger when written: its Actions secrets and its Dependabot secrets.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_823433320 = jsondecode(data.github_rest_api.repository_823433320.body).name
  # The Nexus login its Gradle jobs read the maven-central proxy with, in both
  # stores: workflow runs on Dependabot's pull requests read only Dependabot's.
  repository_823433320_maven_mirror = {
    MAVEN_MIRROR_USERNAME = local.nexus_users["svc-doppelganger-ci"].userId
    MAVEN_MIRROR_PASSWORD = var.nexus_passwords["svc-doppelganger-ci"]
  }
  repository_823433320_actions_secrets = merge(local.repository_823433320_maven_mirror, {
    SENTRY_AUTH_TOKEN = var.sentry_auth_tokens.doppelganger

    SOPS_AGE_KEY = var.doppelganger.sops_age_key

    TS_AUDIENCE = data.terraform_remote_state.tailscale.outputs.audiences.doppelganger
    TS_OAUTH_ID = data.terraform_remote_state.tailscale.outputs.oauth_client_ids.doppelganger
  })
  repository_823433320_dependabot_secrets = merge(local.repository_823433320_maven_mirror, {
    DEPENDABOT_MERGE_TOKEN = var.github_pats["terraform-dependabot--doppelganger"]
  })
}

data "github_rest_api" "repository_823433320" {
  endpoint = "repositories/823433320"
}

resource "github_actions_secret" "repository_823433320" {
  for_each = toset(keys(local.repository_823433320_actions_secrets))

  repository  = local.repository_823433320
  secret_name = each.key
  value       = local.repository_823433320_actions_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_dependabot_secret" "repository_823433320" {
  for_each = toset(keys(local.repository_823433320_dependabot_secrets))

  repository  = local.repository_823433320
  secret_name = each.key
  value       = local.repository_823433320_dependabot_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
