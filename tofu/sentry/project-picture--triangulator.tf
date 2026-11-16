# picture-triangulator: the project, named picture-triangulator, its client key, and its alert.
resource "sentry_project" "picture_triangulator" {
  name         = "picture-triangulator"
  slug         = "picture-triangulator"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "javascript-nextjs"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_key" "picture_triangulator" {
  name         = "Default"
  organization = sentry_project.picture_triangulator.organization
  project      = sentry_project.picture_triangulator.slug

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "picture_triangulator" {
  organization = sentry_project.picture_triangulator.organization
  project      = sentry_project.picture_triangulator.slug
}

resource "sentry_alert" "picture_triangulator" {
  name              = "Send a notification for new issues"
  organization      = sentry_project.picture_triangulator.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.picture_triangulator.id]
  frequency_minutes = 30

  trigger_conditions = [
    { first_seen_event = {} },
  ]

  action_filters = [
    {
      logic_type = "all"
      actions = [
        {
          email = {
            target_type      = "issue_owners"
            fallthrough_type = "ActiveMembers"
          }
        },
      ]
    },
  ]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
