# regulad-clonezilla: the bucket, and the Clonezilla key restricted to it.
resource "b2_bucket" "regulad_clonezilla" {
  bucket_name = "regulad-clonezilla"
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

resource "b2_application_key" "clonezilla" {
  key_name = "Clonezilla"
  capabilities = [
    "deleteFiles",
    "listBuckets",
    "listFiles",
    "readBucketEncryption",
    "readBucketLifecycleRules",
    "readBucketLogging",
    "readBucketNotifications",
    "readBucketReplications",
    "readBuckets",
    "readFiles",
    "shareFiles",
    "writeBucketEncryption",
    "writeBucketLifecycleRules",
    "writeBucketLogging",
    "writeBucketNotifications",
    "writeBucketReplications",
    "writeBuckets",
    "writeFiles",
  ]
  bucket_ids = [b2_bucket.regulad_clonezilla.bucket_id]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
