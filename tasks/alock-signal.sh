#!/bin/sh
# An Ansible step's signal: a digest of alock's records of the step's hosts,
# refs/alock/host/<host> and origin's refs/alock-origin/host/<host>, each the
# commit the host was last applied from. Every worktree of this clone shares
# those refs, and in remote mode origin carries them between clones, so an apply
# from any of them changes the signal, and its dependents' plans run again.
# AGENTS.md § Tasks.
#
#   tasks/alock-signal.sh <stage> <host pattern>
set -eu
stage=$1
pattern=$2
top=$(git rev-parse --show-toplevel)
cd "$top/$stage"
# The hosts the pattern names, from the inventory, whose cache serves this read
# of names alone. A host name holds no character that alock's ref names encode.
hosts=$(PATH="$PWD/bin:$PATH" sops exec-env ../tofu/shared/backend.sops.env \
    "ansible '$pattern' --list-hosts" | awk 'NR > 1 { print $1 }')
for host in $hosts; do
    printf '%s %s %s\n' "$host" \
        "$(git rev-parse -q --verify "refs/alock/host/$host" || echo none)" \
        "$(git rev-parse -q --verify "refs/alock-origin/host/$host" || echo none)"
done | cksum
