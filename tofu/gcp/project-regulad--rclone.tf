# regulad-rclone: rclone's access to Google Drive.
locals {
  regulad_rclone_services = toset([
    "analyticshub.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudtrace.googleapis.com",
    "dataform.googleapis.com",
    "dataplex.googleapis.com",
    "datastore.googleapis.com",
    "drive.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
  ])
}

resource "google_project" "regulad_rclone" {
  name       = "regulad rclone"
  project_id = "regulad-rclone"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service" "regulad_rclone" {
  for_each = local.regulad_rclone_services

  project = google_project.regulad_rclone.project_id
  service = each.value

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account" "rclone" {
  project    = google_project.regulad_rclone.project_id
  account_id = "rclone"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
