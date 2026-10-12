# subnet-20230331-2242: the subnet; it uses the VCN-default DHCP options, routes,
# and security list in network.tf.

resource "oci_core_subnet" "legacy" {
  display_name              = "subnet-20230331-2242"
  compartment_id            = var.tenancy_ocid
  vcn_id                    = oci_core_vcn.legacy.id
  cidr_block                = "10.0.0.0/24"
  dhcp_options_id           = oci_core_dhcp_options.legacy_default.id
  dns_label                 = "subnet03312242"
  ipv6cidr_blocks           = [var.ipv6_subnet_cidr]
  prohibit_internet_ingress = false
  route_table_id            = oci_core_route_table.legacy_default.id
  security_list_ids         = [oci_core_security_list.legacy_default.id]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
