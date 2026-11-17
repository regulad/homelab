# doppelganger: the project, named doppelganger-front, its client key, its alert, its
# web-crawler filter, and its code mapping.
resource "sentry_project" "doppelganger" {
  name         = "doppelganger-front"
  slug         = "doppelganger"
  organization = local.organization
  teams        = [sentry_team.regulad.slug]
  platform     = "javascript-nextjs"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_key" "doppelganger" {
  name         = "Default"
  organization = sentry_project.doppelganger.organization
  project      = sentry_project.doppelganger.slug

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The default monitor of the project's new issues, which Sentry created with
# the project.
data "sentry_project_issue_stream_monitor" "doppelganger" {
  organization = sentry_project.doppelganger.organization
  project      = sentry_project.doppelganger.slug
}

resource "sentry_alert" "doppelganger" {
  name              = "doppelganger-front"
  organization      = sentry_project.doppelganger.organization
  monitor_ids       = [data.sentry_project_issue_stream_monitor.doppelganger.id]
  frequency_minutes = 1440

  trigger_conditions = [
    { first_seen_event = {} },
  ]

  action_filters = [
    {
      logic_type = "all"
      actions = [
        {
          email = {
            target_type = "team"
            # FIXME: this team no longer exists; regulad is the organization's
            # only team, so the alert emails no one. Revisit once Parker picks
            # its recipients.
            target_id = "4507672050991104"
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

# Drops the events of clients that identify themselves as web crawlers.
resource "sentry_project_inbound_data_filter" "doppelganger_web_crawlers" {
  organization = sentry_project.doppelganger.organization
  project      = sentry_project.doppelganger.slug
  filter_id    = "web-crawlers"
  active       = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The code mapping that links the project's stack frames to its repository.
resource "sentry_organization_code_mapping" "doppelganger" {
  organization   = sentry_project.doppelganger.organization
  integration_id = data.sentry_organization_integration.github.id
  repository_id  = sentry_organization_repository.doppelganger.id
  project_id     = sentry_project.doppelganger.internal_id
  default_branch = "master"
  stack_root     = "web/"
  source_root    = "apps/web/"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
