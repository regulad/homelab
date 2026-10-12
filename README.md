# homelab

Current progress: **static decompilation of OCI state**.

The existing OCI infrastructure is represented by 74 explicit OpenTofu resources
in [`tofu/oracle/`](tofu/oracle/README.md). Adoption imported those resources with
zero additions, changes, or deletions. The post-adoption plan reports no changes.

Sensitive input values are encrypted with SOPS and age. State is encrypted locally
and backed up outside the repository; state, plaintext inputs, plans, and discovery
snapshots are excluded from version history.

Remote state, Proxmox adoption, and Ansible service management remain future work.
See [`AGENTS.md`](AGENTS.md) for the migration plan and operating rules.

Licensed under [GNU AGPLv3](LICENSE.md).
