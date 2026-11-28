# moved: every past address move, so old states and backups still plan cleanly.

# regulad/parkerwahle became regulad/landing, and its project took the new name.
moved {
  from = sentry_project.parkerwahle
  to   = sentry_project.landing
}

moved {
  from = sentry_key.parkerwahle
  to   = sentry_key.landing
}

moved {
  from = sentry_alert.parkerwahle
  to   = sentry_alert.landing
}

moved {
  from = sentry_organization_code_mapping.parkerwahle
  to   = sentry_organization_code_mapping.landing
}

moved {
  from = sentry_organization_repository.parkerwahle
  to   = sentry_organization_repository.landing
}
