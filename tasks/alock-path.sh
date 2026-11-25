# shellcheck shell=sh
# Sourced by the step scripts. Until alock fixes it, PATH must list exactly one
# alock bin, the pinned release's (AGENTS.md § Parallel agents); the release is
# read from the pin in .claude/settings.json.
_alock_ref=$(jq -r '.extraKnownMarketplaces.alock.source.plugins[0].source.ref' "$(git rev-parse --show-toplevel)/.claude/settings.json")
PATH="$HOME/.claude/plugins/cache/alock/alock/${_alock_ref#alock--v}/bin:$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '/.claude/plugins/cache/alock/' | paste -sd: -)"
export PATH
unset _alock_ref
