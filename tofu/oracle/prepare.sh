# shellcheck shell=sh
# Decrypt OCI input values into the gitignored secrets.auto.tfvars.json file, and
# export the OCI API key and the state backend's credentials and endpoint into
# the calling shell.
# It also puts ansible-generated/bin on PATH, where the inventory plugin finds
# bin/tofu-oracle.
#
# Source it from anywhere in the clone; do not execute it:
#
#   . tofu/oracle/prepare.sh
#
# The resource definitions are ordinary .tf files. This script only decrypts
# values; it never generates HCL, calls OCI, imports state, or applies
# infrastructure changes. Sourcing runs it in the caller's shell, so the variables
# it exports persist for later tofu commands there. It works in sh, bash and zsh,
# and reports failure through its exit status instead of exiting the shell.

_homelab_sops() {
    # sops looks in ~/.config only on Linux; use the same identity on macOS.
    if [ -z "${SOPS_AGE_KEY_FILE-}${SOPS_AGE_KEY-}${SOPS_AGE_KEY_CMD-}" ] &&
        [ -f "$HOME/.config/sops/age/keys.txt" ]; then
        SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops "$@"
    else
        sops "$@"
    fi
}

_homelab_oracle_prepare() {
    # dash, bash, zsh and macOS sh all support local.
    # shellcheck disable=SC3043
    local root dir destination plaintext provider backend name value
    root=$(git rev-parse --show-toplevel) || return 1
    dir="$root/tofu/oracle"
    destination="$dir/secrets.auto.tfvars.json"
    if ! git -C "$dir" check-ignore -q -- "$destination"; then
        echo 'prepare.sh: decrypted inputs must be gitignored.' >&2
        return 1
    fi
    plaintext=$(_homelab_sops decrypt "$dir/secrets.sops.json") || return 1
    if ! printf '%s\n' "$plaintext" |
        jq -e '(.tenancy_ocid // "") != "" and (.state_encryption_passphrase // "") != ""' >/dev/null; then
        echo 'prepare.sh: unexpected OCI input file: expected tenancy_ocid and state_encryption_passphrase inputs.' >&2
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
    # Provider credentials: only the expected names, each present. Values are
    # never printed.
    provider=$(_homelab_sops decrypt "$dir/provider.sops.env") || return 1
    name=$(printf '%s\n' "$provider" | grep -v -E '^[[:space:]]*(#|$)' |
        grep -v -E '^(OCI_USER_OCID|OCI_FINGERPRINT|OCI_PRIVATE_KEY)=' | head -n 1 | cut -d= -f1)
    if [ -n "$name" ]; then
        echo "prepare.sh: unexpected key in provider.sops.env: $name" >&2
        return 1
    fi
    for name in OCI_USER_OCID OCI_FINGERPRINT OCI_PRIVATE_KEY; do
        if ! printf '%s\n' "$provider" | grep -q "^$name=."; then
            echo "prepare.sh: provider.sops.env is missing $name." >&2
            return 1
        fi
    done
    # The provider and the s3 backend read these from the environment, so they
    # never reach .terraform/ or saved plans. Check every name before exporting any.
    backend=$(_homelab_sops decrypt "$root/tofu/shared/backend.sops.env") || return 1
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        if ! printf '%s\n' "$backend" | grep -q "^$name=."; then
            echo "prepare.sh: backend.sops.env is missing $name." >&2
            return 1
        fi
    done
    # The private key stays one line, its newlines written \n; the provider
    # restores them.
    for name in OCI_USER_OCID OCI_FINGERPRINT OCI_PRIVATE_KEY; do
        value=$(printf '%s\n' "$provider" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        value=$(printf '%s\n' "$backend" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    # The inventory plugin runs binary_path from a scratch directory, so it must
    # be a bare name found on PATH. Add the directory only once.
    case ":$PATH:" in
        *":$root/ansible-generated/bin:"*) ;;
        *) export PATH="$root/ansible-generated/bin:$PATH" ;;
    esac
    echo 'Decrypted OCI inputs, the OCI API key and backend credentials are ready. Resource definitions remain in the .tf files.'
}

_homelab_oracle_prepare
_homelab_status=$?
unset -f _homelab_oracle_prepare _homelab_sops
# eval expands the status before unsetting it, so the subshell's exit status is
# the last one and becomes the status of sourcing this file.
eval "unset _homelab_status; (exit $_homelab_status)"
