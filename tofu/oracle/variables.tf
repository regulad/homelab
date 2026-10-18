variable "tenancy_ocid" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "ipv6_subnet_cidrs" {
  description = "The GUA IPv6 /64 prefixes for the two OCI subnets."
  type = object({
    legacy     = string
    wahlecloud = string
  })
  sensitive = true
  nullable  = false
}

variable "router_next_hop_ids" {
  description = "Existing router address OCIDs; explicit IDs avoid a route/subnet/instance dependency cycle."
  type = object({
    ipv4 = string
    ipv6 = string
  })
  sensitive = true
  nullable  = false
}
