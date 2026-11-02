variable "tenancy_ocid" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "ipv6_subnet_cidrs" {
  description = "The GUA IPv6 /64 prefixes for the two OCI subnets; host suffixes are declared in the instance files."
  type = object({
    legacy     = string
    wahlecloud = string
  })
  sensitive = true
  nullable  = false

  validation {
    condition = alltrue([
      for cidr in values(var.ipv6_subnet_cidrs) :
      can(cidrhost(cidr, 0)) && endswith(cidr, "/64") && strcontains(cidr, ":")
    ])
    error_message = "Provide each IPv6 subnet with a /64 prefix."
  }
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
