# firewall: cluster-wide firewall options.

resource "proxmox_virtual_environment_cluster_firewall" "cluster" {
  enabled        = true
  forward_policy = "ACCEPT"
  input_policy   = "ACCEPT"
  # cluster.fw leaves the output and forward policies unset; these are Proxmox's effective defaults.
  output_policy = "ACCEPT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
