# sentry (Sentry)

The `.tf` files are the source of truth for the Sentry organization `regulad`: its team,
its projects with their client keys (DSNs), the projects' alerts, and their code mappings
with the GitHub repositories those link to. Its adoption is the
first, descriptive pass: it mirrors the live organization, so adopting it changes nothing.
Fixes follow as separate, reviewed changes.

| Location | Configuration |
|---|---|
| `team-regulad.tf` | The organization's one team, which holds every project |
| `project-<slug>.tf` | One file per project: the project, its client key, its alert with the default monitor the alert watches, and its code mapping, each where it has one |
| `integration-github.tf` | The GitHub integration `regulad`, read through a data source, and the repositories of it that the code mappings link to |
| `outputs.tf` | The `dsn` output: each project's DSN, from its Default key, by project slug |
| `locals.tf` | The organization's slug |
| `providers.tf`, `versions.tf` | Provider auth and pinned versions |
| `state.tf` | Enforced state encryption and its passphrase input |

A `-` inside a project's slug is written as `--` in its file name
(`project-pheidippides--notify.tf`); resource labels write it as `_`.

The provider is `jianyuan/sentry`, a community provider that Sentry sponsors; Sentry
publishes none of its own. OpenTofu's registry holds no signing key for it, so `tofu init`
skips its signature check; the lock file's checksums still pin the build.

## Projects

Each project declares its name, slug, team and platform, and its key only its name. Every
other setting is Sentry's default, the same across the projects, and is left undeclared:
digests, resolve age, inbound filters, client security, highlighted tags, which follow the
platform, and each key's JavaScript loader. A change to one of those shows in no plan.
The one exception is doppelganger's web-crawler inbound filter, which is declared on
the app's behalf, so that turning it off shows in a plan.

Every project has an alert, and every alert emails the issue's owners, falling back to the
project's active members. All but doppelganger's are Sentry's default for a new project;
doppelganger's, named `doppelganger-front`, fires at most once a day. Each alert watches its project's default issue-stream
monitor, read through the `sentry_project_issue_stream_monitor` data source. The
high-priority triggers have no native form in the provider, which passes them through as
`legacy_trigger_conditions`.

Never set a project's `default_key` to `false`. On creation, the provider then deletes
every key named `Default`, and every key here has that name.

## Code mappings

Every project has a code mapping, which links the project's stack frames to its source in
a GitHub repository of the integration `regulad`. Sentry generated doppelganger's,
peppercord's and picture-triangulator's. picture-triangulator's repository is archived on GitHub, and
Sentry lists it as disabled.

The three pheidippides projects are Android apps in the doppelganger repository, under
`pheidippides/`. Their frames carry a Java module rather than a path, which Sentry turns
into one by writing each `.` as `/`, so each mapping maps its app's package to the
package's directory under `app/src/main/java`.

rosellaview's frames carry the absolute path of the checkout that built the app, as its
build rewrites neither its source map nor its native debug files. It has a mapping per
checkout: GitHub's runner for store builds, and the vega distrobox for development builds.
Each checkout's `third_party/UxPlay/`, a submodule whose source GitHub keeps only in
`regulad/UxPlay`, has a mapping of its own to that repository's `rosella` branch, which
Sentry tries first as its stack root is longer. Its other submodules are upstream
repositories, beyond the GitHub integration, which reaches only regulad's own, so their
frames stay unlinked.

## DSNs

The `dsn` output gives each project's DSN, from its Default key, by project slug.
`ansible-generated` reads it as `sentry_dsns`, in its `group_vars/all.yml`, through the
`cloud.terraform.tf_output` lookup, on the operator's machine, so a run that renders one
needs this root's `prepare.sh` sourced. It delivers:

| Project | To |
|---|---|
| `peppercord` | `PEPPERCORD_SENTRY_DSN` in each PepperCord mirror's `.env` |
| `doppelganger` | `NEXT_PUBLIC_SENTRY_DSN` in doppelgangerhq.com's `web.env` |

A key replaced here reaches them at the next `site.yml` run on those hosts.

## Credentials

OpenTofu authenticates as `homelab-tofu`, an internal integration in `regulad`, created
under Settings → Custom Integrations. Its token belongs to the organization rather than to a
user, reaches `regulad` alone, and cannot manage members. It holds these permissions:
Project and Team at Admin, Alerts at Read & Write, and Organization at Read; deleting a key
or a project needs Project at Admin. The token is in `provider.sops.env`, which `prepare.sh` exports as `SENTRY_AUTH_TOKEN`. Deleting the token,
or the integration, revokes it. The same file keeps the integration's client secret,
`SENTRY_CLIENT_SECRET`, which signs the webhooks Sentry sends; nothing uses it yet, and
`prepare.sh` never exports it.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/sentry/prepare.sh       # exports the token and backend credentials, decrypts inputs
tofu -chdir=tofu/sentry init -input=false -lockfile=readonly
tofu -chdir=tofu/sentry validate
tofu -chdir=tofu/sentry plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs
`tofu`. It needs `sops`, `jq` and `git`. It decrypts `secrets.sops.yaml` into the ignored
`secrets.auto.tfvars.json`, which holds the state passphrase.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`sentry/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports.

## Adoption

The team, the eight projects, their keys and the four alerts were imported into the remote
state, and the import blocks were removed after the adoption apply. Its one live change put
doppelganger and the three pheidippides projects, which had no team, in `regulad`, as the
provider requires a team on every project. The four code mappings and their repositories
were later imported the same way, changing nothing. matrix-synapse, which took upstream
Synapse's errors, was then deleted, as the organization keeps only its own projects. A
plan is now a no-op. Every adopted resource carries `prevent_destroy = true`.

## Not managed here

| What | Why, or who owns it |
|---|---|
| The organization `nefum` | Retired, and queued for deletion |
| The `homelab-tofu` integration and its token | This root's own credential, kept in `provider.sops.env` |
| Other custom integrations, such as Vercel's | The provider has no resource for custom integrations, as the FIXME in `versions.tf` says; it only reads an installation, through `sentry_app_installation` |
| "Send a notification when pull requests are ready" | Sentry's default Seer alert; the provider cannot express its `seer_activity_trigger` |
| Dashboards | All 20 are Sentry's prebuilt dashboards |
| The uptime monitor Sentry detected for `https://doppelgangerhq.com`, disabled | The provider requires an environment, which the monitor lacks, so adopting it would change it, and its update turns a detected monitor into a manual one |
| The organization's settings, such as requiring two-factor authentication | The provider's `sentry_organization` holds only an organization's name and slug, as the FIXME in `versions.tf` says |
| Data scrubbing, the organization's and each project's, IP addresses among it | The pinned provider has no resource for it; upstream support awaits a release, as the FIXME in `versions.tf` says |
| The GitHub integration, and its repositories no code mapping links to | Installed through GitHub; the integration is only read here |
| Members | Beyond an internal integration's permissions |

Discovery output stays local in `docs/snapshot/sentry/`. Every mutation or state change
needs Parker's explicit approval.
