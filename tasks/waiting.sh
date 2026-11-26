#!/bin/sh
# List the steps that wait on something, for `bin/do_task pending`: a root
# whose plan for HEAD's commit has changes, its saved plan in docs/snapshot,
# and any step whose last plan or check was not clean (it found changes,
# failed, or has not run), as no clean marker records it. A plan with no
# changes saves no file, and a clean plan or check writes its marker
# (tasks/tofu.yml, tasks/ansible.yml). AGENTS.md § Tasks.
#
#   STEPS='<step> …' tasks/waiting.sh
set -eu
top=$(git rev-parse --show-toplevel)
commit=$(git rev-parse --short=7 HEAD)
clean="${TASK_TEMP_DIR:-$top/.task}/clean"
for step in $STEPS; do
    plan="$top/docs/snapshot/$step@$commit.tfplan"
    if [ -f "$plan" ]; then
        echo "$step: changes wait to be applied: $plan"
    elif [ ! -f "$clean/$step" ]; then
        echo "$step: not clean: changes, a failure, or not yet planned"
    fi
done
