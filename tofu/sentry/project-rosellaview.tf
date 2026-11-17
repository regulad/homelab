# rosellaview: the project, named RosellaView, its client key, its alert, and its code mappings.
locals {
  # Where each build of the app checks the repository out.
  rosellaview_checkouts = {
    # Store builds, by .github/workflows/release.yml on GitHub's runner.
    release = "/home/runner/work/RosellaView/RosellaView/"
    # Development builds, in place in the vega distrobox.
    development = "/home/regulad.linux/repositories/RosellaView/"
  }

  # The UxPlay submodule, whose source GitHub keeps in its own repository, and
  # the branch RosellaView's .gitmodules tracks there.
  rosellaview_uxplay = {
    path   = "third_party/UxPlay/"
    branch = "rosella"
  }
}

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

# The code mappings that link the app's stack frames to its repository. Its
# frames carry the absolute paths of the checkout that built it, as neither
# Metro's source map nor the native debug files are rewritten: a symbolicated
# JavaScript frame's filename is its source map's source, and a native frame's
# absolute path its DWARF path.
resource "sentry_organization_code_mapping" "rosellaview" {
  organization   = sentry_project.rosellaview.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.rosellaview.id
  project_id     = sentry_project.rosellaview.internal_id
  default_branch = "master"
  stack_root     = local.rosellaview_checkouts.release

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_organization_code_mapping" "rosellaview_development" {
  organization   = sentry_project.rosellaview.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.rosellaview.id
  project_id     = sentry_project.rosellaview.internal_id
  default_branch = "master"
  stack_root     = local.rosellaview_checkouts.development
}

# The frames of the UxPlay submodule, which a longer stack root sends to its own
# repository ahead of the mappings above.
#
# WONTFIX: RosellaView's other submodules, ffmpeg, libplist, openssl,
# node-api-headers and sentry-native, get no mapping. They are upstream
# repositories, and Sentry links only to repositories its GitHub integration
# reaches, which is installed on regulad's account alone. Their frames stay
# unlinked.
resource "sentry_organization_code_mapping" "rosellaview_uxplay" {
  for_each = local.rosellaview_checkouts

  organization   = sentry_project.rosellaview.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.uxplay.id
  project_id     = sentry_project.rosellaview.internal_id
  default_branch = local.rosellaview_uxplay.branch
  stack_root     = "${each.value}${local.rosellaview_uxplay.path}"
}
