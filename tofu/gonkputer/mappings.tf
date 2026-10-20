# mappings: PCI, USB and directory resource mappings.

resource "proxmox_hardware_mapping_pci" "ax200" {
  name = "AX200"
  map = [
    {
      comment      = null
      id           = "8086:2723" # Intel Wi-Fi 6 AX200
      iommu_group  = 29
      node         = "prodingus"
      path         = "0000:08:00.0"
      subsystem_id = "8086:0084" # Intel
    },
  ]
  mediated_devices = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_hardware_mapping_pci" "rx6800" {
  name = "RX6800"
  map = [
    {
      comment      = null
      id           = "1002:73bf" # AMD Radeon RX 6800 (Navi 21)
      iommu_group  = 27
      node         = "prodingus"
      path         = "0000:07:00"
      subsystem_id = "1462:3961" # MSI
    },
  ]
  mediated_devices = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_hardware_mapping_usb" "back_ups" {
  name = "Back-UPS"
  map = [
    {
      comment = null
      id      = "051d:0002" # APC UPS
      node    = "prodingus"
      path    = null
    },
  ]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_hardware_mapping_usb" "cps" {
  name = "CPS"
  map = [
    {
      comment = null
      id      = "0764:0501" # CyberPower CP1500 AVR UPS
      node    = "prodingus"
      path    = null
    },
  ]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_hardware_mapping_usb" "ax200" {
  name = "AX200"
  map = [
    {
      comment = null
      id      = "8087:0029" # Intel AX200 Bluetooth
      node    = "prodingus"
      path    = null
    },
  ]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_hardware_mapping_usb" "tubeszb" {
  name = "TubesZB"
  map = [
    {
      comment = null
      id      = "1a86:7523" # QinHeng CH340 serial converter
      node    = "prodingus"
      path    = null
    },
  ]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_hardware_mapping_dir" "cephfs" {
  name = "cephfs"
  map = [
    {
      node = "prodingus"
      path = "/mnt/pve/cephfs"
    },
  ]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
