# cluster: datacenter options and the custom CPU model.

resource "proxmox_cluster_options" "cluster" {
  crs_ha                    = "dynamic"
  crs_ha_auto_rebalance     = true
  crs_ha_rebalance_on_start = true
  description               = var.cluster_description
  ha_shutdown_policy        = "migrate"
  keyboard                  = "en-us"
  mac_prefix                = "BC:24:11"
  migration_type            = "secure"
  next_id = {
    lower = null
    upper = 1000
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_custom_cpu_model" "ryzen_vermeer_v3" {
  id             = "RYZEN-Vermeer-v3"
  reported_model = "EPYC-Milan-v3"
  flags          = ["-pcid"]
  hidden         = false
  phys_bits      = "48"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
