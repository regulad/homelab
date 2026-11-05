# regulad rclone: the application rclone signs in to OneDrive with, and its
# service principal. Its client secret, which the provider cannot import, stays
# outside this root, in rclone's configuration.

locals {
  # The delegated Graph permissions rclone's OneDrive backend asks for.
  regulad_rclone_scopes = [
    "Files.Read",
    "Files.Read.All",
    "Files.ReadWrite",
    "Files.ReadWrite.All",
    "offline_access",
    "Sites.Read.All",
    "User.Read",
  ]
}

resource "azuread_application" "regulad_rclone" {
  display_name     = "regulad rclone"
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"

  # Personal Microsoft accounts need version 2 access tokens.
  api {
    requested_access_token_version = 2
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

    dynamic "resource_access" {
      for_each = local.regulad_rclone_scopes

      content {
        id   = data.azuread_service_principal.msgraph.oauth2_permission_scope_ids[resource_access.value]
        type = "Scope"
      }
    }
  }

  web {
    redirect_uris = ["http://localhost:53682/"] # rclone's local OAuth listener
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_service_principal" "regulad_rclone" {
  client_id = azuread_application.regulad_rclone.client_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
