locals {
  homelab_ipv4_cidr = "10.23.0.0/20"

  # Reuse these stable family keys for rules that are identical across IPv4 and IPv6.
  dual_stack_internet_cidrs = {
    ipv4 = "0.0.0.0/0"
    ipv6 = "::/0"
  }

  dual_stack_vcn_sources = {
    ipv4 = "10.131.0.0/16"
    # Derive the enclosing /56 without publishing the GUA prefix.
    ipv6 = cidrsubnet(replace(var.ipv6_subnet_cidr, "/64", "/56"), 0, 0)
  }
}

resource "oci_core_security_list" "services_default" {
  display_name   = "Default Security List for wahlecloud"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  dynamic "egress_security_rules" {
    for_each = local.dual_stack_internet_cidrs
    iterator = cidr
    content {
      destination      = cidr.value
      destination_type = "CIDR_BLOCK"
      protocol         = "all" # All IP protocols
      stateless        = false
    }
  }

  ingress_security_rules {

    icmp_options {
      code = -1
      type = 3
    }
    protocol    = "1" # ICMP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {

    icmp_options {
      code = 0
      type = 2
    }
    protocol    = "58" # ICMPv6
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {

    icmp_options {
      code = 4
      type = 3
    }
    protocol    = "1" # ICMP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  dynamic "ingress_security_rules" {
    for_each = local.dual_stack_internet_cidrs
    iterator = cidr
    content {
      protocol    = "6" # TCP
      source      = cidr.value
      source_type = "CIDR_BLOCK"
      stateless   = false

      tcp_options {
        max = 22
        min = 22
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = local.dual_stack_vcn_sources
    iterator = cidr
    content {
      description = "LAN"
      protocol    = "all" # All IP protocols
      source      = cidr.value
      source_type = "CIDR_BLOCK"
      stateless   = false
    }
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
    source      = local.homelab_ipv4_cidr
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

resource "oci_core_dhcp_options" "services_default" {
  display_name     = "Default DHCP Options for wahlecloud"
  compartment_id   = var.tenancy_ocid
  vcn_id           = oci_core_vcn.services.id
  domain_name_type = "SUBNET_DOMAIN"
  options {
    server_type = "VcnLocalPlusInternet"
    type        = "DomainNameServer"
  }

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

resource "oci_core_internet_gateway" "services" {
  display_name   = "wgateway"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id
  enabled        = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
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

resource "oci_core_vcn" "services" {
  display_name   = "wahlecloud"
  compartment_id = var.tenancy_ocid
  cidr_blocks    = ["10.131.0.0/16"]
  dns_label      = "wahlecloud"
  is_ipv6enabled = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_route_table" "services_default" {
  display_name   = "Default Route Table for wahlecloud"
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

  route_rules {
    destination       = local.homelab_ipv4_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.router_next_hop_ids.ipv4
    route_type        = "STATIC"
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

  route_rules {
    destination       = "fd83:b84c:aa57:1::/64"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.router_next_hop_ids.ipv6
    route_type        = "STATIC"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
