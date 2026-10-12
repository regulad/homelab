# homelab

[![wakatime](https://wakatime.com/badge/github/regulad/homelab.svg)](https://wakatime.com/badge/github/regulad/homelab)

Declarative infrastructure for a home Proxmox cluster and an OCI tenancy:
OpenTofu for machines, Ansible and Podman Quadlets for what runs on them.

WIP.

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

See [`.claude/PLAN.md`](.claude/PLAN.md) for the migration plan and each phase's
status, and [`AGENTS.md`](AGENTS.md) for the rules and conventions agents follow.

Licensed under [GNU AGPLv3](LICENSE.md).

## Adjacent IaC projects

Tailnet ACL policy and DNS live in
[`regulad/tailscale-acls`](https://github.com/regulad/tailscale-acls).

Workstation configuration is at [`regulad/dotfiles`](https://github.com/regulad/dotfiles).
