#!/bin/bash
# /var/lib/vz/snippets/101.sh
#
# post-start hookscript for VM 101, does two things:
#   1. Blocks a specific MAC from forwarding out of every tap
#      belonging to this VM (e.g. isolating net0/net2 for pfSense's
#      shitty SLAAC support).
#   2. Pins each "CPU N/KVM" vCPU thread to a host CPU using the VM's
#      own `affinity:` line.

set -u
vmid="$1"
phase="$2"

EXPECTED_VMID="101"
if [ "$vmid" != "$EXPECTED_VMID" ]; then
    echo "101.sh: refusing to run, called with VMID '${vmid}' but this script is hardcoded for ${EXPECTED_VMID}" >&2
    exit 1
fi

BLOCK_MAC="bc:24:11:08:e4:e8"
conf="/etc/pve/qemu-server/${vmid}.conf"

# ---------------------------------------------------------------------
# 1. MAC blocking
# ---------------------------------------------------------------------
block_mac() {
    local own_net
    own_net="$(grep -i "$BLOCK_MAC" "$conf" | grep -oP '^net\K[0-9]+')"

    for iface_path in /sys/class/net/tap${vmid}i*; do
        [ -e "$iface_path" ] || continue
        local iface idx
        iface="$(basename "$iface_path")"
        idx="${iface##*i}"
        [ -n "$own_net" ] && [ "$idx" = "$own_net" ] && continue
        ebtables -L FORWARD | grep -q "${BLOCK_MAC}.*${iface}" || \
            ebtables -I FORWARD 1 -o "$iface" -s "$BLOCK_MAC" -j DROP
    done
}

# ---------------------------------------------------------------------
# 2. vCPU pinning
# ---------------------------------------------------------------------
expand_cpulist() {
    local spec="$1" part start end c
    local -a out=()
    IFS=',' read -ra parts <<< "$spec"
    for part in "${parts[@]}"; do
        if [[ "$part" == *-* ]]; then
            start="${part%-*}"; end="${part#*-}"
            for (( c=start; c<=end; c++ )); do out+=("$c"); done
        else
            out+=("$part")
        fi
    done
    printf '%s\n' "${out[@]}"
}

count_vcpu_threads() {
    local pid="$1" n=0 c f
    for f in /proc/"$pid"/task/*/comm; do
        c="$(cat "$f" 2>/dev/null)"
        [[ "$c" =~ ^CPU\ [0-9]+/KVM$ ]] && (( n++ ))
    done
    echo "$n"
}

pin_vcpus() {
    local affinity cores sockets total_vcpus
    affinity="$(grep -m1 '^affinity:' "$conf" | cut -d: -f2- | tr -d ' ')"
    cores="$(grep -m1   '^cores:'    "$conf" | cut -d: -f2- | tr -d ' ')"
    sockets="$(grep -m1 '^sockets:'  "$conf" | cut -d: -f2- | tr -d ' ')"
    cores="${cores:-1}"
    sockets="${sockets:-1}"
    total_vcpus=$(( cores * sockets ))

    if [ -z "$affinity" ]; then
        echo "pin-vcpus: VM ${vmid} has no 'affinity' set, nothing to do" >&2
        return 0
    fi

    local -a HOST_CPUS
    mapfile -t HOST_CPUS < <(expand_cpulist "$affinity")

    if [ "${#HOST_CPUS[@]}" -ne "$total_vcpus" ]; then
        echo "pin-vcpus: VM ${vmid} has ${total_vcpus} vCPUs (sockets=${sockets} x cores=${cores})" \
             "but affinity '${affinity}' expands to ${#HOST_CPUS[@]} CPUs - refusing to pin" >&2
        return 1
    fi

    local pidfile="/run/qemu-server/${vmid}.pid"
    local i qemu_pid
    for (( i=0; i<20; i++ )); do
        [ -s "$pidfile" ] && break
        sleep 0.5
    done
    qemu_pid="$(cat "$pidfile" 2>/dev/null)"
    if [ -z "$qemu_pid" ] || [ ! -d "/proc/$qemu_pid" ]; then
        echo "pin-vcpus: VM ${vmid} PID not found" >&2
        return 1
    fi

    for (( i=0; i<100; i++ )); do
        [ "$(count_vcpu_threads "$qemu_pid")" -ge "$total_vcpus" ] && break
        sleep 0.1
    done
    local have
    have="$(count_vcpu_threads "$qemu_pid")"
    if [ "$have" -lt "$total_vcpus" ]; then
        echo "pin-vcpus: VM ${vmid} only has ${have}/${total_vcpus} vCPU threads after 10s, giving up" >&2
        return 1
    fi

    local task tid comm idx cpu
    for task in /proc/"${qemu_pid}"/task/*; do
        tid="$(basename "$task")"
        comm="$(cat "${task}/comm" 2>/dev/null)"
        if [[ "$comm" =~ ^CPU\ ([0-9]+)/KVM$ ]]; then
            idx="${BASH_REMATCH[1]}"
            cpu="${HOST_CPUS[$idx]}"
            taskset -pc "$cpu" "$tid" >/dev/null
            logger -t pin-vcpus "vm ${vmid}: vCPU ${idx} (tid ${tid}) -> host cpu ${cpu}"
        fi
    done
}

# ---------------------------------------------------------------------
# main - explicit handling for every phase Proxmox may invoke
# ---------------------------------------------------------------------
case "$phase" in
    pre-start)
        # nothing to do before the VM exists
        ;;
    post-start)
        #block_mac
        pin_vcpus
        ;;
    pre-stop)
        # nothing to do
        ;;
    post-stop)
        # taps/threads are already gone, nothing to clean up
        ;;
    *)
        echo "101.sh: unrecognized phase '${phase}'" >&2
        exit 1
        ;;
esac

exit 0
