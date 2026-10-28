variable "node_ssh_addresses" {
  description = "SSH address of each node, keyed by node name. The provider uploads snippets over SSH."
  type        = map(string)
  sensitive   = true
  nullable    = false
}

variable "lan_ipv6_cidr" {
  description = "The LAN's (VLAN 1's) GUA /64, which the ISP's router advertises."
  type        = string
  sensitive   = true
  nullable    = false
}
