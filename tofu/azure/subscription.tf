# Pay-As-You-Go: the directory's one subscription, which holds no resources,
# and Parker's Owner grant on it. homelab-tofu's grant is in homelab-tofu.tf.

data "azurerm_subscription" "this" {}

resource "azurerm_role_assignment" "parker_owner" {
  scope                = data.azurerm_subscription.this.id
  role_definition_name = "Owner"
  principal_id         = "c2e80979-83b2-449e-a4ce-487b334bf101" # Parker Wahle, the directory's one user
  # Microsoft's, from when it retired Classic Administrators.
  description = "The Classic Admin role was converted to an Azure Owner role on behalf of the user due to Classic Admin retirement."

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
