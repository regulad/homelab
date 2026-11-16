# The client IDs of the directory's applications, by slug: the one source for
# the roots and hosts that name an Entra client. A client ID is public.
output "oauth_client_ids" {
  value = {
    homelab-tofu   = azuread_application.homelab_tofu.client_id
    regulad-rclone = azuread_application.regulad_rclone.client_id
  }

  # The providers sign in as homelab-tofu before any state can be read, so its
  # client ID is also a literal in locals.tf; it must be this application's.
  precondition {
    condition     = local.client_id == azuread_application.homelab_tofu.client_id
    error_message = "locals.tf's client_id must be homelab-tofu's client ID."
  }
}
