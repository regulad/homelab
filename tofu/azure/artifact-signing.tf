# Artifact Signing: its resource provider, the regulad resource group and
# signing account, and Parker's grant to validate identities on the account,
# all made by hand in the portal. Identity validations and certificate profiles
# stay outside this root (see README.md); the profiles' names are written here.

locals {
  # The account's certificate profiles, made by hand, by profile type. Both
  # carry Parker's Public identity validation as an individual developer.
  artifact_signing_profiles = {
    public_trust      = "regulad"
    public_trust_test = "regulad-test"
  }
}

resource "azurerm_resource_provider_registration" "code_signing" {
  name = "Microsoft.CodeSigning"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "regulad" {
  name     = "regulad"
  location = "eastus"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_trusted_signing_account" "regulad" {
  name                = "regulad"
  resource_group_name = azurerm_resource_group.regulad.name
  location            = azurerm_resource_group.regulad.location
  sku_name            = "Basic"

  depends_on = [azurerm_resource_provider_registration.code_signing]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Creating or managing an identity validation, which only the portal does, needs
# this role; Owner does not include it.
resource "azurerm_role_assignment" "parker_identity_verifier" {
  scope                = azurerm_trusted_signing_account.regulad.id
  role_definition_name = "Artifact Signing Identity Verifier"
  principal_id         = local.parker_object_id

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
