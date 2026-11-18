# uulanding: the project, deployed from regulad/uulanding.
resource "vercel_project" "uulanding" {
  name                                              = "uulanding"
  auto_assign_custom_domains                        = false
  automatically_expose_system_environment_variables = true
  customer_success_code_visibility                  = false
  directory_listing                                 = false
  framework                                         = "nextjs"
  function_failover                                 = false
  git_fork_protection                               = true
  git_lfs                                           = false
  node_version                                      = "20.x"
  on_demand_concurrent_builds                       = false
  preview_deployments_disabled                      = false
  prioritise_production_builds                      = false
  protected_sourcemaps                              = false
  root_directory                                    = "apps/web"

  git_repository = {
    production_branch = "main"
    repo              = "regulad/uulanding"
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
    fluid                     = false
    function_default_cpu_type = "standard_legacy"
    function_default_regions  = ["iad1"]
  }

  vercel_authentication = {
    deployment_type = "standard_protection"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
