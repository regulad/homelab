# Network Path Analyzer: the policy that lets the service read the network it
# analyzes, which the console made as the analyzer was first used.
resource "oci_identity_policy" "network_path_analyzer" {
  name           = "VNPA-Tenancy-Policy"
  compartment_id = var.tenancy_ocid
  description    = "VNPA-Exec-Policy description"
  statements = [
    "allow any-user to inspect compartments in tenancy where all { request.principal.type = 'vnpa-service' }",
    "allow any-user to read instances in tenancy where all { request.principal.type = 'vnpa-service' }",
    "allow any-user to read virtual-network-family in tenancy where all { request.principal.type = 'vnpa-service' }",
    "allow any-user to read load-balancers in tenancy where all { request.principal.type = 'vnpa-service' }",
    "allow any-user to read network-security-group in tenancy where all { request.principal.type = 'vnpa-service' }",
  ]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
