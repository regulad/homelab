variable "shared_ssh_metadata" {
  description = "SSH metadata shared by the web and bailout instances."
  type        = map(string)
  sensitive   = true
  nullable    = false
}

variable "availability_domains" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "backup_policy_id" {
  description = "Backup policy shared by livekit, mail, and router."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "instance_metadata" {
  type      = map(map(string))
  sensitive = true
  nullable  = false
}

variable "tenancy_ocid" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "ipv6_subnet_cidr" {
  description = "Sensitive GUA IPv6 /64; host suffixes are declared in the instance files."
  type        = string
  sensitive   = true
  nullable    = false

  validation {
    condition     = can(cidrhost(var.ipv6_subnet_cidr, 0)) && endswith(var.ipv6_subnet_cidr, "/64") && strcontains(var.ipv6_subnet_cidr, ":")
    error_message = "Provide an IPv6 subnet with a /64 prefix."
  }
}

variable "tailscale_cidrs" {
  description = "Shared Tailscale ranges supplied by tofu/shared."
  type = object({
    ipv4 = string
    ipv6 = string
  })
  nullable = false
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
