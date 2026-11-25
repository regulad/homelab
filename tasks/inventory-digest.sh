#!/bin/sh
# Print a digest of what one terraform_state inventory source selects from its
# root's state: the plugin's own cache entry, the resources whose attributes
# become host variables. The cache is made for this digest alone, in a private
# temporary directory removed after it, as it holds those attributes in
# plaintext; the operator's cache is left as it is.
#
#   tasks/inventory-digest.sh <stage>/inventory/<root>.terraform_state.yml
set -eu
source=$1
stage=${source%%/*}
top=$(git rev-parse --show-toplevel)
. "$top/tasks/alock-path.sh"
cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT
(
    cd "$top/$stage"
    ANSIBLE_INVENTORY_CACHE_CONNECTION=$cache PATH="$PWD/bin:$PATH" \
        sops exec-env ../tofu/shared/backend.sops.env \
        "ansible-inventory -i '${source#*/}' --graph --flush-cache" >/dev/null
)
find "$cache" -type f -exec cat {} + | cksum
