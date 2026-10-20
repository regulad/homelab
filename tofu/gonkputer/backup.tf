# backup: the weekly backup job.

resource "proxmox_backup_job" "weekly" {
  id       = "backup-1599bab8-f41c"
  schedule = "sun 01:00"
  enabled  = true
  storage  = "cephfs"
  all      = true
  compress = "zstd"
  exclude  = ["100", "101"] # aboriginal, dodo
  fleecing = {
    enabled = true
    storage = "local-lvm"
  }
  mode              = "snapshot"
  notes_template    = "{{guestname}}"
  notification_mode = "notification-system"
  prune_backups = {
    keep-weekly = "2"
  }
  repeat_missed = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
