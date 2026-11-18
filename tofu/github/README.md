# github (GitHub)

The `.tf` files are the source of truth for the GitHub Actions, Dependabot and
environment secrets of regulad's repositories.

**Only repositories that need secrets are defined here. A repository with no secrets is
not defined in policy.** A repository that comes to need a secret gets a `repo-<id>.tf`
here; one whose last secret goes leaves it.

| Location | Configuration |
|---|---|
| `repo-<id>.tf` | One file per repository with secrets, by its GitHub repository ID: its Actions secrets, Dependabot secrets and environment secrets |
| `locals.tf` | Nexus's users and ingress's kodi publisher, read from `ansible-generated`'s data |
| `tailscale.tf` | `tofu/tailscale`'s outputs |
| `variables.tf` | The secret values, from `secrets.sops.yaml`, and the Nexus passwords |
| `providers.tf`, `versions.tf` | Provider auth and pinned versions |
| `state.tf` | Enforced state encryption and its passphrase input |

Files and resource labels are keyed by repository ID (`repo-1386017153.tf`,
`repository_1386017153`), which never changes, because the settings bot owns repository
names. Each file reads its repository's current name from `repositories/<id>` through the
`github_rest_api` data source, as GitHub's API takes names; a rename shows in the next plan.

## Values

Every value is derived; none is typed into GitHub.

- **SOPS:** issued tokens and keys live in `secrets.sops.yaml`, under keys that say what each
  is for. A token several repositories use is one key. Issued values carry no provenance
  comment; generated ones do. Fill or change one with `sops edit`, then apply.
- **Ansible's Nexus data:** the Nexus CI logins, `svc-redroid` for redroid-script and
  `nx-aaoracled` for aaoracled's `nexus-ios` environment, take their names from
  `nexus_security_users` in `ansible-generated/inventory/group_vars/nexus_servers.yml`.
  Their passwords come from `nexus_servers.sops.yml`, which `prepare.sh` reads. A password
  rotated there reaches Nexus through `site.yml --tags nexus_security`, and these
  repositories through an apply here; run the two together. kodi-plugins' SSH user and web
  root likewise come from ingress's `host_files_login_users` and `host_files_directories`.
- **tofu/tailscale:** the federated identities' client IDs and audiences, `TS_OAUTH_ID`
  and `TS_AUDIENCE`, come from `tofu/tailscale`'s outputs, read in `tailscale.tf`;
  `prepare.sh` adds that root's state passphrase.
- **Plaintext:** values that are no secret, such as a key alias, are written in the `.tf`
  files.

GitHub never returns a secret's value. A secret changed in GitHub shows as drift, through
its update time, and the next apply writes this repository's value back.

## Personal access tokens

The repositories' personal access tokens are issued by hand in GitHub's settings and kept
in SOPS. GitHub has no API that issues one, and no App-issued token can fill a secret,
as those last an hour. To rotate one, issue a new token, put it in `secrets.sops.yaml`, and
apply.

Later, not yet: workflows move off personal access tokens, to GitHub's built-in tokens
(`GITHUB_TOKEN`, Dependabot's) wherever they suffice and to an App of each repository's own
otherwise.

## Credentials

OpenTofu authenticates as the homelab GitHub App, owned by regulad and created by hand. Its
repository permissions are Secrets, Dependabot secrets and Environments at Read and write,
and Metadata at Read. It is installed on all of regulad's repositories, including those
created later: an App cannot change its own installation, so a narrower one would need a
hand-made change for each repository's first secret. Its ID and installation ID are in
`providers.tf`; its private key is in `provider.sops.env`, which `prepare.sh` exports as
`GITHUB_APP_PEM_FILE`, on one line with each newline written as `\n`. Deleting the key,
or the App, revokes it.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/github/prepare.sh       # exports the App key and backend credentials, decrypts inputs
tofu -chdir=tofu/github init -input=false -lockfile=readonly
tofu -chdir=tofu/github validate
tofu -chdir=tofu/github plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed. It needs `sops`, `jq` and `git`, and refuses an
input left empty, which would blank a secret.

State and saved plans use enforced AES-GCM encryption, and hold every secret's value, as
the provider has no write-only argument. Never change or lose the passphrase. State is
remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`github/terraform.tfstate`, with S3-native locking.

## Not managed here

| What | Why, or who owns it |
|---|---|
| Repositories without secrets | Not defined in policy, as above |
| The repositories themselves, and their settings | Only their secrets are managed here |
| The homelab GitHub App and its installation | Created and installed by hand; an App cannot manage itself |
| Personal access tokens | Issued by hand; GitHub has no API for them |

Discovery output stays local in `docs/snapshot/github/`. Every mutation or state change
needs Parker's explicit approval.
