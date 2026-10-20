# ha: HA rules. Each guest file holds its own HA resource.

resource "proxmox_harule" "freeipa_on_prodingus" {
  rule      = "ha-rule-3da3198c-de3b"
  type      = "node-affinity"
  resources = [proxmox_haresource.freeipa.resource_id]
  nodes = {
    prodingus = null
  }
  disable = false
  strict  = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# FIXME: jondingus is no longer a cluster node, so this rule pins uptime to nothing.
# Revisit after adoption, when the rule can be dropped.
resource "proxmox_harule" "uptime_on_jondingus" {
  rule      = "ha-rule-157366ac-952c"
  type      = "node-affinity"
  resources = [proxmox_haresource.uptime.resource_id]
  nodes = {
    jondingus = null
  }
  disable = false
  strict  = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
