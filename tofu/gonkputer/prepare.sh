# shellcheck shell=sh
# Prepare the calling shell to run OpenTofu in tofu/gonkputer: select the
# committed tofu.rc, export the Proxmox endpoint and API token and the state
# backend's credentials, make applies serial (TF_CLI_ARGS_apply), and decrypt
# the OpenTofu inputs into the gitignored secrets.auto.tfvars.json file.
#
# Source it from anywhere in the clone; do not execute it:
#
#   . tofu/gonkputer/prepare.sh
#
# The resource definitions are ordinary .tf files. This script only decrypts
# values; it never generates HCL, calls Proxmox, imports state, or applies
# infrastructure changes. The credentials stay in the environment, never on disk.
# It works in sh, bash and zsh, and reports failure through its exit status
# instead of exiting the shell.

_homelab_sops() {
    # sops looks in ~/.config only on Linux; use the same identity on macOS.
    if [ -z "${SOPS_AGE_KEY_FILE-}${SOPS_AGE_KEY-}${SOPS_AGE_KEY_CMD-}" ] &&
        [ -f "$HOME/.config/sops/age/keys.txt" ]; then
        SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops "$@"
    else
        sops "$@"
    fi
}

_homelab_gonkputer_prepare() {
    # dash, bash, zsh and macOS sh all support local.
    # shellcheck disable=SC3043
    local root dir destination plaintext provider backend name value
    root=$(git rev-parse --show-toplevel) || return 1
    dir="$root/tofu/gonkputer"
    destination="$dir/secrets.auto.tfvars.json"
    if ! git -C "$dir" check-ignore -q -- "$destination"; then
        echo 'prepare.sh: decrypted inputs must be gitignored.' >&2
        return 1
    fi
    # Provider credentials: only the expected names, each present. Values are
    # never printed.
    provider=$(_homelab_sops decrypt "$dir/provider.sops.env") || return 1
    name=$(printf '%s\n' "$provider" | grep -v -E '^[[:space:]]*(#|$)' |
        grep -v -E '^(PROXMOX_VE_ENDPOINT|PROXMOX_VE_API_TOKEN)=' | head -n 1 | cut -d= -f1)
    if [ -n "$name" ]; then
        echo "prepare.sh: unexpected key in provider.sops.env: $name" >&2
        return 1
    fi
    for name in PROXMOX_VE_ENDPOINT PROXMOX_VE_API_TOKEN; do
        if ! printf '%s\n' "$provider" | grep -q "^$name=."; then
            echo "prepare.sh: provider.sops.env is missing $name." >&2
            return 1
        fi
    done
    # The s3 backend reads these from the environment, so they never reach
    # .terraform/ or saved plans. Check every name before exporting any.
    backend=$(_homelab_sops decrypt "$root/tofu/shared/backend.sops.env") || return 1
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        if ! printf '%s\n' "$backend" | grep -q "^$name=."; then
            echo "prepare.sh: tofu/shared/backend.sops.env is missing $name." >&2
            return 1
        fi
    done
    plaintext=$(_homelab_sops decrypt "$dir/secrets.sops.json") || return 1
    if ! printf '%s\n' "$plaintext" |
        jq -e '(.state_encryption_passphrase // "") != ""' >/dev/null; then
        echo 'prepare.sh: unexpected gonkputer input file: expected a state_encryption_passphrase input.' >&2
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
    for name in PROXMOX_VE_ENDPOINT PROXMOX_VE_API_TOKEN; do
        value=$(printf '%s\n' "$provider" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        value=$(printf '%s\n' "$backend" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    export TF_CLI_CONFIG_FILE="$dir/tofu.rc"
    # Snippet uploads open their own SSH connections as root through the
    # operator's agent. Bitwarden's SSH agent refuses or drops signing requests
    # that arrive in parallel, so applies run one operation at a time and each
    # prompt can be approved. Plans only read through the API and stay parallel.
    export TF_CLI_ARGS_apply="-parallelism=1"
    echo 'Loaded the Proxmox and state backend credentials, selected tofu.rc, and made applies serial for this shell. Decrypted inputs are ready.'
}

_homelab_gonkputer_prepare
_homelab_status=$?
unset -f _homelab_gonkputer_prepare _homelab_sops
# eval expands the status before unsetting it, so the subshell's exit status is
# the last one and becomes the status of sourcing this file.
eval "unset _homelab_status; (exit $_homelab_status)"
