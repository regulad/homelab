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

# The addresses Email Delivery may approve as senders, those of FreeIPA's
# declared accounts, which bin/email-senders builds into
# email-senders.sops.json and prepare.sh decrypts. Not sensitive: each address
# keys a sender resource, so plans and state name it whatever this says. SOPS
# keeps them out of the repository, which is all they need.
variable "email_senders" {
  type     = list(string)
  nullable = false

  validation {
    condition     = alltrue([for address in var.email_senders : can(regex("^[^@\\s]+@[^@\\s]+$", address))])
    error_message = "Each sender is one address, local part and domain."
  }
}
