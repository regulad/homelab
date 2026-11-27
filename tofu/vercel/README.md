# vercel (Vercel)

The `.tf` files are the source of truth for the projects of the Vercel team `regulad`
(slug `regulad0`, `team_JrB4YMLbrdINYpJ5RdhGyK3d`), the account's only team: each
project, its custom domains and its environment variables.

| Project | Repository | Custom domains | Environment |
|---|---|---|---|
| `battleship-visualizer` | `regulad/battleship-visualizer` | | |
| `github-readme-stats` | `regulad/github-readme-stats` | | `PAT_1` |
| `ml4webedit` | `regulad/ml4webedit` | | `SENTRY_AUTH_TOKEN` |
| `parkerwahle` | `regulad/parkerwahle` | `regulad.xyz`, `www.regulad.xyz` | `NEXT_PUBLIC_GA_TAG` |
| `picture-triangulator` | `regulad/picture-triangulator` | | |

| Location | Configuration |
|---|---|
| `project-<name>.tf` | One file per project: the project, then its custom domains and its environment variables |
| `providers.tf`, `versions.tf` | Provider auth, the default team and the pinned version |
| `state.tf` | Enforced state encryption |
| `variables.tf` | The state passphrase, the GitHub personal access tokens, the Sentry organization tokens, and `tofu/ga4`'s state passphrase |
| `ga4.tf` | `tofu/ga4`'s outputs, read from its state: the properties' measurement IDs |

## Provider

`vercel/vercel` comes from OpenTofu's registry, which holds no GPG key for it, so
`tofu init` skips its signature check; the checksums in `.terraform.lock.hcl`, for Linux and
macOS on amd64 and arm64, are what pin it.

## Projects

Every project is adopted as Vercel shows it; the first pass describes and later changes
prescribe. Each project's `<name>.vercel.app` domain, which Vercel assigns itself, is not
declared. The custom domains' DNS records, such as `_vercel` verification records, are
`tofu/cloudflare`'s.

## Environment variables

Values come from SOPS, and sensitive ones are declared `sensitive`, as Vercel then never
returns them. A GitHub personal access token is not written here: `prepare.sh` reads the
`pat` and `fine_grained` maps from `tofu/github-user/personal.sops.yaml`, its only copy, as
`github_pats`, so a token
this root and `tofu/github` both use is rotated in one place and applied in each. A Sentry
organization token likewise comes from `tofu/sentry/org-tokens.sops.yaml`, its only copy, as
`sentry_auth_tokens`: ml4webedit's production build makes its Sentry release and uploads its
source maps with `terraform-ml4webedit`.

## Credentials

OpenTofu authenticates with a Vercel access token for the `regulad` team, made in the
account's token settings (https://vercel.com/account/tokens). It is in
`provider.sops.env`, which `prepare.sh` exports as `VERCEL_API_TOKEN`. Deleting the token
revokes it.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/vercel/prepare.sh       # exports the token and backend credentials, decrypts inputs
tofu -chdir=tofu/vercel init -input=false -lockfile=readonly
tofu -chdir=tofu/vercel validate
tofu -chdir=tofu/vercel plan -input=false -detailed-exitcode
```
