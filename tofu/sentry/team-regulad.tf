# regulad: the organization's one team, which holds every project.
resource "sentry_team" "regulad" {
  name         = "regulad"
  slug         = "regulad"
  organization = local.organization

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
