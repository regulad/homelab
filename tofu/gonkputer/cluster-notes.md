### Drives

The SMR RBD pool is NOT redundant in any way. It is ONLY to be used as backup storage, where it can serve a tertiary rather than primary or secondary role. 

Used for the SMR pool with 1/1, IT CAN ONLY BE WRITTEN TO BY ONE TASK AT ONCE! Currently, this is UrBackup, which is a good fit since its incremental nature means once written to objects aren't touched, which is good for SMR shingling behaviour.

Discarding behaves erratically with CoW behaviour. Ensure that the volume from which the image is CoWed from is *as small as possible*, as it can only discard *down* to that size; any difference, even in **if a block contains only unallocated space** is kept as a delta.

### DNS

mDNS is much more durable than a DNS server managed by the DHCP server. The Verizon ISP router is particularly bad. The DNS rebinding risk is manageable.

As for hostnames: do not include the domain name (home.arpa) in the hostname given to a guest!

### New node setup bible

```bash
apt install avahi-daemon avahi-utils libnss-mdns rasdaemon kdump-tools
systemctl enable --now rasdaemon
sed -i 's/^#KDUMP_NUM_DUMPS=.*/KDUMP_NUM_DUMPS=1/' /etc/default/kdump-tools
# make sure to edit /etc/default/grub.d/kdump-tools.cfg crashkernel to whatever `kdump-config show` says is best for that hardware configuration
```

* Be warned: for graphical `qnetd` hosts, don't use `kdump-tools`, it can be unreliable
* Turk can't self-right, it needs a standby operator to boot since the Dell reliability menu prompts for confirmation.
* With proper usage of `zram` and non-volatile memory used for swap pages, the PVE balloon is absolutely useless. Best setup: enable balloon, but don't set a minimum memory, and let it deflate as necessary.  

### Subnets

| VLAN | IPv4 | IPv6 | DNS | Use |
|---|---|---|---|---|
| 1 (native) | `10.23.0.0/20` | `fd83:b84c:aa57:1::/64`, GUA by SLAAC | `regulad.internal`; `regulad-verizon-livingston.internal` (deprecated) | LAN |
| 8 | `10.23.128.0/20` | `fd83:b84c:aa57:8::/64` | N/A | Guest |
| 16 | `10.23.16.0/20` | `fd83:b84c:aa57:10::/64` | N/A | Corosync and Ceph |
| N/A | `10.131.80.0/24` | GUA | `pubsub.wahlecloud.oraclevcn.com` | OCI VCN |
| N/A | `100.64.0.0/10` | `fd7a:115c:a1e0::/48` | `ts.net` | Tailnet |

No VLAN above 16 exists. Homelab ULA: `fd83:b84c:aa57::/48`.

### VLAN IDs in addresses

IPv4: `10.23.0.0/20` OR'd with the VLAN ID in the third octet's upper 4 bits, so VLAN 8 is `1000`: `10.23.128.0/20`. VLAN 1 is native, `0000`; VLAN 16 takes `0001`, the slot VLAN 1 leaves free.

IPv6: the VLAN ID in hex as the homelab ULA's fourth hextet, so VLAN 16 is `fd83:b84c:aa57:10::/64`.

### Misc.

* rbd-pwl can't coexist with HA. when a node drops the exclusive lock won't come with it.
* NBD, NFS, & Ceph are woefully slow for random R/W over the 1GiB network.
* AppFlowy is a pile of shit.
