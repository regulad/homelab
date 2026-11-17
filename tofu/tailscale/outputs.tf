# The federated identities' client IDs, by repository, which tofu/github sets
# as each repository's TS_OAUTH_ID. OAuth client IDs are no secret.
output "oauth_client_ids" {
  value = {
    doppelganger   = tailscale_federated_identity.doppelganger.id
    peppercord     = tailscale_federated_identity.peppercord.id
    tailscale_acls = tailscale_federated_identity.tailscale_acls.id
  }
}

# Each identity's audience, which a run requests its identity token for.
output "audiences" {
  value = {
    doppelganger   = tailscale_federated_identity.doppelganger.audience
    peppercord     = tailscale_federated_identity.peppercord.audience
    tailscale_acls = tailscale_federated_identity.tailscale_acls.audience
  }
}

output "tailnet_id" {
  value = local.tailnet_id
}
