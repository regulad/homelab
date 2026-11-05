# regulad.net: the zone, with no records yet, on a new zone's settings.

resource "cloudflare_zone" "regulad_net" {
  name    = "regulad.net"
  account = { id = local.account_id }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
