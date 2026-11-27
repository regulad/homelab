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

# The project's Firebase side, which Firebase added to it in 2021: no apps, and
# a default Hosting site with nothing released. Firebase can't be removed from a
# project once added, so destroying this only drops it from state.
resource "google_firebase_project" "home_assistant" {
  provider = google-beta.home_assistant
  project  = google_project.home_assistant.project_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Firebase Hosting's default site, named for the project, which Firebase made
# with it. Firebase can't delete a project's default site; it has nothing
# released.
resource "google_firebase_hosting_site" "home_assistant" {
  provider = google-beta.home_assistant
  project  = google_project.home_assistant.project_id
  site_id  = google_project.home_assistant.project_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Firebase's Admin SDK service agent, which Firebase made with the project.
# Nothing uses it: the project has no Firebase apps, and Home Assistant
# authenticates as home-assistant.
resource "google_service_account" "home_assistant_firebase_adminsdk" {
  project      = google_project.home_assistant.project_id
  account_id   = "firebase-adminsdk-g6ta6"
  display_name = "firebase-adminsdk"
  description  = "Firebase Admin SDK Service Agent"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
