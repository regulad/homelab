resource "oci_core_ipv6" "bailout" {
  display_name  = "ipv620260809235715"
  subnet_id     = oci_core_subnet.services.id
  defined_tags  = {}
  freeform_tags = {}
  ip_address    = var.ip_addresses.bailout_ip_address
  lifetime      = "RESERVED"
  vnic_id       = one(data.oci_core_vnic_attachments.bailout.vnic_attachments).vnic_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_ipv6" "livekit" {
  display_name  = "ipv620251219003930"
  subnet_id     = oci_core_subnet.services.id
  defined_tags  = {}
  freeform_tags = {}
  ip_address    = var.ip_addresses.livekit_ip_address
  lifetime      = "RESERVED"
  vnic_id       = one(data.oci_core_vnic_attachments.livekit.vnic_attachments).vnic_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_ipv6" "mail" {
  display_name  = "ipv620251208230834"
  subnet_id     = oci_core_subnet.services.id
  defined_tags  = {}
  freeform_tags = {}
  ip_address    = var.ip_addresses.mail_ip_address
  lifetime      = "RESERVED"
  vnic_id       = one(data.oci_core_vnic_attachments.mail.vnic_attachments).vnic_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_ipv6" "router" {
  display_name  = "ipv620251208221035"
  subnet_id     = oci_core_subnet.services.id
  defined_tags  = {}
  freeform_tags = {}
  ip_address    = var.ip_addresses.router_ip_address
  lifetime      = "RESERVED"
  vnic_id       = one(data.oci_core_vnic_attachments.router.vnic_attachments).vnic_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_ipv6" "web" {
  display_name  = "ipv620251101052630"
  subnet_id     = oci_core_subnet.legacy.id
  defined_tags  = {}
  freeform_tags = {}
  ip_address    = var.ip_addresses.web_ip_address
  lifetime      = "EPHEMERAL"
  vnic_id       = one(data.oci_core_vnic_attachments.web.vnic_attachments).vnic_id

  lifecycle {
    prevent_destroy = true
  }
}
