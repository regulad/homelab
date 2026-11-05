# shellcheck shell=sh
# Prepare the calling shell to run OpenTofu in tofu/azure: export homelab-tofu's
# certificate and key as the PKCS#12 bundle ARM_CLIENT_CERTIFICATE, export the
# state backend's credentials, and decrypt the OpenTofu inputs into the
# gitignored secrets.auto.tfvars.json file.
#
# Source it from anywhere in the clone; do not execute it:
#
#   . tofu/azure/prepare.sh
#
# The bundle is built here from provider.sops.yaml and service-principal-tofu.crt,
# since Entra ID holds only the certificate. It carries no password: it lives
# only in the environment, beside where a password would. The credentials stay
# in the environment, never on disk. This script never generates HCL, imports
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

_homelab_azure_prepare() {
    # dash, bash, zsh and macOS sh all support local.
    # shellcheck disable=SC3043
    local root dir destination plaintext provider backend name value bundle
    root=$(git rev-parse --show-toplevel) || return 1
    dir="$root/tofu/azure"
    destination="$dir/secrets.auto.tfvars.json"
    if ! git -C "$dir" check-ignore -q -- "$destination"; then
        echo 'prepare.sh: decrypted inputs must be gitignored.' >&2
        return 1
    fi
    # Provider credentials: exactly the expected key, present. Values are never
    # printed.
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
        jq -e '(.state_encryption_passphrase // "") != ""' >/dev/null; then
        echo 'prepare.sh: unexpected azure input file: expected a state_encryption_passphrase input.' >&2
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
    # The key reaches openssl through a pipe, never a file or a command line.
    bundle=$(printf '%s\n' "$provider" | jq -r .private_key |
        openssl pkcs12 -export -inkey /dev/stdin -in "$dir/service-principal-tofu.crt" -passout pass: |
        openssl base64 -A) || return 1
    if [ -z "$bundle" ]; then
        echo 'prepare.sh: building the PKCS#12 bundle failed.' >&2
        return 1
    fi
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        value=$(printf '%s\n' "$backend" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    export "ARM_CLIENT_CERTIFICATE=$bundle"
    export ARM_CLIENT_CERTIFICATE_PASSWORD=
    echo 'Loaded the homelab-tofu certificate and state backend credentials for this shell. Decrypted inputs are ready.'
}

_homelab_azure_prepare
_homelab_status=$?
unset -f _homelab_azure_prepare _homelab_sops
# eval expands the status before unsetting it, so the subshell's exit status is
# the last one and becomes the status of sourcing this file.
eval "unset _homelab_status; (exit $_homelab_status)"
