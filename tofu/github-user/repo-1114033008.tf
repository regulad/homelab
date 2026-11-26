# Repository 1114033008, named dotfiles when written: regulad's, to which
# regubot commits homelab's SSH exports (tasks/exports.sh) as a collaborator,
# which tofu/github's personal workspace invites it to be.

# regubot's pending invitations, from which the one to this repository is
# picked by its ID, which stays the same through a rename.
data "github_rest_api" "repository_invitations" {
  endpoint = "user/repository_invitations"

  lifecycle {
    enabled = local.bot
  }
}

locals {
  repository_1114033008_invitations = local.bot ? [
    for invitation in jsondecode(data.github_rest_api.repository_invitations.body) :
    tostring(invitation.id) if invitation.repository.id == 1114033008
  ] : []
}

# Accepted once: the invitation is gone after, so the ID it is found by turns
# empty, which allow_empty_id takes. The accepted ID stays in state; a change
# to it would replace the resource, and so accept nothing, so it is ignored.
resource "github_user_invitation_accepter" "repository_1114033008" {
  invitation_id  = join("", local.repository_1114033008_invitations)
  allow_empty_id = true

  lifecycle {
    enabled        = local.bot
    ignore_changes = [invitation_id]
  }
}
