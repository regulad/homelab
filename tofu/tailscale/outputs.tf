# The federated identities' client IDs, by repository, which tofu/github sets
# as each repository's TS_OAUTH_ID. OAuth client IDs are no secret.
output "oauth_client_ids" {
  value = {
    doppelganger = tailscale_federated_identity.doppelganger.id
    kodi_plugins = tailscale_federated_identity.kodi_plugins.id
    peppercord   = tailscale_federated_identity.peppercord.id
  }
}

# Each identity's audience, which a run requests its identity token for.
output "audiences" {
  value = {
    doppelganger = tailscale_federated_identity.doppelganger.audience
    kodi_plugins = tailscale_federated_identity.kodi_plugins.audience
    peppercord   = tailscale_federated_identity.peppercord.audience
  }
}
