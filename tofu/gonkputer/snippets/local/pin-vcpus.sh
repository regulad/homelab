#!/bin/bash
# /var/lib/vz/snippets/pin-vcpus.sh
#
# Pins each "CPU N/KVM" vCPU thread to an individual host CPU, using
# the CPU list from that VM's own `affinity:` line. Reusable across
# any VM - just attach it as that VM's hookscript and set `affinity:`
# to exactly as many CPUs as the VM has vCPUs (sockets x cores).

set -u
vmid="$1"
phase="$2"

[ "$phase" = "post-start" ] || exit 0

conf="/etc/pve/qemu-server/${vmid}.conf"
[ -r "$conf" ] || { echo "pin-vcpus: cannot read $conf" >&2; exit 1; }

# Reads the first (active, non-pending) occurrence of each key
affinity="$(grep -m1 '^affinity:' "$conf" | cut -d: -f2- | tr -d ' ')"
cores="$(grep -m1   '^cores:'    "$conf" | cut -d: -f2- | tr -d ' ')"
sockets="$(grep -m1 '^sockets:'  "$conf" | cut -d: -f2- | tr -d ' ')"
cores="${cores:-1}"
sockets="${sockets:-1}"
total_vcpus=$(( cores * sockets ))

if [ -z "$affinity" ]; then
    echo "pin-vcpus: VM ${vmid} has no 'affinity' set, nothing to do" >&2
    exit 0
fi

# Expand "8-11,24-27" -> 8 9 10 11 24 25 26 27, preserving listed order
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
mapfile -t HOST_CPUS < <(expand_cpulist "$affinity")

if [ "${#HOST_CPUS[@]}" -ne "$total_vcpus" ]; then
    echo "pin-vcpus: VM ${vmid} has ${total_vcpus} vCPUs (sockets=${sockets} x cores=${cores})" \
         "but affinity '${affinity}' expands to ${#HOST_CPUS[@]} CPUs - refusing to pin" >&2
    exit 1
fi

pidfile="/run/qemu-server/${vmid}.pid"
for (( i=0; i<20; i++ )); do
    [ -s "$pidfile" ] && break
    sleep 0.5
done
qemu_pid="$(cat "$pidfile" 2>/dev/null)"
if [ -z "$qemu_pid" ] || [ ! -d "/proc/$qemu_pid" ]; then
    echo "pin-vcpus: VM ${vmid} PID not found" >&2
    exit 1
fi

# Poll for all vCPU threads to actually exist, instead of guessing with sleep
count_vcpu_threads() {
    local pid="$1" n=0 c
    for f in /proc/"$pid"/task/*/comm; do
        c="$(cat "$f" 2>/dev/null)"
        [[ "$c" =~ ^CPU\ [0-9]+/KVM$ ]] && (( n++ ))
    done
    echo "$n"
}

for (( i=0; i<100; i++ )); do
    [ "$(count_vcpu_threads "$qemu_pid")" -ge "$total_vcpus" ] && break
    sleep 0.1
done
have="$(count_vcpu_threads "$qemu_pid")"
if [ "$have" -lt "$total_vcpus" ]; then
    echo "pin-vcpus: VM ${vmid} only has ${have}/${total_vcpus} vCPU threads after 10s, giving up" >&2
    exit 1
fi

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

exit 0
