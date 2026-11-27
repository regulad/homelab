# shellcheck shell=sh
# Prepare the calling shell to run OpenTofu in tofu/ga4: select the committed
# tofu.rc, export tofu-analytics's private key as TF_VAR_private_key and the
# state backend's credentials, and decrypt the OpenTofu inputs, this root's
# state passphrase and tofu/gcp's, into the gitignored secrets.auto.tfvars.json
# file.
#
# Source it from anywhere in the clone; do not execute it:
#
#   . tofu/ga4/prepare.sh
#
# The resource definitions are ordinary .tf files. This script only decrypts
# values; it never generates HCL, calls Google Analytics, imports state, or
# applies infrastructure changes. The credentials stay in the environment, never
# on disk: providers.tf assembles the key file from the private key and
# tofu/gcp's tofu_analytics output. It works in sh, bash and zsh, and reports
# failure through its exit status instead of exiting the shell.

_homelab_sops() {
    # sops looks in ~/.config only on Linux; use the same identity on macOS.
    if [ -z "${SOPS_AGE_KEY_FILE-}${SOPS_AGE_KEY-}${SOPS_AGE_KEY_CMD-}" ] &&
        [ -f "$HOME/.config/sops/age/keys.txt" ]; then
        SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops "$@"
    else
        sops "$@"
    fi
}

_homelab_ga4_prepare() {
    # dash, bash, zsh and macOS sh all support local.
    # shellcheck disable=SC3043
    local root dir destination plaintext gcp provider backend name value
    root=$(git rev-parse --show-toplevel) || return 1
    dir="$root/tofu/ga4"
    destination="$dir/secrets.auto.tfvars.json"
    if ! git -C "$dir" check-ignore -q -- "$destination"; then
        echo 'prepare.sh: decrypted inputs must be gitignored.' >&2
        return 1
    fi
    # Provider credentials: exactly the expected key, present. Its value is
    # never printed.
    provider=$(_homelab_sops decrypt --output-type json "$dir/provider.sops.yaml") || return 1
    if ! printf '%s\n' "$provider" |
        jq -e 'keys == ["private_key"] and all(.[]; . != "")' >/dev/null; then
        echo 'prepare.sh: provider.sops.yaml must hold exactly private_key.' >&2
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
        jq -e '(keys == ["state_encryption_passphrase"]) and (.state_encryption_passphrase != "")' >/dev/null; then
        echo 'prepare.sh: unexpected ga4 input file: expected only the state_encryption_passphrase input.' >&2
        return 1
    fi
    # tofu/gcp's state passphrase, which gcp.tf needs to read its outputs, joins
    # the inputs from tofu/gcp's own encrypted file, its only copy. Both pass
    # through pipes, never a command line.
    gcp=$(_homelab_sops decrypt --extract '["state_encryption_passphrase"]' "$root/tofu/gcp/secrets.sops.yaml") || return 1
    if [ -z "$gcp" ]; then
        echo 'prepare.sh: tofu/gcp/secrets.sops.yaml has no state_encryption_passphrase.' >&2
        return 1
    fi
    plaintext=$({
        printf '%s\n' "$plaintext"
        printf '%s' "$gcp" | jq -R -s '{gcp_state_encryption_passphrase: .}'
    } | jq -s add) || return 1
    if [ -e "$destination" ]; then
        # Compare data, not formatting. Preserve any differing local edits.
        if [ "$(jq -S -c . "$destination")" != "$(printf '%s\n' "$plaintext" | jq -S -c .)" ]; then
            echo 'prepare.sh: secrets.auto.tfvars.json has local edits. Preserve them before decrypting updated inputs.' >&2
            return 1
        fi
    else
        (umask 077 && printf '%s\n' "$plaintext" >"$destination") || return 1
    fi
    value=$(printf '%s\n' "$provider" | jq -r .private_key) || return 1
    export "TF_VAR_private_key=$value"
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        value=$(printf '%s\n' "$backend" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    export TF_CLI_CONFIG_FILE="$dir/tofu.rc"
    echo "Loaded tofu-analytics's private key and the state backend credentials and selected tofu.rc for this shell. Decrypted inputs are ready."
}

_homelab_ga4_prepare
_homelab_status=$?
unset -f _homelab_ga4_prepare _homelab_sops
# eval expands the status before unsetting it, so the subshell's exit status is
# the last one and becomes the status of sourcing this file.
eval "unset _homelab_status; (exit $_homelab_status)"
