# Both providers sign in as homelab-tofu with its certificate, which sourcing
# prepare.sh exports as a PKCS#12 bundle in ARM_CLIENT_CERTIFICATE. Neither
# falls back to an Azure CLI login.

provider "azuread" {
  tenant_id = local.tenant_id
  client_id = local.client_id
  use_cli   = false
}

provider "azurerm" {
  tenant_id       = local.tenant_id
  subscription_id = local.subscription_id
  client_id       = local.client_id
  use_cli         = false

  features {}
}
