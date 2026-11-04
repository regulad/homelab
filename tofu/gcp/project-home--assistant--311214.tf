# home-assistant-311214: Home Assistant's Google integrations, with its Firebase
# project. Firebase's own service account is Firebase's, not adopted.
locals {
  home_assistant_services = toset([
    "appengine.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "calendar-json.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "datastore.googleapis.com",
    "fcm.googleapis.com",
    "firebase.googleapis.com",
    "firebasedynamiclinks.googleapis.com",
    "firebasehosting.googleapis.com",
    "firebaseinstallations.googleapis.com",
    "firebaseremoteconfig.googleapis.com",
    "firebaserules.googleapis.com",
    "fitness.googleapis.com",
    "googlecloudmessaging.googleapis.com",
    "homegraph.googleapis.com",
    "identitytoolkit.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "runtimeconfig.googleapis.com",
    "securetoken.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "telemetry.googleapis.com",
    "testing.googleapis.com",
  ])
}

# Its label firebase=enabled is Firebase's. The provider manages only the labels
# written here, so leaving it out leaves it alone.
resource "google_project" "home_assistant" {
  name       = "home-assistant"
  project_id = "home-assistant-311214"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service" "home_assistant" {
  for_each = local.home_assistant_services

  project = google_project.home_assistant.project_id
  service = each.value

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account" "home_assistant" {
  project      = google_project.home_assistant.project_id
  account_id   = "home-assistant"
  display_name = "home-assistant"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
