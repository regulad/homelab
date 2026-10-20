# ceph: the Ceph pools, filesystem and metadata servers created through Proxmox.
# Their storages are in storage.tf. `.mgr` and the RGW pools were not created
# through Proxmox and are not described.

# The PG autoscaler is on for every pool, so `pg_num` is left to it.
resource "proxmox_ceph_pool" "rbd_ssd" {
  node_name         = "prodingus"
  name              = "rbd_ssd"
  application       = "rbd"
  crush_rule        = "replicated_rule_ssd"
  size              = 2
  min_size          = 1
  pg_autoscale_mode = "on"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_ceph_pool" "rbd_cmr" {
  node_name         = "prodingus"
  name              = "rbd_cmr"
  application       = "rbd"
  crush_rule        = "replicated_rule_cmr"
  size              = 3
  min_size          = 2
  pg_autoscale_mode = "on"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Proxmox created the pools cephfs_metadata and cephfs_data with the filesystem.
# Destroying a CephFS is a manual procedure; the provider refuses to.
resource "proxmox_ceph_fs" "cephfs" {
  node_name = "prodingus"
  name      = "cephfs"

  metadata_pool = {
    crush_rule = "replicated_rule_ssd"
    size       = 2
    min_size   = 1
  }

  data_pool = {
    crush_rule = "replicated_rule_cmr"
    size       = 3
    min_size   = 2
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# prodingus serves cephfs; prodingus1 and prodingus2 are hot spares on the same host.
resource "proxmox_ceph_mds" "prodingus" {
  node_name = "prodingus"
  name      = "prodingus"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_ceph_mds" "prodingus1" {
  node_name = "prodingus"
  name      = "prodingus1"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_ceph_mds" "prodingus2" {
  node_name = "prodingus"
  name      = "prodingus2"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
