module "legacy" {
  source = "./legacy"

  providers = {
    oci = oci
  }

  availability_domains = var.availability_domains
  image_ids            = var.image_ids
  instance_metadata    = var.instance_metadata
  ip_addresses         = var.ip_addresses
  network_cidrs        = var.network_cidrs
  tenancy_ocid         = var.tenancy_ocid
}

module "wahlecloud" {
  source = "./wahlecloud"

  providers = {
    oci = oci
  }

  availability_domains = var.availability_domains
  backup_policy_ids    = var.backup_policy_ids
  image_ids            = var.image_ids
  instance_metadata    = var.instance_metadata
  ip_addresses         = var.ip_addresses
  network_cidrs        = var.network_cidrs
  route_next_hop_ids   = var.route_next_hop_ids
  tenancy_ocid         = var.tenancy_ocid
}
