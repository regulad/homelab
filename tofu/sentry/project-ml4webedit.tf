# ml4webedit: the project, named ml4webedit, its client key, its alert, and its code mapping.
resource "sentry_project" "ml4webedit" {
  name         = "ml4webedit"
  slug         = "ml4webedit"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "javascript-react"

  # Sentry creates neither its own key named Default nor its own alert, so the
  # key and the alert below are the project's only ones. The issue-stream
  # monitor comes with the project either way.
  default_key   = false
  default_rules = false
}

resource "sentry_key" "ml4webedit" {
  name         = "Default"
  organization = sentry_project.ml4webedit.organization
  project      = sentry_project.ml4webedit.slug
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "ml4webedit" {
  organization = sentry_project.ml4webedit.organization
  project      = sentry_project.ml4webedit.slug
}

resource "sentry_alert" "ml4webedit" {
  name              = "Send a notification for high priority issues"
  organization      = sentry_project.ml4webedit.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.ml4webedit.id]
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
}

# The code mapping that links ml4webedit's stack frames to the repository, from
# its root: the source maps Vite writes name each source by its path there.
resource "sentry_organization_code_mapping" "ml4webedit" {
  organization   = sentry_project.ml4webedit.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.ml4webedit.id
  project_id     = sentry_project.ml4webedit.internal_id
  default_branch = "main"
  stack_root     = "./"
}
