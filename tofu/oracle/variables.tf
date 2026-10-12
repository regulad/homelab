variable "tenancy_ocid" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "email_addresses" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "network_cidrs" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "availability_domains" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "ip_addresses" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "instance_metadata" {
  type      = map(map(string))
  sensitive = true
  nullable  = false
}

variable "image_ids" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "route_next_hop_ids" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "backup_policy_ids" {
  type      = map(string)
  sensitive = true
  nullable  = false
}
