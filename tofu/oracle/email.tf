resource "oci_email_dkim" "primary" {
  name            = "regulad-iad-20260815"
  defined_tags    = var.creation_tags.email_dkims_primary
  description     = "recheck"
  email_domain_id = oci_email_email_domain.primary.id
  freeform_tags   = {}

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_email_email_domain" "primary" {
  name           = "regulad.xyz"
  compartment_id = var.tenancy_ocid
  defined_tags   = var.creation_tags.email_domains_primary
  freeform_tags  = {}

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_email_sender" "noreply" {
  compartment_id = var.tenancy_ocid
  defined_tags   = var.creation_tags.email_senders_noreply
  email_address  = var.email_addresses.noreply
  freeform_tags  = {}

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_email_sender" "personal" {
  compartment_id = var.tenancy_ocid
  defined_tags   = var.creation_tags.email_senders_personal
  email_address  = var.email_addresses.personal
  freeform_tags  = {}

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_policy" "mail" {
  name           = "svc-mail"
  compartment_id = var.tenancy_ocid
  defined_tags   = var.creation_tags.policies_mail
  description    = "mail entitlement"
  freeform_tags  = {}
  statements     = ["allow group svc-mail to use email-family in tenancy"]

  lifecycle {
    prevent_destroy = true
  }
}
