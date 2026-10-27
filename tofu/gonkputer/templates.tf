# templates: container templates from Proxmox's index, on the cephfs storage.
#
# Each URL and SHA-512 are Proxmox's, from the template index that `pveam update`
# verifies against Proxmox's signature (/var/lib/pve-manager/apl-info/ on the node).
# download.proxmox.com answers over HTTP only, so the checksum is what vouches for
# the file.

locals {
  # Where Proxmox's template index points its system templates.
  proxmox_templates_url = "http://download.proxmox.com/images/system"
}

resource "proxmox_download_file" "ubuntu_24_04_standard" {
  node_name          = "prodingus"
  datastore_id       = proxmox_storage_cephfs.cephfs.id
  content_type       = "vztmpl"
  url                = "${local.proxmox_templates_url}/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  checksum           = "45c2978e6b97fe292ada95fe06834276015e5739a594db4de2fdfd830fa0c37942e8ae118fc1e32ffd9154b3f9378b592738b668ea3957db41f2907b86f219de"
  checksum_algorithm = "sha512"
}

resource "proxmox_download_file" "ubuntu_26_04_standard" {
  node_name          = "prodingus"
  datastore_id       = proxmox_storage_cephfs.cephfs.id
  content_type       = "vztmpl"
  url                = "${local.proxmox_templates_url}/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
  checksum           = "d5607f124d01f8ddfebd8e7da34c0022fb2a464e1662ee1e39a13f5ed1bae08a7364c486247fbd9f69f26c710729884ee5047aadb89f33a40066cd5f0d9def88"
  checksum_algorithm = "sha512"
}

# For wako, FreeIPA's new server.
resource "proxmox_download_file" "almalinux_10_default" {
  node_name          = "prodingus"
  datastore_id       = proxmox_storage_cephfs.cephfs.id
  content_type       = "vztmpl"
  url                = "${local.proxmox_templates_url}/almalinux-10-default_20250930_amd64.tar.xz"
  checksum           = "ba26baea9b73188f1ec308f27a3c3e4efcd7fc8bfca976dc2dfffc89c5681df4ac3a96e136f841d769a8b6a04c6cf0db97ffef70def853a0c3486c90a30e3418"
  checksum_algorithm = "sha512"
}
