# well-known: the Worker that answers every path under regulad.xyz's
# /.well-known/, ahead of the redirect Worker that serves the rest of the host:
# Matrix's discovery files for the server name regulad.xyz, the domain of
# @regulad:regulad.xyz, and a 400 for any other path. The zone's HSTS setting
# adds Strict-Transport-Security to each response.

resource "cloudflare_workers_script" "well_known" {
  account_id         = local.account_id
  script_name        = "well-known"
  main_module        = "well-known.js"
  compatibility_date = "2026-11-24"
  content            = <<-EOT
    // Matrix's discovery files (the specification's "Server discovery"), by
    // path, each as compact JSON with its keys in the order written here.
    const documents = new Map(Object.entries({
      "/.well-known/matrix/client": {
        "m.homeserver": { base_url: ${jsonencode("https://${cloudflare_dns_record.regulad_xyz_matrix_cname.name}")} },
        "m.identity_server": { base_url: "https://matrix.org" },
        // MSC4143: Element Call's LiveKit, through lk-jwt-service on livekit.
        "org.matrix.msc4143.rtc_foci": [
          { type: "livekit", livekit_service_url: ${jsonencode("https://${cloudflare_dns_record.regulad_xyz_livekit_a.name}/livekit/jwt")} },
        ],
      },
      "/.well-known/matrix/server": { "m.server": ${jsonencode("${cloudflare_dns_record.regulad_xyz_matrix_cname.name}:443")} },
      "/.well-known/matrix/support": {
        contacts: [{ matrix_id: ${jsonencode("@regulad:${cloudflare_zone.regulad_xyz.name}")}, role: "m.role.admin" }],
      },
    }).map(([path, document]) => [path, JSON.stringify(document)]));

    // A discovery file is public and may be cached for an hour; nothing else
    // here may be cached without revalidating.
    const json = {
      "access-control-allow-origin": "*",
      "cache-control": "public, max-age=3600",
      "content-type": "application/json",
    };
    const revalidate = { "cache-control": "public, max-age=0, must-revalidate" };

    // A part of a query, form-decoded: "+" is a space, and a malformed escape
    // is kept as it is.
    function decode(part) {
      try {
        return decodeURIComponent(part.replaceAll("+", " "));
      } catch {
        return part.replaceAll("+", " ");
      }
    }

    // The query, form-decoded and encoded again, without empty pairs; a key
    // written without "=" keeps none.
    function reencode(search) {
      const pairs = search.slice(1).split("&").filter(Boolean).map((pair) => {
        const at = pair.indexOf("=");
        if (at < 0) {
          return encodeURIComponent(decode(pair));
        }
        return encodeURIComponent(decode(pair.slice(0, at))) + "=" + encodeURIComponent(decode(pair.slice(at + 1)));
      });
      return pairs.length ? "?" + pairs.join("&") : "";
    }

    export default {
      async fetch(request) {
        const url = new URL(request.url);
        const document = documents.get(url.pathname);
        if (document !== undefined) {
          switch (request.method) {
            case "GET":
            case "HEAD":
              return new Response(document, { headers: json });
            case "OPTIONS":
              return new Response(null, { status: 204, headers: { allow: "GET, HEAD, OPTIONS", ...revalidate } });
            default:
              return new Response(null, { status: 405, headers: { "content-length": "0", ...revalidate } });
          }
        }
        // A discovery file's path with a trailing slash, whatever the method,
        // goes to the path without it, relative to this host.
        if (url.pathname.endsWith("/") && documents.has(url.pathname.slice(0, -1))) {
          const location = url.pathname.slice(0, -1) + reencode(url.search);
          return new Response("Redirecting...\n", {
            status: 308,
            headers: { "content-type": "text/plain", location, refresh: "0;url=" + location, ...revalidate },
          });
        }
        return new Response(null, { status: 400 });
      },
    };
  EOT
}

# A route takes precedence over a custom domain on the same host, so these
# paths reach this Worker, and every other path on regulad.xyz the redirect.
resource "cloudflare_workers_route" "well_known" {
  zone_id = cloudflare_zone.regulad_xyz.id
  pattern = "${cloudflare_zone.regulad_xyz.name}/.well-known/*"
  script  = cloudflare_workers_script.well_known.script_name
}
