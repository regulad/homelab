variable "availability_domains" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "image_ids" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "instance_metadata" {
  type      = map(map(string))
  sensitive = true
  nullable  = false
}

variable "ip_addresses" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "network_cidrs" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

variable "tenancy_ocid" {
  type      = string
  sensitive = true
  nullable  = false
}
