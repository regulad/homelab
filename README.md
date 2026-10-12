# homelab

Current progress: **static decompilation of OCI state**.

The existing OCI infrastructure is represented by 74 explicit OpenTofu resources
in [`tofu/oracle/`](tofu/oracle/README.md). Adoption imported those resources with
zero additions, changes, or deletions. The post-adoption plan reports no changes.

Sensitive input values are encrypted with SOPS and age. State is encrypted locally
and backed up outside the repository; state, plaintext inputs, plans, and discovery
snapshots are excluded from version history.

## Checks

[`.pre-commit-config.yaml`](.pre-commit-config.yaml) runs file-hygiene checks from the
pinned `pre-commit-hooks`, `tofu fmt`, `tofu validate`, TFLint, and public-repository
privacy guards: SOPS files must be encrypted, and neither OCIDs (other than named
stock images) nor GUA IPv6 literals may appear in plaintext. The OpenTofu hooks use
the operator's installed OpenTofu and TFLint; pre-commit 4.4.0 or newer builds an
environment only for `pre-commit-hooks`. Initialize each root once
(`tofu -chdir=tofu/oracle init -backend=false -input=false -lockfile=readonly`),
enable the Git hook with `pre-commit install`, and check everything with
`pre-commit run --all-files`.

Remote state, Proxmox adoption, and Ansible service management remain future work.
See [`AGENTS.md`](AGENTS.md) for the migration plan and operating rules.

Licensed under [GNU AGPLv3](LICENSE.md).
