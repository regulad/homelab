# access: the LDAP realm and its ACL; users and groups come from the realm sync.

resource "proxmox_realm_ldap" "home_arpa" {
  # The bind password is not managed here: Proxmox never returns it, and it stays out of the repository.
  realm                 = "home.arpa"
  default               = true
  server1               = "freeipa.regulad-verizon-livingston.internal"
  mode                  = "ldaps"
  verify                = true
  base_dn               = "dc=home,dc=arpa"
  bind_dn               = "uid=svc-proxmox,cn=users,cn=accounts,dc=home,dc=arpa"
  case_sensitive        = true
  group_classes         = "posixGroup"
  group_name_attr       = "cn"
  sync_attributes       = "email=mail"
  sync_defaults_options = "remove-vanished=acl;entry;properties,scope=both"
  user_attr             = "uid"
  user_classes          = "posixAccount"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_acl" "admins_administrator" {
  path      = "/"
  group_id  = "admins-home.arpa"
  role_id   = "Administrator"
  propagate = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
