# Each discovered instance has one attached VNIC. one() fails if that changes.

data "oci_core_vnic_attachments" "web" {
  compartment_id = var.tenancy_ocid
  instance_id    = oci_core_instance.web.id

  filter {
    name   = "state"
    values = ["ATTACHED"]
  }
}
