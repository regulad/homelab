resource "oci_core_vcn" "legacy" {
  display_name   = "vcn-20230331-2242"
  compartment_id = var.tenancy_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "vcn03312242"
  is_ipv6enabled = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_internet_gateway" "legacy" {
  display_name   = "Internet Gateway vcn-20230331-2242"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.legacy.id
  enabled        = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

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

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

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

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_security_list" "legacy_default" {
  display_name   = "Default Security List for vcn-20230331-2242"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.legacy.id

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all" # All IP protocols
    stateless        = false
  }

  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = false

    icmp_options {
      type = 3  # Destination Unreachable
      code = -1 # All codes (unset in OCI)
    }
  }

  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    icmp_options {
      type = 3 # Destination Unreachable
      code = 4 # Fragmentation Needed and DF set (path MTU discovery)
    }
  }

  ingress_security_rules {
    protocol    = "17" # UDP
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = false

    udp_options {
      max = 53
      min = 53

      source_port_range {
        max = 53
        min = 53
      }
    }
  }

  ingress_security_rules {
    protocol    = "17" # UDP
    source      = var.tailscale_cidrs.ipv4
    source_type = "CIDR_BLOCK"
    stateless   = false

    udp_options {
      max = 53
      min = 53

      source_port_range {
        max = 53
        min = 53
      }
    }
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      max = 22
      min = 22
    }
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      max = 53
      min = 53

      source_port_range {
        max = 53
        min = 53
      }
    }
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.tailscale_cidrs.ipv4
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      max = 53
      min = 53

      source_port_range {
        max = 53
        min = 53
      }
    }
  }

  ingress_security_rules {
    protocol    = "all" # All IP protocols
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    protocol    = "all" # All IP protocols
    source      = var.tailscale_cidrs.ipv4
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    description = "HTTP"
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      max = 80
      min = 80
    }
  }

  ingress_security_rules {
    description = "HTTPS"
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      max = 443
      min = 443
    }
  }

  ingress_security_rules {
    description = "Minecraft Voice Chat"
    protocol    = "17" # UDP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    udp_options {
      max = 24454
      min = 24454

      source_port_range {
        max = 24454
        min = 24454
      }
    }
  }

  ingress_security_rules {
    description = "Tailscale IPv4 Direct Connections"
    protocol    = "17" # UDP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = true

    udp_options {
      max = 41641
      min = 41641
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
