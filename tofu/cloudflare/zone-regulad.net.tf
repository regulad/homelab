# regulad.net: the zone and its DNSSEC, with no records yet, on a new zone's settings.

resource "cloudflare_zone" "regulad_net" {
  name    = "regulad.net"
  account = { id = local.account_id }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Cloudflare Registrar, the domain's registrar, publishes the DS record.
resource "cloudflare_zone_dnssec" "regulad_net" {
  zone_id = cloudflare_zone.regulad_net.id
  status  = "active"
}
