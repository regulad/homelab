# pheidippides-locate: the project, named pheidippides-locate, its client key, its alert, and its code mapping.
resource "sentry_project" "pheidippides_locate" {
  name         = "pheidippides-locate"
  slug         = "pheidippides-locate"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "android"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_key" "pheidippides_locate" {
  name         = "Default"
  organization = sentry_project.pheidippides_locate.organization
  project      = sentry_project.pheidippides_locate.slug

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "pheidippides_locate" {
  organization = sentry_project.pheidippides_locate.organization
  project      = sentry_project.pheidippides_locate.slug
}

resource "sentry_alert" "pheidippides_locate" {
  name              = "Send a notification for new issues"
  organization      = sentry_project.pheidippides_locate.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.pheidippides_locate.id]
  frequency_minutes = 30

  trigger_conditions = [
    { first_seen_event = {} },
  ]

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

# The code mapping that links the app's stack frames to its source in the
# doppelganger repository. A frame's module, with each . as /, is its path
# under src/main/java.
resource "sentry_organization_code_mapping" "pheidippides_locate" {
  organization   = sentry_project.pheidippides_locate.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.doppelganger.id
  project_id     = sentry_project.pheidippides_locate.internal_id
  default_branch = "master"
  stack_root     = "xyz/regulad/pheidippides/locate/"
  source_root    = "pheidippides/PheidippidesLocate/app/src/main/java/xyz/regulad/pheidippides/locate/"
}
