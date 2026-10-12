resource "oci_core_network_security_group" "bailout" {
  display_name   = "bailout"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group" "livekit" {
  display_name   = "livekit"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group" "mail" {
  display_name   = "mail"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group" "router" {
  display_name   = "tailscalerouter"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "bailout_rule_01" {
  description               = "bailout646"
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.bailout.id
  protocol                  = "17"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {

    destination_port_range {
      max = 51820
      min = 51820
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "bailout_rule_02" {
  description               = "bailout464"
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.bailout.id
  protocol                  = "17"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {

    destination_port_range {
      max = 51821
      min = 51821
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_01" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 80
      min = 80
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_02" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 443
      min = 443
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_03" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 7881
      min = 7881
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_04" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 5349
      min = 5349
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_05" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 80
      min = 80
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_06" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 443
      min = 443
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_07" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 7881
      min = 7881
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_08" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 5349
      min = 5349
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_09" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "17"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {

    destination_port_range {
      max = 3478
      min = 3478
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_10" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "17"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {

    destination_port_range {
      max = 40000
      min = 30000
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_11" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "17"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {

    destination_port_range {
      max = 60000
      min = 50000
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_12" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "17"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {

    destination_port_range {
      max = 3478
      min = 3478
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_13" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "17"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {

    destination_port_range {
      max = 40000
      min = 30000
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "livekit_rule_14" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.livekit.id
  protocol                  = "17"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {

    destination_port_range {
      max = 60000
      min = 50000
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_01" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 25
      min = 25
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_02" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 143
      min = 143
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_03" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 465
      min = 465
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_04" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 587
      min = 587
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_05" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 993
      min = 993
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_06" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 25
      min = 25
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_07" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 143
      min = 143
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_08" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 465
      min = 465
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_09" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 587
      min = 587
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_10" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 993
      min = 993
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_11" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 4190
      min = 4190
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_12" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 4190
      min = 4190
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_13" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 80
      min = 80
    }

    source_port_range {
      max = 80
      min = 80
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "mail_rule_14" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.mail.id
  protocol                  = "6"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {

    destination_port_range {
      max = 80
      min = 80
    }

    source_port_range {
      max = 80
      min = 80
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "router_rule_01" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.router.id
  protocol                  = "17"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = true

  udp_options {

    destination_port_range {
      max = 39127
      min = 39127
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_network_security_group_security_rule" "router_rule_02" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.router.id
  protocol                  = "17"
  source                    = "::/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = true

  udp_options {

    destination_port_range {
      max = 39127
      min = 39127
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_security_list" "services_default" {
  display_name   = "Default Security List for wahlecloud"
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.services.id

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  egress_security_rules {
    destination      = "::/0"
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
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {

    icmp_options {
      code = 0
      type = 2
    }
    protocol    = "58"
    source      = "::/0"
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
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      max = 22
      min = 22
    }
  }

  ingress_security_rules {
    description = "LAN"
    protocol    = "all"
    source      = var.network_cidrs.services_default_ingress_security_rules_6_source
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    description = "LAN"
    protocol    = "all"
    source      = var.network_cidrs.services_default_ingress_security_rules_7_source
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

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
    protocol    = "all"
    source      = var.network_cidrs.services_public_ingress_security_rules_1_source
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    description = "Peering"
    protocol    = "all"
    source      = var.network_cidrs.legacy_default_ingress_security_rules_4_source
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  ingress_security_rules {
    description = "Peering"
    protocol    = "all"
    source      = var.network_cidrs.services_public_ingress_security_rules_3_source
    source_type = "CIDR_BLOCK"
    stateless   = false
  }

  lifecycle {
    prevent_destroy = true
  }
}
