# moved: every past address move, so old states and backups still plan cleanly.

# doppelgangerhq.com's Have I Been Pwned record took a suffix once the apex
# had a second TXT record, its SPF policy.
moved {
  from = cloudflare_dns_record.doppelgangerhq_com_txt
  to   = cloudflare_dns_record.doppelgangerhq_com_txt_hibp
}
