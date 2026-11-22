# memory: the memory store's application, the OAuth2 provider mcp-auth-proxy
# signs its users in through, and the binding that admits memoryusers alone.

# Synced from FreeIPA by the freeipa source (source-freeipa.tf), which owns it;
# ansible-generated's basic_memory role converges its members there.
data "authentik_group" "memoryusers" {
  name          = "memoryusers"
  include_users = false
}

resource "authentik_application" "memory" {
  name              = "Memory"
  slug              = "memory"
  protocol_provider = authentik_provider_oauth2.memory.id
  # Not in the user's library: it has no page to open, only the sign-in that
  # mcp-auth-proxy starts.
  meta_hide = true
}

# mcp-auth-proxy's client: it signs a user in with the authorization code
# flow, with PKCE, and reads the user's groups from userinfo, which the
# profile scope carries. authentik generates the client secret, which
# outputs.tf passes to ansible-generated.
resource "authentik_provider_oauth2" "memory" {
  name               = "Provider for Memory"
  client_id          = "memory"
  authorization_flow = data.authentik_flow.default_provider_authorization_explicit_consent.id
  invalidation_flow  = data.authentik_flow.default_provider_invalidation_flow.id
  signing_key        = data.authentik_certificate_key_pair.self_signed.id
  property_mappings  = data.authentik_property_mapping_provider_scope.openid.ids
  grant_types        = ["authorization_code"]

  allowed_redirect_uris = [
    { matching_mode = "strict", redirect_uri_type = "authorization", url = "https://memory.regulad.xyz/.auth/oidc/callback" },
  ]
}

# The application admits members of memoryusers alone, besides mcp-auth-proxy's
# own check of the groups claim.
resource "authentik_policy_binding" "memory_group_memoryusers" {
  target = authentik_application.memory.uuid
  group  = data.authentik_group.memoryusers.id
  order  = 0
}
