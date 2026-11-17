# doppelganger: the project, named doppelganger-front, its client key, and its code mapping.
resource "sentry_project" "doppelganger" {
  name         = "doppelganger-front"
  slug         = "doppelganger"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "javascript-nextjs"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_key" "doppelganger" {
  name         = "Default"
  organization = sentry_project.doppelganger.organization
  project      = sentry_project.doppelganger.slug

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The code mapping that links the project's stack frames to its repository.
resource "sentry_organization_code_mapping" "doppelganger" {
  organization   = sentry_project.doppelganger.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.doppelganger.id
  project_id     = sentry_project.doppelganger.internal_id
  default_branch = "master"
  stack_root     = "web/"
  source_root    = "apps/web/"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
