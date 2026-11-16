# shellcheck shell=sh
# Prepare the calling shell to run OpenTofu in tofu/stripe: export the state
# backend's credentials, and decrypt the OpenTofu inputs, the state passphrase
# and each mode's restricted key, into the gitignored secrets.auto.tfvars.json
# file. The provider takes the selected workspace's key from those inputs.
#
# Source it from anywhere in the clone; do not execute it:
#
#   . tofu/stripe/prepare.sh
#
# The resource definitions are ordinary .tf files. This script only decrypts
# values; it never generates HCL, calls Stripe, selects a workspace, imports
# state, or applies infrastructure changes. It works in sh, bash and zsh, and
# reports failure through its exit status instead of exiting the shell.

_homelab_sops() {
    # sops looks in ~/.config only on Linux; use the same identity on macOS.
    if [ -z "${SOPS_AGE_KEY_FILE-}${SOPS_AGE_KEY-}${SOPS_AGE_KEY_CMD-}" ] &&
        [ -f "$HOME/.config/sops/age/keys.txt" ]; then
        SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops "$@"
    else
        sops "$@"
    fi
}

_homelab_stripe_prepare() {
    # dash, bash, zsh and macOS sh all support local.
    # shellcheck disable=SC3043
    local root dir destination plaintext backend name value workspace
    root=$(git rev-parse --show-toplevel) || return 1
    dir="$root/tofu/stripe"
    destination="$dir/secrets.auto.tfvars.json"
    if ! git -C "$dir" check-ignore -q -- "$destination"; then
        echo 'prepare.sh: decrypted inputs must be gitignored.' >&2
        return 1
    fi
    # The s3 backend reads these from the environment, so they never reach
    # .terraform/ or saved plans. Check every name before exporting any.
    backend=$(_homelab_sops decrypt "$root/tofu/shared/backend.sops.env") || return 1
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        if ! printf '%s\n' "$backend" | grep -q "^$name=."; then
            echo "prepare.sh: tofu/shared/backend.sops.env is missing $name." >&2
            return 1
        fi
    done
    # Inputs: the passphrase and both modes' keys, each present. Values are
    # never printed.
    plaintext=$(_homelab_sops decrypt --output-type json "$dir/secrets.sops.yaml") || return 1
    if ! printf '%s\n' "$plaintext" | jq -e '
        (keys == ["api_keys", "state_encryption_passphrase"])
        and ((.state_encryption_passphrase // "") != "")
        and ((.api_keys | keys) == ["live", "sandbox"])
        and all(.api_keys[]; . != "")' >/dev/null; then
        echo 'prepare.sh: secrets.sops.yaml must hold state_encryption_passphrase and api_keys.live and api_keys.sandbox, none empty.' >&2
        return 1
    fi
    if [ -e "$destination" ]; then
        # Compare data, not formatting. Preserve any differing local edits.
        if [ "$(jq -S -c . "$destination")" != "$(printf '%s\n' "$plaintext" | jq -S -c .)" ]; then
            echo 'prepare.sh: secrets.auto.tfvars.json has local edits. Preserve them before decrypting updated inputs.' >&2
            return 1
        fi
    else
        (umask 077 && printf '%s\n' "$plaintext" >"$destination") || return 1
    fi
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        value=$(printf '%s\n' "$backend" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    # The selected workspace decides which mode a plan touches; say which it is.
    workspace=default
    if [ -f "$dir/.terraform/environment" ]; then
        workspace=$(cat "$dir/.terraform/environment")
    fi
    echo "Loaded the state backend credentials for this shell. Decrypted inputs are ready. Selected workspace: $workspace."
}

_homelab_stripe_prepare
_homelab_status=$?
unset -f _homelab_stripe_prepare _homelab_sops
# eval expands the status before unsetting it, so the subshell's exit status is
# the last one and becomes the status of sourcing this file.
eval "unset _homelab_status; (exit $_homelab_status)"
