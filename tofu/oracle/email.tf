locals {
  # The domains whose senders Email Delivery approves, each once Oracle has
  # found its DKIM key's CNAME in DNS and made the key active.
  email_sender_domains = [
    oci_email_email_domain.primary.name,
    oci_email_email_domain.nefumllc_com.name,
    oci_email_email_domain.regulad_net.name,
  ]

  # The approved senders: mail's own, noreply@regulad.xyz, to which
  # ansible-generated/files/mail's postfix-generic.regexp rewrites root's and
  # localhost's mail, and which no FreeIPA account holds; then each address of
  # FreeIPA's declared accounts, from var.email_senders, in those domains.
  email_senders = concat(
    ["noreply@regulad.xyz"],
    [for address in var.email_senders : address if contains(local.email_sender_domains, split("@", address)[1])],
  )
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
# Delivery for as it does for regulad.xyz.
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

# svc-mail: the group the policy below lets send, its one user, which mail's
# Postfix signs in to Email Delivery as, and that user's membership. Oracle
# requires a description on a user and a group; these two got theirs as they
# were adopted.
resource "oci_identity_group" "mail" {
  name           = "svc-mail"
  compartment_id = var.tenancy_ocid
  description    = "Email Delivery senders"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_user" "mail" {
  name           = "svc-mail@regulad.xyz"
  compartment_id = var.tenancy_ocid
  description    = "mail's Postfix, relaying through Email Delivery"
  email          = "svc-mail@regulad.xyz"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_user_group_membership" "mail" {
  group_id = oci_identity_group.mail.id
  user_id  = oci_identity_user.mail.id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# svc-mail@regulad.xyz's SMTP credential, mail's login to Email Delivery, which
# mail's host_vars read from the mail_smtp_credential output. Oracle shows the
# password only as it creates the credential, so a rotation replaces it:
# `tofu apply -replace`, then mail's host_files. A user holds at most two. The
# provider does not mark the password sensitive, so a plan that replaces the
# credential prints the old one, and `tofu show` prints the current one: review
# such a plan only through its JSON, as the README sets out.
resource "oci_identity_smtp_credential" "mail" {
  user_id     = oci_identity_user.mail.id
  description = "mail's Postfix, relaying through Email Delivery"
}

resource "oci_identity_policy" "mail" {
  name           = "svc-mail"
  compartment_id = var.tenancy_ocid
  description    = "mail entitlement"
  statements     = ["allow group ${oci_identity_group.mail.name} to use email-family in tenancy"]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
