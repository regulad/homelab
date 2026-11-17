# The provider authenticates with the tailnet's homelab API access token, which
# prepare.sh exports as TAILSCALE_API_KEY from its only copy, the
# tailscale_api_token in ansible-common/group_vars/all.sops.yml.
provider "tailscale" {
  tailnet = local.tailnet_id
}
