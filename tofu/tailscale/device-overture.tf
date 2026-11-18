# overture: its tags. tag:server, given by hand, and tag:syncthing, its
# membership in regulad's Syncthing mesh.
data "tailscale_device" "overture" {
  hostname = "overture"
}

resource "tailscale_device_tags" "overture" {
  device_id = data.tailscale_device.overture.node_id
  tags      = ["tag:server", "tag:syncthing"]

  # The policy must define a tag before a device can carry it.
  depends_on = [tailscale_acl.policy]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
