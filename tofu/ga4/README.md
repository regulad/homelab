# ga4 (Google Analytics)

The `.tf` files are the source of truth for Parker's Google Analytics account,
`accounts/183524752` (`regulad`), and the four GA4 properties in it. This is the first,
descriptive pass: it mirrors what was made in Analytics' console, through the Admin API's
v1beta. Every resource was imported, and the import blocks were removed after the adoption
apply, which changed nothing live; a plan is now a no-op. Every adopted resource carries
`prevent_destroy = true`.

| Location | Configuration |
|---|---|
| `account.tf` | The account |
| `property-<name>.tf` | One file per property: the property, its data retention settings, its data stream, custom dimensions and key events |
| `gcp.tf` | `tofu/gcp`'s outputs, read from its state: `tofu-analytics`'s address and key ID |
| `providers.tf`, `variables.tf`, `versions.tf`, `tofu.rc` | The credentials, the pinned version and where it is installed from |
| `state.tf` | Enforced state encryption and its passphrase inputs |
| `outputs.tf` | `measurement_ids`: each property's web stream's measurement ID, by property name, which `tofu/vercel` and `ansible-generated` deliver as `NEXT_PUBLIC_GA_TAG` |
| | `doppelganger_measurement_protocol_secret` (sensitive): doppelganger's Measurement Protocol secret, which `ansible-generated` delivers to its server |

## Properties

Every property has one web data stream, and with it the key event `purchase`, which Analytics
creates with every web stream and refuses to delete; doppelganger's also counts `sign_up`, and
its stream alone has a Measurement Protocol secret. No property has custom dimensions, custom
metrics, Google Ads links or Firebase links.

The user data collection acknowledgement that a property's `acknowledge_user_data_collection`
gives is an action no API reads back and that can't be withdrawn. Parker gave it for every
property on 2026-11-27, through `true` here, when the sites' privacy policies were updated;
doppelganger's Measurement Protocol secret needs it.

## Provider

The provider is `himanoa/ga4`, at the version `0.1.0-remaining.2`, which covers the Admin API's
v1beta. It is on no registry: the mirror at `https://opentofu.regulad.xyz/`, built from
[`regulad/opentofu-registry`](https://github.com/regulad/opentofu-registry)'s `providers.toml`,
serves it, and `tofu.rc`, which `prepare.sh` selects, installs it from there alone.
`tofu providers lock` ignores the CLI configuration, so the lock file is written with
`-net-mirror=https://opentofu.regulad.xyz/`, for Linux and macOS on amd64 and arm64.

## Credentials

OpenTofu works as `tofu-analytics`, a service account of `tofu/gcp`'s in the project `regulad`,
which enables the Admin API. Its key's private half, which Google never had, is in
`provider.sops.yaml`; `tofu/gcp` uploads its certificate. Sourcing `prepare.sh` exports the
private key as `TF_VAR_private_key`, and `providers.tf` assembles the key file Google would
otherwise hand out, in memory, from it and `tofu/gcp`'s `tofu_analytics` output, the account's
address and the key's ID, read from `tofu/gcp`'s state with its passphrase, which `prepare.sh`
adds to the inputs from `tofu/gcp/secrets.sops.yaml`. Deleting the key from the account
revokes it.

The account is an Editor of the Google Analytics account, granted by Parker in Analytics'
console (Admin, Account access management), which no provider reaches. It holds no Google
Cloud role.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/ga4/prepare.sh       # selects tofu.rc, exports the private key and backend credentials, decrypts inputs
tofu -chdir=tofu/ga4 init -input=false -lockfile=readonly
tofu -chdir=tofu/ga4 validate
tofu -chdir=tofu/ga4 plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs `tofu`.
It needs `sops`, `jq` and `git`. It decrypts `secrets.sops.yaml` into the ignored
`secrets.auto.tfvars.json`, with `tofu/gcp`'s state passphrase. The pipeline's step is `ga4`,
after `gcp`.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`ga4/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports.

## Not managed here

The provider has no resource for these: most are outside the Admin API's v1beta, and the rest,
such as the data sharing settings, only readable there. They stay in Analytics' console. OpenTofu manages only what it declares, so they need no configuration to
be left alone.

| What | Where it is set |
|---|---|
| Account and property access (users, groups and `tofu-analytics`'s own Editor role) | Admin, Account or Property access management |
| Data sharing settings | Admin, Account settings |
| Google tag settings: enhanced measurement, cross-domain links, internal traffic rules, unwanted referrals, session timeout | Each web stream's page |
| Data filters, consent settings, Google signals, data collection for ads personalization, reporting identity | Admin, Data collection and modification, and Data display |
| Audiences, channel groups, custom event creation and modification, attribution settings | Admin, Data display |
| Product links other than Firebase and Google Ads (BigQuery, Search Console, Merchant Center and others) | Admin, Product links |
| Firebase's own project and apps | Firebase, and `tofu/gcp` for the Google Cloud project |

Discovery output stays local in `docs/snapshot/ga4/`. Every mutation or state change needs
Parker's explicit approval.
