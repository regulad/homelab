# Shared OpenTofu constants

This module exports non-sensitive constants and manages no resources or providers.
`tailscale.tf` defines the tailnet IPv4 and IPv6 ranges once for all provider roots.

From a root such as `tofu/oracle` or a future `tofu/proxmox`:

```hcl
module "shared" {
  source = "../shared"
}
```

Use `module.shared.tailscale_cidrs.ipv4` or `.ipv6`, or pass the complete object
to child modules. OpenTofu loads this directory as a module, not individual files.
