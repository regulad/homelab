#!/bin/bash
set -euo pipefail

CTID="$1"
PHASE="$2"

NAS_MNT="/tmp/mnt_nas_${CTID}"

NAS_SRC="/mnt/nas"

UID_OFFSET=100000
GID_OFFSET=100000

mount_bindfs() {
    mkdir -p "$NAS_MNT"

    if ! mountpoint -q "$NAS_MNT"; then
        bindfs --forward-odirect=4096 \
               --enable-lock-forwarding \
               --multithreaded \
               --uid-offset="$UID_OFFSET" \
               --gid-offset="$GID_OFFSET" \
               "$NAS_SRC" \
               "$NAS_MNT"
    fi
}

umount_bindfs() {
    # Unmount in reverse order, lazily to avoid race conditions
    mountpoint -q "$NAS_MNT" && umount -l "$NAS_MNT"

    rmdir "$NAS_MNT" 2>/dev/null || true
}

case "$PHASE" in
    pre-start)
        mount_bindfs
        ;;
    post-stop)
        umount_bindfs
        ;;
esac

exit 0
