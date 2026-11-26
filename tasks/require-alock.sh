#!/bin/sh
# Refuse an apply that Claude Code runs unless the command it runs is alock's
# shim, so that no agent's apply goes past alock's lock and commit check.
# Claude Code sets CLAUDECODE=1 in each command it runs; Parker's own applies
# from his shell pass. A plan or check needs none: alock passes read-only calls
# straight through.
#
#   tasks/require-alock.sh <tofu|ansible-playbook>
set -eu
[ "${CLAUDECODE:-}" = 1 ] || exit 0
top=$(git rev-parse --show-toplevel)
. "$top/tasks/alock-path.sh"
found=$(command -v "$1" || true)
case $found in
*/.claude/plugins/cache/alock/*) ;;
*)
    echo "require-alock: $1 is ${found:-missing}, not alock's shim. Install alock with" >&2
    echo "  claude plugin install alock@alock --scope project" >&2
    echo "then have Parker run /reload-plugins (AGENTS.md § Parallel agents)." >&2
    exit 1
    ;;
esac
