# immich: the Immich application, its OAuth2 provider, and the bindings that
# decide who may sign in to it.

# Both synced from FreeIPA by the freeipa source (source-freeipa.tf), which owns
# them.
data "authentik_group" "immichusers" {
  name          = "immichusers"
  include_users = false
}

data "authentik_user" "regulad" {
  username = "regulad"
}

resource "authentik_application" "immich" {
  name               = "Immich"
  slug               = "immich"
  protocol_provider  = authentik_provider_oauth2.immich.id
  meta_launch_url    = "https://immich.regulad.xyz/auth/login?autoLaunch=1"
  policy_engine_mode = "all"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "authentik_provider_oauth2" "immich" {
  name                    = "Provider for Immich"
  client_id               = "r81eUMeBrpqXf79rPSC3yQ0m8ekgnkLlXAsBkpM9"
  authorization_flow      = data.authentik_flow.default_provider_authorization_explicit_consent.id
  invalidation_flow       = data.authentik_flow.default_provider_invalidation_flow.id
  signing_key             = data.authentik_certificate_key_pair.self_signed.id
  property_mappings       = data.authentik_property_mapping_provider_scope.openid.ids
  access_token_validity   = "minutes=5"
  refresh_token_threshold = "hours=1"

  # Immich's mobile app's callback, then its web login and the settings page
  # that links an account.
  allowed_redirect_uris = [
    { matching_mode = "strict", redirect_uri_type = "authorization", url = "app.immich:///oauth-callback" },
    { matching_mode = "strict", redirect_uri_type = "authorization", url = "https://immich.regulad.xyz/auth/login" },
    { matching_mode = "strict", redirect_uri_type = "authorization", url = "https://immich.regulad.xyz/user-settings" },
  ]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# With the application's policy_engine_mode "all", a user signs in only if every
# binding passes: a member of immichusers who is not regulad.
resource "authentik_policy_binding" "immich_group_immichusers" {
  target = authentik_application.immich.uuid
  group  = data.authentik_group.immichusers.id
  order  = 0

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "authentik_policy_binding" "immich_user_regulad" {
  target = authentik_application.immich.uuid
  user   = data.authentik_user.regulad.pk
  order  = 1
  negate = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
