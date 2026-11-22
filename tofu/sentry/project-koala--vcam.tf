# koala-vcam: the project, named koala-vcam, its client key, its alert, and its
# code mappings. koala-vcam is Koala's virtual camera, koala_vcam_source.dll, in
# regulad/Koala: Windows' camera service loads it, not Koala, so it reports to
# a project of its own.
resource "sentry_project" "koala_vcam" {
  name         = "koala-vcam"
  slug         = "koala-vcam"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "rust"

  # Sentry creates neither its own key named Default nor its own alert, so the
  # key and the alert below are the project's only ones. The issue-stream
  # monitor comes with the project either way.
  default_key   = false
  default_rules = false
}

resource "sentry_key" "koala_vcam" {
  name         = "Default"
  organization = sentry_project.koala_vcam.organization
  project      = sentry_project.koala_vcam.slug
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "koala_vcam" {
  organization = sentry_project.koala_vcam.organization
  project      = sentry_project.koala_vcam.slug
}

resource "sentry_alert" "koala_vcam" {
  name              = "Send a notification for high priority issues"
  organization      = sentry_project.koala_vcam.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.koala_vcam.id]
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

# The code mappings that link the DLL's stack frames to Koala's repository,
# from its root, as koala's do: its frames carry the absolute paths of the
# checkout that built it, which its PDB records. It builds no warlock-client,
# so it needs no mapping of the Warlock submodule's; its other dependencies'
# frames, windows-rs's and Rust's standard library's, stay unlinked, as
# koala's do.
resource "sentry_organization_code_mapping" "koala_vcam" {
  for_each = local.koala_checkouts

  organization   = sentry_project.koala_vcam.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.koala.id
  project_id     = sentry_project.koala_vcam.internal_id
  default_branch = "master"
  stack_root     = each.value
}
