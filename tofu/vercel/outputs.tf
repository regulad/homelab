# The IPv4 addresses Vercel recommends for each custom domain at a zone's apex,
# by domain, which tofu/cloudflare writes as the domain's A records.
output "recommended_ipv4s" {
  value = {
    (vercel_project_domain.landing_regulad_net.domain) = data.vercel_domain_config.landing_regulad_net.recommended_ipv4s
  }
}
