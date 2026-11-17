# doppelganger: the app behind doppelgangerhq.com's web push, and the API key
# doppelgangerhq.com sends notifications with.
locals {
  # Its IPv4 and IPv6 addresses, from tofu/oracle.
  doppelgangerhq_com = data.terraform_remote_state.oracle.outputs.public_addresses["doppelgangerhq.com"]
}

resource "onesignal_app" "doppelganger" {
  name               = "Doppelganger"
  organization_id    = local.organization_id
  chrome_web_origin  = "https://doppelgangerhq.com"
  safari_site_origin = "https://doppelgangerhq.com"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Usable only from doppelgangerhq.com's own addresses.
resource "onesignal_app_api_key" "doppelganger" {
  app_id = onesignal_app.doppelganger.id
  name   = "doppelgangerhq.com"
  ip_allowlist = [
    "${local.doppelgangerhq_com.ipv4}/32",
    "${local.doppelgangerhq_com.ipv6}/128",
  ]
}

# The key, for doppelgangerhq.com's web.env as ONESIGNAL_API_KEY. OneSignal
# returns it only when the key is created or rotated.
output "doppelganger_api_key" {
  value     = onesignal_app_api_key.doppelganger.value
  sensitive = true
}
