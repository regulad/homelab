locals {
  # The account regulad, which holds every zone, tunnel and API token here.
  account_id = "4b4e4b955e31f2e6b82a4626230fcebf"

  # The zones mail receives for, by name: each has an mta-sts and an
  # autoconfig host, served by the Workers of those names.
  mail_zones = {
    (cloudflare_zone.regulad_xyz.name)  = cloudflare_zone.regulad_xyz.id
    (cloudflare_zone.nefumllc_com.name) = cloudflare_zone.nefumllc_com.id
    (cloudflare_zone.regulad_net.name)  = cloudflare_zone.regulad_net.id
  }

  # The MTA-STS policy (RFC 8461) of every zone mail receives for, which the
  # mta-sts Worker serves, and its id, which each zone's _mta-sts record names
  # and which must change whenever the policy does: a hash of it. Senders that
  # honour it deliver only over TLS that verifies for the listed MX.
  mta_sts_policy = join("", [for line in [
    "version: STSv1",
    "mode: enforce",
    "mx: ${cloudflare_dns_record.regulad_xyz_mail_a.name}",
    "max_age: 604800",
  ] : "${line}\r\n"])
  mta_sts_policy_id = substr(sha256(local.mta_sts_policy), 0, 32)

  # Where senders send their daily SMTP TLS reports (RFC 8460) for those zones.
  tls_rpt_address = "postmaster@${cloudflare_zone.regulad_xyz.name}"
}
