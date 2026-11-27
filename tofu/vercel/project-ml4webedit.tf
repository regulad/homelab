# ml4webedit: the project, deployed from regulad/ml4webedit.
resource "vercel_project" "ml4webedit" {
  name                                              = "ml4webedit"
  auto_assign_custom_domains                        = true
  automatically_expose_system_environment_variables = true
  build_machine_type                                = "basic"
  customer_success_code_visibility                  = false
  directory_listing                                 = false
  enable_affected_projects_deployments              = true
  framework                                         = "vite"
  function_failover                                 = false
  git_fork_protection                               = true
  git_lfs                                           = false
  node_version                                      = "24.x"
  on_demand_concurrent_builds                       = false
  preview_deployments_disabled                      = false
  prioritise_production_builds                      = true
  protected_sourcemaps                              = true

  git_repository = {
    production_branch = "main"
    repo              = "regulad/ml4webedit"
    type              = "github"
  }

  oidc_token_config = {
    issuer_mode = "team"
  }

  passport = {
    deployment_type = "all"
    enabled         = false
  }

  resource_config = {
    fluid                    = true
    function_default_regions = ["iad1"]
  }

  vercel_authentication = {
    deployment_type = "standard_protection_new"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The token the production build creates ml4webedit's Sentry release and
# uploads its source maps with, read by @sentry/vite-plugin. Preview builds,
# which report nothing, upload nothing.
resource "vercel_project_environment_variable" "ml4webedit_sentry_auth_token" {
  key        = "SENTRY_AUTH_TOKEN"
  project_id = vercel_project.ml4webedit.id
  sensitive  = true
  target     = ["production"]
  value      = var.sentry_auth_tokens["terraform-ml4webedit"]
}

# The site's Sentry DSN, tofu/sentry's ml4webedit project's, which
# regulad/ml4webedit's Vite build writes in, defaulting to the same value.
# Public, as every page ships it.
resource "vercel_project_environment_variable" "ml4webedit_vite_sentry_dsn" {
  key        = "VITE_SENTRY_DSN"
  project_id = vercel_project.ml4webedit.id
  sensitive  = false
  target     = ["production", "preview"]
  value      = data.terraform_remote_state.sentry.outputs.dsn.ml4webedit
}
