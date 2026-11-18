# OpenTofu authenticates as the homelab repository's GitHub App, regulad-homelab,
# installed on all of regulad's repositories, so a repository's first secret
# needs only its repo-<id>.tf. Its ID and installation ID are no secrets; its
# private key comes from provider.sops.env (GITHUB_APP_PEM_FILE), which
# sourcing prepare.sh exports.
provider "github" {
  owner = "regulad"

  app_auth {
    id              = "5812009"
    installation_id = "183198755"
  }
}
