resource "oci_core_dhcp_options" "legacy_default" {
  display_name     = "Default DHCP Options for vcn-20230331-2242"
  compartment_id   = var.tenancy_ocid
  vcn_id           = oci_core_vcn.legacy.id
  defined_tags     = var.creation_tags.dhcp_options_legacy_default
  domain_name_type = "CUSTOM_DOMAIN"
  freeform_tags    = {}

  options {
    custom_dns_servers  = []
    search_domain_names = ["vcn03312242.oraclevcn.com"]
    type                = "SearchDomain"
  }

  options {
    custom_dns_servers  = []
    search_domain_names = []
    server_type         = "VcnLocalPlusInternet"
    type                = "DomainNameServer"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_dhcp_options" "services_default" {
  display_name     = "Default DHCP Options for wahlecloud"
  compartment_id   = var.tenancy_ocid
  vcn_id           = oci_core_vcn.services.id
  defined_tags     = var.creation_tags.dhcp_options_services_default
  domain_name_type = "SUBNET_DOMAIN"
  freeform_tags    = {}

  options {
    custom_dns_servers  = []
    search_domain_names = []
    server_type         = "VcnLocalPlusInternet"
    type                = "DomainNameServer"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_dhcp_options" "services_public" {
  display_name     = "pubsub"
  compartment_id   = var.tenancy_ocid
  vcn_id           = oci_core_vcn.services.id
  defined_tags     = var.creation_tags.dhcp_options_services_public
  domain_name_type = "SUBNET_DOMAIN"
  freeform_tags    = {}

  options {
    custom_dns_servers  = [var.ip_addresses.router_create_vnic_details_1_private_ip, var.ip_addresses.router_ip_address]
    search_domain_names = []
    server_type         = "CustomDnsServer"
    type                = "DomainNameServer"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_internet_gateway" "legacy" {
  display_name   = "Internet Gateway vcn-20230331-2242"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.legacy.id
  defined_tags   = var.creation_tags.internet_gateways_legacy
  enabled        = true
  freeform_tags  = {}

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_internet_gateway" "services" {
  display_name   = "wgateway"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id
  defined_tags   = var.creation_tags.internet_gateways_services
  enabled        = true
  freeform_tags  = {}

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_subnet" "legacy" {
  display_name               = "subnet-20230331-2242"
  compartment_id             = var.tenancy_ocid
  vcn_id                     = oci_core_vcn.legacy.id
  cidr_block                 = var.network_cidrs.legacy_cidr_block
  defined_tags               = var.creation_tags.subnets_legacy
  dhcp_options_id            = oci_core_dhcp_options.legacy_default.id
  dns_label                  = "subnet03312242"
  freeform_tags              = {}
  ipv4cidr_blocks            = [var.network_cidrs.legacy_cidr_block]
  ipv6cidr_block             = var.network_cidrs.legacy_ipv6cidr_block
  ipv6cidr_blocks            = [var.network_cidrs.legacy_ipv6cidr_blocks_1]
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.legacy_default.id
  security_list_ids          = [oci_core_security_list.legacy_default.id]

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_subnet" "services" {
  display_name               = "pubsub"
  compartment_id             = var.tenancy_ocid
  vcn_id                     = oci_core_vcn.services.id
  cidr_block                 = var.network_cidrs.services_cidr_block
  defined_tags               = var.creation_tags.subnets_services
  dhcp_options_id            = oci_core_dhcp_options.services_public.id
  dns_label                  = "pubsub"
  freeform_tags              = {}
  ipv4cidr_blocks            = [var.network_cidrs.services_cidr_block]
  ipv6cidr_block             = var.network_cidrs.services_ipv6cidr_block
  ipv6cidr_blocks            = [var.network_cidrs.services_ipv6cidr_blocks_1]
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.services_public.id
  security_list_ids          = [oci_core_security_list.services_public.id, oci_core_security_list.services_default.id]

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_vcn" "legacy" {
  display_name            = "vcn-20230331-2242"
  compartment_id          = var.tenancy_ocid
  cidr_block              = var.network_cidrs.legacy_default_ingress_security_rules_1_source
  cidr_blocks             = [var.network_cidrs.legacy_default_ingress_security_rules_1_source]
  defined_tags            = var.creation_tags.vcns_legacy
  dns_label               = "vcn03312242"
  freeform_tags           = {}
  ipv6private_cidr_blocks = []
  is_ipv6enabled          = true
  security_attributes     = {}

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_vcn" "services" {
  display_name            = "wahlecloud"
  compartment_id          = var.tenancy_ocid
  cidr_block              = var.network_cidrs.services_default_ingress_security_rules_6_source
  cidr_blocks             = [var.network_cidrs.services_default_ingress_security_rules_6_source]
  defined_tags            = var.creation_tags.vcns_services
  dns_label               = "wahlecloud"
  freeform_tags           = {}
  ipv6private_cidr_blocks = []
  is_ipv6enabled          = true
  security_attributes     = {}

  lifecycle {
    prevent_destroy = true
  }
}
