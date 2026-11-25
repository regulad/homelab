# tinyxnb: the project, named tinyxnb, its client key, its alert, and its code mappings.
resource "sentry_project" "tinyxnb" {
  name         = "tinyxnb"
  slug         = "tinyxnb"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "dotnet"

  # Sentry creates neither its own key named Default nor its own alert, so the
  # key and the alert below are the project's only ones. The issue-stream
  # monitor comes with the project either way.
  default_key   = false
  default_rules = false
}

resource "sentry_key" "tinyxnb" {
  name         = "Default"
  organization = sentry_project.tinyxnb.organization
  project      = sentry_project.tinyxnb.slug
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "tinyxnb" {
  organization = sentry_project.tinyxnb.organization
  project      = sentry_project.tinyxnb.slug
}

resource "sentry_alert" "tinyxnb" {
  name              = "Send a notification for high priority issues"
  organization      = sentry_project.tinyxnb.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.tinyxnb.id]
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

# The code mappings that link the handler's and xnb2png's stack frames to the
# repository, from its root. A .NET frame's absolute path is the one its PDB
# records, the checkout's that built it.
resource "sentry_organization_code_mapping" "tinyxnb" {
  for_each = local.tinyxnb_checkouts

  organization   = sentry_project.tinyxnb.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.tinyxnb.id
  project_id     = sentry_project.tinyxnb.internal_id
  default_branch = "main"
  stack_root     = each.value
}
