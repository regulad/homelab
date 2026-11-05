# autoconfig: the Worker that serves Mozilla's autoconfig file at each mail
# zone's autoconfig host, where Thunderbird and Nextcloud Mail look first for
# an address's IMAP and SMTP settings.

locals {
  # The clientConfig every mail zone's address gets: mail's IMAP over TLS, and
  # its SMTP submission over TLS, or with STARTTLS. Users log in with their
  # address.
  autoconfig_mail_host = cloudflare_dns_record.regulad_xyz_mail_a.name
  autoconfig_domains   = join("\n", [for zone in keys(local.mail_zones) : "    <domain>${zone}</domain>"])
  autoconfig_xml       = <<-EOT
    <?xml version="1.0" encoding="UTF-8"?>
    <clientConfig version="1.1">
      <emailProvider id="${cloudflare_zone.regulad_xyz.name}">
    ${local.autoconfig_domains}
        <displayName>${local.autoconfig_mail_host}</displayName>
        <displayShortName>${cloudflare_zone.regulad_xyz.name}</displayShortName>
        <incomingServer type="imap">
          <hostname>${local.autoconfig_mail_host}</hostname>
          <port>993</port>
          <socketType>SSL</socketType>
          <authentication>password-cleartext</authentication>
          <username>%EMAILADDRESS%</username>
        </incomingServer>
        <outgoingServer type="smtp">
          <hostname>${local.autoconfig_mail_host}</hostname>
          <port>465</port>
          <socketType>SSL</socketType>
          <authentication>password-cleartext</authentication>
          <username>%EMAILADDRESS%</username>
        </outgoingServer>
        <outgoingServer type="smtp">
          <hostname>${local.autoconfig_mail_host}</hostname>
          <port>587</port>
          <socketType>STARTTLS</socketType>
          <authentication>password-cleartext</authentication>
          <username>%EMAILADDRESS%</username>
        </outgoingServer>
      </emailProvider>
    </clientConfig>
  EOT
}

resource "cloudflare_workers_script" "autoconfig" {
  account_id         = local.account_id
  script_name        = "autoconfig"
  main_module        = "autoconfig.js"
  compatibility_date = "2026-11-05"
  content            = <<-EOT
    // Mozilla's autoconfig file, as XML at its one path, whatever the query.
    const config = ${jsonencode(local.autoconfig_xml)};

    export default {
      async fetch(request) {
        if (new URL(request.url).pathname !== "/mail/config-v1.1.xml") {
          return new Response("Not found\n", { status: 404 });
        }
        return new Response(config, { headers: { "content-type": "application/xml; charset=utf-8" } });
      },
    };
  EOT
}

resource "cloudflare_workers_custom_domain" "autoconfig" {
  for_each = local.mail_zones

  account_id = local.account_id
  zone_id    = each.value
  hostname   = "autoconfig.${each.key}"
  service    = cloudflare_workers_script.autoconfig.script_name
}
