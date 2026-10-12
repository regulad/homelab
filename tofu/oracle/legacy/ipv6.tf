resource "oci_core_ipv6" "web" {
  display_name = "ipv620251101052630"
  subnet_id    = oci_core_subnet.legacy.id
  ip_address   = var.ip_addresses.web_ip_address
  lifetime     = "EPHEMERAL"
  vnic_id      = one(data.oci_core_vnic_attachments.web.vnic_attachments).vnic_id

  lifecycle {
    prevent_destroy = true
  }
}
