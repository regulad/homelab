# aboriginal: VM 100 and its firewall options.

resource "proxmox_virtual_environment_vm" "aboriginal" {
  # The snippet IDs below are written out; this keeps the files ahead of the guest.
  depends_on = [proxmox_virtual_environment_file.pin_vcpus]

  name      = "aboriginal"
  node_name = "prodingus"
  description = chomp(<<EOT
MAINTENENCE TASKS AT 5:35

Needs >48GiB

This node has a graphics card passed through, even though it does not absolutely need it. This is because it was migrated from a standalone Ubuntu Server install, and things like grub and many services expect a GPU.

## WIFI

While a 160MHz wide WiFi 6 channel would be faster than gigabit ethernet, the CR1000B FIOS router doesn't support it on the 5GHz band: it only supports it on 6GHz. Since the AX200 doesn't support the 6 GHz WiFi 6E band, that means it'll max out at the 1200Mbps speed of a 80MHz channel. Not worth it over gigabit ethernet which is reliable.

I've opted not to use the WiFi card while an ethernet bridge is in use. The ISP router doesn't like two devices advertising the same hostname: it trips its DNS rebinding protection.

## WEIRD INSANE ISSUES

For the Virtiofs->NFS mount, xattrs work but acls do not. cache=shared is not supported and causes proxmox to drop the virtiofs device even though docs say it should be. I've instead chosen to use cache=never, which offloads caching to the NFS FSC which should be up-to-date with whats on disk. Since the virtiofs and FSC are just connected via the kernel, this should still be more performant than default caching behaviour.

BEES & COMPRESSION: An interesting experiment, but absolutely a no-go for actual random R/W on a system. Better suited for an environment wherre it makes sense

Virtio vIOMMU causes page faults (???)

Setting the GPU to the primary vga card with x-vga breaks networking... somehow.

Passing through a GPU breaks the metering of how much memory has been paged in from the host.

The UPS USB cord keeps coming loose.
EOT
  )
  protection          = true
  bios                = "ovmf"
  boot_order          = ["virtio0"]
  hook_script_file_id = "local:snippets/pin-vcpus.sh"
  machine             = "q35"
  scsi_hardware       = "virtio-scsi-single"
  # Never reboot this VM on its own: its passed-through AMD GPU does not reset
  # properly when the KVM host detaches and re-attaches it. Restart it by rerooting,
  # or together with a host reboot. Changes that need a reboot stay pending.
  reboot_after_update = false
  tags                = [local.tags.locally_backed, local.tags.terraform, local.tags.virtiofsd]

  network_device {
    mac_address = "BC:24:11:5D:BE:75"
    vlan_id     = 1
    # Bypasses the firewall: no firewall bridge for this NIC.
    firewall = false
  }

  agent {
    enabled = true
  }

  cpu {
    affinity = "8-11,24-27"
    cores    = 8
    flags    = []
    numa     = true
    type     = "host"
    units    = 1000
  }

  disk {
    datastore_id = ""
    discard      = "on"
    interface    = "virtio0"
    iothread     = true
    size         = 238
  }

  efi_disk {
    pre_enrolled_keys = true
    type              = "4m"
  }

  hostpci {
    device  = "hostpci0"
    mapping = proxmox_hardware_mapping_pci.ax200.name
    pcie    = true
    rombar  = true
  }

  hostpci {
    device  = "hostpci1"
    mapping = proxmox_hardware_mapping_pci.rx6800.name
    pcie    = true
    rombar  = true
  }

  memory {
    dedicated      = 32768
    hugepages      = "1024"
    keep_hugepages = true
  }

  operating_system {
    type = "l26"
  }

  rng {
    source = "/dev/urandom"
  }

  startup {
    order    = 1
    up_delay = 120
  }

  usb {
    mapping = proxmox_hardware_mapping_usb.ax200.name
  }

  usb {
    mapping = proxmox_hardware_mapping_usb.tubeszb.name
  }

  usb {
    mapping = proxmox_hardware_mapping_usb.bcm20702a0.name
  }

  # The APC UPS is under maintenance; restore this block when it is back.
  # usb {
  #   mapping = proxmox_hardware_mapping_usb.back_ups.name
  # }

  # TODO: declare usb4, which is live as `mapping=CPS` (the CyberPower UPS). The
  # provider reads only usb0 to usb3, so a usb block for it would plan a change
  # on every run. Pending https://github.com/bpg/terraform-provider-proxmox/issues/3009.

  vga {
    type = "virtio-gl"
  }

  virtiofs {
    direct_io    = true
    expose_acl   = true
    expose_xattr = true
    mapping      = proxmox_hardware_mapping_dir.cephfs.name
  }

  # Pauses instead of resetting, because the GPU does not survive VM 100
  # restarting on its own; a lapsed VM stays paused for inspection by hand.
  watchdog {
    action  = "pause"
    enabled = true
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_virtual_environment_firewall_options" "aboriginal" {
  node_name = "prodingus"
  vm_id     = proxmox_virtual_environment_vm.aboriginal.vm_id
  # Disabled, and bypassed anyway: net0 has no firewall flag. The other options repeat
  # Proxmox's effective defaults, because the provider's own ndp and radv defaults differ.
  enabled       = false
  dhcp          = false
  input_policy  = "DROP"
  log_level_in  = "nolog"
  log_level_out = "nolog"
  macfilter     = true
  ndp           = true
  output_policy = "ACCEPT"
  radv          = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Listed in the Ansible inventory while it starts on boot. A quasi-hardware VM:
# first installed on hardware, then imaged into a VM, so Ansible configures it.
resource "ansible_host" "aboriginal" {
  count = proxmox_virtual_environment_vm.aboriginal.on_boot ? 1 : 0

  name = "${proxmox_virtual_environment_vm.aboriginal.name}.${local.guest_domain}"
  # The watchdog group, for the watchdog daemon, follows the VM's watchdog device.
  groups = sort(concat(
    ["gonkputer", "kdump", "proxmox_vms", "ubuntu"],
    [for device in proxmox_virtual_environment_vm.aboriginal.watchdog : "watchdog" if device.enabled],
  ))

  # On the tailnet itself, it answers LAN SSH over tailscale0, so the
  # connection only works by its tailnet name.
  variables = {
    ansible_host = "${proxmox_virtual_environment_vm.aboriginal.name}.${local.tailnet_domain}"
  }
}
