# Each OAuth2 provider's client ID, by application slug.
output "oauth_client_ids" {
  value = {
    immich = authentik_provider_oauth2.immich.client_id
  }
}
