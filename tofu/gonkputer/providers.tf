# The endpoint and API token come from provider.sops.env (PROXMOX_VE_ENDPOINT and
# PROXMOX_VE_API_TOKEN), which sourcing prepare.sh exports. TLS verification
# stays on: the endpoint carries a Tailscale-managed certificate.
provider "proxmox" {
  # Only snippet uploads use SSH: as root, through the operator's SSH agent
  # (SSH_AUTH_SOCK). The provider ignores ~/.ssh/config, so each node's address is explicit.
  ssh {
    agent    = true
    username = "root"
    # Calls under /nodes/{node}/ run as root@pam with a ticket minted on the node over
    # this SSH connection, for operations Proxmox reserves for root@pam itself (such as
    # USB passthrough by device ID). Everything else still uses the API token.
    root_ticket = true

    node {
      name    = "prodingus"
      address = var.node_ssh_addresses.prodingus
    }
  }
}
