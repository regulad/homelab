# freeipa: the LDAP source that syncs users and groups from the old FreeIPA
# server, through the stand-in that answers at its address, and the CA
# certificate that server's certificate is checked against.

locals {
  # The old server's suffix, which the stand-in still serves.
  freeipa_base_dn = "dc=home,dc=arpa"
}

resource "authentik_source_ldap" "freeipa" {
  name                    = "freeipa"
  slug                    = "freeipa"
  server_uri              = "ldaps://freeipa.regulad-verizon-livingston.internal"
  bind_cn                 = "uid=svc-authentik,cn=users,cn=accounts,${local.freeipa_base_dn}"
  bind_password           = var.ldap_bind_password
  base_dn                 = local.freeipa_base_dn
  start_tls               = false # ldaps: TLS from the connection's start
  additional_user_dn      = "cn=users,cn=accounts"
  additional_group_dn     = "cn=groups,cn=accounts"
  group_object_filter     = "(objectClass=groupofnames)"
  group_membership_field  = "memberOf"
  object_uniqueness_field = "ipaUniqueID"
  # Users and groups gone from the directory are deleted here too.
  delete_not_found_objects = true
  property_mappings        = data.authentik_property_mapping_source_ldap.freeipa_user.ids
  property_mappings_group  = data.authentik_property_mapping_source_ldap.freeipa_group.ids

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The source's peer certificate, which the provider cannot set (versions.tf).
resource "authentik_certificate_key_pair" "ipa_ca" {
  name             = "ipa-ca.crt"
  certificate_data = file("${path.module}/../../ansible-common/roles/ca_trust/files/trusted/freeipa-home.arpa.crt")

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
    # The pair has no private key, which the provider reads back as "\n". An
    # update sends that "\n", which authentik's serializer trims to the empty
    # key the pair already has.
    ignore_changes = [key_data]
  }
}

data "authentik_property_mapping_source_ldap" "freeipa_user" {
  managed_list = [
    "goauthentik.io/sources/ldap/default-dn-path",
    "goauthentik.io/sources/ldap/default-name",
    "goauthentik.io/sources/ldap/default-mail",
    "goauthentik.io/sources/ldap/openldap-cn",
    "goauthentik.io/sources/ldap/openldap-uid",
  ]
}

data "authentik_property_mapping_source_ldap" "freeipa_group" {
  managed_list = ["goauthentik.io/sources/ldap/openldap-cn"]
}
