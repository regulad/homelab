# shellcheck shell=sh
# Prepare the calling shell to run OpenTofu in tofu/supabase: export the
# homelab-tofu scoped access token and the state backend's credentials, and
# decrypt the OpenTofu inputs, the state passphrase and the database password,
# into the gitignored secrets.auto.tfvars.json file.
#
# Source it from anywhere in the clone; do not execute it:
#
#   . tofu/supabase/prepare.sh
#
# The resource definitions are ordinary .tf files. This script only decrypts
# values; it never generates HCL, calls Supabase, imports state, or applies
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

_homelab_supabase_prepare() {
    # dash, bash, zsh and macOS sh all support local.
    # shellcheck disable=SC3043
    local root dir destination plaintext provider backend name value
    root=$(git rev-parse --show-toplevel) || return 1
    dir="$root/tofu/supabase"
    destination="$dir/secrets.auto.tfvars.json"
    if ! git -C "$dir" check-ignore -q -- "$destination"; then
        echo 'prepare.sh: decrypted inputs must be gitignored.' >&2
        return 1
    fi
    # Provider credentials: only the expected name, present. Values are never
    # printed.
    provider=$(_homelab_sops decrypt "$dir/provider.sops.env") || return 1
    name=$(printf '%s\n' "$provider" | grep -v -E '^[[:space:]]*(#|$)' |
        grep -v -E '^SUPABASE_ACCESS_TOKEN=' | head -n 1 | cut -d= -f1)
    if [ -n "$name" ]; then
        echo "prepare.sh: unexpected key in provider.sops.env: $name" >&2
        return 1
    fi
    if ! printf '%s\n' "$provider" | grep -q '^SUPABASE_ACCESS_TOKEN=.'; then
        echo 'prepare.sh: provider.sops.env is missing SUPABASE_ACCESS_TOKEN.' >&2
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
    plaintext=$(_homelab_sops decrypt --output-type json "$dir/secrets.sops.yaml") || return 1
    if ! printf '%s\n' "$plaintext" |
        jq -e '((.state_encryption_passphrase // "") != "") and ((.database_password // "") != "")' >/dev/null; then
        echo 'prepare.sh: unexpected supabase input file: expected state_encryption_passphrase and database_password inputs.' >&2
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
    value=$(printf '%s\n' "$provider" | sed -n 's/^SUPABASE_ACCESS_TOKEN=//p' | head -n 1)
    export "SUPABASE_ACCESS_TOKEN=$value"
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        value=$(printf '%s\n' "$backend" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    echo 'Loaded the homelab-tofu access token and state backend credentials for this shell. Decrypted inputs are ready.'
}

_homelab_supabase_prepare
_homelab_status=$?
unset -f _homelab_supabase_prepare _homelab_sops
# eval expands the status before unsetting it, so the subshell's exit status is
# the last one and becomes the status of sourcing this file.
eval "unset _homelab_status; (exit $_homelab_status)"
