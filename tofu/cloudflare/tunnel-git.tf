# git: the tunnel that cloudflared on git.regulad.internal runs, and its routes.
# cloudflared runs with the tunnel's token, from that host's secrets.sops.yml.

resource "cloudflare_zero_trust_tunnel_cloudflared" "git" {
  name       = "git"
  account_id = local.account_id
  config_src = "cloudflare"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "git" {
  account_id = local.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.git.id

  config = {
    ingress = [
      {
        hostname = cloudflare_dns_record.regulad_xyz_git_ssh_cname.name
        service  = "ssh://localhost:2222" # Forgejo's built-in SSH server
      },
      # Any other request.
      { service = "http_status:404" },
    ]
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
