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
# prepare.sh is written for an interactive shell: no -e or -u, and its report
# goes to stderr so that `tofu output -json` stays the only stdout.
set +eu
. "$top/tofu/$root/prepare.sh" >&2 || exit 1
set -eu
exec tofu -chdir="$top/tofu/$root" "$@"
