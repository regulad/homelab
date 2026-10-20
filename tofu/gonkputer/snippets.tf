# snippets: hookscripts and cloud-init vendor data on the local and cephfs storages.
#
# The committed copies under snippets/<storage>/ match the live files byte for byte. They
# are not imported: an import records neither content nor mode, which would force a
# replacement. The first apply instead overwrites each live file in place with its identical
# copy. The provider only notices a file that disappears; edits made on the node go unseen,
# and changing a committed copy deletes and re-uploads the file.

resource "proxmox_virtual_environment_file" "pin_vcpus" {
  node_name    = "prodingus"
  datastore_id = "local"
  content_type = "snippets"
  file_mode    = "0755"

  source_raw {
    data      = file("${path.module}/snippets/local/pin-vcpus.sh")
    file_name = "pin-vcpus.sh"
  }
}

resource "proxmox_virtual_environment_file" "hook_101" {
  node_name    = "prodingus"
  datastore_id = "local"
  content_type = "snippets"
  file_mode    = "0755"

  source_raw {
    data      = file("${path.module}/snippets/local/101.sh")
    file_name = "101.sh"
  }
}

# No guest references this hookscript.
resource "proxmox_virtual_environment_file" "lxc_bindfs_hook" {
  node_name    = "prodingus"
  datastore_id = "local"
  content_type = "snippets"
  file_mode    = "0755"

  source_raw {
    data      = file("${path.module}/snippets/local/lxc-bindfs-hook.sh")
    file_name = "lxc-bindfs-hook.sh"
  }
}

resource "proxmox_virtual_environment_file" "vendor" {
  node_name    = "prodingus"
  datastore_id = "local"
  content_type = "snippets"
  file_mode    = "0644"

  source_raw {
    data      = file("${path.module}/snippets/local/vendor.yaml")
    file_name = "vendor.yaml"
  }
}

resource "proxmox_virtual_environment_file" "block_mac_108" {
  node_name    = "prodingus"
  datastore_id = "cephfs"
  content_type = "snippets"
  file_mode    = "0755"

  source_raw {
    data      = file("${path.module}/snippets/cephfs/block-mac-108.sh")
    file_name = "block-mac-108.sh"
  }
}

# No guest references this hookscript.
resource "proxmox_virtual_environment_file" "block_ula" {
  node_name    = "prodingus"
  datastore_id = "cephfs"
  content_type = "snippets"
  file_mode    = "0755"

  source_raw {
    data      = file("${path.module}/snippets/cephfs/block-ula.sh")
    file_name = "block-ula.sh"
  }
}

resource "proxmox_virtual_environment_file" "ubuntu_vendor" {
  node_name    = "prodingus"
  datastore_id = "cephfs"
  content_type = "snippets"
  file_mode    = "0644"

  source_raw {
    data      = file("${path.module}/snippets/cephfs/ubuntu-vendor.yaml")
    file_name = "ubuntu-vendor.yaml"
  }
}
