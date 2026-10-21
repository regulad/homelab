#!/bin/sh
# Exit non-zero if any RAM-backed filesystem is out of space or inodes.
# Intended as a watchdogd(8) health check:
#     watchdogd -t 60 -s 15 -e /usr/local/bin/ramfs-check.sh
#
# Matches md(4) memory disks and tmpfs. A filesystem is "full" when it is
# below BOTH 16 MiB and 5% free (so the percentage governs small mounts
# like /var/run and the absolute floor governs large ones like /var), or
# independently when inodes drop below 5% free.

out=$(df -ik | awk '
	$1 !~ /^\/dev\/md[0-9]+$/ && $1 != "tmpfs" { next }
	{ blk = 100 - $5; ino = 100 - $8 }
	($4 < 16384 && blk < 5) || ino < 5 {
		printf "%s full: %d KiB (%d%%) blocks, %d%% inodes free\n", $9, $4, blk, ino
		bad = 1
	}
	END { exit bad }
')
rc=$?

if [ -n "$out" ]; then
	echo "$out" | logger -t ramfs-check -p daemon.crit
	echo "$out" 2>/dev/null > /dev/console
	echo "$out" >&2
fi

exit "$rc"
