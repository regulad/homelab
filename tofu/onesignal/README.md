# onesignal (OneSignal)

The `.tf` files are the source of truth for the OneSignal organization the Organization API
key belongs to (`f68a4e21-a700-4bdc-ab37-538cf60b83d1`) and the apps in it:

| App | ID | What it is |
|---|---|---|
| `Doppelganger` | `5ac065a9-c76c-4c31-8159-85a260832ee6` | doppelgangerhq.com's web push, Chrome and Safari |
| `homelab-provider-test` | `09e56944-87d3-461b-af14-21a4a41106c6` | The app the provider's live tests run in |

| Location | Configuration |
|---|---|
| `app-<name>.tf` | One file per app: the app, then its API keys and their outputs |
| `oracle.tf` | `tofu/oracle`'s outputs, read from its state: doppelgangerhq.com's public addresses |
| `locals.tf` | The organization ID both apps share |
| `providers.tf`, `versions.tf`, `tofu.rc` | Provider auth, the pinned version and where it is installed from |
| `state.tf` | Enforced state encryption and its passphrase inputs |

## Provider

The provider is our own, [`regulad/terraform-provider-onesignal`](https://github.com/regulad/terraform-provider-onesignal),
under the address `registry.opentofu.org/regulad/onesignal`. It is on no registry: the
mirror at `https://opentofu.regulad.xyz/`, built from
[`regulad/opentofu-registry`](https://github.com/regulad/opentofu-registry)'s `providers.toml`,
serves it, and `tofu.rc`, which `prepare.sh` selects, installs it from there alone.
`tofu providers lock` ignores the CLI configuration, so the lock file is written with
`-net-mirror=https://opentofu.regulad.xyz/`, for Linux and macOS on amd64 and arm64.

## Apps

Each app declares only what was chosen for it: its name, its organization, and its web
push origins. Everything else is undeclared and neither sent nor compared. Push
credentials are write-only in the provider and declared nowhere here, so the ones the
dashboard set stay as they are. OneSignal cannot delete an app through its API, so
destroying one fails; every app carries `prevent_destroy = true` too.

`homelab-provider-test` holds nothing of its own. The provider's `make testlive` creates API
keys and templates in it and destroys them again, so they are not declared here, and it
needs the app to exist.

## API keys

`Doppelganger`'s key `doppelgangerhq.com` is usable only from doppelgangerhq.com's IPv4 and
IPv6 addresses, as a `/32` and a `/128`, from `tofu/oracle`'s `public_addresses` output, read
from its state with its passphrase, which `prepare.sh` adds to the inputs from
`tofu/oracle/secrets.sops.json`. After an apply to `tofu/oracle` changes the instance's
addresses, apply this root for the allowlist to follow. OneSignal returns a key's value only
when it is created or rotated, so the value lives in state, and the sensitive
`doppelganger_api_key` output passes it on.

Segments and templates need an app's own API key, as OneSignal refuses the Organization key
for them. None are declared: both apps keep OneSignal's defaults.

## Credentials

OpenTofu authenticates with an Organization API key, made in the dashboard's organization
settings. It is in `provider.sops.env`, which `prepare.sh` exports as
`ONESIGNAL_ORGANIZATION_API_KEY`. Deleting the key in the dashboard revokes it.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/onesignal/prepare.sh       # selects tofu.rc, exports the key and backend credentials, decrypts inputs
tofu -chdir=tofu/onesignal init -input=false -lockfile=readonly
tofu -chdir=tofu/onesignal validate
tofu -chdir=tofu/onesignal plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs
`tofu`. It needs `sops`, `jq` and `git`. It decrypts `secrets.sops.yaml` into the ignored
`secrets.auto.tfvars.json`, with `tofu/oracle`'s state passphrase.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`onesignal/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports.

## Adoption

Both apps are adopted by the import blocks in `imports.tf`, which go after the adoption
apply. Every mutation or state change needs Parker's explicit approval.
