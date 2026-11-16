# pheidippides-notify: the project, named pheidippides-notify, and its client key.
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
