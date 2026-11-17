# kodi-plugins: the federated identity whose Actions runs mint keys to join the
# tailnet, as tag:ci-kodi, to publish to ingress.
resource "tailscale_federated_identity" "kodi_plugins" {
  description = "kodi-plugins"
  issuer      = local.github_actions_issuer
  # Runs on the default branch alone, as GitHub writes their identity token's sub.
  subject = "repo:regulad@52430642/kodi-plugins@1386017153:ref:refs/heads/master"
  scopes  = ["auth_keys"]
  tags    = ["tag:ci-kodi"]
}
