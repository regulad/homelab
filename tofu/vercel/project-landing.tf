# landing: the project, deployed from regulad/parkerwahle, its domain regulad.net, and Vercel's
# recommended records for it.
resource "vercel_project" "landing" {
  name                                              = "landing"
  auto_assign_custom_domains                        = true
  automatically_expose_system_environment_variables = true
  customer_success_code_visibility                  = false
  directory_listing                                 = false
  framework                                         = "nextjs"
  function_failover                                 = false
  git_fork_protection                               = true
  git_lfs                                           = false
  node_version                                      = "26.x"
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

# The site's primary domain.
resource "vercel_project_domain" "landing_regulad_net" {
  domain     = "regulad.net"
  project_id = vercel_project.landing.id
}

# The records Vercel recommends for regulad.net, which outputs.tf gives
# tofu/cloudflare for the apex's A records. Vercel recommends no IPv6 address:
# it serves custom domains over IPv4 only.
data "vercel_domain_config" "landing_regulad_net" {
  domain             = vercel_project_domain.landing_regulad_net.domain
  project_id_or_name = vercel_project.landing.id
}

# The site's Google Analytics tag, tofu/ga4's landing measurement ID, which
# landing's layout reads at build time, defaulting to the same
# value. Public, as every page serves it.
resource "vercel_project_environment_variable" "landing_next_public_ga_tag" {
  key        = "NEXT_PUBLIC_GA_TAG"
  project_id = vercel_project.landing.id
  sensitive  = false
  target     = ["production", "preview"]
  value      = data.terraform_remote_state.ga4.outputs.measurement_ids.landing
}

# The token the production build creates landing's Sentry release and
# uploads its source maps with, read by @sentry/nextjs's build plugin. Preview
# builds, which report nothing, upload nothing.
resource "vercel_project_environment_variable" "landing_sentry_auth_token" {
  key        = "SENTRY_AUTH_TOKEN"
  project_id = vercel_project.landing.id
  sensitive  = true
  target     = ["production"]
  value      = var.sentry_auth_tokens["terraform-parkerwahle"]
}

# The site's Sentry DSN, tofu/sentry's landing project's, which
# landing reads at build time, defaulting to the same value.
# Public, as every page ships it.
resource "vercel_project_environment_variable" "landing_next_public_sentry_dsn" {
  key        = "NEXT_PUBLIC_SENTRY_DSN"
  project_id = vercel_project.landing.id
  sensitive  = false
  target     = ["production", "preview"]
  value      = data.terraform_remote_state.sentry.outputs.dsn.landing
}
