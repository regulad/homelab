# The adoption's import blocks, removed after the adoption apply.

import {
  to = cloudflare_zone.aporia_blue
  id = "e8d2fdbc32d977fa7a4dbc99bf174953"
}

import {
  to = cloudflare_zone.doppelgangerhq_com
  id = "14dfd8b8a6a7492da8b82cbb733b8b0b"
}

import {
  to = cloudflare_zone.nefumllc_com
  id = "ec223e95698c29efe4e463bd3e7f09f6"
}

import {
  to = cloudflare_zone.regulad_net
  id = "01821fd9e3bd605b8e3b81a6c7aaf1b6"
}

import {
  to = cloudflare_zone.regulad_xyz
  id = "ca8c8b30f815de27b550595b20e2151c"
}

import {
  to = cloudflare_zone_dnssec.regulad_xyz
  id = "ca8c8b30f815de27b550595b20e2151c"
}

import {
  for_each = local.regulad_xyz_settings

  to = cloudflare_zone_setting.regulad_xyz[each.key]
  id = "ca8c8b30f815de27b550595b20e2151c/${each.key}"
}

import {
  to = cloudflare_zone_setting.regulad_xyz_security_header
  id = "ca8c8b30f815de27b550595b20e2151c/security_header"
}

import {
  to = cloudflare_zero_trust_tunnel_cloudflared.git
  id = "4b4e4b955e31f2e6b82a4626230fcebf/b267d4c7-96bb-41a0-9a25-8cfb1f5c8510"
}

import {
  to = cloudflare_zero_trust_tunnel_cloudflared_config.git
  id = "4b4e4b955e31f2e6b82a4626230fcebf/b267d4c7-96bb-41a0-9a25-8cfb1f5c8510"
}

import {
  to = cloudflare_account_token.ingress_caddy
  id = "4b4e4b955e31f2e6b82a4626230fcebf/6e86e1fff8437dce7d6459650cf5959f"
}

import {
  to = cloudflare_account_token.mail_certbot
  id = "4b4e4b955e31f2e6b82a4626230fcebf/8ae4bc13261fde1a3d04d985e113a598"
}

import {
  to = cloudflare_dns_record.regulad_xyz_a
  id = "ca8c8b30f815de27b550595b20e2151c/650bc6463028c29e6ba667539f208c37"
}

import {
  to = cloudflare_dns_record.regulad_xyz_mx
  id = "ca8c8b30f815de27b550595b20e2151c/db5d4f00017cbb7502490177074ab711"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_google
  id = "ca8c8b30f815de27b550595b20e2151c/2cb7d81eb6a4ec3a0bd3cf3ab2b58285"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_hibp
  id = "ca8c8b30f815de27b550595b20e2151c/a3115d9ac541cc62634c8ea9547e5da8"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_bch
  id = "ca8c8b30f815de27b550595b20e2151c/02354453774c4d6d04d381086643b98a"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_btc
  id = "ca8c8b30f815de27b550595b20e2151c/9f63be17bb0efc41ed3d8bc5878e9fac"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_doge
  id = "ca8c8b30f815de27b550595b20e2151c/f8f003b7d6b00b01b6ec24b7c08c423c"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_eth
  id = "ca8c8b30f815de27b550595b20e2151c/5a1306fa305b967b160d32a336e5ece7"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_ltc
  id = "ca8c8b30f815de27b550595b20e2151c/8cdc9f1ea9c7618670f7e31664cdc998"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_sol
  id = "ca8c8b30f815de27b550595b20e2151c/24968bbcbb1840aa9d01d8552bd1f9cf"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_tari
  id = "ca8c8b30f815de27b550595b20e2151c/937fba971261e356719b3a72af4054bc"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_trx
  id = "ca8c8b30f815de27b550595b20e2151c/b46fd6515a16db8aa2c875669f7a4894"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_wow
  id = "ca8c8b30f815de27b550595b20e2151c/aa504a2ca6003dc22bcd8cfc46b042d9"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_xmr
  id = "ca8c8b30f815de27b550595b20e2151c/62c7a78e08007b0b8a820c306949363b"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_xno
  id = "ca8c8b30f815de27b550595b20e2151c/7c70a6d4b3815505d80aa8fd9ad5bc37"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_oa1_zano
  id = "ca8c8b30f815de27b550595b20e2151c/4507dc3af7da189de242b73ea3dc73ac"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_openai
  id = "ca8c8b30f815de27b550595b20e2151c/9a44b92646768ea5e7849c9fc0799af7"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_sonatype
  id = "ca8c8b30f815de27b550595b20e2151c/f10437b3592b14a1d1d2b39878fd74ad"
}

import {
  to = cloudflare_dns_record.regulad_xyz_txt_spf
  id = "ca8c8b30f815de27b550595b20e2151c/900eba35f4a51134fdd36735ac198aaf"
}

import {
  to = cloudflare_dns_record.regulad_xyz_48674091_noreply_cname
  id = "ca8c8b30f815de27b550595b20e2151c/9639e087620278865fc9f390750adee6"
}

import {
  to = cloudflare_dns_record.regulad_xyz_ai_cname
  id = "ca8c8b30f815de27b550595b20e2151c/a73a43f3cdbf003bda1e88a8c5b2158d"
}

import {
  to = cloudflare_dns_record.regulad_xyz_archive_cname
  id = "ca8c8b30f815de27b550595b20e2151c/0f1d849473fdbd36cb12e0a8840b787d"
}

import {
  to = cloudflare_dns_record.regulad_xyz_atproto_txt
  id = "ca8c8b30f815de27b550595b20e2151c/d03e83243e3516da5266c0b8e977ae4b"
}

import {
  to = cloudflare_dns_record.regulad_xyz_authentik_cname
  id = "ca8c8b30f815de27b550595b20e2151c/3299b931607151730018a643140891dc"
}

import {
  to = cloudflare_dns_record.regulad_xyz_autoconfig_cname
  id = "ca8c8b30f815de27b550595b20e2151c/affbe4d3fe3911c86f9c4ca26e170da7"
}

import {
  to = cloudflare_dns_record.regulad_xyz_autodiscover_tcp_srv
  id = "ca8c8b30f815de27b550595b20e2151c/5723623dff64895d2aeecf27041cd6f7"
}

import {
  to = cloudflare_dns_record.regulad_xyz_autodiscover_cname
  id = "ca8c8b30f815de27b550595b20e2151c/73fa5510bd2cfdf727d8a3da675ac5ae"
}

import {
  to = cloudflare_dns_record.regulad_xyz_ci_cname
  id = "ca8c8b30f815de27b550595b20e2151c/cd0b648e19a1a542b0bf98cb480e8bf4"
}

import {
  to = cloudflare_dns_record.regulad_xyz_cr_cname
  id = "ca8c8b30f815de27b550595b20e2151c/7a7c4da3c0747ea7519ed9b6c10cc193"
}

import {
  to = cloudflare_dns_record.regulad_xyz_discord_txt
  id = "ca8c8b30f815de27b550595b20e2151c/6737b20f070f629fe03afc11f3719daa"
}

import {
  to = cloudflare_dns_record.regulad_xyz_dmarc_txt
  id = "ca8c8b30f815de27b550595b20e2151c/10f18a0b35486901b8c280f00844c0d1"
}

import {
  to = cloudflare_dns_record.regulad_xyz_em910_noreply_cname
  id = "ca8c8b30f815de27b550595b20e2151c/cbed69dfaf9a874d4bb1be33707a5e28"
}

import {
  to = cloudflare_dns_record.regulad_xyz_git_ssh_cname
  id = "ca8c8b30f815de27b550595b20e2151c/20f09d97810a6b2f7882f87dbb366696"
}

import {
  to = cloudflare_dns_record.regulad_xyz_git_cname
  id = "ca8c8b30f815de27b550595b20e2151c/cbae19b67d6df64cca54997142344b59"
}

import {
  to = cloudflare_dns_record.regulad_xyz_git_txt
  id = "ca8c8b30f815de27b550595b20e2151c/0270c3d0a2d46e80683a9d89afe92a5e"
}

import {
  to = cloudflare_dns_record.regulad_xyz_github_pages_challenge_regulad_txt
  id = "ca8c8b30f815de27b550595b20e2151c/ca67f42be9b3959ea036937192b99aa2"
}

import {
  to = cloudflare_dns_record.regulad_xyz_gonkputer_cname
  id = "ca8c8b30f815de27b550595b20e2151c/0f65d639cc0614e0f4d96dac90c6901b"
}

import {
  to = cloudflare_dns_record.regulad_xyz_hass_livingston_cname
  id = "ca8c8b30f815de27b550595b20e2151c/426a99f8da25df6457fb8e27db1e6867"
}

import {
  to = cloudflare_dns_record.regulad_xyz_imaps_tcp_srv
  id = "ca8c8b30f815de27b550595b20e2151c/8ca6bcd4a3c44fe2a1e0ae25659ab8de"
}

import {
  to = cloudflare_dns_record.regulad_xyz_immich_cname
  id = "ca8c8b30f815de27b550595b20e2151c/97aaec53e638f33ffa1c903d3fe077c8"
}

import {
  to = cloudflare_dns_record.regulad_xyz_ingress_https
  id = "ca8c8b30f815de27b550595b20e2151c/4288ecb8421d259de336cf507f164623"
}

import {
  to = cloudflare_dns_record.regulad_xyz_ios_cname
  id = "ca8c8b30f815de27b550595b20e2151c/c3e158c3712af7d65ca1419e0d69806a"
}

import {
  to = cloudflare_dns_record.regulad_xyz_jf_cname
  id = "ca8c8b30f815de27b550595b20e2151c/9b897e2ca65d0ec723c227aed8af00fa"
}

import {
  to = cloudflare_dns_record.regulad_xyz_kasm_cname
  id = "ca8c8b30f815de27b550595b20e2151c/a87509ff0a873510f1b38ace04a282e5"
}

import {
  to = cloudflare_dns_record.regulad_xyz_kodi_cname
  id = "ca8c8b30f815de27b550595b20e2151c/609174d3e821f9ec9e8d09b323da3dc4"
}

import {
  to = cloudflare_dns_record.regulad_xyz_livekit_a
  id = "ca8c8b30f815de27b550595b20e2151c/bb31723ce867416eeb3b97397a6aa1ee"
}

import {
  to = cloudflare_dns_record.regulad_xyz_livekit_aaaa
  id = "ca8c8b30f815de27b550595b20e2151c/318ff4c8de3b87414cf20a72dc986b5f"
}

import {
  to = cloudflare_dns_record.regulad_xyz_mail_domainkey_txt
  id = "ca8c8b30f815de27b550595b20e2151c/87668362204b8b0f2ccd13296407ee17"
}

import {
  to = cloudflare_dns_record.regulad_xyz_mail_a
  id = "ca8c8b30f815de27b550595b20e2151c/280b02f519d17c1ba80840b70b916f1c"
}

import {
  to = cloudflare_dns_record.regulad_xyz_mail_aaaa
  id = "ca8c8b30f815de27b550595b20e2151c/bfd9505afa76f36a5169075d755e0cb9"
}

import {
  to = cloudflare_dns_record.regulad_xyz_mail_txt
  id = "ca8c8b30f815de27b550595b20e2151c/0cd9fa6b2ec793fc9c7b3b5e9561238e"
}

import {
  to = cloudflare_dns_record.regulad_xyz_matrix_cname
  id = "ca8c8b30f815de27b550595b20e2151c/9fba0051c6d8275fee86b80971c3d46f"
}

import {
  to = cloudflare_dns_record.regulad_xyz_minecraft_tcp_mc_srv
  id = "ca8c8b30f815de27b550595b20e2151c/53a0f07306c9b1c17ce142bebf690265"
}

import {
  to = cloudflare_dns_record.regulad_xyz_mta_sts_txt
  id = "ca8c8b30f815de27b550595b20e2151c/6926611237233bfc71b8fe14f1bf033d"
}

import {
  to = cloudflare_dns_record.regulad_xyz_nextcloud_cname
  id = "ca8c8b30f815de27b550595b20e2151c/c78c10dde2e673c5f49646b23184801f"
}

import {
  to = cloudflare_dns_record.regulad_xyz_openclaw_cname
  id = "ca8c8b30f815de27b550595b20e2151c/56174f4917e27e7f8e3a88a8b468eb6f"
}

import {
  to = cloudflare_dns_record.regulad_xyz_opentofu_cname
  id = "ca8c8b30f815de27b550595b20e2151c/915e7614f9a57d7a6574dc8412e1a40c"
}

import {
  to = cloudflare_dns_record.regulad_xyz_oracle_tailscale_router_a
  id = "ca8c8b30f815de27b550595b20e2151c/7320e0a715fd74244859a16cda72bbb2"
}

import {
  to = cloudflare_dns_record.regulad_xyz_oracle_tailscale_router_aaaa
  id = "ca8c8b30f815de27b550595b20e2151c/d6d8b0b9ee6e77dd62fcefc020aa20e7"
}

import {
  to = cloudflare_dns_record.regulad_xyz_pterodactyl_cname
  id = "ca8c8b30f815de27b550595b20e2151c/7370c42a7a93caf3858478d68b097a97"
}

import {
  to = cloudflare_dns_record.regulad_xyz_email_dkim_cname
  id = "ca8c8b30f815de27b550595b20e2151c/0e66ac437eb7a52b34a2b3013fce1f14"
}

import {
  to = cloudflare_dns_record.regulad_xyz_regulad_cname
  id = "ca8c8b30f815de27b550595b20e2151c/d60741c881c99f45974af8bb14bc4502"
}

import {
  to = cloudflare_dns_record.regulad_xyz_repo_cname
  id = "ca8c8b30f815de27b550595b20e2151c/be2fa3eb5cfdc63b8bc56d20b81a9211"
}

import {
  to = cloudflare_dns_record.regulad_xyz_rsshub_cname
  id = "ca8c8b30f815de27b550595b20e2151c/8fad21ba320b4b731fbf76bae2aad12c"
}

import {
  to = cloudflare_dns_record.regulad_xyz_s1_domainkey_noreply_cname
  id = "ca8c8b30f815de27b550595b20e2151c/a427c6cbd5e0e394d62e3cf3167e7061"
}

import {
  to = cloudflare_dns_record.regulad_xyz_s2_domainkey_noreply_cname
  id = "ca8c8b30f815de27b550595b20e2151c/3f965916882daabea66ee35fb7014375"
}

import {
  to = cloudflare_dns_record.regulad_xyz_s3_cname
  id = "ca8c8b30f815de27b550595b20e2151c/ae2bcc84e378fe71f98f129b5fc06480"
}

import {
  to = cloudflare_dns_record.regulad_xyz_wildcard_s3_cname
  id = "ca8c8b30f815de27b550595b20e2151c/7a6dc38b1958e68e63a745a84b44f7d0"
}

import {
  to = cloudflare_dns_record.regulad_xyz_submission_tcp_srv
  id = "ca8c8b30f815de27b550595b20e2151c/df69dba8f5d0a26ab3d1175f6bf370e4"
}

import {
  to = cloudflare_dns_record.regulad_xyz_t_cname
  id = "ca8c8b30f815de27b550595b20e2151c/6f493e414875a939a64d0315bf84154b"
}

import {
  to = cloudflare_dns_record.regulad_xyz_tvheadend_livingston_cname
  id = "ca8c8b30f815de27b550595b20e2151c/1fa11b8abc03e7f8a904712f894d12b2"
}

import {
  to = cloudflare_dns_record.regulad_xyz_uptime_cname
  id = "ca8c8b30f815de27b550595b20e2151c/8aa72dd878ad5e036b3b511580d3d445"
}

import {
  to = cloudflare_dns_record.regulad_xyz_url1107_noreply_cname
  id = "ca8c8b30f815de27b550595b20e2151c/ce6d0dacfaceb0f865e0e12fa7e76175"
}

import {
  to = cloudflare_dns_record.regulad_xyz_vercel_txt_apex
  id = "ca8c8b30f815de27b550595b20e2151c/e378ea68534efa4fba2abe86d821c668"
}

import {
  to = cloudflare_dns_record.regulad_xyz_vercel_txt_www
  id = "ca8c8b30f815de27b550595b20e2151c/1a92bd20242d5a9e0db84e7566e37aba"
}

import {
  to = cloudflare_dns_record.regulad_xyz_vw_cname
  id = "ca8c8b30f815de27b550595b20e2151c/45c7d81da251678e9e968caf2e133db0"
}

import {
  to = cloudflare_dns_record.regulad_xyz_www_cname
  id = "ca8c8b30f815de27b550595b20e2151c/8eaace477e2b0773c2a9ca426d692877"
}

import {
  to = cloudflare_dns_record.doppelgangerhq_com_a
  id = "14dfd8b8a6a7492da8b82cbb733b8b0b/fc2d25a46b87590c7262dd3ecda3ceb3"
}

import {
  to = cloudflare_dns_record.doppelgangerhq_com_aaaa
  id = "14dfd8b8a6a7492da8b82cbb733b8b0b/ba137ac83468d35259bfea93fef084b6"
}

import {
  to = cloudflare_dns_record.doppelgangerhq_com_txt
  id = "14dfd8b8a6a7492da8b82cbb733b8b0b/ddfa18d656ce6f756ecbeff0b06e2ca5"
}

import {
  to = cloudflare_dns_record.nefumllc_com_mx
  id = "ec223e95698c29efe4e463bd3e7f09f6/b7889c9288d37ce83a6f90310b94f74b"
}

import {
  to = cloudflare_dns_record.nefumllc_com_txt_google
  id = "ec223e95698c29efe4e463bd3e7f09f6/beb26f51d30c18ce7874aadaad6e2a59"
}

import {
  to = cloudflare_dns_record.nefumllc_com_txt_spf
  id = "ec223e95698c29efe4e463bd3e7f09f6/3e47d2ca021a352a6ef71049c29c3408"
}

import {
  to = cloudflare_dns_record.nefumllc_com_dmarc_txt
  id = "ec223e95698c29efe4e463bd3e7f09f6/92e90428d075712e847bab5e08ce0ee7"
}

import {
  to = cloudflare_dns_record.nefumllc_com_mail_domainkey_txt
  id = "ec223e95698c29efe4e463bd3e7f09f6/8f71dd81dd3e9d3cdfcd4e9b6ae463c1"
}

import {
  to = cloudflare_dns_record.nefumllc_com_www_cname
  id = "ec223e95698c29efe4e463bd3e7f09f6/bea1b7405d8b7c5f02a9bea9d4df24e9"
}

import {
  to = cloudflare_dns_record.aporia_blue_a
  id = "e8d2fdbc32d977fa7a4dbc99bf174953/2140a53239dae8d51d8332ea952b47bd"
}

import {
  to = cloudflare_dns_record.aporia_blue_vercel_txt
  id = "e8d2fdbc32d977fa7a4dbc99bf174953/d6cc5582d0dda57674429e9f8deb276c"
}
