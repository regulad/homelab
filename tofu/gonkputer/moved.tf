# moved: every past address move, so old states and backups still plan cleanly.

# The freeipa container's Ansible host took the template's count once its HA
# resource replaced the freeipa VM's.
moved {
  from = ansible_host.freeipa
  to   = ansible_host.freeipa[0]
}

# The softether container's HA resource took the label once the softether VM's
# was destroyed with the VM.
moved {
  from = proxmox_haresource.softether_container
  to   = proxmox_haresource.softether
}
