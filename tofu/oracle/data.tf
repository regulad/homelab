# Each discovered instance has one attached VNIC. one() fails if that changes.

data "oci_core_vnic_attachments" "bailout" {
  compartment_id = var.tenancy_ocid
  instance_id    = oci_core_instance.bailout.id

  filter {
    name   = "state"
    values = ["ATTACHED"]
  }
}

data "oci_core_vnic_attachments" "livekit" {
  compartment_id = var.tenancy_ocid
  instance_id    = oci_core_instance.livekit.id

  filter {
    name   = "state"
    values = ["ATTACHED"]
  }
}

data "oci_core_vnic_attachments" "mail" {
  compartment_id = var.tenancy_ocid
  instance_id    = oci_core_instance.mail.id

  filter {
    name   = "state"
    values = ["ATTACHED"]
  }
}

data "oci_core_vnic_attachments" "router" {
  compartment_id = var.tenancy_ocid
  instance_id    = oci_core_instance.router.id

  filter {
    name   = "state"
    values = ["ATTACHED"]
  }
}

data "oci_core_vnic_attachments" "web" {
  compartment_id = var.tenancy_ocid
  instance_id    = oci_core_instance.web.id

  filter {
    name   = "state"
    values = ["ATTACHED"]
  }
}
