resource "oci_core_security_list" "legacy_default" {
  display_name   = "Default Security List for vcn-20230331-2242"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.legacy.id

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }
  ingress_security_rules {

    icmp_options {
      code = -1
      type = 3
    }
    protocol    = "1"
    source      = var.network_cidrs.legacy_default_ingress_security_rules_1_source
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {

    icmp_options {
      code = 4
      type = 3
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    protocol    = "17"
    source      = var.network_cidrs.legacy_default_ingress_security_rules_1_source
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
    protocol    = "17"
    source      = var.network_cidrs.legacy_default_ingress_security_rules_4_source
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
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      max = 22
      min = 22
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.network_cidrs.legacy_default_ingress_security_rules_1_source
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
    protocol    = "6"
    source      = var.network_cidrs.legacy_default_ingress_security_rules_4_source
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
    protocol    = "all"
    source      = var.network_cidrs.legacy_default_ingress_security_rules_1_source
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.network_cidrs.legacy_default_ingress_security_rules_4_source
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    description = "HTTP"
    protocol    = "6"
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
    protocol    = "6"
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
    protocol    = "17"
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
    protocol    = "17"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = true

    udp_options {
      max = 41641
      min = 41641
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
