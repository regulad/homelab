resource "oci_core_route_table" "legacy_default" {
  display_name   = "Default Route Table for vcn-20230331-2242"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.legacy.id
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.legacy.id
    route_type        = "STATIC"
  }

  lifecycle {
    prevent_destroy = true
  }
}
