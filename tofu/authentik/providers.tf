# OpenTofu signs in as homelab-tofu, a service account in the superuser group
# authentik Admins, through Caddy on ingress. ansible-generated's homelab-tofu
# blueprint defines the account and its token, authentik_tofu_token in the
# authentik host's secrets.sops.yml, which sourcing prepare.sh exports as
# TF_VAR_authentik_token.
provider "authentik" {
  url   = "https://authentik.regulad.xyz"
  token = var.authentik_token
}
