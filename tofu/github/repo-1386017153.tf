# Repository 1386017153, named kodi-plugins when written: the tailnet identity and SSH login that publishing uses,
# and the age key it decrypts publish.sops.yaml, its SSH key, with; and the token its Dependabot auto-merge merges
# with.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1386017153 = local.personal ? jsondecode(data.github_rest_api.repository_1386017153.body).name : ""
  repository_1386017153_actions_secrets = {
    SOPS_AGE_KEY = var.kodi_plugins.sops_age_key

    SSH_KEY_HOST     = local.kodi_publish.host
    SSH_KEY_USER     = local.kodi_publish.user
    STATIC_FILE_BASE = local.kodi_publish.root

    TS_AUDIENCE = data.terraform_remote_state.tailscale.outputs.audiences.kodi_plugins
    TS_OAUTH_ID = data.terraform_remote_state.tailscale.outputs.oauth_client_ids.kodi_plugins
  }
}

data "github_rest_api" "repository_1386017153" {
  endpoint = "repositories/1386017153"

  lifecycle {
    enabled = local.personal
  }
}

resource "github_actions_secret" "repository_1386017153" {
  for_each = local.personal ? toset(keys(local.repository_1386017153_actions_secrets)) : toset([])

  repository  = local.repository_1386017153
  secret_name = each.key
  value       = local.repository_1386017153_actions_secrets[each.key]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_dependabot_secret" "repository_1386017153" {
  repository  = local.repository_1386017153
  secret_name = "DEPENDABOT_MERGE_TOKEN"
  value       = var.github_pats.fine_grained["terraform-dependabot--kodi---plugins"]

  lifecycle {
    enabled = local.personal
  }
}
