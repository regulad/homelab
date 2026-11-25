# github-readme-stats: the project, deployed from regulad/github-readme-stats, and its environment variable PAT_1.
resource "vercel_project" "github_readme_stats" {
  name                                              = "github-readme-stats"
  auto_assign_custom_domains                        = true
  automatically_expose_system_environment_variables = true
  build_machine_type                                = "basic"
  customer_success_code_visibility                  = false
  directory_listing                                 = false
  enable_affected_projects_deployments              = true
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
    repo              = "regulad/github-readme-stats"
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

resource "vercel_project_environment_variable" "github_readme_stats_pat_1" {
  key        = "PAT_1"
  project_id = vercel_project.github_readme_stats.id
  sensitive  = true
  target     = ["production"]
  value      = var.github_pats.pat["terraform-github--readme--stats"]
  visibility = "secret"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
