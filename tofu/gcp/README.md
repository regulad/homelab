# gcp (Google Cloud)

The `.tf` files are to be the source of truth for Google Cloud: every project of Parker's, in
this one root and state. There is no organization, so the projects stand side by side, and
each grants `homelab-tofu` Owner in its own IAM policy. This is the first, descriptive pass: it
mirrors the five projects Parker keeps. Every resource was imported, and the import blocks were
removed after the adoption apply, which changed nothing live; a plan is now a no-op. Every
adopted resource carries `prevent_destroy = true`. Fixes follow as separate, reviewed changes.

| Location | Configuration |
|---|---|
| `project-<id>.tf` | One file per project: the project, the APIs it has enabled, and its service accounts and reCAPTCHA keys |
| `homelab-tofu.tf` | The service account this root works as, and its Owner grant on every project |
| `outputs.tf` | The `oauth_client_ids` output: every project's OAuth client IDs, which each project's file lists, by project ID, then by slug |
| `providers.tf`, `versions.tf` | Provider settings and pinned versions |
| `state.tf` | Enforced state encryption and its passphrase input |
| `service-account-tofu.crt` | The certificate of the service account's key, public |

## Credentials

OpenTofu works as the service account `homelab-tofu` in its home project, `regulad`, with a
key whose private half Google never had:

- `service-account-tofu.crt` (RSA 2048, valid until 2036-11-01) was uploaded to the account,
  as Google's "upload a public key" procedure describes.
- Its private key is in `provider.sops.yaml`. The home project and the key's ID, which Google
  assigned at the upload, are plaintext in `prepare.sh`.
- Sourcing `prepare.sh` assembles the key file Google would otherwise hand out, in memory, and
  exports it as `GOOGLE_CREDENTIALS`, with the home project as `GOOGLE_PROJECT`, the provider's
  default. Every resource still names its own project.

The account has `roles/owner` on every project: this root manages IAM itself, so a narrower
role would contain nothing. The APIs it calls through the home project, such as Cloud Resource
Manager and IAM, are enabled there. Deleting the key from the account revokes it.

The account and its grants were made by hand to bootstrap this root, in Cloud Shell:
`gcloud iam service-accounts create`, `gcloud projects add-iam-policy-binding` for each
project, and `gcloud iam service-accounts keys upload` of the certificate. A new project needs
its own grant before this root can reach it.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/gcp/prepare.sh       # exports the service account key and backend credentials, decrypts inputs
tofu -chdir=tofu/gcp init -input=false -lockfile=readonly
tofu -chdir=tofu/gcp validate
tofu -chdir=tofu/gcp plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs `tofu`.
It needs `sops`, `jq` and `git`. It decrypts `secrets.sops.yaml` into the ignored
`secrets.auto.tfvars.json`, which holds the state passphrase.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`gcp/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports.

## Not managed here

OpenTofu manages only what it declares, so these need no configuration to be left alone.

| What | Why, or who owns it |
|---|---|
| OAuth 2.0 clients and the consent screen | No public API creates, lists or updates them, so the provider has no resource for them: IAP's OAuth Admin API, which only ever handled clients of internal brands, was shut down on 2026-03-19, and provider 8.0.0 removed `google_iap_brand` and `google_iap_client`. `google_iam_oauth_client` is Workforce Identity Federation's, not a sign-in client. The console's Google Auth Platform pages are their only home. Their IDs, which are public, are still this root's to give: each project's file lists its clients' IDs in a `locals` map, and `oauth_client_ids` exports them to every root and host that names one, such as `tofu/supabase`, so no client ID is written anywhere else. An ID begins with its project's number, which the output checks |
| Service account keys | The provider cannot import them; Google keeps the secrets of its own keys |
| Google's service accounts and agents, such as Compute Engine's default account and Firebase's `firebase-adminsdk-*` | The services that create them |
| `home-assistant-311214`'s Firebase project, apps and browser key, and its `firebase=enabled` label | Firebase |
| Each project's `_Default` and `_Required` log buckets and sinks | Cloud Logging creates them with every project |
| `regulad`'s default VPC, its subnets, routes and firewall rules | Compute Engine creates it with the project |
| The billing account itself | Parker's Google account; only `regulad`'s link to it is here |

Discovery output stays local in `docs/snapshot/gcp/`. Every mutation or state change needs
Parker's explicit approval.
