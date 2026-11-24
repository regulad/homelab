# koala-winget: regubot's SSH signing key for the winget-pkgs commits Koala's
# workflows make. Its private half is Koala's winget.sops.yaml, encrypted to
# Parker's age key and to the one tofu/github gives Koala's release environment.
# A new title or key replaces the key.
resource "github_user_ssh_signing_key" "koala_winget" {
  title = "koala-winget"
  key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPDJ+4dCc8ibM93rg2YpCbWVUOfRBHt3h0yTSLLPiM+C"

  lifecycle {
    enabled = local.bot
  }
}
