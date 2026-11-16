# matrix-synapse: the project, named matrix-synapse, its client key, and its alert.
resource "sentry_project" "matrix_synapse" {
  name         = "matrix-synapse"
  slug         = "matrix-synapse"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "other"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_key" "matrix_synapse" {
  name         = "Default"
  organization = sentry_project.matrix_synapse.organization
  project      = sentry_project.matrix_synapse.slug

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "matrix_synapse" {
  organization = sentry_project.matrix_synapse.organization
  project      = sentry_project.matrix_synapse.slug
}

resource "sentry_alert" "matrix_synapse" {
  name              = "Send a notification for high priority issues"
  organization      = sentry_project.matrix_synapse.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.matrix_synapse.id]
  frequency_minutes = 30

  # Sentry's high-priority triggers, which the provider passes through
  # rather than models.
  legacy_trigger_conditions = ["new_high_priority_issue", "existing_high_priority_issue"]

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
