# stripe (Stripe)

The `.tf` files are the source of truth for the Stripe account regulad.xyz, in both of
its modes: its sandbox mirrors live. The account holds nothing yet, so the root declares
no resources; they start here as they are needed.

| Location | Configuration |
|---|---|
| `providers.tf`, `versions.tf` | Provider auth, by workspace, and pinned versions |
| `variables.tf` | Each mode's restricted key |
| `state.tf` | Enforced state encryption and its passphrase input |

The provider is Stripe's own, `stripe/stripe`. Its repository carries no licence file, so
OpenTofu's registry shows no docs for it; they are at docs.stripe.com/terraform and in the
provider's repository.

## Workspaces

One configuration serves both modes, each with its own state in an OpenTofu workspace:
`sandbox` and `live`. The `sandbox` workspace is precisely what Stripe calls the account's
**Test mode**, whose keys start `rk_test_`, `sk_test_` and `pk_test_`. It is not one of the
environments the Dashboard lists under Sandboxes. `live` is the account's live mode. The provider takes the selected workspace's key, so a key never
meets the other mode's state; the `default` workspace has no key, so a plan there fails
once the root declares anything for the provider to read. Every change goes to `sandbox` first and then to `live`, each from a plan saved at
the same commit and named for its workspace, `docs/snapshot/stripe.<workspace>@<commit>.tfplan`.

The selected workspace lives in `.terraform/environment`, and nothing in a `plan` or
`apply` command shows it: check it with `tofu -chdir=tofu/stripe workspace show` before
each, and `prepare.sh` prints it. alock locks and records the root as a single target, so
the two workspaces never apply at once, and its record of the last applied commit covers
both.

State sits at `stripe/<workspace>/terraform.tfstate` in the state bucket.

## Credentials

OpenTofu authenticates with `homelab-tofu`, a restricted key in each mode, created under
Developers → API keys. Each has Write on every permission, as the root may manage anything
the provider can. Being its own key, it can be revoked without touching the keys apps use.
Both keys are in `secrets.sops.yaml`, as `api_keys.live` (`rk_live_…`) and
`api_keys.sandbox` (`rk_test_…`); a validation refuses them swapped.

Stripe allows 25 read requests a second in a sandbox and 100 in live mode. Its docs advise
`-parallelism` between 2 and 5 once the root holds many resources.

## Running it

From the repository root, in bash or zsh on Linux or macOS:

```bash
. tofu/stripe/prepare.sh       # exports backend credentials, decrypts inputs, prints the workspace
tofu -chdir=tofu/stripe init -input=false -lockfile=readonly
tofu -chdir=tofu/stripe workspace select sandbox   # or live
tofu -chdir=tofu/stripe validate
tofu -chdir=tofu/stripe plan -input=false -detailed-exitcode
```

`prepare.sh` must be sourced, not executed, so its exports reach the shell that runs
`tofu`. It needs `sops`, `jq` and `git`. It decrypts `secrets.sops.yaml` into the ignored
`secrets.auto.tfvars.json`, which holds the state passphrase and both keys.

State and saved plans use enforced AES-GCM encryption. Never change or lose the passphrase.
The backend's credentials come from `tofu/shared/backend.sops.env`, which `prepare.sh`
exports.

Every mutation or state change needs Parker's explicit approval.
