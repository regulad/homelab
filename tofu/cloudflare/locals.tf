locals {
  # The account regulad, which holds every zone, tunnel and API token here.
  account_id = "4b4e4b955e31f2e6b82a4626230fcebf"

  # The MTA-STS policy (RFC 8461) of every zone mail receives for, which the
  # mta-sts Worker serves, and its id, which each zone's _mta-sts record names
  # and which must change whenever the policy does: a hash of it. testing
  # reports failed TLS without refusing delivery.
  mta_sts_policy = join("", [for line in [
    "version: STSv1",
    "mode: testing",
    "mx: ${cloudflare_dns_record.regulad_xyz_mail_a.name}",
    "max_age: 604800",
  ] : "${line}\r\n"])
  mta_sts_policy_id = substr(sha256(local.mta_sts_policy), 0, 32)
}
