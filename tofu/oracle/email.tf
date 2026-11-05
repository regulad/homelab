locals {
  email_senders = [
    "noreply@regulad.xyz",
    "regulad@regulad.xyz",
    "pw@nefumllc.com",
    "pw@regulad.net",
  ]
}

resource "oci_email_dkim" "primary" {
  name            = "regulad-iad-20260815"
  description     = "recheck"
  email_domain_id = oci_email_email_domain.primary.id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_email_email_domain" "primary" {
  name           = "regulad.xyz"
  compartment_id = var.tenancy_ocid

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# nefumllc.com and regulad.net, which mail's Postfix falls back to Email
# Delivery for as it does for regulad.xyz. Their senders can be approved only
# once Oracle has found each DKIM key's CNAME in DNS and made the key active.
resource "oci_email_email_domain" "nefumllc_com" {
  name           = "nefumllc.com"
  compartment_id = var.tenancy_ocid
}

resource "oci_email_dkim" "nefumllc_com" {
  name            = "nefumllc-iad-20261105"
  email_domain_id = oci_email_email_domain.nefumllc_com.id
}

resource "oci_email_email_domain" "regulad_net" {
  name           = "regulad.net"
  compartment_id = var.tenancy_ocid
}

resource "oci_email_dkim" "regulad_net" {
  name            = "regulad-iad-20261105"
  email_domain_id = oci_email_email_domain.regulad_net.id
}

resource "oci_email_sender" "sender" {
  for_each = toset(local.email_senders)

  compartment_id = var.tenancy_ocid
  email_address  = each.value

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_policy" "mail" {
  name           = "svc-mail"
  compartment_id = var.tenancy_ocid
  description    = "mail entitlement"
  statements     = ["allow group svc-mail to use email-family in tenancy"]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
