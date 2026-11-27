# shellcheck shell=sh
# Prepare the calling shell to run OpenTofu in tofu/vercel: export the Vercel
# access token and the state backend's credentials, and decrypt the OpenTofu
# inputs, with the GitHub personal access tokens from
# tofu/github-user/personal.sops.yaml and the Sentry organization tokens from
# tofu/sentry/org-tokens.sops.yaml, their only copies, into the gitignored
# secrets.auto.tfvars.json file.
#
# Source it from anywhere in the clone; do not execute it:
#
#   . tofu/vercel/prepare.sh
#
# The resource definitions are ordinary .tf files. This script only decrypts
# values; it never generates HCL, calls Vercel, imports state, or applies
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

_homelab_vercel_prepare() {
    # dash, bash, zsh and macOS sh all support local.
    # shellcheck disable=SC3043
    local root dir destination plaintext pats sentry ga4 provider backend name value
    root=$(git rev-parse --show-toplevel) || return 1
    dir="$root/tofu/vercel"
    destination="$dir/secrets.auto.tfvars.json"
    if ! git -C "$dir" check-ignore -q -- "$destination"; then
        echo 'prepare.sh: decrypted inputs must be gitignored.' >&2
        return 1
    fi
    # Provider credentials: only the expected name, present. Values are never
    # printed.
    provider=$(_homelab_sops decrypt "$dir/provider.sops.env") || return 1
    name=$(printf '%s\n' "$provider" | grep -v -E '^[[:space:]]*(#|$)' |
        grep -v -E '^VERCEL_API_TOKEN=' | head -n 1 | cut -d= -f1)
    if [ -n "$name" ]; then
        echo "prepare.sh: unexpected key in provider.sops.env: $name" >&2
        return 1
    fi
    if ! printf '%s\n' "$provider" | grep -q '^VERCEL_API_TOKEN=.'; then
        echo 'prepare.sh: provider.sops.env is missing VERCEL_API_TOKEN.' >&2
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
    # The GitHub personal access tokens, from their only copy, by their names
    # on GitHub: classic under pat, fine-grained under fine_grained.
    pats=$(_homelab_sops decrypt --output-type json \
        "$root/tofu/github-user/personal.sops.yaml") || return 1
    # The Sentry organization tokens, by repository, from their only copy,
    # tofu/sentry's org-tokens.sops.yaml.
    sentry=$(_homelab_sops decrypt --extract '["org_tokens"]' --output-type json \
        "$root/tofu/sentry/org-tokens.sops.yaml") || return 1
    # tofu/ga4's state passphrase, which ga4.tf needs to read its outputs, from
    # tofu/ga4's own encrypted file, its only copy.
    ga4=$(_homelab_sops decrypt --extract '["state_encryption_passphrase"]' "$root/tofu/ga4/secrets.sops.yaml") || return 1
    plaintext=$({
        printf '%s\n' "$plaintext"
        printf '%s' "$pats" | jq '{github_pats: {pat, fine_grained}}'
        printf '%s' "$sentry" | jq '{sentry_auth_tokens: .}'
        printf '%s' "$ga4" | jq -R -s '{ga4_state_encryption_passphrase: .}'
    } | jq -s add) || return 1
    # An empty value is a slot scaffolded for a secret not yet issued
    # (AGENTS.md, Secrets to add by hand): it is left out of the input, so a
    # resource that reads it fails the plan on a missing key instead of
    # blanking an environment variable, and every other resource still plans.
    plaintext=$(printf '%s\n' "$plaintext" | jq 'walk(if type == "object" then with_entries(select(.value != "")) else . end)') || return 1
    if [ -e "$destination" ]; then
        # Compare data, not formatting. Preserve any differing local edits.
        if [ "$(jq -S -c . "$destination")" != "$(printf '%s\n' "$plaintext" | jq -S -c .)" ]; then
            echo 'prepare.sh: secrets.auto.tfvars.json has local edits. Preserve them before decrypting updated inputs.' >&2
            return 1
        fi
    else
        (umask 077 && printf '%s\n' "$plaintext" >"$destination") || return 1
    fi
    value=$(printf '%s\n' "$provider" | sed -n 's/^VERCEL_API_TOKEN=//p' | head -n 1)
    export "VERCEL_API_TOKEN=$value"
    for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3; do
        value=$(printf '%s\n' "$backend" | sed -n "s/^$name=//p" | head -n 1)
        export "$name=$value"
    done
    echo 'Loaded the Vercel token and state backend credentials for this shell. Decrypted inputs are ready.'
}

_homelab_vercel_prepare
_homelab_status=$?
unset -f _homelab_vercel_prepare _homelab_sops
# eval expands the status before unsetting it, so the subshell's exit status is
# the last one and becomes the status of sourcing this file.
eval "unset _homelab_status; (exit $_homelab_status)"
