# pheidippides-notify: the project, named pheidippides-notify, its client key, and its code mapping.
resource "sentry_project" "pheidippides_notify" {
  name         = "pheidippides-notify"
  slug         = "pheidippides-notify"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "android"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_key" "pheidippides_notify" {
  name         = "Default"
  organization = sentry_project.pheidippides_notify.organization
  project      = sentry_project.pheidippides_notify.slug

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The code mapping that links the app's stack frames to its source in the
# doppelganger repository. A frame's module, with each . as /, is its path
# under src/main/java.
resource "sentry_organization_code_mapping" "pheidippides_notify" {
  organization   = sentry_project.pheidippides_notify.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.doppelganger.id
  project_id     = sentry_project.pheidippides_notify.internal_id
  default_branch = "master"
  stack_root     = "xyz/regulad/pheidippides/notify/"
  source_root    = "pheidippides/PheidippidesNotify/app/src/main/java/xyz/regulad/pheidippides/notify/"
}
