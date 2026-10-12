resource "oci_core_dhcp_options" "legacy_default" {
  display_name     = "Default DHCP Options for vcn-20230331-2242"
  compartment_id   = var.tenancy_ocid
  vcn_id           = oci_core_vcn.legacy.id
  domain_name_type = "CUSTOM_DOMAIN"
  options {
    search_domain_names = ["vcn03312242.oraclevcn.com"]
    type                = "SearchDomain"
  }

  options {
    server_type = "VcnLocalPlusInternet"
    type        = "DomainNameServer"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_internet_gateway" "legacy" {
  display_name   = "Internet Gateway vcn-20230331-2242"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.legacy.id
  enabled        = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_subnet" "legacy" {
  display_name               = "subnet-20230331-2242"
  compartment_id             = var.tenancy_ocid
  vcn_id                     = oci_core_vcn.legacy.id
  cidr_block                 = var.network_cidrs.legacy_cidr_block
  dhcp_options_id            = oci_core_dhcp_options.legacy_default.id
  dns_label                  = "subnet03312242"
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

resource "oci_core_vcn" "legacy" {
  display_name   = "vcn-20230331-2242"
  compartment_id = var.tenancy_ocid
  cidr_block     = var.network_cidrs.legacy_default_ingress_security_rules_1_source
  cidr_blocks    = [var.network_cidrs.legacy_default_ingress_security_rules_1_source]
  dns_label      = "vcn03312242"
  is_ipv6enabled = true
  lifecycle {
    prevent_destroy = true
  }
}
