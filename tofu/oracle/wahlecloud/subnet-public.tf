# public: the pubsub subnet and its dedicated DHCP options, routes, and security list.

locals {
  # The homelab is bridged to this subnet through the router.
  dual_stack_homelab_cidrs = {
    ipv4 = "10.23.0.0/20"
    ipv6 = "fd83:b84c:aa57:1::/64" # Homelab ULA; fourth hextet 0001.
  }
}

resource "oci_core_subnet" "services" {
  display_name              = "pubsub"
  compartment_id            = var.tenancy_ocid
  vcn_id                    = oci_core_vcn.services.id
  cidr_block                = "10.131.80.0/24"
  dhcp_options_id           = oci_core_dhcp_options.services_public.id
  dns_label                 = "pubsub"
  ipv6cidr_blocks           = [var.ipv6_subnet_cidr]
  prohibit_internet_ingress = false
  route_table_id            = oci_core_route_table.services_public.id
  security_list_ids         = [oci_core_security_list.services_public.id, oci_core_security_list.services_default.id]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_dhcp_options" "services_public" {
  display_name     = "pubsub"
  compartment_id   = var.tenancy_ocid
  vcn_id           = oci_core_vcn.services.id
  domain_name_type = "SUBNET_DOMAIN"

  options {
    custom_dns_servers = [local.router_ipv4_address, local.router_ipv6_address]
    server_type        = "CustomDnsServer"
    type               = "DomainNameServer"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_route_table" "services_public" {
  display_name   = "pubsub"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  dynamic "route_rules" {
    for_each = local.dual_stack_internet_cidrs
    iterator = cidr
    content {
      destination       = cidr.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_internet_gateway.services.id
      route_type        = "STATIC"
    }
  }

  dynamic "route_rules" {
    for_each = local.dual_stack_homelab_cidrs
    iterator = cidr
    content {
      destination       = cidr.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = var.router_next_hop_ids[cidr.key]
      route_type        = "STATIC"
    }
  }

  route_rules {
    destination       = var.tailscale_cidrs.ipv4
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.router_next_hop_ids.ipv4
    route_type        = "STATIC"
  }

  route_rules {
    destination       = var.tailscale_cidrs.ipv6
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.router_next_hop_ids.ipv6
    route_type        = "STATIC"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_security_list" "services_public" {
  display_name   = "pubsub"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  ingress_security_rules {
    description = "Peering"
    protocol    = "all" # All IP protocols
    # The existing homelab ingress rule permits IPv4 only.
    source      = local.dual_stack_homelab_cidrs.ipv4
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    description = "Peering"
    protocol    = "all" # All IP protocols
    source      = var.tailscale_cidrs.ipv4
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    description = "Peering"
    protocol    = "all" # All IP protocols
    source      = var.tailscale_cidrs.ipv6
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
