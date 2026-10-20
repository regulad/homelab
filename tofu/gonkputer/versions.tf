terraform {
  required_version = "= 1.13.1"
  required_providers {
    proxmox = {
      # A build of bpg/proxmox with full Ceph support (proxmox_ceph_pool fixes,
      # proxmox_storage_rbd, proxmox_ceph_mds, proxmox_ceph_fs and proxmox_storage_cephfs),
      # served under this address by the mirror https://opentofu.regulad.xyz/ that tofu.rc
      # configures.
      source  = "bpg/proxmox"
      version = "= 0.118.0-pr3204.pr3207.pr3209.1"
    }
    # Declares the guests' Ansible inventory (ansible_host), which ansible-generated
    # reads from this root's state.
    ansible = {
      source  = "ansible/ansible"
      version = "= 1.5.0"
    }
  }
}
