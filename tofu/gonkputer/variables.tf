variable "cluster_description" {
  description = "The datacenter's Markdown notes, which name internal hosts and networks."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "node_ssh_addresses" {
  description = "SSH address of each node, keyed by node name. The provider uploads snippets over SSH."
  type        = map(string)
  sensitive   = true
  nullable    = false
}
