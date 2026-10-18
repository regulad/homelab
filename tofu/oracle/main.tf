locals {
  # Keyed by each name's trailing AD number: ad_1, ad_2, ad_3.
  availability_domains = {
    for ad in data.oci_identity_availability_domains.tenancy.availability_domains :
    "ad_${regex("-AD-(\\d+)$", ad.name)[0]}" => ad.name
  }
}

# Availability-domain names carry a tenancy-specific prefix, so they are looked up.
data "oci_identity_availability_domains" "tenancy" {
  compartment_id = var.tenancy_ocid
}

module "shared" {
  source = "../shared"
}

module "legacy" {
  source = "./legacy"

  tailscale_cidrs  = module.shared.tailscale_cidrs
  ipv6_subnet_cidr = var.ipv6_subnet_cidrs.legacy

  providers = {
    oci = oci
  }

  availability_domains = local.availability_domains
  tenancy_ocid         = var.tenancy_ocid
}

module "wahlecloud" {
  source = "./wahlecloud"

  tailscale_cidrs  = module.shared.tailscale_cidrs
  ipv6_subnet_cidr = var.ipv6_subnet_cidrs.wahlecloud

  providers = {
    oci = oci
  }

  availability_domains = local.availability_domains
  router_next_hop_ids  = var.router_next_hop_ids
  tenancy_ocid         = var.tenancy_ocid
}
