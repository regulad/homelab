# mta-sts: the Worker that serves the MTA-STS policy at each mail zone's
# mta-sts host, whose certificate Cloudflare issues with the custom domain.

resource "cloudflare_workers_script" "mta_sts" {
  account_id         = local.account_id
  script_name        = "mta-sts"
  main_module        = "mta-sts.js"
  compatibility_date = "2026-11-05"
  content            = <<-EOT
    // The MTA-STS policy, as text/plain at its one path, and nothing else.
    const policy = ${jsonencode(local.mta_sts_policy)};

    export default {
      async fetch(request) {
        if (new URL(request.url).pathname !== "/.well-known/mta-sts.txt") {
          return new Response("Not found\n", { status: 404 });
        }
        return new Response(policy, { headers: { "content-type": "text/plain; charset=utf-8" } });
      },
    };
  EOT
}

resource "cloudflare_workers_custom_domain" "mta_sts" {
  for_each = local.mail_zones

  account_id = local.account_id
  zone_id    = each.value
  hostname   = "mta-sts.${each.key}"
  service    = cloudflare_workers_script.mta_sts.script_name
}
