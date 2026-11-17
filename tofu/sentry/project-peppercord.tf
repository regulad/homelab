# peppercord: the project, named peppercord, its client key, its alert, and its code mapping.
resource "sentry_project" "peppercord" {
  name         = "peppercord"
  slug         = "peppercord"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "python"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_key" "peppercord" {
  name         = "Default"
  organization = sentry_project.peppercord.organization
  project      = sentry_project.peppercord.slug

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "peppercord" {
  organization = sentry_project.peppercord.organization
  project      = sentry_project.peppercord.slug
}

resource "sentry_alert" "peppercord" {
  name              = "Send a notification for high priority issues"
  organization      = sentry_project.peppercord.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.peppercord.id]
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

# The code mapping that links the project's stack frames to its repository.
resource "sentry_organization_code_mapping" "peppercord" {
  organization   = sentry_project.peppercord.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.peppercord.id
  project_id     = sentry_project.peppercord.internal_id
  default_branch = "main"
  stack_root     = "/app/"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
