# shellcheck shell=sh
# Prepare the calling shell to run OpenTofu in tofu/github-user: select the
# committed tofu.rc, export the selected workspace's account token and the
# state backend's credentials, and decrypt the OpenTofu inputs, this root's
# state passphrase, into the gitignored secrets.auto.tfvars.json file.
#
# Source it from anywhere in the clone; do not execute it. Source it again
# after selecting another workspace, for that workspace's token:
#
#   . tofu/github-user/prepare.sh
#
# The resource definitions are ordinary .tf files. This script only decrypts
# values; it never generates HCL, calls GitHub, imports state, or applies
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

_homelab_github_user_prepare() {
    # dash, bash, zsh and macOS sh all support local.
    # shellcheck disable=SC3043
    local root dir destination plaintext backend name value workspace token
    root=$(git rev-parse --show-toplevel) || return 1
    dir="$root/tofu/github-user"
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
    plaintext=$(_homelab_sops decrypt --output-type json "$dir/secrets.sops.yaml") || return 1
    if ! printf '%s\n' "$plaintext" |
        jq -e '(keys == ["state_encryption_passphrase"]) and (.state_encryption_passphrase != "")' >/dev/null; then
        echo 'prepare.sh: unexpected github-user input file: expected only the state_encryption_passphrase input.' >&2
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
    export TF_CLI_CONFIG_FILE="$dir/tofu.rc"
    # The selected workspace, TF_WORKSPACE's or the one .terraform records,
    # decides which account a plan acts as, and so whose token the provider
    # reads, as GITHUB_TOKEN: <workspace>.sops.yaml's terraform-github--user.
    # The default workspace has none.
    workspace=${TF_WORKSPACE:-}
    if [ -z "$workspace" ]; then
        workspace=default
        if [ -f "$dir/.terraform/environment" ]; then
            workspace=$(cat "$dir/.terraform/environment")
        fi
    fi
    case $workspace in
    personal | bot)
        token=$(_homelab_sops decrypt --extract '["pat"]["terraform-github--user"]' \
            "$dir/$workspace.sops.yaml") || return 1
        if [ -z "$token" ]; then
            echo "prepare.sh: $workspace.sops.yaml has no terraform-github--user; fill it with sops edit." >&2
            return 1
        fi
        export "GITHUB_TOKEN=$token"
        echo "Loaded the $workspace workspace's account token and the state backend credentials and selected tofu.rc for this shell. Decrypted inputs are ready. Source this again after selecting another workspace."
        ;;
    *)
        unset GITHUB_TOKEN
        echo "Loaded the state backend credentials and selected tofu.rc for this shell. Decrypted inputs are ready. The selected workspace, $workspace, has no account: select personal or bot, then source this again."
        ;;
    esac
}

_homelab_github_user_prepare
_homelab_status=$?
unset -f _homelab_github_user_prepare _homelab_sops
# eval expands the status before unsetting it, so the subshell's exit status is
# the last one and becomes the status of sourcing this file.
eval "unset _homelab_status; (exit $_homelab_status)"
