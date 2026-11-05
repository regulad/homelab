# regulad.net: the zone, its DNSSEC and its DNS records, on a new zone's settings.

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

resource "cloudflare_dns_record" "regulad_net_mx" {
  name     = cloudflare_zone.regulad_net.name
  zone_id  = cloudflare_zone.regulad_net.id
  type     = "MX"
  content  = cloudflare_dns_record.regulad_xyz_mail_a.name
  priority = 0
  ttl      = 1 # Automatic
}

resource "cloudflare_dns_record" "regulad_net_txt_spf" {
  name    = cloudflare_zone.regulad_net.name
  zone_id = cloudflare_zone.regulad_net.id
  type    = "TXT"
  content = "\"v=spf1 mx include:rp.oracleemaildelivery.com -all\""
  ttl     = 1 # Automatic
}

# Its reports go to the zone's own address at Cloudflare's DMARC Management.
resource "cloudflare_dns_record" "regulad_net_dmarc_txt" {
  name    = "_dmarc.${cloudflare_zone.regulad_net.name}"
  zone_id = cloudflare_zone.regulad_net.id
  type    = "TXT"
  content = "\"v=DMARC1; p=reject; rua=mailto:a722b8b5be234e3997e3fa60d8c33c83@dmarc-reports.cloudflare.net\""
  ttl     = 1 # Automatic
}

# The policy the mta-sts Worker serves at mta-sts.regulad.net, by its id.
resource "cloudflare_dns_record" "regulad_net_mta_sts_txt" {
  name    = "_mta-sts.${cloudflare_zone.regulad_net.name}"
  zone_id = cloudflare_zone.regulad_net.id
  type    = "TXT"
  content = "\"v=STSv1; id=${local.mta_sts_policy_id}\""
  ttl     = 1 # Automatic

  depends_on = [cloudflare_workers_custom_domain.mta_sts]
}

resource "cloudflare_dns_record" "regulad_net_smtp_tls_txt" {
  name    = "_smtp._tls.${cloudflare_zone.regulad_net.name}"
  zone_id = cloudflare_zone.regulad_net.id
  type    = "TXT"
  content = "\"v=TLSRPTv1; rua=mailto:${local.tls_rpt_address}\""
  ttl     = 1 # Automatic
}

resource "cloudflare_dns_record" "regulad_net_mail_domainkey_txt" {
  name    = "mail._domainkey.${cloudflare_zone.regulad_net.name}"
  zone_id = cloudflare_zone.regulad_net.id
  type    = "TXT"
  content = "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoodhZe4X7PcVKGvmHqua4x6pCn3pkXFLcr/yqfM+BsflzYTBlrdPtN/0a8OQR/nDigfVm3m8ULxSzptxX4t7YWScGN8bV3nkupZsjZ3DVZO+aOZ+PtwH3shyFl2ToGniNbGefw4BDEc5xMY5L8IaMbiKQWa+i8TeIZUoHDwYlJgrcAo/8I1Js60hlnTc3zeSN\" \"bGU4kV7UleOkNWDdHkeuCPa8afxUDC+BkItuROX4i3ecXNOqNC3LbScYBZdRH6QWrRvztccADR73zWZ43IVbZrDYb49P0h6poKKZj7GSQ4DIcb2FZjrQo55WSiDQHSc8vGmWpYACYqWxop0tT4ifwIDAQAB\""
  ttl     = 1 # Automatic
}

resource "cloudflare_dns_record" "regulad_net_email_dkim_cname" {
  name    = trimsuffix(data.terraform_remote_state.oracle.outputs.email_dkim[cloudflare_zone.regulad_net.name].name, ".")
  zone_id = cloudflare_zone.regulad_net.id
  type    = "CNAME"
  content = data.terraform_remote_state.oracle.outputs.email_dkim[cloudflare_zone.regulad_net.name].target
  ttl     = 1 # Automatic
}

# RFC 6186/8314: where mail clients find IMAP and submission, each over TLS,
# on mail's host.
resource "cloudflare_dns_record" "regulad_net_imaps_tcp_srv" {
  name     = "_imaps._tcp.${cloudflare_zone.regulad_net.name}"
  zone_id  = cloudflare_zone.regulad_net.id
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

resource "cloudflare_dns_record" "regulad_net_submissions_tcp_srv" {
  name     = "_submissions._tcp.${cloudflare_zone.regulad_net.name}"
  zone_id  = cloudflare_zone.regulad_net.id
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

resource "cloudflare_dns_record" "regulad_net_submission_tcp_srv" {
  name     = "_submission._tcp.${cloudflare_zone.regulad_net.name}"
  zone_id  = cloudflare_zone.regulad_net.id
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
