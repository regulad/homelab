# TODO: arawi

What keeps `arawi`'s pfSense configuration from converging through the
`pfsense` role. Check an item off once a `--check` run reports it unchanged, or
once it is reported or fixed upstream in `pfsensible.core` (0.7.1 pinned).

## First converging run

- [x] Rules: name the 19 rules, as in `main.yml`, which `pfsense_aggregate` otherwise deletes and recreates; their IPv6 sources move to the `home_ipv6` and `tailnet_subnet_ipv6` aliases
- [ ] Private keys: drop the stored keys of the 5 certificates and 2 CAs other than the two `arawi.regulad.internal` certificates; `pfsense_cert` and `pfsense_ca` keep keys they are not given

## Upstream

Each bypassed for now by a `pfsense_config_section` section in `main.yml`, or
by an alias.

- [x] `pfsense_nat_outbound` cannot parse IPv6 networks: [#268](https://github.com/pfsensible/core/issues/268). Section `outbound_nat`
- [x] `pfsense_nat_outbound` crashes logging an existing rule with an IPv6 destination (`prefix '2603' not found in prefix map`): [#267](https://github.com/pfsensible/core/issues/267). Section `outbound_nat`
- [x] `pfsense_rule` cannot take IPv6 literals (`Cannot parse address`): [#219](https://github.com/pfsensible/core/issues/219), fixed on `master` after 0.7.1 by [#220](https://github.com/pfsensible/core/pull/220), unreleased. Aliases `home_ipv6`, `tailnet_subnet_ipv6`
- [x] `pfsense_cert` fails on two certificates with the same description (`Found multiple certs for descr`): selection by `refid` requested in [#274](https://github.com/pfsensible/core/issues/274). Section `certificates`
- [x] `pfsense_dns_resolver` crashes with `'PFSenseModule' object has no attribute 'obj'` when `sslcert` names a description two certificates share: [#269](https://github.com/pfsensible/core/issues/269). Section `dns_resolver`
- [x] `pfsense_dns_resolver` rejects IPv6 servers in domain overrides: [#270](https://github.com/pfsensible/core/issues/270). Section `dns_resolver`
- [x] `pfsense_gateway` rejects the link-local `tailscalerouter6` on the SLAAC LAN interface: [#271](https://github.com/pfsensible/core/issues/271). Section `gateways`
- [x] `pfsense_gateway` does not model `interval`, `alert_interval`, `data_payload` or `gw_down_kill_states`: [#277](https://github.com/pfsensible/core/issues/277). Section `gateways` owns every gateway instead
- [x] `pfsense_dhcp_server` and `pfsense_dhcp_static` write `ddnsclientupdates: allow` and `ddnsdomainkeyalgorithm: hmac-md5` where pfSense stores them empty: [#273](https://github.com/pfsensible/core/issues/273). Section `dhcp`
- [x] `pfsense_dhcp_server` and `pfsense_dhcp_static` do not model `dnsregpolicy`, `earlydnsregpolicy`, the DDNS ports and secondary server, `filename32arm`, `filename64arm`, `uefihttpboot` or `custom_kea_config`: [#278](https://github.com/pfsensible/core/issues/278). Section `dhcp` owns all of `dhcpd` instead
- [x] `pfsense_shellcmd` manages only the Shellcmd package's commands and has no `afterbootupshellcmd` type: [#279](https://github.com/pfsensible/core/issues/279). Section `boot_commands`
- [x] `pfsense_cert` and `pfsense_ca` cannot remove a stored private key: [#275](https://github.com/pfsensible/core/issues/275)
- [x] `pfsense_setup` rejects the stored `logincss` value `1e3f75;`: [#272](https://github.com/pfsensible/core/issues/272); related: [#256](https://github.com/pfsensible/core/issues/256). Left unmanaged
- [x] Rules, outbound NAT rules and routes are matched only by description: [#276](https://github.com/pfsensible/core/issues/276); related: [#222](https://github.com/pfsensible/core/issues/222), [#235](https://github.com/pfsensible/core/pull/235)

## No module

Owned by `pfsense_config_section` sections until a module exists.

- [x] WireGuard tunnels and peers (`wireguard`): feature request [#128](https://github.com/pfsensible/core/issues/128)
- [x] GRE tunnel `U5G_GRE` (`gre`): [#280](https://github.com/pfsensible/core/issues/280)
- [x] Gateway groups `failover4` and `failover6` and the default gateways (`gateways`): module merged on `master` after 0.7.1 by [#250](https://github.com/pfsensible/core/pull/250), unreleased
- [x] Limiters `guest_up` and `guest_down` (`limiters`): [#281](https://github.com/pfsensible/core/issues/281)
- [x] Router advertisements (`router_advertisements`): [#282](https://github.com/pfsensible/core/issues/282)
- [x] Kea custom configuration (`kea`, and inside `dhcp`): [#278](https://github.com/pfsensible/core/issues/278)
- [x] DNS Resolver ACLs (inside `dns_resolver`): [#283](https://github.com/pfsensible/core/issues/283), the separate module asked for when [#116](https://github.com/pfsensible/core/pull/116) was closed
- [x] Cron jobs (`cron`): feature request [#265](https://github.com/pfsensible/core/issues/265)
- [x] Dynamic DNS (`dyndns`): [#284](https://github.com/pfsensible/core/issues/284)
- [x] AutoConfigBackup (`autoconfigbackup`): [#285](https://github.com/pfsensible/core/issues/285)
- [x] SNMP (`snmp`): feature request [#164](https://github.com/pfsensible/core/issues/164)

Managed by sections, with nothing to report upstream; a `--check` run reports each
unchanged:

- [x] sudo rules (`sudo`)
- [x] SSH (`ssh`)
- [x] Serial console (`console`)
- [x] System > Advanced settings without a module: powerd, crypto, RAM disks, state and table limits, NAT reflection, bogons, IPv6, offloads and the DHCPv6 DUID (`system_misc`, `system_firewall`, `system_network`)
- [x] Filter settings beside the rules: `bypassstaticroutes` and the rule separators (`filter_extras`), and `diag/ipv6nat` (`diag`)
- [x] Unused features kept empty: virtual IPs, PPPs, QinQ, IPsec, OpenVPN, proxy ARP, Wake-on-LAN (`unused_features`)

System Patches has no configuration in `config.xml`: no custom patches exist, and
its patches run from an `earlyshellcmd`.

## Left to pfSense and its packages

Each is written by pfSense or a package, so the repository does not own it.

- `system/earlyshellcmd`: the System Patches and WireGuard packages each install their own boot command; only the `/usr/local/bin/unbound-rpz-restore.sh` entry is the repository's, in section `unbound_rpz_boot`
- `installedpackages/shellcmdsettings`: WireGuard's entry for its boot command
- `installedpackages/package`, `menu` and `service`: package bookkeeping, written by the installers
- `ifgroups`: the WireGuard interface group
- `dhcpbackend`
- `system/pkg_repo_conf_path`: pfSense's updater rewrites it on every upgrade
- Metadata: the config revision, `lastchange`, `revision`, `nextuid`, `nextgid`

## Not yet managed

- [ ] Web interface settings in `system/webgui` beyond `pfsense_setup`
- [ ] User fields `pfsense_user` does not model: `expires`, `ipsecpsk`, `dashboardcolumns`, `webguicss`; requested in [#286](https://github.com/pfsensible/core/issues/286)
- [ ] Leftovers of uninstalled packages: `installedpackages/bandwidthd` (and `/usr/local/bandwidthd/`), `installedpackages/ntopng`, which stores a Redis password in the clear
- [ ] Dashboard widgets and `rrd`
