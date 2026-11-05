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
  content = "\"v=spf1 mx include:rp.oracleemaildelivery.com -all\""
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
  content = "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApVj/pHNnnP0eXbgGKll1bO9RcNnY0Ajic+4PgOy3tjU1ZTCKlvdNThyT9LApdVqfXRjkGyG7NuqaJ02QiTuO2Hl1I6L50plOxubQOvrSF1GhCqBRBoGaYGAi1Pe0o+pt5mEuLtvfqjKIDZv5demsaSjUVfDv7hdJrTaDymBcv2RJR35oG5EZKjAzQZ9W+Xn96\" \"wcWDwhBCoie2vkKHQ6KvlB6zm/C6kAk/XoOwEInsY11h/lt61nFKAAq9etx/dHlG8EN71xN7jMU2i8LNtGLTI5Xc53Y1Z6+NOObJ0hTtZsKjCBZLOHdnRGEwLCjWygp8/21YPSao/YEXhVMgwKy3wIDAQAB\""
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "nefumllc_com_email_dkim_cname" {
  name    = trimsuffix(data.terraform_remote_state.oracle.outputs.email_dkim[cloudflare_zone.nefumllc_com.name].name, ".")
  zone_id = cloudflare_zone.nefumllc_com.id
  type    = "CNAME"
  content = data.terraform_remote_state.oracle.outputs.email_dkim[cloudflare_zone.nefumllc_com.name].target
  ttl     = 1 # Automatic
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
