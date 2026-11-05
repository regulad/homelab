# cloudflare (Cloudflare)

The `.tf` files are the source of truth for the Cloudflare account `regulad`: its five zones
and their DNS records, the DNSSEC of `regulad.xyz`, `nefumllc.com` and `regulad.net`, the
settings in which `regulad.xyz` differs from a new zone, the `git` tunnel and its routes, the
`mta-sts` Worker, and the account's API tokens.

| Location | Configuration |
|---|---|
| `zone-<zone>.tf` | Each zone, its DNSSEC where it is signed, and its DNS records; `zone-regulad.xyz.tf` also holds its settings |
| `tunnel-git.tf` | The `git` tunnel, which cloudflared on `git.regulad.internal` runs, and its routes |
| `worker-mta--sts.tf` | The `mta-sts` Worker, which serves the MTA-STS policy at `mta-sts.` in each zone mail receives for |
| `tokens.tf` | The account's API tokens, other than this root's own |
| `oracle.tf` | `tofu/oracle`'s outputs, read from its state |
| `locals.tf` | The account ID, the MTA-STS policy with its id, and the TLS-RPT reporting address |
| `providers.tf`, `versions.tf` | Provider settings and pinned versions |
| `state.tf` | Enforced state encryption with its passphrase input, and `tofu/oracle`'s passphrase for reading its state |

## DNS records

Each record's label is `<zone>_<name>_<type>`, its zone and name written with `_` for each
`.` and `-`, a name's leading `_` dropped, `*` written `wildcard`, and the name left out at
the apex: `regulad_xyz_mail_a`, `regulad_xyz_dmarc_txt`. Where a name and type repeat, a
suffix says which record it is (`regulad_xyz_txt_spf`), and a record whose name changes with
its value is labelled for its role (`regulad_xyz_email_dkim_cname`). A `ttl` of 1 is
Cloudflare's automatic TTL.

Names are built from their zone's name, and a record pointing at a host declared here
references that record. The OCI instances' A and AAAA records and each zone's Email Delivery
DKIM record read their values from `tofu/oracle`'s outputs, so no GUA is written here. After an
apply to `tofu/oracle` changes one, apply this root for its records to follow.

`regulad.xyz` declares only the settings in which it differs from a new zone, as
`regulad.net` showed on 2026-11-04; the other four zones use the new-zone settings, and none
of their settings is declared. A change to an undeclared setting shows in no plan.

## Credentials

Cloudflare's API accepts only bearer secrets: API tokens, or a user's legacy Global API Key,
which carries all of that user's access. OpenTofu uses an account-owned API token, which
belongs to the account rather than to a user. It is in `provider.sops.env`, which `prepare.sh`
exports as `CLOUDFLARE_API_TOKEN`. Deleting it under Manage Account → API Tokens revokes it.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/cloudflare/prepare.sh       # exports the API token and backend credentials, decrypts inputs
tofu -chdir=tofu/cloudflare init -input=false -lockfile=readonly
tofu -chdir=tofu/cloudflare validate
tofu -chdir=tofu/cloudflare plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs `tofu`.
It needs `sops`, `jq` and `git`. It decrypts `secrets.sops.yaml` into the ignored
`secrets.auto.tfvars.json`, adding `tofu/oracle`'s state passphrase from
`tofu/oracle/secrets.sops.json`, its only copy.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`cloudflare/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports; `oracle.tf` reads `tofu/oracle`'s
state with them.

## Not managed here

| What | Why, or who owns it |
|---|---|
| `ingress.regulad.xyz` and `dodo.regulad.xyz`, A and AAAA | The `cloudflare-ddns` container on each host keeps them current; their home IPv6 prefix rotates |
| `git.regulad.xyz`'s HTTPS record | Caddy on ingress publishes it with its ECH keys, which it rotates |
| `_acme-challenge` TXT records | ACME clients create and delete them for DNS-01 challenges |
| `regulad.xyz`'s three page rules | The Page Rules API refuses account-owned tokens, and Cloudflare deprecates Page Rules for Single Redirects. They send `regulad.xyz/*` to `https://www.regulad.xyz` (301), and `www.regulad.xyz/*` (302) and `t.regulad.xyz/*` (301) to Linktree. Only `t` is proxied, so only its rule takes effect |
| `regulad.xyz`'s `http_config_settings` ruleset | It holds no rules |
| The `homelab-tofu` API token | This root's own credential, in `provider.sops.env`, created by hand like `svc-tofu-state`'s key, so that no apply can change or revoke the access it runs with. It holds every permission group, on the account and on all its zones |
| The user API token of `cloudflare-ddns` on dodo and ingress, and of certbot on dodo | It belongs to Parker's user, whose tokens an account-owned token cannot read |

Discovery output stays local in `docs/snapshot/cloudflare/`. Every mutation or state change
needs Parker's explicit approval.
