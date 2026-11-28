# moved: every past address move, so old states and backups still plan cleanly.

# regulad/parkerwahle became regulad/landing, and its project took the new name.
moved {
  from = vercel_project.parkerwahle
  to   = vercel_project.landing
}

moved {
  from = vercel_project_domain.parkerwahle_regulad_xyz
  to   = vercel_project_domain.landing_regulad_xyz
}

moved {
  from = vercel_project_domain.parkerwahle_www_regulad_xyz
  to   = vercel_project_domain.landing_www_regulad_xyz
}

moved {
  from = vercel_project_environment_variable.parkerwahle_next_public_ga_tag
  to   = vercel_project_environment_variable.landing_next_public_ga_tag
}

moved {
  from = vercel_project_environment_variable.parkerwahle_sentry_auth_token
  to   = vercel_project_environment_variable.landing_sentry_auth_token
}

moved {
  from = vercel_project_environment_variable.parkerwahle_next_public_sentry_dsn
  to   = vercel_project_environment_variable.landing_next_public_sentry_dsn
}
