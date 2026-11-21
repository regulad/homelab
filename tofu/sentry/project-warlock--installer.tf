# warlock-installer: the project, named warlock-installer, its client key, its
# alert, and its code mappings. warlock-installer is one of Warlock's programs,
# in regulad/Warlock.
resource "sentry_project" "warlock_installer" {
  name         = "warlock-installer"
  slug         = "warlock-installer"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "rust"

  # Sentry creates neither its own key named Default nor its own alert, so the
  # key and the alert below are the project's only ones. The issue-stream
  # monitor comes with the project either way.
  default_key   = false
  default_rules = false
}

resource "sentry_key" "warlock_installer" {
  name         = "Default"
  organization = sentry_project.warlock_installer.organization
  project      = sentry_project.warlock_installer.slug
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "warlock_installer" {
  organization = sentry_project.warlock_installer.organization
  project      = sentry_project.warlock_installer.slug
}

resource "sentry_alert" "warlock_installer" {
  name              = "Send a notification for high priority issues"
  organization      = sentry_project.warlock_installer.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.warlock_installer.id]
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

# The code mappings that link the program's stack frames to Warlock's
# repository, from its root, as warlock's do: its frames carry the absolute
# paths of the checkout that built it, which its PDB records. It builds no
# devourer, so it needs no mapping of devourer's; its other dependencies'
# frames stay unlinked, as warlock's do.
resource "sentry_organization_code_mapping" "warlock_installer" {
  for_each = local.warlock_checkouts

  organization   = sentry_project.warlock_installer.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.warlock.id
  project_id     = sentry_project.warlock_installer.internal_id
  default_branch = "master"
  stack_root     = each.value
}
