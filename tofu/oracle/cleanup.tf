# Leftovers made by hand, imported only to be destroyed: the next change
# removes this file. svc-mail's SMTP credential 20260815, exposed on
# 2026-11-19; three manual full backups of mail's, livekit's and
# tailscalerouter's boot volumes from 2026-06-21, which never expire; and a
# console history of tailscalerouter from 2025-12-08. Each ID is looked up, so
# no OCID of the tenancy's is written here.

locals {
  # The manual backups' IDs, by the boot volume each was taken of.
  manual_boot_volume_backups = {
    for backup in data.oci_core_boot_volume_backups.tenancy.boot_volume_backups :
    {
      (oci_core_boot_volume.mail.id)    = "mail"
      (oci_core_boot_volume.livekit.id) = "livekit"
      (oci_core_boot_volume.router.id)  = "router"
    }[backup.boot_volume_id] => backup.id
    if backup.source_type == "MANUAL"
  }
}

data "oci_identity_smtp_credentials" "svc_mail" {
  user_id = local.svc_mail_user_id
}

data "oci_core_boot_volume_backups" "tenancy" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_console_histories" "tenancy" {
  compartment_id = var.tenancy_ocid
}

import {
  to = oci_identity_smtp_credential.mail_20260815
  id = "users/${local.svc_mail_user_id}/smtpCredentials/${one([for credential in data.oci_identity_smtp_credentials.svc_mail.smtp_credentials : credential.id if credential.description == "20260815"])}"
}

import {
  for_each = local.manual_boot_volume_backups

  to = oci_core_boot_volume_backup.manual[each.key]
  id = each.value
}

import {
  to = oci_core_console_history.router
  id = one([for history in data.oci_core_console_histories.tenancy.console_histories : history.id if history.display_name == "consolehistory20251208221837"])
}

resource "oci_identity_smtp_credential" "mail_20260815" {
  user_id     = local.svc_mail_user_id
  description = "20260815"
}

resource "oci_core_boot_volume_backup" "manual" {
  for_each = local.manual_boot_volume_backups
}

resource "oci_core_console_history" "router" {
  instance_id = oci_core_instance.router.id
}
