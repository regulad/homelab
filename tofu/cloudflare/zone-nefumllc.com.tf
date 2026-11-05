# nefumllc.com: the zone, its DNSSEC and its DNS records, on a new zone's settings.

resource "cloudflare_zone" "nefumllc_com" {
  name    = "nefumllc.com"
  account = { id = local.account_id }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Cloudflare Registrar, the domain's registrar, publishes the DS record.
resource "cloudflare_zone_dnssec" "nefumllc_com" {
  zone_id = cloudflare_zone.nefumllc_com.id
  status  = "active"
}

resource "cloudflare_dns_record" "nefumllc_com_mx" {
  name     = cloudflare_zone.nefumllc_com.name
  zone_id  = cloudflare_zone.nefumllc_com.id
  type     = "MX"
  content  = cloudflare_dns_record.regulad_xyz_mail_a.name
  priority = 10
  ttl      = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "nefumllc_com_txt_google" {
  name    = cloudflare_zone.nefumllc_com.name
  zone_id = cloudflare_zone.nefumllc_com.id
  type    = "TXT"
  content = "\"google-site-verification=hQyvf-Z1djhMURNpcDaeLR_UtQvTK-9N3KhxZi0HgeE\""
  ttl     = 3600

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "nefumllc_com_txt_spf" {
  name    = cloudflare_zone.nefumllc_com.name
  zone_id = cloudflare_zone.nefumllc_com.id
  type    = "TXT"
  content = "\"v=spf1 mx -all\""
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "nefumllc_com_dmarc_txt" {
  name    = "_dmarc.${cloudflare_zone.nefumllc_com.name}"
  zone_id = cloudflare_zone.nefumllc_com.id
  type    = "TXT"
  content = "\"v=DMARC1; p=none; rua=mailto:394ae14f9ebd41ac83232b8ef521789d@dmarc-reports.cloudflare.net\""
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "nefumllc_com_mail_domainkey_txt" {
  name    = "mail._domainkey.${cloudflare_zone.nefumllc_com.name}"
  zone_id = cloudflare_zone.nefumllc_com.id
  type    = "TXT"
  content = "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAilO8aBltj55SgPKV9cQk+S6f8rVFIwHDfiO30NbQA/7SPfkOYm5yaV2xaVht2SMkQDzNTqT/2hyZuedN/DlzktIzsy93eeRvPf/ko8/Dt3INcGtKDV0rS3aPLKDy+7s4YFZxZKDas7wt7ilYcCy3L6UUWJPi0iTR3WiZtSi7JxqqQyg8c1SsIxBou6+B6ibsS\" \"DznPScLfsUBQjA+CinpqOdY/GeAHCn5zK7qNvlThbxFVCSKEz2EHYEVPHCw06NJDDwv4HT7VGeUH4gkluoJ5HYYpEiwz77eT4jLtSZcODkMbdv1M20EbQbeFNCHYzxEsgsipAFPRxsuoc2SHcv97QIDAQAB\""
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "nefumllc_com_www_cname" {
  name    = "www.${cloudflare_zone.nefumllc_com.name}"
  zone_id = cloudflare_zone.nefumllc_com.id
  type    = "CNAME"
  content = "ghs.googlehosted.com"
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
