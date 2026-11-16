# Each project's DSN, by project slug: the public DSN of its Default key, which
# ansible-generated delivers to the services that report to it. A DSN only lets
# a client send events, and apps ship it in their code, so it is no secret; the
# provider marks it sensitive only because the same map holds the deprecated
# secret DSN.
output "dsn" {
  value = {
    for key in [
      sentry_key.doppelganger,
      sentry_key.matrix_synapse,
      sentry_key.peppercord,
      sentry_key.pheidippides_administrate,
      sentry_key.pheidippides_locate,
      sentry_key.pheidippides_notify,
      sentry_key.picture_triangulator,
      sentry_key.rosellaview,
    ] : key.project => nonsensitive(key.dsn["public"])
  }
}
