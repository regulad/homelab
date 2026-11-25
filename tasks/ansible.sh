#!/bin/sh
# Run ansible-playbook in one stage, from inside its folder, with the state
# backend's credentials and the stage's bin on PATH (AGENTS.md § Everyday
# commands). --flush-cache, because an upstream apply may have changed the
# OpenTofu state its inventory caches.
#
#   tasks/ansible.sh <stage> <ansible-playbook arguments>
#
# WRAP, a command in the stage's bin, runs it in turn, as bin/with-switch-keys
# does for the SG300s.
set -eu
stage=$1
shift
top=$(git rev-parse --show-toplevel)
. "$top/tasks/alock-path.sh"
cd "$top/$stage"
# sops exec-env takes one command string: quote each argument for the shell.
command=ansible-playbook
for arg in --flush-cache "$@"; do
    command="$command '$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")'"
done
PATH="$PWD/bin:$PATH" exec ${WRAP:+"bin/$WRAP"} sops exec-env ../tofu/shared/backend.sops.env "$command"
