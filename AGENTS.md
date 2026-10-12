# Agent cheat sheet: `regulad/homelab`

Read this first. This repository makes a home Proxmox cluster and an OCI tenancy
declarative: OpenTofu for machines, Ansible and Podman Quadlets for what runs on
them. Parker supervises and approves.

- **Plan and status:** [`.claude/PLAN.md`](.claude/PLAN.md) has the goals, phases, and each phase's current status.
- **History:** [`.claude/HISTORY.md`](.claude/HISTORY.md) records past approvals, apply results, and superseded decisions. Append new history there and nowhere else.
- **Directory detail:** each `README.md`, starting with [`tofu/oracle/README.md`](tofu/oracle/README.md).

Where this file and the plan disagree, this file wins.

## Hard rules

1. **Approval for every mutation.** Never change infrastructure or state without Parker's explicit approval in chat for that specific action; an earlier approval never carries over. This covers `tofu apply|destroy|import`, `tofu state rm|mv|push`, `ansible-playbook` without `--check`, `pct|qm destroy|stop|set`, `podman rm|stop`, `oci ... delete|update`, and anything that edits Tailscale ACLs. Local file edits, SOPS encryption, validation, and read-only plans need no approval.
2. **Read-only discovery.** Use read-only credentials, such as a Proxmox `PVEAuditor` token. OCI is the exception: Parker's own read/write session token, so rule 1 is the safeguard there. Never create or broaden credentials yourself.
3. **No installs.** Never install tools, Python packages (`uv sync`, `uv tool install`), pre-commit hook environments, or OpenTofu providers (`tofu init` downloads) without Parker's approval for that install. He manages tools declaratively; `uv` is the Python/tool manager.
4. **No secrets in git; the repository is public.** Never commit tokens, keys, state, plans, `.terraform/`, plaintext `*.tfvars`, or discovery output. Sensitive values that must be committed go in SOPS-encrypted `*.sops.*` files (age recipients in `.sops.yaml`).
   - OCIDs owned by our tenancy or compartments link resources to the tenancy, so they stay encrypted, including router next-hop and backup-policy IDs. Verified stock-image OCIDs may be plaintext, with the exact image name in a comment above `source_id`. Verify ownership before publishing an unfamiliar OCID.
   - GUA IPv6 `/64` prefixes stay encrypted; derive host addresses and enclosing prefixes from them. IPv4, ULA and Tailscale ranges, and IPv6 host suffixes are plaintext.
5. **Don't invent facts.** Discover with read-only commands, keep raw output in the gitignored `docs/snapshot/`, and ask about anything unknown. Verify provider and tool details (resource names, import ID formats, flags) against current docs.
6. **Stop and ask** when a plan shows any destroy or replace, when an Ansible `--check` shows unexpected changes on a production host, or at an auth or permission wall.
7. **Pin everything:** providers with a committed `.terraform.lock.hcl`, Ansible collections in `requirements.yml`, container image tags (never `latest`), and pre-commit hook revisions.
8. **Commits only when Parker asks.** Keep each one small and single-purpose, with a conventional-commit message. Every commit carries the contributing agent's own `Co-authored-by` trailer. Never add `Signed-off-by` with Parker's identity unless he says so for those commits, and never bypass commit signing.

## Model architecture

This model guides where new work goes. The repository itself is the
authoritative state: where they differ, the repository wins, and changing the
model is Parker's decision.

```
homelab/
├── AGENTS.md, README.md
├── .claude/                     # PLAN.md, HISTORY.md
├── .pre-commit-config.yaml      # file hygiene, OpenTofu, privacy, Ansible lint hooks
├── .sops.yaml, .gitignore, ansible.cfg
├── docs/
│   ├── snapshot/                # local-only discovery output (gitignored)
│   └── runbooks/                # move-a-service, rotate-keys, restore-state
├── tofu/
│   ├── shared/                  # resource-free constants for every root
│   ├── <provider>/              # one root per provider, own state (oracle, proxmox, tailnet)
│   │   └── <child>/             # child modules split by network or concern
│   └── modules/                 # reusable child modules, e.g. lxc-guest/, vm-guest/
└── ansible/
    ├── inventory/               # inventory.py, group_vars/, host_vars/<host>/{main,services}.yml
    ├── playbooks/               # site.yml, base.yml, services.yml
    ├── roles/                   # base, podman, tailscale, avahi, quadlet_services
    └── requirements.yml         # pinned collections
```

- **OpenTofu** owns which machines exist. It never manages containers or in-guest files.
- **cloud-init**, set by OpenTofu, does only minimal bootstrap: admin user, SSH key, and a tailnet join with a pre-authorized, tagged key.
- **Ansible** owns everything inside a guest after bootstrap. Service lifecycle lives in Ansible data (`host_vars`), never in OpenTofu state.
- **Separate roots per provider** limit blast radius. Cross-root sharing goes through explicit outputs, or through `tofu/shared` for constants.

## Everyday commands

From the repository root, in PowerShell 7.5 or newer:

```powershell
./tofu/oracle/prepare.ps1                         # decrypt inputs into the ignored secrets.auto.tfvars.json
$env:OCI_CLI_AUTH = 'security_token'
$env:OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING = 'True'
oci session validate --profile DEFAULT            # `oci session refresh` extends a still-valid token
tofu '-chdir=tofu/oracle' init '-backend=false' '-input=false' '-lockfile=readonly'   # once per clone; downloads providers
tofu '-chdir=tofu/oracle' plan '-input=false' '-detailed-exitcode'                    # 0 no changes, 2 diff, 1 error
pre-commit run --all-files
```

- Run plans from a root, never from a child module.
- Write plaintext plan output and saved plans to `docs/snapshot/`. State and saved plans are AES-GCM encrypted with the passphrase from SOPS; never change or lose it.
- Before an approved apply, copy the encrypted state, `secrets.sops.json`, and the lock file to `%LOCALAPPDATA%/homelab/oracle-backups/<label>-<timestamp>/`. Apply exactly the saved plan Parker approved, then confirm a fresh plan is a no-op.
- The OCI session token lasts 60 minutes, and refreshing extends it up to 24 hours. After that, Parker must run `oci session authenticate` himself.

## Verification before review

```bash
pre-commit run --all-files
tofu -chdir=tofu/<root> fmt -check -recursive
tofu -chdir=tofu/<root> validate
tofu -chdir=tofu/<root> plan -detailed-exitcode
ansible-lint ansible/
ansible-playbook ansible/playbooks/site.yml --check --diff --limit <host>
ansible-inventory -i ansible/inventory/inventory.py --graph
```

Run the Ansible lines once Ansible exists. Also confirm that nothing secret is
staged (`git diff --cached`), lock files are committed, and no plan shows an
unintended destroy or replace.

## Conventions

- **Docs:** `AGENTS.md`, `.claude/PLAN.md`, and every `README.md` contain only intent and current state. Record what happened (work done, approvals, apply results, superseded decisions) by appending to `.claude/HISTORY.md`.
- **Guest names:** lowercase, hyphenated, stable (`svc-<name>`, `host-<role>`); the tailnet MagicDNS name equals the hostname.
- **Tags:** every guest carries `managed-by=opentofu`; tailnet tags map to ACL groups.
- **OpenTofu:** one root per provider; modules take explicit inputs; no secrets in `locals`.
- **Ansible:** roles expose knobs in `defaults/` and avoid `vars/`; handlers for restarts; every role passes `ansible-lint`.
- **Quadlets:** one file per unit; image tags pinned; volumes named, not bind-mounted from ad hoc paths.
- **File names:** where `-` delimits parts of a file name (`instance-<name>.tf`, `subnet-<name>.tf`), write each `-` inside a part as `--`. For example, subnet `subnet-20230331-2242` lives in `subnet-subnet--20230331--2242.tf`.

### OpenTofu HCL (as practiced in `tofu/oracle`)
- **HCL first:** ordinary, readable `.tf` resources with inline non-sensitive settings and direct references. SOPS holds sensitive input values only, never encrypted HCL, resource definitions, or a topology data model.
- **Files:** one `instance-<name>.tf` per host and one `subnet-<name>.tf` per subnet, each opening with a `# <name>: <contents>.` header. `network.tf` holds network-wide `locals`, the VCN, gateways, and the defaults the provider creates with the VCN. A distinct concern gets its own file (`email.tf`). `locals.tf` holds only values shared across files, and `variables.tf` declares inputs. `moved.tf` keeps every past address move so old states and backups still plan cleanly.
- **Order within a file:** file-local `locals` first, then the primary resource, then what depends on it.
  - Host files: instance, boot volume, backup-policy assignment, VNIC lookup, IPv6 assignment, NSG, NSG rules.
  - Subnet files: the subnet, then its own DHCP options, route table, and security lists.
  - `network.tf`: VCN, internet gateway, DHCP options, route tables, security lists.
- **Order within a resource:** meta-arguments (`for_each`) first, followed by a blank line. Then identity (`display_name`, `compartment_id`, parent IDs), placement (`availability_domain`, `fault_domain`), other scalar arguments, and nested blocks. Blank lines separate nested blocks; none directly inside an opening brace. Keep list order the provider or service treats as meaningful.
- **Imperative leftovers:** every adopted resource ends with this footer:
  ```hcl
    # The following exists as an artifact of import from the imperative setup.
    lifecycle {
      prevent_destroy = true
    }
  ```
  Schema placeholders that exist only for adoption, such as the boot-volume `source_details { type = "bootVolume" }`, sit between that comment and `lifecycle`. `ignore_changes` stays as narrow as possible and carries a comment explaining what owns the ignored field. Image-created boot volumes ignore only `source_details`; never fabricate a clone or restore source.
- **Opaque values get a comment:** wherever possible, put a comment next to any value whose meaning is not self-evident:
  - protocol numbers: `"1" # ICMP`, `"6" # TCP`, `"17" # UDP`, `"58" # ICMPv6`, `"all" # All IP protocols`
  - ICMP `type`/`code` pairs: `type = 3 # Destination Unreachable`
  - ports, on the opening line of the block holding `max`/`min`: `destination_port_range { # SMTP`, `tcp_options { # SSH`. A rule whose existing `description` already names the port needs no comment.
  - each plaintext stock-image OCID: the exact image name on the line above `source_id`

  Use HCL comments for this, not new `description` arguments; adding a description changes infrastructure.
- **IPv4/IPv6 pairs:** values that exist per IP family are objects keyed `ipv4`, then `ipv6`, named `dual_stack_<what>` when local (`local.dual_stack_internet_cidrs`, `var.tailscale_cidrs`, `var.router_next_hop_ids`).
  - Rules or routes identical across families iterate over the pair: `for_each` with `each.value`, or a `dynamic` block with `iterator = cidr`. The stable family keys keep resource addresses independent of ordering.
  - Rules that differ by family stay explicit.
  - A shared address pair never implies a permission for both families. Comment any family-only exception, such as an IPv4-only peering rule.
  - Constants that belong to one subnet or host live at the top of that file; network-wide pairs live in `network.tf`.
- **Addresses:** GUA host addresses are `cidrhost(var.ipv6_subnet_cidr, parseint("<64-bit hex suffix>", 16))`. Enclosing prefixes are derived from the encrypted `/64`, never written.
- **Lookups:** read a host's VNIC through a `data "oci_core_vnic_attachments"` filtered to `ATTACHED` and `one()`, so a second VNIC fails loudly instead of being guessed.
- **Inputs:** sensitive inputs are `sensitive = true` and `nullable = false` and come from `secrets.sops.json`. Non-sensitive values are inline HCL, not variables. Resource-free constants shared by several roots live in `tofu/shared`.
- **Versions:** pins live only in each root's `versions.tf`. Child modules declare provider sources only and start with `# tflint-ignore-file: terraform_required_version, terraform_required_providers`.
- **Tags:** every OCI instance sets `freeform_tags = { "managed-by" = "opentofu" }` as its last scalar argument.
- **Deferred problems:** a setting known to be wrong but kept for now gets `# FIXME: <what is wrong>. Revisit <when>.` on the lines directly above it.
- **Labels:** resource labels are stable identities; renaming one needs a `moved` block. NSG rules are labelled `<host>_<protocol>_<port or range>`; bailout's two family-specific rules keep their adopted `bailout_rule_NN` labels.

## Standing decisions

- **Pre-commit:** `.pre-commit-config.yaml` runs the pinned `pre-commit/pre-commit-hooks` plus local hooks that use installed tools (`language: unsupported`) or `pygrep`. Gitleaks is not wanted.
- **Discovery snapshots** stay on the operator's machine; only configuration derived from them is committed. Parker's review of `docs/snapshot/SUMMARY.md` gates the adoption phases.
- **OCI auth:** Parker's own user, through an `oci session authenticate` read/write session token in the `DEFAULT` profile, because OpenTofu writes back to OCI.
- **OCI adoption is complete** for the scope in the plan's Phase 5. Never regenerate or re-import it.
- **OCI state** is local, with enforced AES-GCM encryption and backups under `%LOCALAPPDATA%/homelab/oracle-backups/` on Parker's backed-up laptop. Migrating to a remote backend is deferred until the rest of the repository is ready.
- **VCN defaults** stay ordinary adopted resources guarded by `prevent_destroy`. Moving them to `oci_core_default_*` resource types is wontfix.
- **The OCI `ansible_hosts` output** waits for the Ansible phases.
- **Known non-issues:** the Email Delivery DKIM key shows `NEEDS_ATTENTION` for about a week after the mail server power-cycles; this is cosmetic. The tenancy is pay-as-you-go, so resources beyond Always Free limits (such as extra boot-volume backups) are expected.
