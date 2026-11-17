# PepperCord: the federated identity whose Actions runs mint keys to join the tailnet.
resource "tailscale_federated_identity" "peppercord" {
  description = "PepperCord"
  issuer      = local.github_actions_issuer
  # Runs on the default branch alone, as GitHub writes their identity token's sub.
  subject = "repo:regulad@52430642/PepperCord@364397477:ref:refs/heads/main"
  scopes  = ["auth_keys"]
  tags    = ["tag:ci-client-peppercord"]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
