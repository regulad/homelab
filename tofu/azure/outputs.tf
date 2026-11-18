# The client IDs of the directory's applications, by slug: the one source for
# the roots and hosts that name an Entra client. A client ID is public.
output "oauth_client_ids" {
  value = merge(
    {
      homelab-tofu   = azuread_application.homelab_tofu.client_id
      regulad-rclone = azuread_application.regulad_rclone.client_id
    },
    { for environment, application in azuread_application.warlock : "warlock-${environment}" => application.client_id },
  )

  # The providers sign in as homelab-tofu before any state can be read, so its
  # client ID is also a literal in locals.tf; it must be this application's.
  precondition {
    condition     = local.client_id == azuread_application.homelab_tofu.client_id
    error_message = "locals.tf's client_id must be homelab-tofu's client ID."
  }
}

# The directory and subscription that a workflow's azure/login signs in to.
output "tenant_id" {
  value = local.tenant_id
}

output "subscription_id" {
  value = data.azurerm_subscription.this.subscription_id
}

# What a workflow signs with: the signing account's endpoint and name, and its
# certificate profiles' names, by profile type.
output "artifact_signing" {
  value = {
    endpoint = azurerm_trusted_signing_account.regulad.account_uri
    account  = azurerm_trusted_signing_account.regulad.name
    profiles = local.artifact_signing_profiles
  }
}

# Warlock's GitHub environments, each with the certificate profile its runs sign
# with; each signs in as oauth_client_ids' warlock-<environment>.
output "warlock_profiles" {
  value = local.warlock_profiles
}
