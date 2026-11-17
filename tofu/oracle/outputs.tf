# What tofu/cloudflare reads, through its terraform_remote_state data source,
# for the DNS records that name these hosts and the Email Delivery domain.

output "public_addresses" {
  description = "Each instance's public addresses, keyed by its display name (its Ansible hostname), then by IP family."
  # The IPv6 addresses derive from the encrypted /64 prefixes.
  sensitive = true
  value = {
    "bailout"            = { ipv4 = oci_core_instance.bailout.public_ip, ipv6 = oci_core_ipv6.bailout.ip_address }
    "doppelgangerhq.com" = { ipv4 = oci_core_instance.web.public_ip, ipv6 = oci_core_ipv6.web.ip_address }
    "livekit"            = { ipv4 = oci_core_instance.livekit.public_ip, ipv6 = oci_core_ipv6.livekit.ip_address }
    "mail"               = { ipv4 = oci_core_instance.mail.public_ip, ipv6 = oci_core_ipv6.mail.ip_address }
    "tailscalerouter"    = { ipv4 = oci_core_instance.router.public_ip, ipv6 = oci_core_ipv6.router.ip_address }
  }
}

output "email_dkim" {
  description = "Each Email Delivery domain's DKIM CNAME record, by domain: its name, and the target Oracle serves the key at."
  value = {
    for domain, dkim in {
      (oci_email_email_domain.primary.name)      = oci_email_dkim.primary
      (oci_email_email_domain.nefumllc_com.name) = oci_email_dkim.nefumllc_com
      (oci_email_email_domain.regulad_net.name)  = oci_email_dkim.regulad_net
    } :
    domain => {
      name   = dkim.dns_subdomain_name
      target = dkim.cname_record_value
    }
  }
}

# What tofu/tailscale reads, through its terraform_remote_state data source, for
# the tailnet's DNS configuration and policy file: the VCN's services subnet,
# which tailscalerouter routes into the tailnet, and the two hosts there that
# resolve the tailnet's queries.
output "tailnet" {
  description = "The services subnet's prefixes, and pihole2's and tailscalerouter's addresses, by IP family."
  # The IPv6 values derive from the encrypted /64 prefix.
  sensitive = true
  value = {
    services        = { ipv4 = oci_core_subnet.services.cidr_block, ipv6 = var.ipv6_subnet_cidrs.wahlecloud }
    pihole2         = { ipv4 = local.pihole2_ipv4_address, ipv6 = local.pihole2_ipv6_address }
    tailscalerouter = { ipv4 = local.router_ipv4_address, ipv6 = local.router_ipv6_address }
  }
}
