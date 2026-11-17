# policy: the tailnet's policy file, from policy.hujson.tftpl. The template is
# the policy, comments and all, with the resolvers' and the Oracle VCN's
# addresses filled in from locals.tf, which also feeds dns.tf. Tailscale
# validates the policy and runs its tests before accepting it, so a failing
# test fails the apply and leaves the tailnet as it was.
resource "tailscale_acl" "policy" {
  acl = templatefile("${path.module}/policy.hujson.tftpl", {
    oracle    = local.oracle
    resolvers = local.resolvers
  })

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
