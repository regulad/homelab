# Each OAuth2 provider's client ID, by application slug.
output "oauth_client_ids" {
  value = {
    immich = authentik_provider_oauth2.immich.client_id
    memory = authentik_provider_oauth2.memory.client_id
  }
}

# The client secrets authentik generated for the providers whose clients
# ansible-generated configures, by application slug: mcp-auth-proxy's, for
# memory.
output "oauth_client_secrets" {
  value = {
    memory = authentik_provider_oauth2.memory.client_secret
  }
  sensitive = true
}
