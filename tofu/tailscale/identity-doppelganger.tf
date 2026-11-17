# doppelganger: the federated identity whose Actions runs mint keys to join the tailnet.
resource "tailscale_federated_identity" "doppelganger" {
  description = "doppelganger"
  issuer      = local.github_actions_issuer
  # Runs on the default branch alone, as GitHub writes their identity token's sub.
  subject = "repo:regulad@52430642/doppelganger@823433320:ref:refs/heads/master"
  scopes  = ["auth_keys"]
  tags    = ["tag:ci-client-doppelganger"]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
