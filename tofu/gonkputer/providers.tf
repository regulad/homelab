# The endpoint and API token come from provider.sops.env (PROXMOX_VE_ENDPOINT and
# PROXMOX_VE_API_TOKEN), which sourcing prepare.sh exports. TLS verification
# stays on: the endpoint carries a Tailscale-managed certificate.
provider "proxmox" {
  # Only snippet uploads use SSH: as root, through the operator's SSH agent
  # (SSH_AUTH_SOCK). The provider ignores ~/.ssh/config, so each node's address is explicit.
  ssh {
    agent    = true
    username = "root"

    node {
      name    = "prodingus"
      address = var.node_ssh_addresses.prodingus
    }
  }
}
