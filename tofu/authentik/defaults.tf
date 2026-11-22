# defaults: objects authentik makes itself, read here and never managed. The
# flows come from its shipped blueprints, which re-apply them when an upgrade
# changes them, and the certificate from its first start.

data "authentik_flow" "default_provider_authorization_explicit_consent" {
  slug = "default-provider-authorization-explicit-consent"
}

data "authentik_flow" "default_provider_invalidation_flow" {
  slug = "default-provider-invalidation-flow"
}

# The key pair authentik generated at its first start, which signs the OAuth2
# providers' tokens. Only its ID is read: its certificate and private key stay
# out of state.
data "authentik_certificate_key_pair" "self_signed" {
  name              = "authentik Self-signed Certificate"
  fetch_certificate = false
  fetch_key         = false
}

# The OpenID Connect scopes an OAuth2 provider releases by default.
data "authentik_property_mapping_provider_scope" "openid" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}
