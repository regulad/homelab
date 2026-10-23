# locals: values shared across files.

locals {
  # The node's logical CPU count. Containers set `cores` to it and cap CPU time
  # with `limit`: the provider cannot leave `cores` unset, which Proxmox would
  # treat as every core, and sends 1 when it is missing. See
  # https://github.com/bpg/terraform-provider-proxmox/issues/3210.
  cpu_threads = 32

  # The DNS zone every guest resolves in, from the control node too. Guests are
  # listed in the Ansible inventory under <name>.<guest_domain>.
  guest_domain = "regulad.internal"
  # The tailnet's MagicDNS domain, for guests Ansible reaches over the tailnet.
  tailnet_domain = "tail11540.ts.net"

  # Guest tags, by name. A guest lists the ones it carries in Proxmox's sorted
  # order; every guest carries `terraform`, marking it as managed by OpenTofu.
  tags = {
    amd64v3        = "amd64v3" # LXC containers that need the x86-64-v3 microarchitecture level
    locally_backed = "locally-backed"
    rhel           = "rhel"
    terraform      = "terraform"
    virtiofsd      = "virtiofsd"
  }
}
