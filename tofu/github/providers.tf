# Each workspace manages one account's repositories as that account's own
# GitHub App, installed on all of its repositories, so a repository's first
# secret needs only its repo-<id>.tf: personal manages regulad's, as
# regulad-homelab, and bot regubot's, as regubot-homelab. The default workspace
# manages none, and a plan there fails. An App's ID and installation ID are no
# secrets.
locals {
  github_apps = {
    personal = { owner = "regulad", id = "5812009", installation_id = "183198755" }
    bot      = { owner = "regubot", id = "5896590", installation_id = "185204554" }
  }
  github_app = local.github_apps[terraform.workspace]
}

# The App's private key comes from GITHUB_APP_PEM_FILE, which sourcing
# prepare.sh exports from the selected workspace's
# GITHUB_APP_<WORKSPACE>_PEM_FILE in provider.sops.env: source it again after
# selecting another workspace. GitHub refuses a key that is not its App's.
provider "github" {
  owner = local.github_app.owner

  app_auth {
    id              = local.github_app.id
    installation_id = local.github_app.installation_id
  }
}
