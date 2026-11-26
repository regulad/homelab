#!/bin/sh
# Run ansible-playbook in one stage, from inside its folder, with the state
# backend's credentials and the stage's bin on PATH (AGENTS.md § Everyday
# commands). The inventory comes from its cache, which every <root>:apply
# clears (tasks/tofu.yml), as bare applies are denied; no --flush-cache, which
# would also clear the stage's fact cache that the checks of one pass share.
#
#   tasks/ansible.sh <stage> <ansible-playbook arguments>
#
# WRAP, a command in the stage's bin, runs it in turn, as bin/with-switch-keys
# does for the SG300s. CACHE=ansiblecache keeps the run's facts in the
# ansiblecache Valkey, over the tailnet with TLS, instead of the stage's local
# cache; an unreachable cache fails the run.
set -eu
stage=$1
shift
top=$(git rev-parse --show-toplevel)
. "$top/tasks/alock-path.sh"
cd "$top/$stage"
if [ "${CACHE:-}" = ansiblecache ]; then
    # The password from ansiblecache's own SOPS file, its only copy, into the
    # run's environment alone. The name is the node's on the tailnet, whose
    # certificate Tailscale Serve presents.
    password=$(sops decrypt --extract '["ansiblecache_password"]' \
        "$top/ansible-generated/inventory/host_vars/ansiblecache.regulad.internal/secrets.sops.yml")
    ANSIBLE_CACHE_PLUGIN=community.general.redis
    ANSIBLE_CACHE_PLUGIN_CONNECTION="tls://ansiblecache.tail11540.ts.net:6379:0:$password"
    PYTHONPATH="$top/.task/python${PYTHONPATH:+:$PYTHONPATH}"
    export ANSIBLE_CACHE_PLUGIN ANSIBLE_CACHE_PLUGIN_CONNECTION PYTHONPATH
    unset password
fi
# sops exec-env takes one command string: quote each argument for the shell.
command=ansible-playbook
for arg in "$@"; do
    command="$command '$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")'"
done
PATH="$PWD/bin:$PATH" exec ${WRAP:+"bin/$WRAP"} sops exec-env ../tofu/shared/backend.sops.env "$command"
