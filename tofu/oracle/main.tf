module "shared" {
  source = "../shared"
}

module "legacy" {
  source = "./legacy"

  tailscale_cidrs     = module.shared.tailscale_cidrs
  shared_ssh_metadata = var.shared_ssh_metadata
  ipv6_subnet_cidr    = var.ipv6_subnet_cidrs.legacy

  providers = {
    oci = oci
  }

  availability_domains = var.availability_domains
  tenancy_ocid         = var.tenancy_ocid
}

module "wahlecloud" {
  source = "./wahlecloud"

  tailscale_cidrs     = module.shared.tailscale_cidrs
  shared_ssh_metadata = var.shared_ssh_metadata
  ipv6_subnet_cidr    = var.ipv6_subnet_cidrs.wahlecloud

  providers = {
    oci = oci
  }

  availability_domains = var.availability_domains
  router_next_hop_ids  = var.router_next_hop_ids
  backup_policy_id     = var.backup_policy_id
  instance_metadata    = var.instance_metadata
  tenancy_ocid         = var.tenancy_ocid
}
