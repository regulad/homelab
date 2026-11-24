# Repository 1463115679, named Warlock when written: its signing environments,
# with the refs each admits, and each one's Entra ID sign-in and the Artifact
# Signing account and profile it signs with; and the release environment's
# Sentry token, and the tokens its winget job uses.
# tofu/azure's federated credential for each environment trusts
# runs in it alone, so the refs an environment admits are the refs that can sign
# as it. None of the signing values is secret; they are secrets as the
# repositories' other plaintext values are.
locals {
  # Its current name, which GitHub's API takes. The settings bot owns the name.
  repository_1463115679 = local.personal ? jsondecode(data.github_rest_api.repository_1463115679.body).name : ""

  # The environments tofu/azure's warlock_profiles names, with the branches and
  # tags each admits.
  repository_1463115679_environments = {
    release = { branches = ["master"], tags = ["v*"] }
    testing = { branches = ["master", "testing"], tags = [] }
  }

  repository_1463115679_deployment_policies = merge([
    for environment, refs in local.repository_1463115679_environments : merge(
      { for pattern in refs.branches : "${environment}/branch/${pattern}" => { environment = environment, branch = pattern, tag = null } },
      { for pattern in refs.tags : "${environment}/tag/${pattern}" => { environment = environment, branch = null, tag = pattern } },
    )
  ]...)

  # By environment and name: tofu/azure's application for that environment, and
  # the profile it is granted.
  repository_1463115679_signing_secrets = merge([
    for environment, profile in data.terraform_remote_state.azure.outputs.warlock_profiles : {
      for name, value in {
        AZURE_CLIENT_ID       = data.terraform_remote_state.azure.outputs.oauth_client_ids["warlock-${environment}"]
        AZURE_TENANT_ID       = data.terraform_remote_state.azure.outputs.tenant_id
        AZURE_SUBSCRIPTION_ID = data.terraform_remote_state.azure.outputs.subscription_id

        ARTIFACT_SIGNING_ENDPOINT = data.terraform_remote_state.azure.outputs.artifact_signing.endpoint
        ARTIFACT_SIGNING_ACCOUNT  = data.terraform_remote_state.azure.outputs.artifact_signing.account
        ARTIFACT_SIGNING_PROFILE  = profile
      } : "${environment}/${name}" => { environment = environment, name = name, value = value }
    }
  ]...)

  # The signing secrets; the Sentry organization token that tagged builds,
  # which only release admits, create releases and upload PDBs with; and what
  # release's winget job uses: regubot's token, which it submits with through
  # Komac, and regulad's notifications token, with which it subscribes him to
  # the pull request.
  repository_1463115679_environment_secrets = merge(local.repository_1463115679_signing_secrets, {
    "release/SENTRY_AUTH_TOKEN"           = { environment = "release", name = "SENTRY_AUTH_TOKEN", value = var.sentry_auth_tokens.warlock }
    "release/WINGET_TOKEN"                = { environment = "release", name = "WINGET_TOKEN", value = var.bot_github_pats["terraform-warlock--winget"] }
    "release/REGULAD_NOTIFICATIONS_TOKEN" = { environment = "release", name = "REGULAD_NOTIFICATIONS_TOKEN", value = var.github_pats["terraform-warlock--notifications"] }
  })
}

data "github_rest_api" "repository_1463115679" {
  endpoint = "repositories/1463115679"

  lifecycle {
    enabled = local.personal
  }
}

# Each admits only the refs its deployment policies name.
resource "github_repository_environment" "repository_1463115679" {
  for_each = local.personal ? local.repository_1463115679_environments : {}

  repository  = local.repository_1463115679
  environment = each.key

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_environment_deployment_policy" "repository_1463115679" {
  for_each = local.personal ? local.repository_1463115679_deployment_policies : {}

  repository     = local.repository_1463115679
  environment    = github_repository_environment.repository_1463115679[each.value.environment].environment
  branch_pattern = each.value.branch
  tag_pattern    = each.value.tag
}

resource "github_actions_environment_secret" "repository_1463115679" {
  for_each = local.personal ? local.repository_1463115679_environment_secrets : {}

  repository  = local.repository_1463115679
  environment = github_repository_environment.repository_1463115679[each.value.environment].environment
  secret_name = each.value.name
  value       = each.value.value
}
