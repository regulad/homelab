#!/bin/sh
# Write a step's upstream signal, .task/upstream/<step>: one line for every
# value the step reads from another step or root, found in the step's own
# files, so that go-task's up-to-date check re-plans the step when one of them
# changes. AGENTS.md § Tasks.
#
#   tasks/upstream.sh <step> <tofu|ansible> <path>... [-- <step>...]
#
# The references it recognises:
# - `key = "<root>/terraform.tfstate"` in .tf files: a terraform_remote_state
#   read of that root's outputs.
# - an Ansible stage's *.terraform_state.yml inventory sources: each one's
#   signal is a digest of what its plugin selects from the state, the
#   resources whose attributes become host variables. The plugin selects them
#   itself, into a cache of its own made for the digest and removed after it,
#   so the signal follows the inventory file and nothing restates it.
# - `../tofu/<root>'` or `"`: a cloud.terraform.tf_output lookup's project_path.
# - `tofu/<root>/<name>.sops.<ext>`: another root's SOPS file, by content.
# - each <step> after `--`: that step's signal, for a dependency no file names.
#
# Reads STEPS, the pipeline's steps, TASK, go-task's executable, and
# SCAN_EXCLUDE, a directory name to leave out: a host the stage excepts.
set -eu
step=$1
kind=$2
shift 2
paths=
extra=
while [ $# -gt 0 ]; do
    if [ "$1" = -- ]; then
        shift
        extra=$*
        break
    fi
    paths="$paths $1"
    shift
done
self=${step%%.*}

scan() {
    # shellcheck disable=SC2086 # paths is a word list
    grep -rhoE --exclude-dir=collections --exclude-dir=.terraform \
        ${SCAN_EXCLUDE:+--exclude-dir="$SCAN_EXCLUDE"} \
        --include='*.tf' --include='*.yml' --include='*.yaml' --include='*.j2' --include=prepare.sh \
        -e "$1" $paths || true
}

references() {
    if [ "$kind" = tofu ]; then
        scan 'key *= *"[a-z0-9-]+/terraform\.tfstate' |
            sed -E 's/.*= *"([a-z0-9-]+)\/.*/outputs \1/'
    else
        # shellcheck disable=SC2086 # paths is a word list
        find $paths -name '*.terraform_state.yml' -not -path '*/collections/*' |
            sed 's/^/inventory /'
    fi
    scan "\.\./tofu/[a-z0-9-]+['\"]" | sed -E 's/.*tofu\/([a-z0-9-]+).*/outputs \1/'
    scan 'tofu/[a-z0-9-]+/[A-Za-z0-9_.-]+\.sops\.[a-z]+' | sed 's/^/file /'
    for name in $extra; do echo "outputs $name"; done
}

mkdir -p .task/upstream
temporary=$(mktemp ".task/upstream/$step.XXXXXX")
trap 'rm -f "$temporary"' EXIT
references | sort -u | while read -r what name; do
    case $what in
    outputs)
        [ "$name" = "$self" ] && continue
        for candidate in $STEPS; do
            case $candidate in
            "$name" | "$name".*)
                "$TASK" --silent "$candidate:outputs"
                printf 'outputs %s ' "$candidate"
                cat ".task/signals/$candidate.outputs"
                ;;
            esac
        done
        ;;
    inventory)
        printf 'inventory %s ' "$name"
        tasks/inventory-digest.sh "$name"
        ;;
    file)
        printf 'file %s ' "$name"
        cksum <"$name"
        ;;
    esac
done >"$temporary"
mv "$temporary" ".task/upstream/$step"
trap - EXIT
