resource "oci_core_route_table" "legacy_default" {
  display_name   = "Default Route Table for vcn-20230331-2242"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.legacy.id
  defined_tags   = var.creation_tags.route_tables_legacy_default
  freeform_tags  = {}

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

resource "oci_core_route_table" "services_default" {
  display_name   = "Default Route Table for wahlecloud"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id
  defined_tags   = var.creation_tags.route_tables_services_default
  freeform_tags  = {}

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.services.id
    route_type        = "STATIC"
  }

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.services.id
    route_type        = "STATIC"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_route_table" "services_public" {
  display_name   = "pubsub"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id
  defined_tags   = var.creation_tags.route_tables_services_public
  freeform_tags  = {}

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.services.id
    route_type        = "STATIC"
  }

  route_rules {
    destination       = var.network_cidrs.services_public_ingress_security_rules_1_source
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.route_next_hop_ids.services_public_ipv4
    route_type        = "STATIC"
  }

  route_rules {
    destination       = var.network_cidrs.legacy_default_ingress_security_rules_4_source
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.route_next_hop_ids.services_public_ipv4
    route_type        = "STATIC"
  }

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.services.id
    route_type        = "STATIC"
  }

  route_rules {
    destination       = var.network_cidrs.services_public_ingress_security_rules_3_source
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.route_next_hop_ids.services_public_ipv6
    route_type        = "STATIC"
  }

  route_rules {
    destination       = var.network_cidrs.services_public_route_rules_6_destination
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.route_next_hop_ids.services_public_ipv6
    route_type        = "STATIC"
  }

  lifecycle {
    prevent_destroy = true
  }
}
