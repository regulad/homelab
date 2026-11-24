# winget-pkgs: regubot's fork of microsoft/winget-pkgs, from whose branches its
# pipelines open the pull requests that submit winget manifests.

locals {
  # The fork keeps its source's name, which winget's submission tools expect.
  winget_pkgs = {
    owner = "microsoft"
    name  = "winget-pkgs"
  }
}

resource "github_repository" "winget_pkgs" {
  name         = local.winget_pkgs.name
  fork         = true
  source_owner = local.winget_pkgs.owner
  source_repo  = local.winget_pkgs.name

  lifecycle {
    enabled = local.bot
  }
}
