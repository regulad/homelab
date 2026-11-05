# doppelgangerhq.com: the zone and its DNS records, on a new zone's settings.

resource "cloudflare_zone" "doppelgangerhq_com" {
  name    = "doppelgangerhq.com"
  account = { id = local.account_id }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "doppelgangerhq_com_a" {
  name    = cloudflare_zone.doppelgangerhq_com.name
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "A"
  content = data.terraform_remote_state.oracle.outputs.public_addresses["doppelgangerhq.com"].ipv4
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "doppelgangerhq_com_aaaa" {
  name    = cloudflare_zone.doppelgangerhq_com.name
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "AAAA"
  content = data.terraform_remote_state.oracle.outputs.public_addresses["doppelgangerhq.com"].ipv6
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "doppelgangerhq_com_txt_hibp" {
  name    = cloudflare_zone.doppelgangerhq_com.name
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "TXT"
  content = "\"hibp-verify=dweb_cm6cwe2esbst199p9zoxc6sb\""
  ttl     = 1 # Automatic
  comment = "Have I Been Pwned"

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
resource "cloudflare_dns_record" "doppelgangerhq_com_mx" {
  name     = cloudflare_zone.doppelgangerhq_com.name
  zone_id  = cloudflare_zone.doppelgangerhq_com.id
  type     = "MX"
  content  = "." # Null MX: accepts no mail
  priority = 0
  ttl      = 1 # Automatic
}

resource "cloudflare_dns_record" "doppelgangerhq_com_txt_spf" {
  name    = cloudflare_zone.doppelgangerhq_com.name
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "TXT"
  content = "\"v=spf1 -all\""
  ttl     = 1 # Automatic
}

# No rua: aggregate reports would only count mail that is rejected anyway.
resource "cloudflare_dns_record" "doppelgangerhq_com_dmarc_txt" {
  name    = "_dmarc.${cloudflare_zone.doppelgangerhq_com.name}"
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "TXT"
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s\""
  ttl     = 1 # Automatic
}

resource "cloudflare_dns_record" "doppelgangerhq_com_wildcard_mx" {
  name     = "*.${cloudflare_zone.doppelgangerhq_com.name}"
  zone_id  = cloudflare_zone.doppelgangerhq_com.id
  type     = "MX"
  content  = "." # Null MX: accepts no mail
  priority = 0
  ttl      = 1 # Automatic
}

resource "cloudflare_dns_record" "doppelgangerhq_com_wildcard_txt" {
  name    = "*.${cloudflare_zone.doppelgangerhq_com.name}"
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "TXT"
  content = "\"v=spf1 -all\""
  ttl     = 1 # Automatic
}
