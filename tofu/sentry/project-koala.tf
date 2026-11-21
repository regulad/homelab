# koala: the project, named Koala, its client key, its alert, and its code mappings.
locals {
  # Where each build of the app checks the repository out, as Windows writes the
  # path. Sentry matches a stack root as a literal prefix of a frame's path,
  # backslashes and case included, and writes each \ as / only after replacing it.
  koala_checkouts = {
    # Release builds, by .github/workflows/build.yml on GitHub's Windows runner.
    release = "D:\\a\\Koala\\Koala\\"
    # Development builds.
    development = "D:\\repositories\\Koala\\"
  }

  # The Warlock submodule, whose source GitHub keeps in its own repository, and
  # the branch it follows there: Koala's .gitmodules names none, so Warlock's
  # default.
  koala_warlock = {
    path   = "third_party\\warlock\\"
    branch = "master"
  }
}

resource "sentry_project" "koala" {
  name         = "Koala"
  slug         = "koala"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "rust"

  # Sentry creates neither its own key named Default nor its own alert, so the
  # key and the alert below are the project's only ones. The issue-stream
  # monitor comes with the project either way.
  default_key   = false
  default_rules = false
}

resource "sentry_key" "koala" {
  name         = "Default"
  organization = sentry_project.koala.organization
  project      = sentry_project.koala.slug
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "koala" {
  organization = sentry_project.koala.organization
  project      = sentry_project.koala.slug
}

resource "sentry_alert" "koala" {
  name              = "Send a notification for high priority issues"
  organization      = sentry_project.koala.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.koala.id]
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
resource "sentry_organization_code_mapping" "koala" {
  for_each = local.koala_checkouts

  organization   = sentry_project.koala.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.koala.id
  project_id     = sentry_project.koala.internal_id
  default_branch = "master"
  stack_root     = each.value
}

# The frames of the Warlock submodule, whose warlock-client crate Koala builds,
# which a longer stack root sends to its own repository ahead of the mappings
# above.
#
# WONTFIX: Koala's other dependencies, from crates.io and microsoft/windows-rs,
# and Rust's standard library get no mapping. They are upstream repositories,
# and Sentry links only to repositories its GitHub integration reaches, which is
# installed on regulad's account alone. Their frames stay unlinked.
resource "sentry_organization_code_mapping" "koala_warlock" {
  for_each = local.koala_checkouts

  organization   = sentry_project.koala.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.warlock.id
  project_id     = sentry_project.koala.internal_id
  default_branch = local.koala_warlock.branch
  stack_root     = "${each.value}${local.koala_warlock.path}"
}
