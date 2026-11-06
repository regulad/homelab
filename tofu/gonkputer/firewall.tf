# firewall: cluster-wide firewall options, and the security groups guests share.

locals {
  # mDNS's multicast groups, by IP family. A guest that resolves and answers
  # mDNS admits what is sent to them: an answer comes from whichever host
  # answers, so conntrack matches none to its question.
  dual_stack_mdns_groups = {
    ipv4 = "224.0.0.251"
    ipv6 = "ff02::fb"
  }

  # mail's addresses in OCI's pubsub subnet, by IP family, as tofu/oracle's
  # instance-mail.tf fixes them. The LAN reaches both through the tailnet.
  dual_stack_mail_addresses = {
    ipv4 = cidrhost(local.pubsub_ipv4_cidr, 15)
    ipv6 = cidrhost(var.pubsub_ipv6_cidr, parseint("0000e075c8d7eb01", 16))
  }

  # The internal addresses guests that connect where their users ask must not
  # reach, by IP family. IPv4: this network, the private ranges, the tailnet's
  # shared range and link-local. IPv6: the ULAs, the LAN's and the tailnet's
  # among them, and OCI's pubsub subnet, which the LAN reaches through the
  # tailnet. The LAN's GUAs are left to the firewalls of the hosts holding
  # them.
  dual_stack_internal_destinations = {
    ipv4 = join(",", ["0.0.0.0/8", "10.0.0.0/8", module.shared.tailscale_cidrs.ipv4, "169.254.0.0/16", "172.16.0.0/12", "192.168.0.0/16"])
    ipv6 = join(",", ["fc00::/7", var.pubsub_ipv6_cidr])
  }
}

resource "proxmox_virtual_environment_cluster_firewall" "cluster" {
  enabled        = true
  forward_policy = "ACCEPT"
  input_policy   = "ACCEPT"
  # cluster.fw leaves the output and forward policies unset; these are Proxmox's effective defaults.
  output_policy = "ACCEPT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# mDNS's queries and answers, for the guests whose systemd-resolved resolves
# and answers it (ansible-generated's resolved role).
resource "proxmox_virtual_environment_cluster_firewall_security_group" "mdns" {
  name = "mdns"

  dynamic "rule" {
    for_each = local.dual_stack_mdns_groups
    iterator = group

    content {
      type   = "in"
      action = "ACCEPT"
      dest   = group.value
      proto  = "udp"
      dport  = "5353" # mDNS
    }
  }
}

# Every UDP datagram, from anywhere and to any port, for the guests that need
# UDP open: tailscaled's and cloudflared's NAT traversal, and tvheadend's
# HDHomeRun tuner. Each guest's own rules still filter TCP. It covers mDNS, so
# these guests list no mdns group.
resource "proxmox_virtual_environment_cluster_firewall_security_group" "udp" {
  name = "udp"

  rule {
    type   = "in"
    action = "ACCEPT"
    proto  = "udp"
  }
}

# Out: the internet, and of the internal addresses only the services every
# host uses, for guests that connect wherever their users ask, such as the
# public Discord bots' media downloads and Minecraft lookups. The node enforces
# it, out of the guest's reach. Its rules match new connections alone: replies
# to what a guest admits, and the DHCP and neighbour discovery its dhcp and ndp
# options admit, pass ahead of them. It sees the tailnet as routed through
# tailscalerouter; a guest running Tailscale itself would reach the tailnet
# past it, encapsulated.
resource "proxmox_virtual_environment_cluster_firewall_security_group" "internet_only" {
  name = "internet-only"

  # arawi, the guest's resolver.
  dynamic "rule" {
    for_each = local.dual_stack_arawi_lan_addresses
    iterator = address

    content {
      type   = "out"
      action = "ACCEPT"
      dest   = address.value
      macro  = "DNS"
    }
  }

  # mail.regulad.xyz, the mail_relay role's relay host.
  dynamic "rule" {
    for_each = local.dual_stack_mail_addresses
    iterator = address

    content {
      type   = "out"
      action = "ACCEPT"
      dest   = address.value
      proto  = "tcp"
      dport  = "465" # SMTP submission over implicit TLS
    }
  }

  # clamd, which the clamav role's weekly scan streams to. DHCP and SLAAC give
  # it its addresses, so the rule names its port alone.
  rule {
    type   = "out"
    action = "ACCEPT"
    proto  = "tcp"
    dport  = local.clamd_port # clamd
  }

  # Rejected rather than dropped, so a refused connection fails at once and a
  # client with several addresses, such as the scan's, goes on to the next.
  dynamic "rule" {
    for_each = local.dual_stack_internal_destinations
    iterator = destinations

    content {
      type   = "out"
      action = "REJECT"
      dest   = destinations.value
    }
  }
}
