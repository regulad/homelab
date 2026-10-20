#!/bin/bash
VMID="$1"
PHASE="$2"

MAC="bc:24:11:08:e4:e8"

if [ "$PHASE" = "post-start" ]; then
    if [ -e "/etc/pve/qemu-server/${VMID}.conf" ]; then
        OWN_NET=$(qm config "$VMID" | grep -i "$MAC" | grep -oP '^net\K[0-9]+')
    elif [ -e "/etc/pve/lxc/${VMID}.conf" ]; then
        OWN_NET=$(pct config "$VMID" | grep -i "$MAC" | grep -oP '^net\K[0-9]+')
    fi

    for iface_path in /sys/class/net/tap${VMID}i* /sys/class/net/veth${VMID}i*; do
        [ -e "$iface_path" ] || continue
        IFACE=$(basename "$iface_path")
        IDX="${IFACE##*i}"
        [ -n "$OWN_NET" ] && [ "$IDX" = "$OWN_NET" ] && continue
        ebtables -L FORWARD | grep -q "${MAC}.*${IFACE}" || \
            ebtables -I FORWARD 1 -o "$IFACE" -s "$MAC" -j DROP
    done
fi
