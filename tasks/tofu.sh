#!/bin/sh
# Run OpenTofu in one root with the credentials and inputs its own prepare.sh
# provides, sourced into this process alone.
#
#   tasks/tofu.sh <root> [<workspace>] -- <tofu arguments>
set -eu
root=$1
shift
if [ "$1" != -- ]; then
    TF_WORKSPACE=$1
    export TF_WORKSPACE
    shift
fi
shift
top=$(git rev-parse --show-toplevel)
. "$top/tasks/alock-path.sh"
# A root takes its AWS_* variables from its own prepare.sh alone: one the
# operator's shell carries, such as an AWS_ENDPOINT_URL for another S3, would
# reach the backend and the aws provider too.
for name in $(env | sed -n 's/^\(AWS_[A-Za-z0-9_]*\)=.*/\1/p'); do
    unset "$name"
done
# The checked-in SOPS file is the root's only source of its inputs: its
# decrypted copy is written afresh, so that a copy left from an older commit,
# as a rebase leaves one, never trips prepare.sh's guard against local edits.
rm -f "$top/tofu/$root/secrets.auto.tfvars.json"
# prepare.sh is written for an interactive shell: no -e or -u, and its report
# goes to stderr so that `tofu output -json` stays the only stdout.
set +eu
. "$top/tofu/$root/prepare.sh" >&2 || exit 1
set -eu
exec tofu -chdir="$top/tofu/$root" "$@"
