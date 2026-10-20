#!/bin/bash
VMID="$1"
PHASE="$2"

IF="tap${VMID}i0"
IF2="tap${VMID}i2"
ALLOWED_LL_A=fe80::1ef4:3fff:fe14:4bee

# Includes Vizio OUIs which need to use real IPv6 and never the bailout646 IP
BLOCKED_OUIS=(
    00:19:9d
    00:6b:9e
    00:bd:3e
    0c:8b:7d
    14:c6:7d
    2c:64:1f
    3c:9b:d6
    a0:6a:44
    a4:8d:3b
    c4:1c:ff
    cc:95:d7
    e8:38:a0
)
OUI_MASK=ff:ff:ff:00:00:00

ACCEPT_RULE="-p IPv6 -o $IF --ip6-src $ALLOWED_LL_A --ip6-proto ipv6-icmp --ip6-icmp-type router-advertisement -j ACCEPT"
DROP_RULE="-p IPv6 -o $IF --ip6-proto ipv6-icmp --ip6-icmp-type router-advertisement -j DROP"

OUI_RULES=()
for oui in "${BLOCKED_OUIS[@]}"; do
    OUI_RULES+=("-d ${oui}:00:00:00/$OUI_MASK -i $IF2 -j DROP")
    OUI_RULES+=("-s ${oui}:00:00:00/$OUI_MASK -o $IF2 -j DROP")
done

# `ebtables -L` output is not reliably byte-identical to the spec that produced
# it, so it is never matched against. -D resolves the parsed spec instead, which
# makes draining format-independent and safe to run when nothing is installed.
purge_rules() {
    local rule
    for rule in "$ACCEPT_RULE" "$DROP_RULE" "${OUI_RULES[@]}"; do
        while ebtables -D FORWARD $rule 2>/dev/null; do :; done
    done
}

case "$PHASE" in
post-start)
    # Drain first so a re-run cannot duplicate rules, and so the insert order
    # below is the one that ends up in the chain.
    purge_rules
    ebtables -I FORWARD 1 $DROP_RULE
    ebtables -I FORWARD 1 $ACCEPT_RULE
    for rule in "${OUI_RULES[@]}"; do
        ebtables -I FORWARD 1 $rule
    done
    ;;
post-stop)
    purge_rules
    ;;
esac

exit 0
