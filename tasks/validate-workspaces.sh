#!/bin/sh
# Validate an OpenTofu root in each of its workspaces: the pre-commit hook of a
# root with workspaces, which a checkout's selected workspace, often the empty
# default, would otherwise decide. The workspaces are the root's steps in
# Taskfile.yml's STEPS, <root>.<workspace>, so the list is written once.
#
#   tasks/validate-workspaces.sh <root> [<env assignment>...]
set -eu
root=$1
shift
top=$(git rev-parse --show-toplevel)
workspaces=$(sed -n "s/^    - $root\.\([A-Za-z0-9_-]*\)\$/\1/p" "$top/Taskfile.yml")
[ -n "$workspaces" ] || { echo "validate-workspaces: no $root.<workspace> in Taskfile.yml's STEPS" >&2; exit 1; }
for workspace in $workspaces; do
    echo "tofu/$root, workspace $workspace:"
    env TF_WORKSPACE="$workspace" "$@" tofu -chdir="$top/tofu/$root" validate -no-color
done
