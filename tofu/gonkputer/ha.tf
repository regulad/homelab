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
