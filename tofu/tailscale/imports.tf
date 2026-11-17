# Adoption of the federated identities, the policy file and the DNS
# configuration; removed after the apply.
import {
  to = tailscale_federated_identity.doppelganger
  id = "TaExUxAvv681CNTRL-khkxW3byPB11CNTRL"
}

import {
  to = tailscale_federated_identity.peppercord
  id = "TaExUxAvv681CNTRL-kzH6MhzPjf11CNTRL"
}

import {
  to = tailscale_federated_identity.tailscale_acls
  id = "TaExUxAvv681CNTRL-kdAAkL5hWY11CNTRL"
}

import {
  to = tailscale_acl.policy
  id = "acl"
}

import {
  to = tailscale_dns_configuration.dns
  id = "dns_configuration"
}
