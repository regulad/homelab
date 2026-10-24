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

ULA: `fd83:b84c:aa57::/48`

- `10.23.0.0/20`: Entire (untagged) network (no VLAN; VLAN 1 
  - `0000hhhh hhhhhhhh`
  - `10.23.0.1`: `cr1000b.home.arpa`
- VLAN 16: `10.23.16.0/20` `fd83:b84c:aa57:0010:::/64`: PVE corosync intercom & Ceph (VLAN 16)
  - `0001hhhh hhhhhhhh`
  - `10.23.16.3` `prodingus`

regulad-verizon-livingston.internal - 10.23.0.0/20 (router/DNS server; fixed IP 10.23.0.1) + IPv6 (dynamic block, globally routable)

pubsub.wahlecloud.oraclevcn.com - 10.131.80.0/24 (router/DNS server; fixed IP 10.131.80.239) + IPv6 (fixed block, globally routable)

tail11540.ts.net - 100.64.0.0/10 + fd7a:115c:a1e0::/48 

### VLANs

Do not use VLAN tags outside of 16-31. 
IPv4: upper 4 bits of third octet encode VLAN tag So 0d10 -> 0b1010: 10.23.160.0/20 network. IPv6: verbatim in fourth stanza. 0d10 -> 0x000a fd83:b84c:aa57:000a::1/64

Previously, interfaces had tagged subinterfaces. Now, the bridge has the tagged subinterface. This is much better: STP actually works now. Previosuly, VLAN 1 carried the traffic VLAN 16 now carries. However, VLAN 1 is hardcoded to be the self tag for vlan-aware bridges. Since we only use VLAN-unaware bridges, it had to be changed. 16 was chosen to be consistent with the IPv4 addresses, leaving VLANs 1-15 unused.

### Misc.

* rbd-pwl can't coexist with HA. when a node drops the exclusive lock won't come with it.
* NBD, NFS, & Ceph are woefully slow for random R/W over the 1GiB network.
* AppFlowy is a pile of shit.
