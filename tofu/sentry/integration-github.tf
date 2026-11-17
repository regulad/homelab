# github: the organization's GitHub integration, and the repositories it holds
# that the projects' code mappings link to.
data "sentry_organization_integration" "github" {
  organization = local.organization
  provider_key = "github"
  name         = "regulad"
}

resource "sentry_organization_repository" "doppelganger" {
  organization     = local.organization
  integration_type = data.sentry_organization_integration.github.provider_key
  integration_id   = data.sentry_organization_integration.github.id
  identifier       = "regulad/doppelganger"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_organization_repository" "peppercord" {
  organization     = local.organization
  integration_type = data.sentry_organization_integration.github.provider_key
  integration_id   = data.sentry_organization_integration.github.id
  identifier       = "regulad/PepperCord"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Sentry lists this repository as disabled; it is archived on GitHub.
resource "sentry_organization_repository" "picture_triangulator" {
  organization     = local.organization
  integration_type = data.sentry_organization_integration.github.provider_key
  integration_id   = data.sentry_organization_integration.github.id
  identifier       = "regulad/picture-triangulator"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_organization_repository" "rosellaview" {
  organization     = local.organization
  integration_type = data.sentry_organization_integration.github.provider_key
  integration_id   = data.sentry_organization_integration.github.id
  identifier       = "regulad/RosellaView"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "sentry_organization_repository" "uxplay" {
  organization     = local.organization
  integration_type = data.sentry_organization_integration.github.provider_key
  integration_id   = data.sentry_organization_integration.github.id
  identifier       = "regulad/UxPlay"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
