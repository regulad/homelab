# Koala: an application per GitHub environment of regulad/Koala, which its runs
# there sign as through Artifact Signing, with its service principal, the
# federated credential that trusts their GitHub identity tokens, and its grant
# to sign with that environment's certificate profile, as for Warlock. Azure
# grants roles to a service principal, not to one of its credentials, so a
# testing run can never sign with the Public Trust profile. tofu/github sets
# each environment's client ID and the signing account's details in the
# repository.

locals {
  # Koala's GitHub environments, which tofu/github defines with the refs each
  # admits, each with the profile its runs sign with.
  koala_profiles = {
    release = local.artifact_signing_profiles.public_trust
    testing = local.artifact_signing_profiles.public_trust_test
  }
}

resource "azuread_application" "koala" {
  for_each = local.koala_profiles

  display_name     = "koala-${each.key}"
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "koala" {
  for_each = azuread_application.koala

  client_id = each.value.client_id
}

# Runs in that environment alone, as GitHub writes their identity token's sub:
# with the owner's and repository's immutable IDs.
resource "azuread_application_federated_identity_credential" "koala" {
  for_each = azuread_application.koala

  application_id = each.value.id
  display_name   = "github-${each.key}"
  issuer         = "https://token.actions.githubusercontent.com" # GitHub Actions' identity tokens
  subject        = "repo:regulad@52430642/Koala@1465174461:environment:${each.key}"
  audiences      = ["api://AzureADTokenExchange"] # Entra ID's audience for federated credentials
}

resource "azurerm_role_assignment" "koala_signer" {
  for_each = local.koala_profiles

  scope                = "${azurerm_trusted_signing_account.regulad.id}/certificateProfiles/${each.value}"
  role_definition_name = "Artifact Signing Certificate Profile Signer"
  principal_id         = azuread_service_principal.koala[each.key].object_id
  principal_type       = "ServicePrincipal"
  # The service principal is new, and Entra ID may not have replicated it yet.
  skip_service_principal_aad_check = true
}
