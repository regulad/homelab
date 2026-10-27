# softether

SoftEther VPN Server for `softether`, whose one hub, `VPN`, is a local bridge
onto VLAN 1: VPN clients join the LAN as hosts of their own, with DHCP from
arawi. The role builds the server from upstream's source and runs it from
`/usr/local/vpnserver` under systemd. Its configuration is state, not a file
the role writes; see [Configuration](#configuration).

## Why 4.x Stable, and not 5.x

The server runs SoftEther's **Stable edition (4.x)**, pinned to the source
tarball of a release by SHA-256 (`softether_version`, `softether_source_sha256`).
The **Developer Edition (5.x) is ignored until its Windows releases are
code-signed** and Microsoft Defender stops flagging them:

- Defender, and BitDefender too, quarantines the 5.x Windows executables
  (`vpnclient.exe`, `vpnserver.exe`, `vpncmd.exe`) and their services, as
  `Program:Win32/Wacapew.C!ml`, `Trojan:Win32/KepavII!rfn` and
  `Trojan:Win64/Rhadamanthys.GA!MTB`. This started with build 5187 (September
  2024), the newest Windows release.
- Upstream calls these heuristic false positives, will not change the code to
  avoid them, and says its releases may not be signed
  ([ANTIVIRUS.md](https://github.com/SoftEtherVPN/SoftEtherVPN/blob/master/ANTIVIRUS.md),
  [#2183](https://github.com/SoftEtherVPN/SoftEtherVPN/issues/2183)). The 4.x
  Windows releases are signed, and Defender passes them.
- The Windows clients therefore stay on 4.x. A 4.x client would connect to a
  5.x server from build 5180 on
  ([#1392](https://github.com/SoftEtherVPN/SoftEtherVPN/issues/1392)), but 4.x's
  GUI Server Manager has problems with 5.x servers, and 5.x's own is one of the
  flagged executables. So the server stays on 4.x as well.

**Revisit** once the 5.x Windows releases are signed and no longer flagged.

## Why built from source

No distribution packages 4.x, and the one package there is is not fit to use:

- Ubuntu's `softether-vpn` (universe, 21.04 to 26.04) is a 2020 snapshot of
  the 5.x Developer Edition, 5.01.9674. Ubuntu 26.10 removed it because it no
  longer builds; Debian dropped it from testing in 2024.
- Fedora and EPEL have no SoftEther package.

The container runs **Ubuntu 24.04**, whose GCC 13 builds 4.44 as upstream wrote
it. GCC 14 rejects its implicit declarations and GCC 15 defaults to C23, so on
newer releases it would need `-fpermissive -std=gnu18`. 24.04 has security
updates until May 2029.

## Configuration

`vpn_server.config` lives beside the server in `/usr/local/vpnserver`, and the
server rewrites it every few minutes and on shutdown. It holds the server's
certificate and key, the administrator and hub password hashes, the DDNS key
that owns the DDNS and VPN Azure names, and the RADIUS secret. The role never
writes it: it was moved by hand, with both servers stopped. The weekly vzdump
backs it up.

It sets `RadiusRequireMessageAuthenticator true` on the hub. The server then
signs its RADIUS requests with a Message-Authenticator and requires one in
every reply, as FreeRADIUS 3.2's BlastRADIUS defaults expect: the requests
carry `Proxy-State`, and unsigned ones are dropped without an answer.

The unit starts the server only once the file is there
(`ConditionPathExists`): without it the server would write a default
configuration, with an empty administrator password, and listen on the LAN.

## Upstream's systemd unit: security theatre, not adopted

The Stable repository ships a unit with a "Hardening" section,
[`systemd/softether-vpnserver.service`](https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/blob/master/systemd/softether-vpnserver.service):
`PrivateTmp`, `ProtectHome`, `ProtectSystem=full`, `ReadOnlyDirectories=/`
with `/opt/vpnserver` writable, and a `CapabilityBoundingSet` that keeps
`CAP_SYS_ADMIN` and `CAP_SETUID` for a server running as root.

Every one of those protections is a mount in the service's own mount
namespace, and `CAP_SYS_ADMIN` lets the process remount or unmount them. systemd
says so itself: a process that keeps `CAP_SYS_ADMIN`, with no system call filter
against mounting, "can undo the effect" of these settings
([systemd.exec(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html)).
A bounding set that includes the broadest capability there is bounds little. At
best the section does nothing; at worst it suggests a confinement that is not
there. So the role's unit carries none of it. The server runs as root, which a
hub's local bridge needs anyway for its packet socket and promiscuous mode; it
is confined by the unprivileged container it runs in.

## Upgrading

Set `softether_version` and `softether_release_date` to the new Stable release
and `softether_source_sha256` to its source tarball's SHA-256. The role builds
it in a directory of its own, installs the binaries and restarts the server.
