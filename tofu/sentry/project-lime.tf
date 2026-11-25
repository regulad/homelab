# lime: the project, named lime, its client key, its alert, and its code mappings.
resource "sentry_project" "lime" {
  name         = "lime"
  slug         = "lime"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "rust"

  # Sentry creates neither its own key named Default nor its own alert, so the
  # key and the alert below are the project's only ones. The issue-stream
  # monitor comes with the project either way.
  default_key   = false
  default_rules = false
}

resource "sentry_key" "lime" {
  name         = "Default"
  organization = sentry_project.lime.organization
  project      = sentry_project.lime.slug
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "lime" {
  organization = sentry_project.lime.organization
  project      = sentry_project.lime.slug
}

resource "sentry_alert" "lime" {
  name              = "Send a notification for high priority issues"
  organization      = sentry_project.lime.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.lime.id]
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

# The code mappings that link lime's stack frames to the repository, from its
# root. A Rust frame's absolute path is the one its debug information records,
# the checkout's that built it.
resource "sentry_organization_code_mapping" "lime" {
  for_each = local.lime_checkouts

  organization   = sentry_project.lime.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.lime.id
  project_id     = sentry_project.lime.internal_id
  default_branch = "master"
  stack_root     = each.value
}
