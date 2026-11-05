# aporia.blue: the zone and its DNS records, on a new zone's settings.

resource "cloudflare_zone" "aporia_blue" {
  name    = "aporia.blue"
  account = { id = local.account_id }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "aporia_blue_a" {
  name    = cloudflare_zone.aporia_blue.name
  zone_id = cloudflare_zone.aporia_blue.id
  type    = "A"
  content = "216.198.79.1"
  ttl     = 600

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "aporia_blue_vercel_txt" {
  name    = "_vercel.${cloudflare_zone.aporia_blue.name}"
  zone_id = cloudflare_zone.aporia_blue.id
  type    = "TXT"
  content = "\"vc-domain-verify=aporia.blue,4ebe4288572d83a111b6,dc\""
  ttl     = 600

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
