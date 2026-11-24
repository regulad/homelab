# shellcheck shell=sh
# Prepare the calling shell to run OpenTofu in tofu/github: export the selected
# workspace's GitHub App private key and the state backend's credentials, and
# decrypt the OpenTofu inputs, with regulad's personal access tokens from
# tofu/github-personal/secrets.sops.yaml and the Nexus CI users' passwords from
# ansible-generated/inventory/group_vars/nexus_servers.sops.yml, their only
# copies, and tofu/tailscale's state passphrase, into the gitignored
# secrets.auto.tfvars.json file.
#
# Source it from anywhere in the clone; do not execute it. Source it again
# after selecting another workspace, for that workspace's key:
#
#   . tofu/github/prepare.sh
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

_homelab_github_prepare() {
    # dash, bash, zsh and macOS sh all support local.
    # shellcheck disable=SC3043
    local root dir destination plaintext pats nexus tailscale azure provider backend name value user key workspace
    root=$(git rev-parse --show-toplevel) || return 1
    dir="$root/tofu/github"
    destination="$dir/secrets.auto.tfvars.json"
    if ! git -C "$dir" check-ignore -q -- "$destination"; then
        echo 'prepare.sh: decrypted inputs must be gitignored.' >&2
        return 1
    fi
    # Provider credentials: each workspace's App key,
    # GITHUB_APP_<WORKSPACE>_PEM_FILE, and nothing else, each present. Values
    # are never printed.
    provider=$(_homelab_sops decrypt "$dir/provider.sops.env") || return 1
    name=$(printf '%s\n' "$provider" | grep -v -E '^[[:space:]]*(#|$)' |
        grep -v -E '^GITHUB_APP_(PERSONAL|BOT)_PEM_FILE=' | head -n 1 | cut -d= -f1)
    if [ -n "$name" ]; then
        echo "prepare.sh: unexpected key in provider.sops.env: $name" >&2
        return 1
    fi
    for name in GITHUB_APP_PERSONAL_PEM_FILE GITHUB_APP_BOT_PEM_FILE; do
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
    plaintext=$(_homelab_sops decrypt --output-type json "$dir/secrets.sops.yaml") || return 1
    # regulad's personal access tokens, by their names on GitHub, from their
    # only copy, tofu/github-personal's.
    pats=$(_homelab_sops decrypt --extract '["github_pats"]' --output-type json \
        "$root/tofu/github-personal/secrets.sops.yaml") || return 1
    plaintext=$({
        printf '%s\n' "$plaintext"
        printf '%s' "$pats" | jq '{github_pats: .}'
    } | jq -s add) || return 1
    # Every value is filled in: an empty one would blank a repository's secret.
    if ! printf '%s\n' "$plaintext" | jq -e '[.. | strings | select(. == "")] | length == 0' >/dev/null; then
        echo 'prepare.sh: an input is empty; fill it with sops edit (the PATs live in tofu/github-personal/secrets.sops.yaml).' >&2
        return 1
    fi
    # The Nexus CI users' passwords, by user ID, from their only copy. Both pass
    # through pipes, never a command line.
    nexus='{}'
    for user in svc-redroid nx-aaoracled svc-doppelganger-ci; do
        key="nexus_$(printf '%s' "$user" | tr '-' '_')_password"
        value=$(_homelab_sops decrypt --extract "[\"$key\"]" \
            "$root/ansible-generated/inventory/group_vars/nexus_servers.sops.yml") || return 1
        if [ -z "$value" ]; then
            echo "prepare.sh: nexus_servers.sops.yml has no $key." >&2
            return 1
        fi
        nexus=$(printf '%s' "$value" | jq -R -s --argjson n "$nexus" --arg u "$user" '$n + {($u): .}') || return 1
    done
    # tofu/tailscale's state passphrase, which tailscale.tf needs to read its
    # outputs, from tofu/tailscale's own encrypted file, its only copy.
    tailscale=$(_homelab_sops decrypt --extract '["state_encryption_passphrase"]' "$root/tofu/tailscale/secrets.sops.yaml") || return 1
    if [ -z "$tailscale" ]; then
        echo 'prepare.sh: tofu/tailscale/secrets.sops.yaml has no state_encryption_passphrase.' >&2
        return 1
    fi
    # tofu/azure's, likewise, for azure.tf.
    azure=$(_homelab_sops decrypt --extract '["state_encryption_passphrase"]' "$root/tofu/azure/secrets.sops.yaml") || return 1
    if [ -z "$azure" ]; then
        echo 'prepare.sh: tofu/azure/secrets.sops.yaml has no state_encryption_passphrase.' >&2
        return 1
    fi
    plaintext=$({
        printf '%s\n' "$plaintext"
        printf '%s' "$nexus" | jq '{nexus_passwords: .}'
        printf '%s' "$tailscale" | jq -R -s '{tailscale_state_encryption_passphrase: .}'
        printf '%s' "$azure" | jq -R -s '{azure_state_encryption_passphrase: .}'
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
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        value=$(printf '%s\n' "$backend" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    # The selected workspace, TF_WORKSPACE's or the one .terraform records,
    # decides which account a plan touches, and so which App's key the provider
    # reads, as GITHUB_APP_PEM_FILE. The default workspace has none.
    workspace=${TF_WORKSPACE:-}
    if [ -z "$workspace" ]; then
        workspace=default
        if [ -f "$dir/.terraform/environment" ]; then
            workspace=$(cat "$dir/.terraform/environment")
        fi
    fi
    case $workspace in
    personal | bot)
        name="GITHUB_APP_$(printf '%s' "$workspace" | tr '[:lower:]' '[:upper:]')_PEM_FILE"
        value=$(printf '%s\n' "$provider" | sed -n "s/^$name=//p" | head -n 1)
        export "GITHUB_APP_PEM_FILE=$value"
        echo "Loaded the $workspace workspace's GitHub App key and the state backend credentials for this shell. Decrypted inputs are ready. Source this again after selecting another workspace."
        ;;
    *)
        unset GITHUB_APP_PEM_FILE
        echo "Loaded the state backend credentials for this shell. Decrypted inputs are ready. The selected workspace, $workspace, has no App: select personal or bot, then source this again."
        ;;
    esac
}

_homelab_github_prepare
_homelab_status=$?
unset -f _homelab_github_prepare _homelab_sops
# eval expands the status before unsetting it, so the subshell's exit status is
# the last one and becomes the status of sourcing this file.
eval "unset _homelab_status; (exit $_homelab_status)"
