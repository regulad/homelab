# tailscale (Tailscale)

The `.tf` files are the source of truth for the tailnet regulad's configuration: its policy
file, its DNS configuration, its federated identities, the trust credentials with which
GitHub Actions runs act on the tailnet without a secret, and the tags of the devices no
other tool tags. They moved here from
[`regulad/tailscale-acls`](https://github.com/regulad/tailscale-acls), which is to be
retired.

| Location | Configuration |
|---|---|
| `acl.tf`, `policy.hujson.tftpl` | The policy file: the template is the policy, comments and all, with addresses filled in |
| `dns.tf` | The whole DNS configuration |
| `identity-<repository>.tf` | One federated identity per repository whose Actions use the tailnet |
| `device-<host>.tf` | One device's tags, for a device whose Tailscale no other tool configures |
| `oracle.tf` | `tofu/oracle`'s `tailnet` output: the VCN's services subnet and its resolvers |
| `outputs.tf` | `oauth_client_ids` and `audiences`, by repository |
| `locals.tf` | The tailnet's ID, GitHub's token issuer, and the resolvers' addresses |
| `providers.tf`, `versions.tf` | Provider auth and pinned versions |
| `state.tf` | Enforced state encryption and its passphrase input |

A `-` inside a repository's name is written as `--` in its file name; resource labels
write it as `_`.

## Policy and DNS

`tailscale_acl` and `tailscale_dns_configuration` each replace the whole of what they
manage: anything left out is cleared. Tailscale validates the policy and runs its `tests`
before accepting it, so a failing test fails the apply and leaves the tailnet as it was.

The resolvers' addresses are written once, in `locals.tf`, and fill both `dns.tf` and the
policy's IP sets, hosts and tests, which open every nameserver to every node. The Oracle
VCN's come from `tofu/oracle`, derived from its encrypted IPv6 prefix, and arawi's and
cr1000b's from `ansible-generated`'s `group_vars/all.yml`. The policy holds no public IPv6
address literally: each is a template expression. The provider compares policies by their
canonical HuJSON, so indentation never shows as a change, but comments do. The template is
written in Tailscale's own canonical format, tabs and all, so that a change's plan shows the
lines it changes and no others.

## Identities

Each identity trusts GitHub's Actions token issuer, for runs of one repository's default
branch, by the token's `sub`, which names the repository and its owner by ID as well as by
name. Each run exchanges its token for a Tailscale access token with the identity's scopes:
`auth_keys` and its CI tag, for doppelganger, PepperCord and kodi-plugins, which join the
tailnet. An
identity's tags must exist in the policy's `tagOwners` before the identity can grant them,
so a new identity's tag goes into `policy.hujson.tftpl` first, or in the same change.

tailscale-acls' identity, which applied the policy and DNS from that repository, was
deleted with the repository's retirement rather than adopted.

`tofu/github` reads `oauth_client_ids` and `audiences`, and sets them as each repository's
`TS_OAUTH_ID` and `TS_AUDIENCE`. OAuth client IDs are no secret.

## Device tags

A node the `tailscale` role joins advertises its own tags, its `tailscale_tags`, and gets no
file here. A device whose Tailscale no tool configures, such as overture, gets its tags
from a `device-<host>.tf`, which looks the device up by its short hostname. A tag must be
in the policy's `tagOwners` before a device can carry it, so each device's tags depend
on the policy.

## Credentials

The provider authenticates with the tailnet's `homelab` API access token, the
`tailscale_api_token` in `ansible-common/group_vars/all.sops.yml`, its only copy, which
`prepare.sh` exports as `TAILSCALE_API_KEY`. Tailscale's API access tokens expire; a renewed
one replaces that value.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/tailscale/prepare.sh    # exports the API token and backend credentials, decrypts inputs
tofu -chdir=tofu/tailscale init -input=false -lockfile=readonly
tofu -chdir=tofu/tailscale validate
tofu -chdir=tofu/tailscale plan -input=false -detailed-exitcode
```

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`tailscale/terraform.tfstate`, with S3-native locking.

## Not managed here

| What | Why, or who owns it |
|---|---|
| kodi-plugins' `ci-kodi` auth key | Hand-made; it gives way to kodi-plugins' federated identity once its workflow uses that, and is then revoked |
| The `homelab` API access token | This root's own credential |
| Devices and their settings | Not configured from here, but for the tags in a `device-<host>.tf` |

Every mutation or state change needs Parker's explicit approval.
