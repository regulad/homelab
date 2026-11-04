# aws (Amazon Web Services)

The `.tf` files are the source of truth for the AWS account's IAM users and roles that the
homelab keeps, the home-assistant Lambda, and this root's own access. This is the first,
descriptive pass: it mirrors the live account. Every resource was imported, and the import
blocks were removed after the adoption apply; a plan is now a no-op. Every adopted resource
carries `prevent_destroy = true`. Fixes follow as separate, reviewed changes.

| Location | Configuration |
|---|---|
| `user-HomeAssistant.tf` | The IAM user Home Assistant's AWS integrations sign in as, with its managed policies and access key |
| `user-ASK--CLI.tf` | The IAM user, group and policy the Alexa Skills Kit CLI deploys as, with its access key |
| `lambda-home--assistant.tf` | The Lambda behind Home Assistant's Alexa Smart Home skill: its role, log group, function and Alexa trigger |
| `lambda/home-assistant/lambda_function.py` | That Lambda's code, Home Assistant's published one byte for byte as deployed, zipped by the `archive` provider at plan time |
| `rolesanywhere.tf` | The trust anchor, profile and role `homelab-tofu` that this root signs in through |
| `providers.tf`, `versions.tf` | Provider settings and pinned versions |
| `variables.tf` | The session credentials, ephemeral inputs from `prepare.sh` |
| `state.tf` | Enforced state encryption and its passphrase input |
| `rolesanywhere-ca.crt`, `rolesanywhere-tofu.crt` | The trust anchor's CA and OpenTofu's certificate, both public |
| `tools/go.mod`, `tools/go.sum` | The pinned IAM Roles Anywhere credential helper, run through `go tool` |

## Credentials

No access key exists. OpenTofu works as the IAM role `homelab-tofu`, through IAM Roles
Anywhere:

- `rolesanywhere-tofu.crt` (EC P-256, valid until 2036-11-01) is the only certificate
  `rolesanywhere-ca.crt` has issued or can issue: the CA's key was discarded after signing it.
  That CA is the trust anchor's.
- The certificate's private key is in `provider.sops.yaml` as encrypted PKCS#8, with its
  password. The trust anchor's, profile's and role's ARNs are plaintext in `prepare.sh`, which
  needs them before OpenTofu can read its state.
- Sourcing `prepare.sh` runs the credential helper's `credential-process`, which signs
  `CreateSession` on Roles Anywhere's dual-stack endpoint in the trust anchor's region. The
  temporary credentials it returns last an hour; source `prepare.sh` again to renew them.
- The helper reads its key only from a file, which it opens several times, so a pipe cannot
  feed it ([upstream #187](https://github.com/aws/rolesanywhere-credential-helper/issues/187)).
  `prepare.sh` writes the encrypted key to a temporary file, under `$XDG_RUNTIME_DIR` where it
  is set, and removes it once the helper exits. The password is on the helper's command line
  while it runs.
- `tools/go.mod` pins the helper, a Go module, with its dependencies' hashes in `go.sum`.
  `go tool` builds it with the installed Go, as `GOTOOLCHAIN=local` forbids downloading a
  toolchain; it uses cgo, so a C compiler must be present too. To move to a newer release, run
  `go -C tofu/aws/tools get -tool github.com/aws/rolesanywhere-credential-helper@<version>`.

The role has `AdministratorAccess`: this root manages IAM itself, so a narrower role would
contain nothing. Its trust policy admits `rolesanywhere.amazonaws.com` only for the trust anchor
(`aws:SourceArn`), which AWS recommends against the confused deputy. A condition on the
certificate's subject would add nothing, since the CA can issue no other certificate.
Disabling the trust anchor or the profile revokes access.

The environment's `AWS_*` variables belong to the state backend, which reaches OCI's S3
Compatibility API. So the provider takes its credentials as arguments, which take precedence
over them, and names S3's endpoint itself, which the backend's `AWS_ENDPOINT_URL_S3` would
otherwise replace. For the same reason, the `aws` CLI in a shell that sourced `prepare.sh`
talks to OCI with the backend's key, not to AWS.

The provider uses AWS's dual-stack endpoints (`use_dualstack_endpoint`); only those, under
`api.aws`, have IPv6 addresses.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/aws/prepare.sh       # obtains session credentials, exports backend credentials, decrypts inputs
tofu -chdir=tofu/aws init -input=false -lockfile=readonly
tofu -chdir=tofu/aws validate
tofu -chdir=tofu/aws plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs `tofu`.
It needs `sops`, `jq`, `git`, Go 1.26.6 or later and a C compiler. It decrypts
`secrets.sops.yaml` into the ignored `secrets.auto.tfvars.json`, which holds the state
passphrase and the home-assistant Lambda's `BASE_URL`.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
State is remote, in the `homelab-tofu-state` bucket that `tofu/oracle` manages, under the key
`aws/terraform.tfstate`, with S3-native locking. The backend's credentials come from
`tofu/shared/backend.sops.env`, which `prepare.sh` exports.

## Not managed here

OpenTofu manages only what it declares, so these need no configuration to be left alone.

| What | Why, or who owns it |
|---|---|
| Service-linked roles (`aws-service-role/` path) | The AWS service each belongs to creates and deletes it |
| The root user | Console only, with MFA and no access keys |
| Access key secrets | Kept by the programs that use them, never in state |

Discovery output stays local in `docs/snapshot/aws/`. Every mutation or state change needs
Parker's explicit approval.
