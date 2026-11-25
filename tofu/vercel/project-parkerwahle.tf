# parkerwahle: the project, deployed from regulad/parkerwahle, and its domains regulad.xyz and www.regulad.xyz.
resource "vercel_project" "parkerwahle" {
  name                                              = "parkerwahle"
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
  prioritise_production_builds                      = false
  protected_sourcemaps                              = false

  git_repository = {
    production_branch = "master"
    repo              = "regulad/parkerwahle"
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
    deployment_type = "standard_protection"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "vercel_project_domain" "parkerwahle_regulad_xyz" {
  domain     = "regulad.xyz"
  project_id = vercel_project.parkerwahle.id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "vercel_project_domain" "parkerwahle_www_regulad_xyz" {
  domain               = "www.regulad.xyz"
  project_id           = vercel_project.parkerwahle.id
  redirect_status_code = 308

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
