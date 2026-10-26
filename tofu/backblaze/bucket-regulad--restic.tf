# regulad-restic: the restic repository every host backs up to, through B2's
# S3 API.
resource "b2_bucket" "regulad_restic" {
  bucket_name = "regulad-restic"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }

  # Keeps only the last version: a pack restic prunes is hidden, then deleted
  # a day later.
  lifecycle_rules {
    file_name_prefix             = ""
    days_from_hiding_to_deleting = 1
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
