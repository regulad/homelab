# redirect: the Worker that sends each parked zone's apex and www host to the
# homepage at regulad.xyz.

locals {
  # The zones that serve no site of their own, by name.
  parked_zones = {
    (cloudflare_zone.aporia_blue.name)  = cloudflare_zone.aporia_blue.id
    (cloudflare_zone.nefumllc_com.name) = cloudflare_zone.nefumllc_com.id
    (cloudflare_zone.regulad_net.name)  = cloudflare_zone.regulad_net.id
  }

  # Each parked zone's apex and www host, by host name, with its zone's id.
  redirect_hosts = merge([
    for zone, id in local.parked_zones : {
      (zone)          = id
      ("www.${zone}") = id
    }
  ]...)
}

resource "cloudflare_workers_script" "redirect" {
  account_id         = local.account_id
  script_name        = "redirect"
  main_module        = "redirect.js"
  compatibility_date = "2026-11-24"
  content            = <<-EOT
    // Every request, whatever its path, goes to the homepage for good.
    const target = ${jsonencode("https://${cloudflare_zone.regulad_xyz.name}/")};

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
