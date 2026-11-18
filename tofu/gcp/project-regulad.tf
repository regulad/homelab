# regulad: the home project, which holds homelab-tofu and bills the APIs it calls.
locals {
  regulad_services = toset([
    "apikeys.googleapis.com",
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
    "developerknowledge.googleapis.com",
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

# The API key of Google's Developer Knowledge MCP server, which Parker's coding
# agents send as X-Goog-Api-Key from several machines, so it has no application
# restriction: it reaches the Developer Knowledge API and nothing else. Its value
# is the developer_knowledge_api_key output, which Parker keeps in Bitwarden for
# dotfiles.
resource "google_apikeys_key" "developer_knowledge" {
  name         = "developer-knowledge-mcp"
  display_name = "Developer Knowledge MCP"
  project      = google_project.regulad.project_id

  restrictions {
    api_targets {
      service = "developerknowledge.googleapis.com"
    }
  }

  depends_on = [
    google_project_service.regulad["apikeys.googleapis.com"],
    google_project_service.regulad["developerknowledge.googleapis.com"],
  ]
}
