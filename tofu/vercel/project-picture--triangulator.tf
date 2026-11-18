# picture-triangulator: the project, deployed from regulad/picture-triangulator.
resource "vercel_project" "picture_triangulator" {
  name                                              = "picture-triangulator"
  auto_assign_custom_domains                        = true
  automatically_expose_system_environment_variables = true
  build_command                                     = "turbo build"
  customer_success_code_visibility                  = false
  directory_listing                                 = false
  framework                                         = "nextjs"
  function_failover                                 = false
  git_fork_protection                               = true
  git_lfs                                           = false
  node_version                                      = "18.x"
  on_demand_concurrent_builds                       = false
  preview_deployments_disabled                      = false
  prioritise_production_builds                      = false
  protected_sourcemaps                              = false

  git_repository = {
    production_branch = "main"
    repo              = "regulad/picture-triangulator"
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
