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
