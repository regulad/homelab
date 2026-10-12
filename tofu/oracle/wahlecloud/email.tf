locals {
  email_senders = [
    "noreply@regulad.xyz",
    "regulad@regulad.xyz",
  ]
}

resource "oci_email_dkim" "primary" {
  name            = "regulad-iad-20260815"
  description     = "recheck"
  email_domain_id = oci_email_email_domain.primary.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_email_email_domain" "primary" {
  name           = "regulad.xyz"
  compartment_id = var.tenancy_ocid

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_email_sender" "sender" {
  for_each = toset(local.email_senders)

  compartment_id = var.tenancy_ocid
  email_address  = each.value

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_policy" "mail" {
  name           = "svc-mail"
  compartment_id = var.tenancy_ocid
  description    = "mail entitlement"
  statements     = ["allow group svc-mail to use email-family in tenancy"]

  lifecycle {
    prevent_destroy = true
  }
}
