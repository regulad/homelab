# regulad: the home project, which holds homelab-tofu and bills the APIs it calls.
locals {
  regulad_services = toset([
    "artifactregistry.googleapis.com",
    "autoscaling.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "datastore.googleapis.com",
    "dns.googleapis.com",
    "domains.googleapis.com",
    "gkebackup.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "networkconnectivity.googleapis.com",
    "osconfig.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "recaptchaenterprise.googleapis.com",
    "run.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "telemetry.googleapis.com",
    "texttospeech.googleapis.com",
  ])
}

resource "google_project" "regulad" {
  name            = "regulad"
  project_id      = "regulad"
  billing_account = "01E486-6286C6-F2B41D"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service" "regulad" {
  for_each = local.regulad_services

  project = google_project.regulad.project_id
  service = each.value

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account" "google_text_to_speech" {
  project      = google_project.regulad.project_id
  account_id   = "google-text-to-speech"
  display_name = "google-text-to-speech"
  description  = "For testing of google text-to-speech"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_recaptcha_enterprise_key" "pterodactyl" {
  project      = google_project.regulad.project_id
  display_name = "pterodactyl.regulad.xyz"

  web_settings {
    integration_type  = "SCORE"
    allow_all_domains = false
    allowed_domains   = ["pterodactyl.regulad.xyz"]
    allow_amp_traffic = false
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
