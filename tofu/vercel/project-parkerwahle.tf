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

# The site's Google Analytics tag, tofu/ga4's parkerwahle measurement ID, which
# regulad/parkerwahle's layout reads at build time, defaulting to the same
# value. Public, as every page serves it.
resource "vercel_project_environment_variable" "parkerwahle_next_public_ga_tag" {
  key        = "NEXT_PUBLIC_GA_TAG"
  project_id = vercel_project.parkerwahle.id
  sensitive  = false
  target     = ["production", "preview"]
  value      = data.terraform_remote_state.ga4.outputs.measurement_ids.parkerwahle
}

# The token the production build creates parkerwahle's Sentry release and
# uploads its source maps with, read by @sentry/nextjs's build plugin. Preview
# builds, which report nothing, upload nothing.
resource "vercel_project_environment_variable" "parkerwahle_sentry_auth_token" {
  key        = "SENTRY_AUTH_TOKEN"
  project_id = vercel_project.parkerwahle.id
  sensitive  = true
  target     = ["production"]
  value      = var.sentry_auth_tokens["terraform-parkerwahle"]
}
