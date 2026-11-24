# jenkins-winget: regubot's SSH signing key for the winget-pkgs commits
# regulad/jobs's Jenkins jobs make. Its private half is regulad/jobs's
# winget.sops.yaml, encrypted to Parker's age key and to the one Jenkins holds,
# jenkins_jobs_sops_age_key in its host_vars. A new title or key replaces the
# key.
resource "github_user_ssh_signing_key" "jenkins_winget" {
  title = "jenkins-winget"
  key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqoZUG6Y/MFlVwNyxclV/gTvTAlMyKpbYz9+7V5e5by"

  lifecycle {
    enabled = local.bot
  }
}
