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
  description = "The Email Delivery DKIM key's CNAME record: its name, and the target Oracle serves the key at."
  value = {
    name   = oci_email_dkim.primary.dns_subdomain_name
    target = oci_email_dkim.primary.cname_record_value
  }
}
