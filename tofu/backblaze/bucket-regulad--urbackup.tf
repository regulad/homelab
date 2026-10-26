# regulad-urbackup: empty and unused, to be deleted after the adoption.
resource "b2_bucket" "regulad_urbackup" {
  bucket_name = "regulad-urbackup"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }

  # Keeps only the last version: a version that is hidden or replaced is
  # deleted a day later.
  lifecycle_rules {
    file_name_prefix             = ""
    days_from_hiding_to_deleting = 1
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
