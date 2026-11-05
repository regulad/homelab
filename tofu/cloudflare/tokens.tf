# The account's API tokens. Cloudflare returns a token's value only when it is
# created, so state never holds these.
#
# Not here: homelab-tofu, the token this root signs in with (provider.sops.env).
# It is created by hand, as svc-tofu-state's key is, so that no apply can change
# or revoke the access the apply runs with.

locals {
  # Cloudflare's permission groups, keyed by exact name.
  permission_group_ids = {
    "DNS Write" = "4755a26eedb94da69e1066d98aa820be"
  }
}

# Caddy on ingress solves its ACME DNS-01 challenges with this token, from
# caddy_cloudflare_env in that host's secrets.sops.yml.
resource "cloudflare_account_token" "ingress_caddy" {
  name       = "Edit zone DNS"
  account_id = local.account_id

  policies = [
    {
      effect            = "allow"
      permission_groups = [{ id = local.permission_group_ids["DNS Write"] }]
      resources         = jsonencode({ "com.cloudflare.api.account.zone.${cloudflare_zone.regulad_xyz.id}" = "*" })
    },
  ]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# certbot on mail renews docker-mailserver's certificate by DNS-01 with this
# token, from cloudflare_api_token in that host's secrets.sops.yml.
resource "cloudflare_account_token" "mail_certbot" {
  name       = "mailk"
  account_id = local.account_id

  policies = [
    {
      effect            = "allow"
      permission_groups = [{ id = local.permission_group_ids["DNS Write"] }]
      resources = jsonencode({
        "com.cloudflare.api.account.zone.${cloudflare_zone.nefumllc_com.id}" = "*"
        "com.cloudflare.api.account.zone.${cloudflare_zone.regulad_xyz.id}"  = "*"
      })
    },
  ]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
