# warlock-winget: regubot's SSH signing key for the winget-pkgs commits
# Warlock's workflows make. Its private half is Warlock's winget.sops.yaml,
# encrypted to Parker's age key and to the one tofu/github gives Warlock's
# release environment. A new title or key replaces the key.
resource "github_user_ssh_signing_key" "warlock_winget" {
  title = "warlock-winget"
  key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPs2ldCC+oYg+ROYmHSv6H7SZaSrl06Y2dpPOROnC8kD"

  lifecycle {
    enabled = local.bot
  }
}
