locals {
  # The tailnet's ID, which Tailscale's API takes in place of its name.
  tailnet_id = "TaExUxAvv681CNTRL"

  # GitHub's issuer of the identity tokens Actions runs present.
  github_actions_issuer = "https://token.actions.githubusercontent.com"

  # The homelab's routers, as ansible-generated declares them.
  homelab = yamldecode(file("${path.module}/../../ansible-generated/inventory/group_vars/all.yml"))

  # tofu/oracle's services subnet and its two resolvers. Their IPv6 values derive
  # from the encrypted /64; the policy file and the DNS configuration show them in
  # plans, which stay on the operator's machine.
  oracle = nonsensitive(data.terraform_remote_state.oracle.outputs.tailnet)

  # The tailnet's resolvers, by host, then by IP family, for both the DNS
  # configuration and the policy file's IP sets, hosts and tests.
  resolvers = {
    # Global (homelab): its DHCP reservation on arawi, and its SLAAC address.
    pihole = { ipv4 = "10.23.2.41", ipv6 = "fd83:b84c:aa57:1:be24:11ff:fec8:9b09" }
    # Global (Oracle VCN).
    pihole2 = local.oracle.pihole2
    # Split, for regulad.internal (homelab).
    arawi = { ipv4 = local.homelab.lan_arawi.ipv4, ipv6 = local.homelab.lan_arawi.ipv6 }
    # Split, for pubsub.wahlecloud.oraclevcn.com: the VCN's edge router.
    tailscalerouter = local.oracle.tailscalerouter
    # Split, for regulad-verizon-livingston.internal: IPv4 only.
    cr1000b = { ipv4 = local.homelab.lan_upstream_router.ipv4 }
    # Split, for ncsu.edu and ncstate.net: NC State's own, IPv4 only, public.
    vrd1 = { ipv4 = "152.1.14.14" } # vrd1.ddi.ncsu.edu
    vrd2 = { ipv4 = "152.1.14.12" } # vrd2.ddi.ncsu.edu
  }
}
