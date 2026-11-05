# firewall: cluster-wide firewall options, and the security groups guests share.

locals {
  # mDNS's multicast groups, by IP family. A guest that resolves and answers
  # mDNS admits what is sent to them: an answer comes from whichever host
  # answers, so conntrack matches none to its question.
  dual_stack_mdns_groups = {
    ipv4 = "224.0.0.251"
    ipv6 = "ff02::fb"
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
