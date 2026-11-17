# dns: the tailnet's whole DNS configuration. Applying it replaces Tailscale's:
# what it leaves out is cleared. Every nameserver here must also be reachable
# from every node under the resolvers grant in the policy file.
resource "tailscale_dns_configuration" "dns" {
  magic_dns = true
  # Nodes use the nameservers below instead of their local DNS, so a node that
  # can't reach them has no DNS.
  override_local_dns = true
  # Domains appended to single-label names, tried in order.
  search_paths = ["regulad.internal", "pubsub.wahlecloud.oraclevcn.com", "sd.ncsu.edu"]

  # Global resolvers: pihole (homelab) and pihole2 (Oracle VCN), which keeps
  # answering while the homelab is down.
  dynamic "nameservers" {
    for_each = [
      local.resolvers.pihole.ipv4,
      local.resolvers.pihole.ipv6,
      local.resolvers.pihole2.ipv4,
      local.resolvers.pihole2.ipv6,
    ]
    content {
      address = nameservers.value
    }
  }

  # Resolvers for single domains, which take those domains' queries away from
  # the global resolvers.
  dynamic "split_dns" {
    for_each = {
      # NC State: its own resolvers, reached through the NC State edge router.
      "ncstate.net" = [local.resolvers.vrd2.ipv4, local.resolvers.vrd1.ipv4]
      "ncsu.edu"    = [local.resolvers.vrd2.ipv4, local.resolvers.vrd1.ipv4]
      # Oracle VCN: tailscalerouter.
      "pubsub.wahlecloud.oraclevcn.com" = [local.resolvers.tailscalerouter.ipv4, local.resolvers.tailscalerouter.ipv6]
      # Homelab: cr1000b.
      "regulad-verizon-livingston.internal" = [local.resolvers.cr1000b.ipv4]
      # Homelab: arawi.
      "regulad.internal" = [local.resolvers.arawi.ipv4, local.resolvers.arawi.ipv6]
    }
    content {
      domain = split_dns.key

      dynamic "nameservers" {
        for_each = split_dns.value
        content {
          address = nameservers.value
        }
      }
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
