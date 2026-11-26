# nodes: the cluster's nodes in Ansible's inventory, as the hop to their
# containers.

# Mitogen reaches a container through its node (ansible-generated's
# group_vars/proxmox_containers.yml), which must be an inventory host of its own.
# Each is in proxmox_nodes alone, no OS group and not generated, so no
# ansible-generated play targets it: ansible-hardware configures the nodes.
resource "ansible_host" "node" {
  for_each = nonsensitive(toset(keys(var.node_ssh_addresses)))

  name   = var.node_ssh_addresses[each.key]
  groups = ["proxmox_nodes"]
}
