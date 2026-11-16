# pheidippides-locate: the project, named pheidippides-locate, and its client key.
resource "sentry_project" "pheidippides_locate" {
  name         = "pheidippides-locate"
  slug         = "pheidippides-locate"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "android"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_key" "pheidippides_locate" {
  name         = "Default"
  organization = sentry_project.pheidippides_locate.organization
  project      = sentry_project.pheidippides_locate.slug

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
