# tailscale-acls: the federated identity whose Actions runs apply the policy file and DNS.
resource "tailscale_federated_identity" "tailscale_acls" {
  issuer = local.github_actions_issuer
  # Runs on the default branch alone, as GitHub writes their identity token's sub.
  subject = "repo:regulad@52430642/tailscale-acls@1410698894:ref:refs/heads/master"
  scopes  = ["devices:core:read", "devices:posture_attributes", "dns", "policy_file"]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
