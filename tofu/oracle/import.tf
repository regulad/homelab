# Imports of what was made by hand: svc-mail's group, user and membership, and
# Network Path Analyzer's policy. Removed after the apply that imports them.
# Each ID is looked up, so no OCID of the tenancy's is written here.

locals {
  svc_mail_group_id = one([for group in data.oci_identity_groups.tenancy.groups : group.id if group.name == "svc-mail"])
}

data "oci_identity_groups" "tenancy" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_user_group_memberships" "svc_mail" {
  compartment_id = var.tenancy_ocid
  user_id        = local.svc_mail_user_id
  group_id       = local.svc_mail_group_id
}

data "oci_identity_policies" "tenancy" {
  compartment_id = var.tenancy_ocid
}

import {
  to = oci_identity_group.mail
  id = local.svc_mail_group_id
}

import {
  to = oci_identity_user.mail
  id = local.svc_mail_user_id
}

import {
  to = oci_identity_user_group_membership.mail
  id = one(data.oci_identity_user_group_memberships.svc_mail.memberships[*].id)
}

import {
  to = oci_identity_policy.network_path_analyzer
  id = one([for policy in data.oci_identity_policies.tenancy.policies : policy.id if policy.name == "VNPA-Tenancy-Policy"])
}
