# aporia-blue: the project, deployed from regulad/aporia-blue, and its domain aporia.blue.
resource "vercel_project" "aporia_blue" {
  name                                              = "aporia-blue"
  auto_assign_custom_domains                        = true
  automatically_expose_system_environment_variables = true
  customer_success_code_visibility                  = false
  directory_listing                                 = false
  framework                                         = "nextjs"
  function_failover                                 = false
  git_fork_protection                               = true
  git_lfs                                           = false
  node_version                                      = "24.x"
  on_demand_concurrent_builds                       = false
  preview_deployments_disabled                      = false
  prioritise_production_builds                      = true
  protected_sourcemaps                              = false

  git_repository = {
    production_branch = "master"
    repo              = "regulad/aporia-blue"
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

resource "vercel_project_domain" "aporia_blue_aporia_blue" {
  domain     = "aporia.blue"
  project_id = vercel_project.aporia_blue.id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
