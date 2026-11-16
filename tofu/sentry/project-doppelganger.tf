# doppelganger: the project, named doppelganger-front, and its client key.
resource "sentry_project" "doppelganger" {
  name         = "doppelganger-front"
  slug         = "doppelganger"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "other"

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
