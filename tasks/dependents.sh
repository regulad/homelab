#!/bin/sh
# Print the tasks that propagate a step's apply, one `<task> [VAR=value]` a
# line: the plan of each OpenTofu step that reads it, and the check of each
# Ansible step that reads it, limited to the hosts or groups whose own vars
# read it, or the whole step's plan where its group_vars/all, roles or
# playbooks do. Each step's references come from its own `references` task.
# AGENTS.md § Tasks.
#
#   tasks/dependents.sh <step>
#
# Reads STEPS, the pipeline's steps, and TASK, go-task's executable.
set -eu
step=$1
root=${step%%.*}
for candidate in $STEPS; do
    case $candidate in
    "$root" | "$root".*) continue ;;
    esac
    files=$("$TASK" --silent "$candidate:references" | while read -r what name where; do
        case $what in
        outputs)
            if [ "$name" = "$root" ] || [ "$name" = "$step" ]; then echo "$where"; fi
            ;;
        inventory)
            if grep -qE "key: *\"?$root/terraform\.tfstate" "$name"; then echo "$where"; fi
            ;;
        esac
    done | sort -u)
    [ -n "$files" ] || continue
    case $candidate in
    ansible-*)
        limit=
        whole=false
        for file in $files; do
            case $file in
            */inventory/host_vars/*/*) part=${file#*/inventory/host_vars/} ;;
            */inventory/group_vars/all.yml | */inventory/group_vars/all/*) whole=true; part= ;;
            */inventory/group_vars/*/*) part=${file#*/inventory/group_vars/} ;;
            */inventory/group_vars/*.yml) part=${file#*/inventory/group_vars/}; part=${part%.yml} ;;
            *) whole=true; part= ;;
            esac
            part=${part%%/*}
            [ -n "$part" ] && limit=${limit:+$limit,}$part
        done
        if $whole; then echo "$candidate:plan"; else echo "$candidate:check LIMIT=$limit"; fi
        ;;
    *) echo "$candidate:plan" ;;
    esac
done
