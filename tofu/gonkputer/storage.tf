# storage: the storages, node-local and on Ceph. The Ceph pools and filesystem are in ceph.tf.

resource "proxmox_storage_directory" "local" {
  id               = "local"
  path             = "/var/lib/vz"
  content          = ["backup", "images", "import", "iso", "snippets", "vztmpl"]
  create_base_path = true
  create_subdirs   = true
  disable          = false
  nodes            = []
  shared           = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_storage_lvmthin" "local_lvm" {
  id           = "local-lvm"
  volume_group = "pve"
  thin_pool    = "data"
  content      = ["images", "rootdir"]
  disable      = false
  nodes        = []

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_storage_rbd" "rbd" {
  id      = "rbd"
  pool    = proxmox_ceph_pool.rbd_ssd.name
  content = ["images", "rootdir"]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Created by Proxmox's "Add as storage" with the pool, so it shares the pool's name.
resource "proxmox_storage_rbd" "rbd_cmr" {
  id      = "rbd_cmr"
  pool    = proxmox_ceph_pool.rbd_cmr.name
  content = ["images", "rootdir"]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_storage_cephfs" "cephfs" {
  id      = "cephfs"
  fs_name = proxmox_ceph_fs.cephfs.name
  content = ["backup", "import", "iso", "snippets", "vztmpl"]
  options = "fsc"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
