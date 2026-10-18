variable "availability_domains" {
  description = "Availability-domain names keyed ad_<number>, looked up by the root."
  type        = map(string)
  sensitive   = true
  nullable    = false
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
