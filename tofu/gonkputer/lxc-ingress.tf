# ingress: container 121, its HA resource and its Ansible host.

resource "proxmox_virtual_environment_container" "ingress" {
  node_name     = "prodingus"
  description   = <<EOT
Enabling mDNS in an LXC container is annoying.

```
systemctl enable --now systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
touch /etc/.pve-ignore.resolv.conf
echo 'make_resolv_conf() { :; }' > /etc/dhcp/dhclient-enter-hooks.d/leave_my_resolv_conf_alone
chmod 755 /etc/dhcp/dhclient-enter-hooks.d/leave_my_resolv_conf_alone
touch /etc/systemd/network/.pve-ignore.eth0.network
```

```
# /etc/systemd/resolved.conf
[Resolve]
MulticastDNS=yes
```

```
# /etc/systemd/network/eth0.network
[Network]
MulticastDNS=yes
```
EOT
  start_on_boot = false
  unprivileged  = true
  tags          = [local.tags.terraform]

  console {}

  cpu {
    cores = local.cpu_threads
    limit = 2
  }

  disk {
    datastore_id  = "rbd"
    mount_options = ["discard", "lazytime"]
    size          = 24
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "ingress"

    ip_config {
      ipv4 {
        address = "dhcp"
      }

      ipv6 {
        address = "auto"
      }
    }
  }

  memory {
    dedicated = 2048
    swap      = 1048576
  }

  network_interface {
    firewall    = true
    mac_address = "BC:24:11:4A:25:FA"
    name        = "eth0"
    vlan_id     = 1
  }

  operating_system {
    template_file_id = ""
    type             = "ubuntu"
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_haresource" "ingress" {
  resource_id = "ct:${proxmox_virtual_environment_container.ingress.vm_id}"
  type        = "ct"
  state       = "started"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Listed in the Ansible inventory while its HA resource is requested.
resource "ansible_host" "ingress" {
  count = proxmox_haresource.ingress.state == "started" ? 1 : 0

  name   = "${proxmox_virtual_environment_container.ingress.initialization[0].hostname}.${local.guest_domain}"
  groups = ["gonkputer", "proxmox_containers", "ubuntu"]

  # Reached through proxmox_pct_remote: SSH to the node, then pct into the container.
  variables = {
    ansible_host = var.node_ssh_addresses[proxmox_virtual_environment_container.ingress.node_name]
    proxmox_vmid = proxmox_virtual_environment_container.ingress.vm_id
  }
}
