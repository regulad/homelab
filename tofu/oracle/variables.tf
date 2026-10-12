variable "shared_ssh_metadata" {
  description = "SSH metadata shared by the web and bailout instances."
  type        = map(string)
  sensitive   = true
  nullable    = false
}

variable "tenancy_ocid" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "availability_domains" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "instance_metadata" {
  type      = map(map(string))
  sensitive = true
  nullable  = false
}

variable "backup_policy_id" {
  description = "Backup policy shared by livekit, mail, and router."
  type        = string
  sensitive   = true
  nullable    = false
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
