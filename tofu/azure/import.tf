# The adoption's import blocks, removed after the adoption apply.

import {
  to = azurerm_resource_provider_registration.code_signing
  id = "/subscriptions/d40261cd-31ec-401e-a0c6-791792f048cb/providers/Microsoft.CodeSigning"
}

import {
  to = azurerm_resource_group.regulad
  id = "/subscriptions/d40261cd-31ec-401e-a0c6-791792f048cb/resourceGroups/regulad"
}

import {
  to = azurerm_trusted_signing_account.regulad
  id = "/subscriptions/d40261cd-31ec-401e-a0c6-791792f048cb/resourceGroups/regulad/providers/Microsoft.CodeSigning/codeSigningAccounts/regulad"
}

import {
  to = azurerm_role_assignment.parker_identity_verifier
  id = "/subscriptions/d40261cd-31ec-401e-a0c6-791792f048cb/resourceGroups/regulad/providers/Microsoft.CodeSigning/codeSigningAccounts/regulad/providers/Microsoft.Authorization/roleAssignments/67b1be5c-7e51-4335-8049-95a657c391fa"
}
