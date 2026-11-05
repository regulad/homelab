# homelab-tofu: the application this root signs in as (see README.md), its
# service principal, and its Owner grant on the subscription. Created by hand in
# Cloud Shell to bootstrap this root. Its certificate credential and the
# consent to its Graph permissions stay outside this root.

resource "azuread_application" "homelab_tofu" {
  display_name     = "homelab-tofu"
  sign_in_audience = "AzureADMyOrg"

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

    # Read the directory: users, groups and service principals.
    resource_access {
      id   = data.azuread_service_principal.msgraph.app_role_ids["Directory.Read.All"]
      type = "Role"
    }

    # Manage applications and their service principals. Consent to new
    # permissions, which would need AppRoleAssignment.ReadWrite.All, stays manual.
    resource_access {
      id   = data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
      type = "Role"
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_service_principal" "homelab_tofu" {
  client_id = azuread_application.homelab_tofu.client_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# This root manages the subscription's role assignments, so a narrower role
# would contain nothing.
resource "azurerm_role_assignment" "homelab_tofu_owner" {
  scope                = data.azurerm_subscription.this.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.homelab_tofu.object_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
