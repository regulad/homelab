# shellcheck shell=sh
# Prepare the calling shell to run OpenTofu in tofu/aws: obtain temporary
# credentials for the homelab-tofu role from IAM Roles Anywhere and export them
# as TF_VAR_aws_*, export the state backend's credentials, and decrypt the
# OpenTofu inputs into the gitignored secrets.auto.tfvars.json file.
#
# Source it from anywhere in the clone; do not execute it:
#
#   . tofu/aws/prepare.sh
#
# The credentials last an hour; source it again to renew them. The Roles
# Anywhere credential helper, pinned in tools/go.mod, runs through `go tool`.
# It reads its key from a file, so the key, encrypted PKCS#8, goes to a
# temporary file that holds only ciphertext, removed once the helper exits; its
# password is on the helper's command line while it runs. This script never
# generates HCL, imports state, or applies infrastructure changes.
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

_homelab_aws_prepare() {
    # dash, bash, zsh and macOS sh all support local.
    # shellcheck disable=SC3043
    local root dir destination plaintext provider backend session region keyfile helper_status name value
    root=$(git rev-parse --show-toplevel) || return 1
    dir="$root/tofu/aws"
    destination="$dir/secrets.auto.tfvars.json"
    if ! git -C "$dir" check-ignore -q -- "$destination"; then
        echo 'prepare.sh: decrypted inputs must be gitignored.' >&2
        return 1
    fi
    if ! command -v go >/dev/null; then
        echo 'prepare.sh: go, which builds the pinned IAM Roles Anywhere credential helper, is not on PATH.' >&2
        return 1
    fi
    # Provider credentials: exactly the expected keys, each present. Values are
    # never printed.
    provider=$(_homelab_sops decrypt --output-type json "$dir/provider.sops.yaml") || return 1
    if ! printf '%s\n' "$provider" |
        jq -e 'keys == ["private_key", "private_key_password", "profile_arn", "role_arn", "trust_anchor_arn"] and all(.[]; . != "")' >/dev/null; then
        echo 'prepare.sh: provider.sops.yaml must hold exactly private_key, private_key_password, profile_arn, role_arn and trust_anchor_arn.' >&2
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
        echo 'prepare.sh: unexpected aws input file: expected a state_encryption_passphrase input.' >&2
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
    # CreateSession goes to the trust anchor's region, on its dual-stack endpoint.
    region=$(printf '%s\n' "$provider" | jq -r .trust_anchor_arn | cut -d: -f4)
    keyfile=$(umask 077 && mktemp "${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/homelab-aws-key.XXXXXX") || return 1
    helper_status=0
    if printf '%s\n' "$provider" | jq -r .private_key >"$keyfile"; then
        # go -C runs the helper in tools/, so every path it gets is absolute.
        # GOTOOLCHAIN=local builds it with the installed Go, never a download.
        session=$(GOTOOLCHAIN=local go -C "$dir/tools" tool rolesanywhere-credential-helper credential-process \
            --certificate "$dir/rolesanywhere-tofu.crt" \
            --private-key "$keyfile" \
            --pkcs8-password "$(printf '%s\n' "$provider" | jq -r .private_key_password)" \
            --trust-anchor-arn "$(printf '%s\n' "$provider" | jq -r .trust_anchor_arn)" \
            --profile-arn "$(printf '%s\n' "$provider" | jq -r .profile_arn)" \
            --role-arn "$(printf '%s\n' "$provider" | jq -r .role_arn)" \
            --region "$region" \
            --endpoint "https://rolesanywhere.$region.api.aws") || helper_status=$?
    else
        helper_status=1
    fi
    rm -f "$keyfile"
    [ "$helper_status" -eq 0 ] || return "$helper_status"
    if ! printf '%s\n' "$session" |
        jq -e '[.AccessKeyId, .SecretAccessKey, .SessionToken] | all(. != null and . != "")' >/dev/null; then
        echo 'prepare.sh: aws_signing_helper returned no session credentials.' >&2
        return 1
    fi
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        value=$(printf '%s\n' "$backend" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    TF_VAR_aws_access_key_id=$(printf '%s\n' "$session" | jq -r .AccessKeyId)
    TF_VAR_aws_secret_access_key=$(printf '%s\n' "$session" | jq -r .SecretAccessKey)
    TF_VAR_aws_session_token=$(printf '%s\n' "$session" | jq -r .SessionToken)
    export TF_VAR_aws_access_key_id TF_VAR_aws_secret_access_key TF_VAR_aws_session_token
    echo "Loaded AWS credentials until $(printf '%s\n' "$session" | jq -r .Expiration), and state backend credentials, for this shell. Decrypted inputs are ready."
}

_homelab_aws_prepare
_homelab_status=$?
unset -f _homelab_aws_prepare _homelab_sops
# eval expands the status before unsetting it, so the subshell's exit status is
# the last one and becomes the status of sourcing this file.
eval "unset _homelab_status; (exit $_homelab_status)"
