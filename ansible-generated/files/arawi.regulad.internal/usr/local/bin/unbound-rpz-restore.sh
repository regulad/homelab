#!/bin/sh
# Copy Unbound's split-horizon RPZ into its chroot. Run as an earlyshellcmd,
# before pfSense starts Unbound: /var is a RAM disk, so the copy is gone after
# every boot, and Unbound refuses to start when an RPZ zonefile is missing.

master=/usr/local/etc/unbound/split-horizon.rpz
runtime=/var/unbound/split-horizon.rpz

# pfSense creates the chroot only when it configures Unbound, later in boot.
install -d -o unbound -g unbound -m 0755 /var/unbound || exit 1

if ! install -o root -g wheel -m 0644 "$master" "$runtime"; then
    # An empty zone keeps Unbound starting; "lan" clients then get the public answers.
    # shellcheck disable=SC2016 # $ORIGIN and $TTL are zonefile directives.
    printf '%s\n' \
        '$ORIGIN split-horizon.rpz.' \
        '$TTL 60' \
        '@ IN SOA localhost. nobody.invalid. 1 3600 600 86400 60' \
        '@ IN NS localhost.' > "$runtime" || exit 1
    chown root:wheel "$runtime"
    chmod 0644 "$runtime"
    msg="$master is missing; installed an empty split-horizon RPZ"
    echo "$msg" | logger -t unbound-rpz-restore -p daemon.err
    echo "$msg" 2>/dev/null > /dev/console
fi
