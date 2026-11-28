# redirect: the Worker that sends every request to the hosts it serves, for
# good, to the homepage at regulad.net: each parked zone's apex and www host,
# www.regulad.net, and regulad.xyz's apex and www host, the site's earlier
# address. The well-known Worker answers regulad.xyz's /.well-known/ instead.

locals {
  # The zones that serve no site of their own, by name.
  parked_zones = {
    (cloudflare_zone.aporia_blue.name)  = cloudflare_zone.aporia_blue.id
    (cloudflare_zone.nefumllc_com.name) = cloudflare_zone.nefumllc_com.id
  }

  # The hosts the Worker serves, by host name, with their zone's id: each
  # parked zone's apex and www host, the www host of regulad.net, whose apex
  # serves the site, and regulad.xyz's apex and www host.
  redirect_hosts = merge(concat(
    [
      for zone, id in local.parked_zones : {
        (zone)          = id
        ("www.${zone}") = id
      }
    ],
    [{
      ("www.${cloudflare_zone.regulad_net.name}") = cloudflare_zone.regulad_net.id
      (cloudflare_zone.regulad_xyz.name)          = cloudflare_zone.regulad_xyz.id
      ("www.${cloudflare_zone.regulad_xyz.name}") = cloudflare_zone.regulad_xyz.id
    }],
  )...)
}

resource "cloudflare_workers_script" "redirect" {
  account_id         = local.account_id
  script_name        = "redirect"
  main_module        = "redirect.js"
  compatibility_date = "2026-11-24"
  content            = <<-EOT
    // Every request, whatever its path, goes to the homepage for good.
    const target = ${jsonencode("https://${cloudflare_zone.regulad_net.name}/")};

    export default {
      async fetch() {
        return Response.redirect(target, 301);
      },
    };
  EOT
}

resource "cloudflare_workers_custom_domain" "redirect" {
  for_each = local.redirect_hosts

  account_id = local.account_id
  zone_id    = each.value
  hostname   = each.key
  service    = cloudflare_workers_script.redirect.script_name
}
