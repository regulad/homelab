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

- [ ] `pfsense_nat_outbound` cannot parse IPv6 literals, and crashes logging an existing rule whose destination is one (`prefix '2603' not found in prefix map`); no issue found. Section `outbound_nat`
- [ ] `pfsense_rule` cannot take IPv6 literals; fixed on `master` after 0.7.1 by [#220](https://github.com/pfsensible/core/pull/220) ([#219](https://github.com/pfsensible/core/issues/219)), unreleased; our error text differs. Aliases `home_ipv6`, `tailnet_subnet_ipv6`
- [ ] `pfsense_cert` fails on two certificates with the same description (`Found multiple certs for descr`); no issue found. Section `certificates`
- [ ] `pfsense_gateway` rejects the link-local `tailscalerouter6` on the SLAAC LAN interface; no issue found. Section `gateways`
- [ ] `pfsense_gateway` does not model `interval`, `alert_interval`, `data_payload` or `gw_down_kill_states`; no issue checked. Section `gateways` owns every gateway instead
- [ ] `pfsense_dhcp_server` and `pfsense_dhcp_static` do not model `dnsregpolicy`, `earlydnsregpolicy`, the DDNS ports and secondary server, `filename32arm`, `filename64arm` or `uefihttpboot`, and write `ddnsclientupdates: allow` and `ddnsdomainkeyalgorithm: hmac-md5` where pfSense stores them empty; no issue checked. Section `dhcp` owns all of `dhcpd` instead
- [ ] `pfsense_shellcmd` manages only the Shellcmd package's commands and has no `afterbootupshellcmd` type; no issue checked. Section `boot_commands`
- [ ] `pfsense_dns_resolver` fails with `'PFSenseModule' object has no attribute 'obj'`, the error its "found multiple elements" path raises; six domain overrides here repeat a domain with a second server. No issue found. Section `dns_resolver`
- [ ] `pfsense_cert` and `pfsense_ca` cannot remove a stored private key; no issue found
- [ ] `pfsense_setup` rejects the stored `logincss` value `1e3f75;`; related: [#256](https://github.com/pfsensible/core/issues/256). Left unmanaged
- [ ] Rules, outbound NAT rules and routes are matched only by description; no issue found

## No module

Owned by `pfsense_config_section` sections until a module exists.

- [ ] WireGuard tunnels and peers (`wireguard`); feature request [#128](https://github.com/pfsensible/core/issues/128)
- [ ] GRE tunnel `U5G_GRE` (`gre`)
- [ ] Gateway groups `failover4` and `failover6` and the default gateways (`gateways`); module merged on `master` after 0.7.1 by [#250](https://github.com/pfsensible/core/pull/250), unreleased
- [ ] Limiters `guest_up` and `guest_down` (`limiters`)
- [ ] Router advertisements (`router_advertisements`)
- [ ] Kea custom configuration (`kea`, and inside `dhcp`)
- [ ] DNS Resolver ACLs (inside `dns_resolver`); [#116](https://github.com/pfsensible/core/pull/116) was closed in favour of a separate module that does not exist yet
- [ ] Cron jobs (`cron`); feature request [#265](https://github.com/pfsensible/core/issues/265)
- [ ] Dynamic DNS (`dyndns`)
- [ ] AutoConfigBackup (`autoconfigbackup`)
- [ ] SNMP (`snmp`); feature request [#164](https://github.com/pfsensible/core/issues/164)

- [ ] sudo rules (`sudo`)
- [ ] SSH (`ssh`)
- [ ] Serial console (`console`)
- [ ] System > Advanced settings without a module: powerd, crypto, RAM disks, state and table limits, NAT reflection, bogons, IPv6, offloads and the DHCPv6 DUID (`system_misc`, `system_firewall`, `system_network`)
- [ ] Filter settings beside the rules: `bypassstaticroutes` and the rule separators (`filter_extras`), and `diag/ipv6nat` (`diag`)
- [ ] Unused features kept empty: virtual IPs, PPPs, QinQ, IPsec, OpenVPN, proxy ARP, Wake-on-LAN (`unused_features`)

System Patches has no configuration in `config.xml`: no custom patches exist, and
its patches run from an `earlyshellcmd`.

## Left to pfSense and its packages

Each is written by pfSense or a package, so the repository does not own it.

- `system/earlyshellcmd`: the System Patches and WireGuard packages each install their own boot command
- `installedpackages/shellcmdsettings`: WireGuard's entry for its boot command
- `installedpackages/package`, `menu` and `service`: package bookkeeping, written by the installers
- `ifgroups`: the WireGuard interface group
- `dhcpbackend`
- `system/pkg_repo_conf_path`: pfSense's updater rewrites it on every upgrade
- Metadata: the config revision, `lastchange`, `revision`, `nextuid`, `nextgid`

## Not yet managed

- [ ] Web interface settings in `system/webgui` beyond `pfsense_setup`
- [ ] User fields `pfsense_user` does not model: `expires`, `ipsecpsk`, `dashboardcolumns`, `webguicss`
- [ ] Leftovers of uninstalled packages: `installedpackages/bandwidthd` (and `/usr/local/bandwidthd/`), `installedpackages/ntopng`, which stores a Redis password in the clear
- [ ] Dashboard widgets and `rrd`
