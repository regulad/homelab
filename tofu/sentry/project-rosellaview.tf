# rosellaview: the project, named RosellaView, its client key, and its alert.
resource "sentry_project" "rosellaview" {
  name         = "RosellaView"
  slug         = "rosellaview"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "other"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_key" "rosellaview" {
  name         = "Default"
  organization = sentry_project.rosellaview.organization
  project      = sentry_project.rosellaview.slug

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "rosellaview" {
  organization = sentry_project.rosellaview.organization
  project      = sentry_project.rosellaview.slug
}

resource "sentry_alert" "rosellaview" {
  name              = "Send a notification for high priority issues"
  organization      = sentry_project.rosellaview.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.rosellaview.id]
  frequency_minutes = 0

  # Sentry's high-priority triggers, which the provider passes through
  # rather than models.
  legacy_trigger_conditions = ["new_high_priority_issue", "existing_high_priority_issue"]

  action_filters = [
    {
      logic_type = "any-short"
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
