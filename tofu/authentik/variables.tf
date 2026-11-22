# homelab-tofu's API token (providers.tf), which sourcing prepare.sh exports as
# TF_VAR_authentik_token. An input rather than the provider's AUTHENTIK_TOKEN,
# which the provider requires even to validate.
variable "authentik_token" {
  type      = string
  sensitive = true
  nullable  = false
}

# The freeipa source's bind password (source-freeipa.tf): svc-authentik's on
# the old FreeIPA server. authentik never returns it, so it is sent at every
# update of the source.
variable "ldap_bind_password" {
  type      = string
  sensitive = true
  nullable  = false
}
