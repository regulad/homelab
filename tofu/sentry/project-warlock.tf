# warlock: the project, named Warlock, its client key, its alert, and its code mappings.
locals {
  # The devourer submodule, whose source GitHub keeps in its own repository, and
  # the branch Warlock's .gitmodules tracks there.
  warlock_devourer = {
    path   = "third_party\\devourer\\"
    branch = "warlock"
  }
}

resource "sentry_project" "warlock" {
  name         = "Warlock"
  slug         = "warlock"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "native"

  # Sentry creates neither its own key named Default nor its own alert, so the
  # key and the alert below are the project's only ones. The issue-stream
  # monitor comes with the project either way.
  default_key   = false
  default_rules = false
}

resource "sentry_key" "warlock" {
  name         = "Default"
  organization = sentry_project.warlock.organization
  project      = sentry_project.warlock.slug
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "warlock" {
  organization = sentry_project.warlock.organization
  project      = sentry_project.warlock.slug
}

resource "sentry_alert" "warlock" {
  name              = "Send a notification for high priority issues"
  organization      = sentry_project.warlock.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.warlock.id]
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

# The code mappings that link the app's stack frames to its repository, from
# its root. Its frames carry the absolute paths of the checkout that built it:
# a native frame's absolute path is its PDB's, which rustc and its linker write
# from the build's working directory.
resource "sentry_organization_code_mapping" "warlock" {
  for_each = local.warlock_checkouts

  organization   = sentry_project.warlock.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.warlock.id
  project_id     = sentry_project.warlock.internal_id
  default_branch = "master"
  stack_root     = each.value
}

# The frames of the devourer submodule, whose C library devourer-sys builds,
# which a longer stack root sends to its own repository ahead of the mappings
# above.
#
# FIXME: devourer is compiled by MSVC through CMake, not by rustc, and the form
# of the paths MSVC records in the PDB, such as their slashes and case, is
# unverified. Revisit at Warlock's first event with a devourer frame.
#
# WONTFIX: Warlock's other dependencies, from crates.io, and Rust's standard
# library get no mapping. They are upstream repositories, and Sentry links only
# to repositories its GitHub integration reaches, which is installed on
# regulad's account alone. Their frames stay unlinked.
resource "sentry_organization_code_mapping" "warlock_devourer" {
  for_each = local.warlock_checkouts

  organization   = sentry_project.warlock.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.devourer.id
  project_id     = sentry_project.warlock.internal_id
  default_branch = local.warlock_devourer.branch
  stack_root     = "${each.value}${local.warlock_devourer.path}"
}
