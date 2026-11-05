# locals: values shared across files.

locals {
  # The node's logical CPU count. Containers set `cores` to it and cap CPU time
  # with `limit`: the provider cannot leave `cores` unset, which Proxmox would
  # treat as every core, and sends 1 when it is missing. See
  # https://github.com/bpg/terraform-provider-proxmox/issues/3210.
  cpu_threads = 32

  # The DNS zone every guest resolves in, from the control node too. Guests are
  # listed in the Ansible inventory under <name>.<guest_domain>.
  guest_domain = "regulad.internal"
  # The tailnet's MagicDNS domain, for guests Ansible reaches over the tailnet.
  tailnet_domain = "tail11540.ts.net"

  # VLAN 1's (the LAN's) own ranges, by IP family. Its GUA /64 comes from the
  # ISP's router and is var.lan_ipv6_cidr.
  dual_stack_lan_cidrs = {
    ipv4 = "10.23.0.0/20"
    ipv6 = "fd83:b84c:aa57:1::/64"
  }

  # OCI's pubsub subnet, in tofu/oracle's wahlecloud VCN. Its instances reach the
  # LAN through the tailnet from their own addresses; its GUA /64 is
  # var.pubsub_ipv6_cidr.
  pubsub_ipv4_cidr = "10.131.80.0/24"

  # The ranges the homelab's own hosts connect from, by IP family, as guest
  # firewall sources: the LAN, OCI's pubsub subnet and the tailnet. The OCI
  # router itself, and any device reaching the LAN over the tailnet, comes from
  # its tailnet address; the tailnet's policy decides which devices those are.
  dual_stack_internal_sources = {
    ipv4 = join(",", [local.dual_stack_lan_cidrs.ipv4, local.pubsub_ipv4_cidr, module.shared.tailscale_cidrs.ipv4])
    ipv6 = join(",", [local.dual_stack_lan_cidrs.ipv6, var.lan_ipv6_cidr, var.pubsub_ipv6_cidr, module.shared.tailscale_cidrs.ipv6])
  }

  # ingress's reserved IPv4 address, arawi's DHCP static mapping for it. Guests
  # that admit only ingress name it, and ingress's Caddy reaches them over IPv4
  # alone: over IPv6 it connects from its EUI-64 GUA, which rotates with the
  # delegated prefix.
  ingress_ipv4 = "10.23.2.31"

  # Guest tags, by name. A guest lists the ones it carries in Proxmox's sorted
  # order; every guest carries `terraform`, marking it as managed by OpenTofu.
  tags = {
    amd64v3        = "amd64v3" # LXC containers that need the x86-64-v3 microarchitecture level
    locally_backed = "locally-backed"
    rhel           = "rhel"
    terraform      = "terraform"
    virtiofsd      = "virtiofsd"
  }

  # The tags each container's ansible_host also lists as Ansible groups of the
  # same name, for the roles that key on them.
  ansible_group_tags = [local.tags.amd64v3]
}

# Resource-free constants shared with the other roots, such as the tailnet's
# address ranges.
module "shared" {
  source = "../shared"
}
