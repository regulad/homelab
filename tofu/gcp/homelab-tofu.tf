# homelab-tofu: the service account this root works as (see README.md), and its
# Owner grant on every project. Created by hand to bootstrap this root.
resource "google_service_account" "homelab_tofu" {
  project      = google_project.regulad.project_id
  account_id   = "homelab-tofu"
  display_name = "OpenTofu (regulad/homelab)"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# This root manages IAM itself, so a narrower grant would contain nothing.
resource "google_project_iam_member" "homelab_tofu" {
  for_each = toset([
    google_project.regulad.project_id,
    google_project.home_assistant.project_id,
    google_project.regulad_rclone.project_id,
    google_project.matrix_synapse.project_id,
  ])

  project = each.value
  role    = "roles/owner"
  member  = google_service_account.homelab_tofu.member
}
