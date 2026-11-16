# pheidippides-administrate: the project, named pheidippides-administrate, and its client key.
resource "sentry_project" "pheidippides_administrate" {
  name         = "pheidippides-administrate"
  slug         = "pheidippides-administrate"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "android"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_key" "pheidippides_administrate" {
  name         = "Default"
  organization = sentry_project.pheidippides_administrate.organization
  project      = sentry_project.pheidippides_administrate.slug

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
