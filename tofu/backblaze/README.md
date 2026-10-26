# backblaze (Backblaze B2)

The `.tf` files are the source of truth for the Backblaze B2 account: its buckets and
application keys. This is the first, descriptive pass. It mirrors the live account, so
adoption changed nothing. Fixes follow as separate, reviewed changes.

| Location | Configuration |
|---|---|
| `bucket-<name>.tf` | One file per bucket: the bucket, then the keys restricted to it; `regulad-restic`'s also has the `restic` output |
| `providers.tf`, `versions.tf` | Provider auth and pinned versions |
| `state.tf` | Enforced state encryption and its passphrase input |

A `-` inside a bucket name is written as `--` (`bucket-regulad--restic.tf`); resource labels
write it as `_`.

Every bucket keeps only the last version of each file: its lifecycle rule deletes a version a
day after it is hidden or replaced. Clients that delete through the S3 API, such as restic's
prune, only hide files; the space returns a day later.

## Restic

`bucket-regulad--restic.tf` declares a key for each host in `local.restic_hosts`, restricted
to `regulad-restic` and to the capabilities of the S3 operations restic uses. The sensitive
`restic` output gives the repository, from the account's S3 endpoint, and the keys by short
hostname. The `restic` role, in both Ansible stages, reads it through the
`cloud.terraform.tf_output` lookup and configures restic only on the hosts it names. So this
root runs before the hardware stage, and a host starts or stops backing up when it is added
to or removed from `local.restic_hosts`.

To rotate a host's key, replace it, then deliver the new one:

```bash
tofu -chdir=tofu/backblaze apply -replace='b2_application_key.restic["dodo"]'
# then the restic play of that host's stage's site.yml
```

B2 deletes the old key as the plan replaces it, so the host's jobs fail until `site.yml`
writes the new one to `/etc/restic-env`.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/backblaze/prepare.sh       # exports the B2 master key and backend credentials, decrypts inputs
tofu -chdir=tofu/backblaze init -input=false -lockfile=readonly
tofu -chdir=tofu/backblaze validate
tofu -chdir=tofu/backblaze plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs
`tofu`. It needs `sops`, `jq` and `git`. It exports `B2_APPLICATION_KEY_ID` and
`B2_APPLICATION_KEY`, the account's master application key, from `provider.sops.env` into
that shell only. It decrypts `secrets.sops.json` into the ignored `secrets.auto.tfvars.json`,
which holds the state passphrase.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`backblaze/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports.

## Adoption

The three buckets and the `Clonezilla` key were imported into the remote state, and the
import blocks and their IDs were removed after the adoption apply, which changed nothing
live. A plan is now a no-op. Every adopted resource carries `prevent_destroy = true`.

## Not managed here

| What | Why, or who owns it |
|---|---|
| The master application key | The account's own credential, kept in `provider.sops.env`, rotated by hand |
| Files in the buckets | Data, not configuration |

Discovery output stays local in `docs/snapshot/backblaze/`. Every mutation or state change
needs Parker's explicit approval.
