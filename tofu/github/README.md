# github (GitHub)

The `.tf` files are the source of truth for the GitHub Actions, Dependabot and
environment secrets of regulad's and regubot's repositories, each account's in a
workspace of its own; and for the environments that another
root's credentials trust, with the refs each admits: Warlock's and Koala's, whose runs
sign as `tofu/azure`'s applications. A repository whose environments are defined here declares
none in its own `.github/settings.yml`. Probot Settings, which applies that file, deletes
every environment the file does not list, and replaces an environment's deployment
policies whenever they differ from the file's.

**Only repositories that need secrets are defined here. A repository with no secrets is
not defined in policy.** A repository that comes to need a secret gets a `repo-<id>.tf`
here; one whose last secret goes leaves it.

| Location | Configuration |
|---|---|
| `repo-<id>.tf` | One file per repository with secrets, by its GitHub repository ID: its Actions secrets, Dependabot secrets and environment secrets, and any environments defined here with their deployment policies |
| `locals.tf` | Whether the selected workspace manages regulad's repositories, and Nexus's users and ingress's kodi publisher, read from `ansible-generated`'s data |
| `tailscale.tf` | `tofu/tailscale`'s outputs |
| `azure.tf` | `tofu/azure`'s outputs |
| `variables.tf` | The secret values, from `secrets.sops.yaml`, the personal access tokens, and the Nexus passwords |
| `providers.tf`, `versions.tf` | Provider auth, by workspace, and pinned versions |
| `state.tf` | Enforced state encryption and its passphrase input |

Files and resource labels are keyed by repository ID (`repo-1386017153.tf`,
`repository_1386017153`), which never changes, because the settings bot owns repository
names. Each file reads its repository's current name from `repositories/<id>` through the
`github_rest_api` data source, as GitHub's API takes names; a rename shows in the next plan.

## Workspaces

Each account's repositories have a state of their own, in an OpenTofu workspace:
`personal` for regulad's, and `bot` for regubot's. Each workspace authenticates as its
own account's App, with only that App's key loaded, so a run never acts as the other
account's. A repository's file enables its blocks only in its account's workspace
(`local.personal`), as the other App cannot reach it. The `default` workspace has no App,
and `validate` and `plan` fail there.

The selected workspace lives in `.terraform/environment`, and nothing in a `plan` or
`apply` command shows it: check it with `tofu -chdir=tofu/github workspace show` before
each, and `prepare.sh` names it. alock locks and records the root as a single target, so
the two workspaces never apply at once, and its record of the last applied commit covers
both. A saved plan is named for its workspace, `docs/snapshot/github.<workspace>@<commit>.tfplan`.

State sits at `github/<workspace>/terraform.tfstate` in the state bucket.

## Values

Every value is derived; none is typed into GitHub.

- **SOPS:** issued tokens and keys live in `secrets.sops.yaml`, under keys that say what each
  is for, apart from the personal access tokens, which are
  [`tofu/github-user`](../github-user/README.md)'s. A token several repositories use is one key. Issued values carry no provenance
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
- **tofu/azure:** each environment's Entra client ID, the directory and subscription it signs
  in to, and the Artifact Signing account and profile it signs with, `AZURE_*` and
  `ARTIFACT_SIGNING_*`, come from `tofu/azure`'s outputs, read in `azure.tf`; `prepare.sh`
  adds that root's state passphrase.
- **Plaintext:** values that are no secret, such as a key alias, are written in the `.tf`
  files.

GitHub never returns a secret's value. A secret changed in GitHub shows as drift, through
its update time, and the next apply writes this repository's value back.

## Personal access tokens

The repositories' personal access tokens are regulad's, and regubot's for the winget jobs of
Koala and Warlock, each issued by hand in its account's settings and kept in
`tofu/github-user`'s `personal.sops.yaml` or `bot.sops.yaml`, their only copies, which
`prepare.sh` reads as `github_pats` and `bot_github_pats`; its README says how to rotate one.

Later, not yet: workflows move off personal access tokens, to GitHub's built-in tokens
(`GITHUB_TOKEN`, Dependabot's) wherever they suffice and to an App of each repository's own
otherwise.

## Credentials

In each workspace OpenTofu authenticates as its account's own GitHub App, owned by that
account and created by hand: `personal` as `regulad-homelab`, and `bot` as
`regubot-homelab`. Each App's repository
permissions are Secrets, Dependabot secrets, Environments and Administration at
Read and write, and Actions and Metadata at Read. Administration creates environments and
their deployment policies, and also covers every other repository setting, deleting a
repository included; Actions reads environments. Each is installed on all of its
account's repositories, including those created later: an App cannot change its own installation, so a narrower one would need a
hand-made change for each repository's first secret. Its ID and installation ID are in
`providers.tf`; its private key is in `provider.sops.env` as
`GITHUB_APP_<WORKSPACE>_PEM_FILE`, on one line with each newline written as `\n`.
`prepare.sh` exports the selected workspace's key as `GITHUB_APP_PEM_FILE`, the one the
provider reads, so it is sourced again after selecting another workspace; GitHub refuses
a key that is not its App's. Deleting the key, or the App, revokes it.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/github/prepare.sh       # exports backend credentials and the selected workspace's App key, decrypts inputs
tofu -chdir=tofu/github init -input=false -lockfile=readonly
tofu -chdir=tofu/github workspace select personal   # or bot
. tofu/github/prepare.sh       # again, for that workspace's App key
tofu -chdir=tofu/github validate
tofu -chdir=tofu/github plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed. It needs `sops`, `jq` and `git`, and refuses an
input left empty, which would blank a secret.

State and saved plans use enforced AES-GCM encryption, and hold every secret's value, as
the provider has no write-only argument. Never change or lose the passphrase. State is
remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under
`github/<workspace>/terraform.tfstate`, with S3-native locking.

## Not managed here

| What | Why, or who owns it |
|---|---|
| Repositories without secrets | Not defined in policy, as above |
| The repositories themselves, and their settings | Only their secrets are managed here |
| Each account's GitHub App and its installation | Created and installed by hand; an App cannot manage itself |
| Personal access tokens | Issued by hand; GitHub has no API for them |

Discovery output stays local in `docs/snapshot/github/`. Every mutation or state change
needs Parker's explicit approval.
