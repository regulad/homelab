# authentik (authentik)

The `.tf` files are the source of truth for authentik's own configuration, the identity
provider in the `authentik` container (CT 201): the Immich application with its OAuth2
provider and its bindings, the memory application, whose client is mcp-auth-proxy on
`memory` (memory.regulad.xyz), with its binding to `memoryusers`, the `freeipa` LDAP
source with the CA certificate it checks its server against, and the system settings.
What was set up by hand was adopted in a first, descriptive pass that mirrored the live
configuration; the memory application was created here.

The stack itself, its compose file, `.env` and release, is `ansible-generated`'s
(`host_vars/authentik.regulad.internal/`), which brings authentik up before this root can
reach it.

| Location | Configuration |
|---|---|
| `application-<slug>.tf` | One file per application: the application, its provider and its policy bindings, with the users and groups those bind read through data sources |
| `source-<slug>.tf` | One file per source, with the certificates it uses and the property mappings it applies |
| `system-settings.tf` | The system settings |
| `defaults.tf` | The flows, signing key and scope mappings authentik makes itself, read through data sources |
| `outputs.tf` | The `oauth_client_ids` output, each OAuth2 provider's client ID, and the sensitive `oauth_client_secrets`, the secrets authentik generated for the clients `ansible-generated` configures, each by application slug |
| `variables.tf` | The API token and LDAP bind password inputs |
| `providers.tf`, `versions.tf` | Provider auth and pinned versions |
| `state.tf` | Enforced state encryption and its passphrase input |

A `-` inside a slug is written as `--` in its file name; resource labels write it as `_`.

The provider is `goauthentik/authentik`, authentik's own. Its releases follow authentik's,
each tested against the authentik release of the same year and month, so the pin in
`versions.tf` moves with the server's tag in `ansible-generated`'s compose file. OpenTofu's
registry holds no signing key for it, so `tofu init` skips its signature check; the lock
file's checksums still pin the build.

## authentik's own objects

authentik's shipped blueprints make its default flows, stages, policies, property
mappings, brand, notification rules and roles, and re-apply them when an upgrade changes
them; it generated the self-signed key pair that signs tokens at its first start. None of
them is managed here, so an upgrade's changes to them never show as drift. A resource
here refers to one through a data source (`defaults.tf`). An object a blueprint makes is
never changed here, as the blueprint's next apply would overwrite the change; it gets a
copy of its own instead.

## Users and groups

The `freeipa` source syncs users and groups from FreeIPA, and owns them: none is managed
here, and the bindings read the ones they name through data sources. `akadmin`, the
superuser group `authentik Admins` and the outpost's service account are authentik's own,
made by its bootstrap blueprint and its outpost; `homelab-tofu`, this root's service
account, is `ansible-generated`'s (Credentials).

## Secrets

`secrets.sops.yaml` holds the state passphrase and the `freeipa` source's bind password,
svc-authentik's on the old FreeIPA server. authentik never returns the bind password, so
the provider sends it at every update of the source. The OAuth2 providers' client secrets
are authentik's: each was generated when its provider was created, and is read into state,
not declared.

## Credentials

OpenTofu authenticates as `homelab-tofu`, an authentik service account in the superuser
group `authentik Admins`, with a non-expiring API token. Both are defined by the
`homelab-tofu` blueprint, which `ansible-generated` renders into
`/opt/authentik/blueprints/` (`files/authentik.regulad.internal/opt/authentik/blueprints/`)
and the worker applies from `/blueprints/homelab`. The token is `authentik_tofu_token` in
the authentik host's `ansible-generated/inventory/host_vars/authentik.regulad.internal/secrets.sops.yml`,
its one copy, which `prepare.sh` exports as `TF_VAR_authentik_token` (`variables.tf`); the URL,
`https://authentik.regulad.xyz`, is in `providers.tf`. So `ansible-generated` must have
placed the blueprint before this root can sign in.

To rotate the token, generate a new `authentik_tofu_token`, run `site.yml --tags
host_files --limit authentik.regulad.internal`, and source `prepare.sh` again: the changed
file is applied by the worker, which overwrites the token's key. authentik keeps no pruning
state for blueprints, so removing the file leaves the account and its token in place; delete
them by hand, or with an `absent` entry, to revoke them.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/authentik/prepare.sh       # exports the token and backend credentials, decrypts inputs
tofu -chdir=tofu/authentik init -input=false -lockfile=readonly
tofu -chdir=tofu/authentik validate
tofu -chdir=tofu/authentik plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs
`tofu`. It needs `sops`, `jq` and `git`. It decrypts `secrets.sops.yaml` into the ignored
`secrets.auto.tfvars.json`, which holds the state passphrase and the bind password.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`authentik/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports.

## Adoption

The application, its provider and its two bindings, the source and its CA certificate, and
the system settings were imported into the remote state, and the import blocks were removed
after the adoption apply. Its two changes left authentik as it was: the provider's scope
mappings and the source's property mappings were sent again in the order the `.tf` files
list them, and the source's bind password, which the provider never reads back, was sent
with the value it already had. A plan is now a no-op. Every adopted resource carries
`prevent_destroy = true`.

## Not managed here

| What | Why, or who owns it |
|---|---|
| The `freeipa` source's peer certificate, `ipa-ca.crt` | The provider cannot set it, as the FIXME in `versions.tf` says (#9); its update leaves it as it is. The certificate itself is managed |
| The base URL and the required reason for impersonation | The provider's system settings lack them, as the FIXME in `versions.tf` says (#9) |
| authentik's default flows, stages, policies, mappings, brand, notification rules, roles and outpost | Its shipped blueprints (above) |
| Users and groups | The `freeipa` source, and authentik's bootstrap blueprint for `akadmin` and `authentik Admins` |
| The `homelab-tofu` service account and its token | This root's own credential, from `ansible-generated`'s `homelab-tofu` blueprint (above) |
| The stack, its release and its `.env` | `ansible-generated` |

Every mutation or state change needs Parker's explicit approval.
