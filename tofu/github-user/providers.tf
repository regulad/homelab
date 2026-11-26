# Each workspace manages one GitHub account: personal regulad's, and bot
# regubot's. It signs in with that account's classic token,
# terraform-github--user, which sourcing prepare.sh exports as
# TF_VAR_github_token from the workspace's <workspace>.sops.yaml, an input
# rather than GITHUB_TOKEN, which git's credential helper would use too. The default workspace manages neither,
# and a plan there fails.
locals {
  accounts = {
    personal = "regulad"
    bot      = "regubot"
  }
  account = local.accounts[terraform.workspace]
}

# For an owner that is a user rather than an organization, the provider acts as
# whichever account the token belongs to, creating repositories under it.
provider "github" {
  owner = local.account
  token = var.github_token
}

# The account the token signs in as, read with username = "". Without a token
# the provider falls back to the GitHub CLI's, regulad's own, so a token left
# over from the other workspace, or none, would act as the wrong account: the
# postcondition fails the plan unless it is the workspace's. Nothing reads it:
# the postcondition is its use.
# tflint-ignore: terraform_unused_declarations
data "github_user" "self" {
  username = ""

  lifecycle {
    postcondition {
      condition     = self.login == local.account
      error_message = "The token signs in as ${self.login}, not ${local.account}. Source prepare.sh again after selecting the workspace."
    }
  }
}
