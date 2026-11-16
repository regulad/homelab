# supabase (Supabase)

The `.tf` files are the source of truth for the Supabase organization `regulad`
(`vjpmxgwlilbffofvqunj`, Free plan) and everything in it. It holds one project,
`doppelganger` (`eopqnjmpgtpcdhfcvvxq`, us-east-1, Postgres 17), which backs Doppelganger;
the project has no branches and no Edge Functions. The provider has no resource for an
organization itself, so the organization's own settings and members stay in the Dashboard.

| Location | Configuration |
|---|---|
| `project-<name>.tf` | One file per project: the project, then its settings |
| `variables.tf` | The project's database password input |
| `providers.tf`, `versions.tf` | Provider auth and pinned versions |
| `state.tf` | Enforced state encryption and its passphrase input |

The provider is Supabase's own, `supabase/supabase`. It manages hosted Supabase only.

## Settings

A project's settings declare only what was chosen for it, as `tofu/cloudflare` does for its
zones: for `doppelganger`, Auth's site URL and redirect allow-list, which are
doppelgangerhq.com, and sign-in with Google. Everything else is Supabase's default and
undeclared, so a change to it shows in no plan. Its API, database, network, pooler and
storage groups and its SSL enforcement are wholly undeclared; the provider neither reads
nor sends a group it is not given, and reads back only the keys a group declares. Auth
sends with Supabase's own email, no SMTP of its own. Secrets the API keeps, such as Google's
client secret, are never read back, so they stay the Dashboard's.

## Credentials

OpenTofu authenticates with `homelab-tofu`, a scoped personal access token (`sbp_fc…`)
limited to the `regulad` organization, created under Account → Access Tokens. A scoped token's access
cannot change after it is made, and it expires within a year: a new token replaces it.
It is in `provider.sops.env`, which `prepare.sh` exports as `SUPABASE_ACCESS_TOKEN`.
Deleting the token revokes it.

## Database password

`supabase_project` requires the project's database password, the `postgres` role's, which
Supabase never returns. It is generated, in `secrets.sops.yaml`, and the root sets it on
the project: changing it there and applying rotates it. Doppelganger connects as its own
`prisma` role, whose password is in its `DATABASE_URL` and `DIRECT_URL`, not this one.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/supabase/prepare.sh       # exports the token and backend credentials, decrypts inputs
tofu -chdir=tofu/supabase init -input=false -lockfile=readonly
tofu -chdir=tofu/supabase validate
tofu -chdir=tofu/supabase plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs
`tofu`. It needs `sops`, `jq` and `git`. It decrypts `secrets.sops.yaml` into the ignored
`secrets.auto.tfvars.json`, which holds the state passphrase and the database password.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`supabase/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports.

## Adoption

The project and its settings were imported into the remote state, and the import blocks
removed after the adoption apply. Its one live change set the generated `postgres`
password; the settings' update sent only the declared Auth keys, at their live values. A
plan is now a no-op. Every adopted resource carries `prevent_destroy = true`.

Discovery output stays local in `docs/snapshot/supabase/`. Every mutation or state change
needs Parker's explicit approval.
