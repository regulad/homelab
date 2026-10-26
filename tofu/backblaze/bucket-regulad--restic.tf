# regulad-restic: the restic repository every host backs up to, through B2's
# S3 API, and each of those hosts' keys to it.
locals {
  # The hosts that back up, by short hostname. The restic role configures
  # restic on a host only if it has a key here.
  restic_hosts = toset(["aboriginal", "dodo", "prodingus"])
}

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

# A key per host, so that one can be rotated or revoked alone. The capabilities
# are those of the S3 operations restic uses.
resource "b2_application_key" "restic" {
  for_each = local.restic_hosts

  key_name = "restic-${each.key}"
  capabilities = [
    "deleteFiles", # DeleteObject: prune's deletions, which hide a pack
    "listBuckets", # HeadBucket
    "listFiles",   # ListObjectsV2
    "readBuckets", # GetBucketLocation
    "readFiles",   # GetObject, HeadObject
    "writeFiles",  # PutObject and multipart uploads, and deletion by name
  ]
  bucket_ids = [b2_bucket.regulad_restic.bucket_id]
}

# The account's S3 endpoint, which names its region.
data "b2_account_info" "this" {}

# What the restic role reads, through the cloud.terraform.tf_output lookup.
output "restic" {
  description = "The restic repository, and each host's key to it by short hostname."
  sensitive   = true
  value = {
    repository = "s3:${trimprefix(data.b2_account_info.this.s3_api_url, "https://")}/${b2_bucket.regulad_restic.bucket_name}"
    keys = {
      for host, key in b2_application_key.restic : host => {
        access_key_id     = key.application_key_id
        secret_access_key = key.application_key
      }
    }
  }
}
