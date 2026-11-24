# github-user (GitHub, the accounts)

This root manages the GitHub accounts themselves, regulad's and regubot's, each in a
workspace of its own, signing in with the account's own classic personal access token: what
only a token of the account can do, such as its keys and the repositories it creates or
forks. [`tofu/github`](../github/README.md) sets the accounts' repositories'
secrets, through their Apps.

| Location | Configuration |
|---|---|
| `public-key-<name>.tf` | An SSH authentication key, by its name: `public-key-id_rsa3072.tf`, regulad's, `tofu/shared`'s `regulad_ssh_public_key` |
| `ssh-signing-key-<name>.tf` | An SSH signing key, by its name: `ssh-signing-key-id_rsa3072.tf`, the same key; and regubot's for regulad/jobs's Jenkins jobs, `ssh-signing-key-jenkins--winget.tf` |
| `gpg-key-<name>.tf` | A GPG key, by its name, `x` and its key ID: `gpg-key-x081BE541EA23ACF3.tf`, regulad's |
| `repo-<name>.tf` | One file per repository the account creates or forks: `repo-winget--pkgs.tf`, regubot's fork of `microsoft/winget-pkgs`, and `repo-regubot.tf`, its profile repository and `README.md` |
| `files/regubot/README.md` | The profile README, byte for byte |
| `files/gpg-key-<name>.asc` | A GPG key's armored public key, as GitHub holds it |
| `providers.tf` | Each workspace's account, the provider, and the check of the account the token signs in as |
| `locals.tf` | Whether the selected workspace manages regulad's account or regubot's, and `tofu/shared` |
| `personal.sops.yaml`, `bot.sops.yaml` | Each account's personal access tokens, by their names on GitHub |
| `secrets.sops.yaml` | The state passphrase |
| `variables.tf` | The state passphrase input |
| `versions.tf` | Pinned versions: the provider at a build from the provider mirror, with `github_user_ssh_signing_key` and import for `github_user_gpg_key` |
| `tofu.rc` | The CLI configuration `prepare.sh` selects, which installs that build from the mirror |
| `state.tf` | Enforced state encryption and its passphrase input |

## Workspaces

Each account has a state of its own, in an OpenTofu workspace: `personal` for regulad's, and
`bot` for regubot's. Each signs in with its own account's token, and a postcondition on
`data.github_user.self` fails the plan unless the token is that account's. A file enables its
blocks only in its account's workspace (`local.personal`, `local.bot`). The `default` workspace has no
account, and `validate` and `plan` fail there.

The selected workspace lives in `.terraform/environment`, and nothing in a `plan` or `apply`
command shows it: check it with `tofu -chdir=tofu/github-user workspace show` before each,
and `prepare.sh` names it. alock locks and records the root as a single target, so the two
workspaces never apply at once, and its record of the last applied commit covers both. A
saved plan is named for its workspace, `docs/snapshot/github-user.<workspace>@<commit>.tfplan`.

State sits at `github-user/<workspace>/terraform.tfstate` in the state bucket.

## regubot

regubot is Parker's GitHub machine account, made to submit winget manifests to
`microsoft/winget-pkgs`. It is operated only by deterministic pipelines, never by an LLM
directly. Its address, `bot@regulad.net`, is a mailbox on mail: the FreeIPA account
`regubot` in wako's `freeipa_users_public`, read by logging in to mail as
`regubot@regulad.xyz` with the password in wako's `secrets.sops.yml`. Parker created the
account, with that address as its email, and confirmed it from the mailbox.

Koala and Warlock submit with Komac, which commits to the fork through GitHub's API
(`createCommitOnBranch`); GitHub signs those commits itself, so their pipelines hold only
regubot's token. regulad/jobs's Jenkins jobs commit with git, and sign with an Ed25519 key of
their own, which this root lists as one of regubot's signing keys. Its private half lives in
regulad/jobs, as its `winget.sops.yaml`, encrypted to Parker's age key and to an age key made
for that repository alone, whose identity Jenkins's `host_vars` hold and Ansible delivers.

## Personal access tokens

GitHub has no API that issues a personal access token, and no App-issued token can fill a
repository's secret, as those last an hour. So each token is issued by hand in its
account's settings, under its name there, `terraform-<word>--<word>`, with the narrowest
access that serves it, and kept in that account's file's `github_pats`, named for its
workspace, so the same name means the same use in each. The comment above each gives its
type, its repository access and its permissions.

`terraform-github--user`, in each file, is that account's token for this root: a classic
token with `public_repo`, `delete_repo`, `admin:public_key`, `admin:gpg_key` and
`admin:ssh_signing_key`. Classic, as no App can fork a repository into the account, and a
fine-grained token would need Administration write for the provider's update after a fork,
which deletes repositories as well. It deletes them too, with `delete_repo`: an apply that
destroys or replaces a repository deletes it.

regulad's other tokens are read from `personal.sops.yaml`, their only copy, by:

- `tofu/github`, for repositories' Actions and Dependabot secrets, through its
  `prepare.sh`;
- `tofu/vercel`, for projects' environment variables, through its `prepare.sh`;
- `ansible-generated`, for ghcr.io logins: Nexus's `ghcr-io` proxy
  (`group_vars/nexus_servers.yml`), and the `registry_auth` logins of mail, pihole2 and
  doppelgangerhq.com (their `host_vars`).

regubot's other tokens, one per pipeline that submits to winget-pkgs, are read from
`bot.sops.yaml`, their only copy, by `tofu/github`, for Koala's and Warlock's `release`
environments, and by `ansible-generated`, for Jenkins's `winget-token` credential
(`site.yml --tags host_files --limit jenkins.regulad.internal`).

To rotate one, issue a new token under the same name, put it in its account's file with
`sops edit`, and deliver it as its users say: an apply here, or of `tofu/github` or
`tofu/vercel`; for Nexus, `maintenance.yml --tags nexus-proxy-logins` from
`ansible-generated/`, since Nexus never returns a stored password; for a host,
`site.yml --tags registry_auth --limit <host>`. Then delete the old token in GitHub.

## Credentials

`prepare.sh` exports the selected workspace's `terraform-github--user` as `GITHUB_TOKEN`,
which the provider reads; source it again after selecting another workspace. Without a
token, the provider signs in with the GitHub CLI's, regulad's own, and for a user owner it
acts as whichever account signs in: the postcondition refuses any account but the
workspace's. In the shell that sourced `prepare.sh`, `gh` also acts as that account, as it
prefers `GITHUB_TOKEN` to its own login.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/github-user/prepare.sh       # selects tofu.rc, exports backend credentials and the selected workspace's token, decrypts inputs
tofu -chdir=tofu/github-user init -input=false -lockfile=readonly
tofu -chdir=tofu/github-user workspace select personal   # or bot
. tofu/github-user/prepare.sh       # again, for that workspace's token
tofu -chdir=tofu/github-user validate
tofu -chdir=tofu/github-user plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed. It needs `sops`, `jq` and `git`, and refuses an
empty token.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.

## Not managed here

| What | Why, or who owns it |
|---|---|
| The accounts, their emails and their tokens | Made by hand; GitHub has no API for them |
| The repositories' secrets and environments | `tofu/github`, through each account's App |
| regubot's mailbox | wako's FreeIPA accounts, through `ansible-generated` |

Every mutation or state change needs Parker's explicit approval.
