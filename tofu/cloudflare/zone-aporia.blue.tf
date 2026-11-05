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

# The zone sends and receives no mail, as M3AAWG's practice for parked domains
# has it: RFC 7505's null MX, an SPF policy that authorizes no host, no DKIM
# key, and a DMARC policy that rejects. Nothing can pass SPF or DKIM for the
# zone, so receivers that apply DMARC reject all mail from it. The wildcards
# give every other name under the zone the same MX and SPF.
resource "cloudflare_dns_record" "aporia_blue_mx" {
  name     = cloudflare_zone.aporia_blue.name
  zone_id  = cloudflare_zone.aporia_blue.id
  type     = "MX"
  content  = "." # Null MX: accepts no mail
  priority = 0
  ttl      = 1 # Automatic
}

resource "cloudflare_dns_record" "aporia_blue_txt_spf" {
  name    = cloudflare_zone.aporia_blue.name
  zone_id = cloudflare_zone.aporia_blue.id
  type    = "TXT"
  content = "\"v=spf1 -all\""
  ttl     = 1 # Automatic
}

# No rua: aggregate reports would only count mail that is rejected anyway.
resource "cloudflare_dns_record" "aporia_blue_dmarc_txt" {
  name    = "_dmarc.${cloudflare_zone.aporia_blue.name}"
  zone_id = cloudflare_zone.aporia_blue.id
  type    = "TXT"
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s\""
  ttl     = 1 # Automatic
}

resource "cloudflare_dns_record" "aporia_blue_wildcard_mx" {
  name     = "*.${cloudflare_zone.aporia_blue.name}"
  zone_id  = cloudflare_zone.aporia_blue.id
  type     = "MX"
  content  = "." # Null MX: accepts no mail
  priority = 0
  ttl      = 1 # Automatic
}

resource "cloudflare_dns_record" "aporia_blue_wildcard_txt" {
  name    = "*.${cloudflare_zone.aporia_blue.name}"
  zone_id = cloudflare_zone.aporia_blue.id
  type    = "TXT"
  content = "\"v=spf1 -all\""
  ttl     = 1 # Automatic
}
