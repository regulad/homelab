# regubot: the account's profile repository, named for the account, whose
# README.md GitHub shows on regubot's profile.

resource "github_repository" "regubot" {
  name       = local.account
  visibility = "public"
  # The first commit makes the default branch that README.md is written to.
  auto_init = true
  # Anything for the account goes to regulad, as its README says.
  has_issues = false

  lifecycle {
    enabled = local.bot
  }
}

# files/regubot/README.md, byte for byte, on the default branch. It replaces
# the README.md that auto_init's first commit writes.
resource "github_repository_file" "regubot_readme" {
  repository          = github_repository.regubot.name
  file                = "README.md"
  content             = file("${path.module}/files/regubot/README.md")
  overwrite_on_create = true

  lifecycle {
    enabled = local.bot
  }
}
