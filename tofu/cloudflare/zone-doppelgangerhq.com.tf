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

resource "cloudflare_dns_record" "doppelgangerhq_com_txt" {
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
