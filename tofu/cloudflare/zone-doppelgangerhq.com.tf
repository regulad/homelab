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

resource "cloudflare_dns_record" "doppelgangerhq_com_mx" {
  name     = cloudflare_zone.doppelgangerhq_com.name
  zone_id  = cloudflare_zone.doppelgangerhq_com.id
  type     = "MX"
  content  = cloudflare_dns_record.regulad_xyz_mail_a.name
  priority = 0
  ttl      = 1 # Automatic
}

resource "cloudflare_dns_record" "doppelgangerhq_com_txt_spf" {
  name    = cloudflare_zone.doppelgangerhq_com.name
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "TXT"
  content = "\"v=spf1 mx include:rp.oracleemaildelivery.com -all\""
  ttl     = 1 # Automatic
}

# Its reports go to the zone's own address at Cloudflare's DMARC Management.
resource "cloudflare_dns_record" "doppelgangerhq_com_dmarc_txt" {
  name    = "_dmarc.${cloudflare_zone.doppelgangerhq_com.name}"
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "TXT"
  content = "\"v=DMARC1; p=reject; rua=mailto:da694c3796414541b956f61fd8cd0f17@dmarc-reports.cloudflare.net\""
  ttl     = 1 # Automatic
}

# The policy the mta-sts Worker serves at mta-sts.doppelgangerhq.com, by its id.
resource "cloudflare_dns_record" "doppelgangerhq_com_mta_sts_txt" {
  name    = "_mta-sts.${cloudflare_zone.doppelgangerhq_com.name}"
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "TXT"
  content = "\"v=STSv1; id=${local.mta_sts_policy_id}\""
  ttl     = 1 # Automatic

  depends_on = [cloudflare_workers_custom_domain.mta_sts]
}

resource "cloudflare_dns_record" "doppelgangerhq_com_smtp_tls_txt" {
  name    = "_smtp._tls.${cloudflare_zone.doppelgangerhq_com.name}"
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "TXT"
  content = "\"v=TLSRPTv1; rua=mailto:${local.tls_rpt_address}\""
  ttl     = 1 # Automatic
}

resource "cloudflare_dns_record" "doppelgangerhq_com_mail_domainkey_txt" {
  name    = "mail._domainkey.${cloudflare_zone.doppelgangerhq_com.name}"
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "TXT"
  content = "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxO4iP0AsJeXOBGfTB7u+WcSZSmdmG4Aj2toWVH00Kiyv+9YA5QujTzIxsw3O2b/s7rs1QEsRv7Z4FezulkfCSMJezpTnMQNm6DSWikrWPebl2IzT9JWem8ViPw+a0/ZQRHPWi+tXDne+aAlQjxX970Oalgkj/dLq3ajENOS2lqMrhXcmMLV5+g/Iz97WQyWGR\" \"Uj1/PmcQHyc6XyPq/cI+65QZwG++3TivY137hSwpG+GAHErnmJOHyVDHeMxigPptMx5nPVxCR40wlO0yNtIHaWjyDfp6Bs19aIcrRWSUIZVsJ62Qd7ysG75/AmuC5tOBpZJB+aU4Chue0ZVaPkj/QIDAQAB\""
  ttl     = 1 # Automatic
}

resource "cloudflare_dns_record" "doppelgangerhq_com_email_dkim_cname" {
  name    = trimsuffix(data.terraform_remote_state.oracle.outputs.email_dkim[cloudflare_zone.doppelgangerhq_com.name].name, ".")
  zone_id = cloudflare_zone.doppelgangerhq_com.id
  type    = "CNAME"
  content = data.terraform_remote_state.oracle.outputs.email_dkim[cloudflare_zone.doppelgangerhq_com.name].target
  ttl     = 1 # Automatic
}

# RFC 6186/8314: where mail clients find IMAP and submission, each over TLS,
# on mail's host.
resource "cloudflare_dns_record" "doppelgangerhq_com_imaps_tcp_srv" {
  name     = "_imaps._tcp.${cloudflare_zone.doppelgangerhq_com.name}"
  zone_id  = cloudflare_zone.doppelgangerhq_com.id
  type     = "SRV"
  priority = 10
  ttl      = 1 # Automatic

  data = {
    priority = 10
    weight   = 10
    port     = 993 # IMAP over implicit TLS
    target   = cloudflare_dns_record.regulad_xyz_mail_a.name
  }
}

resource "cloudflare_dns_record" "doppelgangerhq_com_submissions_tcp_srv" {
  name     = "_submissions._tcp.${cloudflare_zone.doppelgangerhq_com.name}"
  zone_id  = cloudflare_zone.doppelgangerhq_com.id
  type     = "SRV"
  priority = 10
  ttl      = 1 # Automatic

  data = {
    priority = 10
    weight   = 10
    port     = 465 # submission over implicit TLS
    target   = cloudflare_dns_record.regulad_xyz_mail_a.name
  }
}

resource "cloudflare_dns_record" "doppelgangerhq_com_submission_tcp_srv" {
  name     = "_submission._tcp.${cloudflare_zone.doppelgangerhq_com.name}"
  zone_id  = cloudflare_zone.doppelgangerhq_com.id
  type     = "SRV"
  priority = 10
  ttl      = 1 # Automatic

  data = {
    priority = 10
    weight   = 10
    port     = 587 # submission with STARTTLS
    target   = cloudflare_dns_record.regulad_xyz_mail_a.name
  }
}

# The names under the zone send and receive no mail, as M3AAWG's practice for
# parked domains has it: RFC 7505's null MX and an SPF policy that authorizes
# no host. A wildcard answers only names that have no records of their own.
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
