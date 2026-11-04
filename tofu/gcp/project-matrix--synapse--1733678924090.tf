# matrix-synapse-1733678924090: the reCAPTCHA key Synapse's registration names.
locals {
  matrix_synapse_services = toset([
    "recaptchaenterprise.googleapis.com",
    "telemetry.googleapis.com",
  ])
}

resource "google_project" "matrix_synapse" {
  name       = "matrix-synapse"
  project_id = "matrix-synapse-1733678924090"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service" "matrix_synapse" {
  for_each = local.matrix_synapse_services

  project = google_project.matrix_synapse.project_id
  service = each.value

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_recaptcha_enterprise_key" "matrix" {
  project      = google_project.matrix_synapse.project_id
  display_name = "matrix.regulad.xyz"

  web_settings {
    integration_type              = "CHECKBOX"
    allow_all_domains             = true
    allowed_domains               = ["matrix.regulad.xyz"]
    allow_amp_traffic             = false
    challenge_security_preference = "BALANCE"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
