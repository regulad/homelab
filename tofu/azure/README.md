# azure (Microsoft Azure and Entra ID)

The `.tf` files are the source of truth for the directory `Default Directory` and its one
subscription, `Pay-As-You-Go`: the directory's applications with their service principals, and
the subscription's role assignments. The subscription holds no resources.

| Location | Configuration |
|---|---|
| `homelab-tofu.tf` | The application this root signs in as, its service principal, and its Owner grant |
| `rclone.tf` | `regulad rclone`, the application rclone signs in to OneDrive with, and its service principal |
| `subscription.tf` | The subscription, and Parker's Owner grant on it |
| `graph.tf` | Microsoft Graph's permission IDs, looked up by name |
| `locals.tf` | The tenant, subscription and `homelab-tofu` client IDs |
| `providers.tf`, `versions.tf` | Provider settings and pinned versions |
| `state.tf` | Enforced state encryption and its passphrase input |

## Credentials

OpenTofu signs in as the application `homelab-tofu` with a certificate whose private key Entra
ID never had:

- `service-principal-tofu.crt` (RSA 2048, valid until 2036-11-02) is the application's one
  credential. Its private key is in `provider.sops.yaml`.
- Sourcing `prepare.sh` builds the PKCS#12 bundle the providers read, in memory, and exports it
  as `ARM_CLIENT_CERTIFICATE`, with no password: the bundle lives only in the environment, where
  its password would sit beside it.
- The credential itself ends on 2027-11-05, a year after it was added: the Azure CLI's
  `credential reset` defaults to one year, whatever the certificate's validity. Extend it when
  it is needed, in Cloud Shell, with
  `az ad app credential reset --id 76130b9f-7f01-4953-bc94-6032540a2c0a --cert @service-principal-tofu.crt --append --end-date <date>`.

The service principal has Owner on the subscription, as this root manages its role
assignments, and Microsoft Graph's Directory.Read.All and Application.ReadWrite.All. Consent to
its Graph permissions is granted by hand, in the portal under the application's API
permissions: managing it from here would need AppRoleAssignment.ReadWrite.All, with which an
application can consent itself to any permission. Deleting the certificate from the
application revokes it.

The application, its credential and its first grants were made by hand to bootstrap this root,
in Cloud Shell: `az ad app create`, `az ad sp create`, `az ad app credential reset --cert` and
`az role assignment create`. Cloud Shell cannot grant admin consent, so that is the portal's.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/azure/prepare.sh            # exports the certificate bundle and backend credentials, decrypts inputs
tofu -chdir=tofu/azure init -input=false -lockfile=readonly
tofu -chdir=tofu/azure validate
tofu -chdir=tofu/azure plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs `tofu`.
It needs `sops`, `jq`, `openssl` and `git`. It decrypts `secrets.sops.yaml` into the ignored
`secrets.auto.tfvars.json`, which holds the state passphrase.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`azure/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports.

## Not managed here

| What | Why, or who owns it |
|---|---|
| `homelab-tofu`'s certificate credential | This root's own credential, created by hand, so that no apply can revoke the access it runs with |
| `regulad rclone`'s client secret | The provider cannot import a secret; it is in rclone's configuration, and ends 2028-02-06 |
| Consent to the applications' permissions | `homelab-tofu`'s by hand in the portal (see Credentials); `regulad rclone`'s given at each sign-in |
| The `sys.mfa-write`, `sys.mfa-delete` and `sys.blockwesteurope` policy assignments | Microsoft's, at the tenant root management group |
| The subscription, the directory and its user | Billing and identity, outside what this root needs to describe |
| Resource provider registrations | The provider registers none; the 18 registered were registered by the portal and Cloud Shell |

Discovery output stays local in `docs/snapshot/azure/`. Every mutation or state change needs
Parker's explicit approval.
