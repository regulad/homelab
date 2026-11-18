# vercel (Vercel)

The `.tf` files are the source of truth for the projects of the Vercel team `regulad`
(slug `regulad0`, `team_JrB4YMLbrdINYpJ5RdhGyK3d`), the account's only team: each
project, its custom domains and its environment variables.

| Project | Repository | Custom domains | Environment |
|---|---|---|---|
| `aporia-blue` | `regulad/aporia-blue` | `aporia.blue` | |
| `battleship-visualizer` | `regulad/battleship-visualizer` | | |
| `github-readme-stats` | `regulad/github-readme-stats` | | `PAT_1` |
| `ml4webedit` | `regulad/ml4webedit` | | |
| `parkerwahle` | `regulad/parkerwahle` | `regulad.xyz`, `www.regulad.xyz` | |
| `picture-triangulator` | `regulad/picture-triangulator` | | |
| `uulanding` | `regulad/uulanding` | | |

| Location | Configuration |
|---|---|
| `project-<name>.tf` | One file per project: the project, then its custom domains and its environment variables |
| `providers.tf`, `versions.tf` | Provider auth, the default team and the pinned version |
| `state.tf` | Enforced state encryption |
| `variables.tf` | The state passphrase and the GitHub personal access tokens |

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
`github_pats` map from `tofu/github/secrets.sops.yaml`, its only copy, so a token both
roots use is rotated in one place and applied in each.

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
