# The adoption's import blocks, removed after the adoption apply.

import {
  to = azuread_application.homelab_tofu
  id = "/applications/e1b0c019-e781-4372-98f1-ac81fd2f1a84"
}

import {
  to = azuread_service_principal.homelab_tofu
  id = "/servicePrincipals/493e488c-e882-4bcb-abd3-41e7e7a9e3ef"
}

import {
  to = azurerm_role_assignment.homelab_tofu_owner
  id = "/subscriptions/d40261cd-31ec-401e-a0c6-791792f048cb/providers/Microsoft.Authorization/roleAssignments/b1b717a5-a685-4233-b282-4692c527cea7"
}

import {
  to = azuread_application.regulad_rclone
  id = "/applications/61a1b01a-66fe-44a3-89d9-01b5bd6c1e30"
}

import {
  to = azuread_service_principal.regulad_rclone
  id = "/servicePrincipals/d427f752-884d-4bde-95e4-ac02a808e06f"
}

import {
  to = azurerm_role_assignment.parker_owner
  id = "/subscriptions/d40261cd-31ec-401e-a0c6-791792f048cb/providers/Microsoft.Authorization/roleAssignments/d31521d1-ca58-4761-8888-07804d8113f2"
}
