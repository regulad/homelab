# regulad.xyz: the zone, its DNSSEC, the settings that differ from a new zone's,
# and its DNS records.

locals {
  # Their own A and AAAA records belong to each host's cloudflare-ddns container
  # (see README.md); records here only point at them.
  regulad_xyz_dodo    = "dodo.${cloudflare_zone.regulad_xyz.name}"
  regulad_xyz_ingress = "ingress.${cloudflare_zone.regulad_xyz.name}"

  # The zone's settings that differ from a new zone's, other than
  # security_header, whose value is an object.
  regulad_xyz_settings = {
    "0rtt"              = "on"
    always_use_https    = "on"
    browser_check       = "off"
    min_tls_version     = "1.2"
    pseudo_ipv4         = "add_header"
    replace_insecure_js = "off"
    ssl                 = "strict"
    tls_1_3             = "zrt"
  }
}

resource "cloudflare_zone" "regulad_xyz" {
  name    = "regulad.xyz"
  account = { id = local.account_id }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zone_dnssec" "regulad_xyz" {
  zone_id = cloudflare_zone.regulad_xyz.id
  status  = "active"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zone_setting" "regulad_xyz" {
  for_each = local.regulad_xyz_settings

  zone_id    = cloudflare_zone.regulad_xyz.id
  setting_id = each.key
  value      = each.value

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zone_setting" "regulad_xyz_security_header" {
  zone_id    = cloudflare_zone.regulad_xyz.id
  setting_id = "security_header"
  value = {
    strict_transport_security = {
      enabled            = true
      include_subdomains = true
      max_age            = 15552000 # 180 days
      nosniff            = true
      preload            = true
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_a" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "A"
  content = "216.198.79.1"
  ttl     = 600

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_mx" {
  name     = cloudflare_zone.regulad_xyz.name
  zone_id  = cloudflare_zone.regulad_xyz.id
  type     = "MX"
  content  = cloudflare_dns_record.regulad_xyz_mail_a.name
  priority = 0
  ttl      = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_google" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "google-site-verification=HyKBSx_dIaefnos7yHYb4dI56QedhaOKIJLXuu7H0Ok"
  ttl     = 3600

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_hibp" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"hibp-verify=dweb_rddvzu86sjrqw21eiw6gprax\""
  ttl     = 1 # Automatic
  comment = "Have I Been Pwned"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_bch" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:bch recipient_address=bitcoincash:qpnpnwfa54qyjg0sg7xyh6n0fttva5ca05g53dm5wm; recipient_name=regulad; address_signature=20cd72801e2ccd96e25920007761e029b3c01b46f5ec578706f30f14988137d0d65ec6ffcbaa9cd6c474ea294cad38726b06c1fc78a537bedf66751017358cc7eb\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_btc" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:btc recipient_address=bc1q9xvxln452n6qlewena8uzdudm5c699rya0rsfq; recipient_name=regulad; address_signature=H7uUM+6vZbPLdupRpU2+T53ob2yM2iS0BTxrV+ap5y/3LScCkLcazA5LxTA4WbwQR9wQBsCegcVym3O4wz+3AVA=\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_doge" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:doge recipient_address=DCEXSUszdPKB1VeEdWKXJHU7uX5A4p3aWJ; recipient_name=regulad\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_eth" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:eth recipient_address=0x637fBBDf7DAd75a46D3102eBd5Ff985F72548cFb; recipient_name=regulad; address_signature=0xd4a86f00d5bbd779bde1db7ef8be2cd91f0d0f241312e7dee9655246d617b1ea6bd114f4d00d687e4e08d2f2e9b1c5e696b4edf9fb65933f59766f28bd0577d21b\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_ltc" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:ltc recipient_address=ltc1q7k7tv3nlm0pw5f6wpq3l7wvgdk2rr2dmsy6suu; recipient_name=regulad; address_signature=ICeXKEPTiVPaOzYa8LVLjkYKDGRrNTnMVEudC/9S/Fe8H/eFOF5Y9vHZ864GdnuF2iN6cyqsJcVQs559xGd/MiI=\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_sol" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:sol recipient_address=6PntZypC2HeuoMAsAWX77AEMcYJGgf38wpvM9AxNDV2M; recipient_name=regulad; address_signature=5369676E6174757265285B332C2031382C203134372C203136392C203139372C203132312C203233362C203133362C20342C203233312C203234332C203131352C203231352C2\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_tari" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:tari recipient_address=343Y7oLZEkg4cvfGETVaXxTeqobQ1dEAiyFtMS25K1bqkUntAiykBRku5f4UAzaijXF53MqDUoh9755kvmzn8uQKWQX; recipient_name=regulad\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_trx" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:trx recipient_address=TFcu1dBpyRdRxr1uASJJuQG6yCjxcrsAsM; recipient_name=regulad; address_signature=d76ea37e09687e325056fc8d46a59872f9e21b8c494b9c0a10b62e56452359a25e83dd81f3c6b1bdf6302336566ab73abec9660c327af2d37ade6587a70c4f301c\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_wow" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:wow recipient_address=Wo3oLouzDPrBNcJmb68owdSeAV328u7HvWATf9SB6V3BWsAf493u4SQMw5GzRiNoKfBAi9K9FTda6AZKXdph1LEh27GpktLwV; recipient_name=regulad; address_signature=SigV2dimacFRqWxRLxQ1Pv4hA2s1kbzqdxviSwinLPmrdBvKLR2omsPLPFXXU7CtrSjziAQdYATMpbipRvDcE3Av\" \"bQN9s\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_xmr" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:xmr recipient_address=4BDJLxB3dDP4TZbKeoqdRH1fFJ4UJSqEhSQ6rU89cpRdjbJuGgy8q3VcMuMFB3dYAWZPfgM9x1gU8Lc4eJ58266W112hgbX; recipient_name=regulad; address_signature=SigV2dgkZgBBZadt2K61zyXxnWoZNv4rqkZ1yRRiabkJqwoWoSb8qU6qgU6veMtgis96NzvUQBQ2vLSsrnd6j3aDmG\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_xno" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:xno recipient_address=nano_1dmgs4z1hj74jbarxcdt8djejpzhbx7pp8rnzaehq9fux419k8w6ny7tj1az; recipient_name=regulad; address_signature=F5A186C0223D14AE278ACC3690B35C02A69AD22B9FCB90D211F27D651BDDA1A3F8E2791071D52A6F3BC0AF51CD14386F984A3015BF4A63139804776C\" \"37F95F0F\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_oa1_zano" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"oa1:zano recipient_address=ZxDRSPVQLaySvNYwGAujSvNSkLMEoDdjpRtGniAP2jSBHb8jiDfXq8ScapknSGbtp2e42xToUCv4UPPm1HZrEZZR1L1dkcTKF; recipient_name=regulad\""
  ttl     = 1 # Automatic
  comment = "OpenAlias"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_openai" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"openai-domain-verification=dv-9I4MLUSaY8WyAQMqlErXIzyO\""
  ttl     = 1 # Automatic
  comment = "OpenAI"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_sonatype" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"rktaukpord\""
  ttl     = 1 # Automatic
  comment = "Sonatype"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_txt_spf" {
  name    = cloudflare_zone.regulad_xyz.name
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"v=spf1 mx include:rp.oracleemaildelivery.com -all\""
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_48674091_noreply_cname" {
  name    = "48674091.noreply.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = "sendgrid.net"
  ttl     = 1 # Automatic
  comment = "Twilio Sendgrid"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_ai_cname" {
  name    = "ai.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_archive_cname" {
  name    = "archive.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_atproto_txt" {
  name    = "_atproto.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"did=did:plc:mwzpcmiliygpkxrx5j4c77nv\""
  ttl     = 1 # Automatic
  comment = "Bluesky"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_authentik_cname" {
  name    = "authentik.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_autoconfig_cname" {
  name    = "autoconfig.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = cloudflare_dns_record.regulad_xyz_mail_a.name
  ttl     = 1 # Automatic
  comment = "Thunderbird/Mozilla"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_autodiscover_tcp_srv" {
  name     = "_autodiscover._tcp.${cloudflare_zone.regulad_xyz.name}"
  zone_id  = cloudflare_zone.regulad_xyz.id
  type     = "SRV"
  priority = 10
  ttl      = 1 # Automatic

  data = {
    priority = 10
    weight   = 10
    port     = 443
    target   = cloudflare_dns_record.regulad_xyz_mail_a.name
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_autodiscover_cname" {
  name    = "autodiscover.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = cloudflare_dns_record.regulad_xyz_mail_a.name
  ttl     = 1 # Automatic
  comment = "Microsoft/Outlook"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_ci_cname" {
  name    = "ci.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_cr_cname" {
  name    = "cr.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_discord_txt" {
  name    = "_discord.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "dh=f976eeec78213bca42c5d5d795df3de410b431dd"
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_dmarc_txt" {
  name    = "_dmarc.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"v=DMARC1; p=reject; sp=reject; fo=0; adkim=r; aspf=r; pct=100; rf=afrf; ri=86400; rua=mailto:752d8cf8205e4581a2f01c82210f585c@dmarc-reports.cloudflare.net; ruf=mailto:regulad@regulad.xyz\""
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_em910_noreply_cname" {
  name    = "em910.noreply.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = "u48674091.wl092.sendgrid.net"
  ttl     = 1 # Automatic
  comment = "Twilio Sendgrid"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_git_ssh_cname" {
  name    = "git-ssh.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.git.id}.cfargotunnel.com"
  ttl     = 1 # Automatic
  proxied = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_git_cname" {
  name    = "git.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_git_txt" {
  name    = "git.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"https://github.com/regulad\""
  ttl     = 1 # Automatic
  comment = "JitPack"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_github_pages_challenge_regulad_txt" {
  name    = "_github-pages-challenge-regulad.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "ed698d40fe19cfbb8213243550e120"
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_gonkputer_cname" {
  name    = "gonkputer.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_hass_livingston_cname" {
  name    = "hass-livingston.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_imaps_tcp_srv" {
  name     = "_imaps._tcp.${cloudflare_zone.regulad_xyz.name}"
  zone_id  = cloudflare_zone.regulad_xyz.id
  type     = "SRV"
  priority = 10
  ttl      = 1 # Automatic

  data = {
    priority = 10
    weight   = 10
    port     = 993
    target   = cloudflare_dns_record.regulad_xyz_mail_a.name
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_immich_cname" {
  name    = "immich.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_ingress_https" {
  name    = local.regulad_xyz_ingress
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "HTTPS"
  ttl     = 1 # Automatic

  data = {
    priority = 1
    target   = "."
    value    = "alpn=\"h2\""
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_ios_cname" {
  name    = "ios.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_jf_cname" {
  name    = "jf.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_kasm_cname" {
  name    = "kasm.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_kodi_cname" {
  name    = "kodi.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_livekit_a" {
  name    = "livekit.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "A"
  content = data.terraform_remote_state.oracle.outputs.public_addresses["livekit"].ipv4
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_livekit_aaaa" {
  name    = "livekit.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "AAAA"
  content = data.terraform_remote_state.oracle.outputs.public_addresses["livekit"].ipv6
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_mail_domainkey_txt" {
  name    = "mail._domainkey.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAj6XmtOVX8Mx+aPsbh7PU8MEIMOLvnvIH1I0OwsVXlvvzp5kxWmNxPPYuDXZBQog0qcVEmtXHEpZ0zxA9h1kVXyFsi2mQq1ETR1OBRT3ShOxkZcThNKXptP9h0oy++EwrUvyIXDFJCTVVo60eb0N4RYwph2L3ZAxGZ2U6sIXdlG+3s25AOyENZIrC7TI5o5OOM\" \"rARsCIteNbAbICuhX/T2ASj2/xTRz6qGZlaJO9Ob0J2vULppJxSvL8YucIMOLJWNm50to99RizXd+v3tgZGUY9RICeUE6xSx+2wSgdfD7bYmhSRWOJSLU74EFUqUe4/wahFgRZybB+CwnXrfLNbywIDAQAB\""
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_mail_a" {
  name    = "mail.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "A"
  content = data.terraform_remote_state.oracle.outputs.public_addresses["mail"].ipv4
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_mail_aaaa" {
  name    = "mail.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "AAAA"
  content = data.terraform_remote_state.oracle.outputs.public_addresses["mail"].ipv6
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_mail_txt" {
  name    = "mail.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"v=spf1 include:regulad.xyz -all\""
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_matrix_cname" {
  name    = "matrix.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_minecraft_tcp_mc_srv" {
  name     = "_minecraft._tcp.mc.${cloudflare_zone.regulad_xyz.name}"
  zone_id  = cloudflare_zone.regulad_xyz.id
  type     = "SRV"
  priority = 0
  ttl      = 1 # Automatic

  data = {
    priority = 0
    weight   = 100
    port     = 45510
    target   = local.regulad_xyz_dodo
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# FIXME: curly quotes (U+201C, U+201D) wrap the value, so it does not begin
# with v=STSv1 and senders ignore it; nor does any record answer for
# mta-sts.regulad.xyz, which would serve the policy. Revisit after the adoption.
# The policy the mta-sts Worker serves at mta-sts.regulad.xyz, by its id.
resource "cloudflare_dns_record" "regulad_xyz_mta_sts_txt" {
  name    = "_mta-sts.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"v=STSv1; id=${local.mta_sts_policy_id}\""
  ttl     = 1 # Automatic

  depends_on = [cloudflare_workers_custom_domain.mta_sts]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_nextcloud_cname" {
  name    = "nextcloud.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_openclaw_cname" {
  name    = "openclaw.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_opentofu_cname" {
  name    = "opentofu.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = "regulad.github.io"
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_oracle_tailscale_router_a" {
  name    = "oracle-tailscale-router.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "A"
  content = data.terraform_remote_state.oracle.outputs.public_addresses["tailscalerouter"].ipv4
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_oracle_tailscale_router_aaaa" {
  name    = "oracle-tailscale-router.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "AAAA"
  content = data.terraform_remote_state.oracle.outputs.public_addresses["tailscalerouter"].ipv6
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_pterodactyl_cname" {
  name    = "pterodactyl.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_email_dkim_cname" {
  name    = trimsuffix(data.terraform_remote_state.oracle.outputs.email_dkim[cloudflare_zone.regulad_xyz.name].name, ".")
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = data.terraform_remote_state.oracle.outputs.email_dkim[cloudflare_zone.regulad_xyz.name].target
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_regulad_cname" {
  name    = "regulad.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = cloudflare_zone.regulad_xyz.name
  ttl     = 1 # Automatic
  comment = "OpenAlias(?)"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_repo_cname" {
  name    = "repo.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_rsshub_cname" {
  name    = "rsshub.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_s1_domainkey_noreply_cname" {
  name    = "s1._domainkey.noreply.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = "s1.domainkey.u48674091.wl092.sendgrid.net"
  ttl     = 1 # Automatic
  comment = "Twilio Sendgrid"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_s2_domainkey_noreply_cname" {
  name    = "s2._domainkey.noreply.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = "s2.domainkey.u48674091.wl092.sendgrid.net"
  ttl     = 1 # Automatic
  comment = "Twilio Sendgrid"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_s3_cname" {
  name    = "s3.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_wildcard_s3_cname" {
  name    = "*.s3.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = cloudflare_dns_record.regulad_xyz_s3_cname.name
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_submission_tcp_srv" {
  name     = "_submission._tcp.${cloudflare_zone.regulad_xyz.name}"
  zone_id  = cloudflare_zone.regulad_xyz.id
  type     = "SRV"
  priority = 10
  ttl      = 1 # Automatic

  data = {
    priority = 10
    weight   = 10
    port     = 587
    target   = cloudflare_dns_record.regulad_xyz_mail_a.name
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_t_cname" {
  name    = "t.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = cloudflare_dns_record.regulad_xyz_www_cname.name
  ttl     = 1 # Automatic
  proxied = true
  comment = "Linktree stub"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_tvheadend_livingston_cname" {
  name    = "tvheadend-livingston.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_uptime_cname" {
  name    = "uptime.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_url1107_noreply_cname" {
  name    = "url1107.noreply.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = "sendgrid.net"
  ttl     = 1 # Automatic
  comment = "Twilio Sendgrid"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_vercel_txt_apex" {
  name    = "_vercel.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"vc-domain-verify=regulad.xyz,65702f51afb12fb12e39,dc\""
  ttl     = 600

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_vercel_txt_www" {
  name    = "_vercel.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "TXT"
  content = "\"vc-domain-verify=www.regulad.xyz,c1f44ce7f8e3ef42bffa,dc\""
  ttl     = 600

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_vw_cname" {
  name    = "vw.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = local.regulad_xyz_ingress
  ttl     = 1 # Automatic

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "regulad_xyz_www_cname" {
  name    = "www.${cloudflare_zone.regulad_xyz.name}"
  zone_id = cloudflare_zone.regulad_xyz.id
  type    = "CNAME"
  content = "aaea064265f63104.vercel-dns-017.com"
  ttl     = 600

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
