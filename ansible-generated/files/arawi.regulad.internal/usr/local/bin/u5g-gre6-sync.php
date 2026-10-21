#!/usr/local/bin/php -f
<?php
/*
 * u5g-gre6-sync.php
 *
 * Keeps the IPv6 addressing on the GRE tunnel to a UniFi U5G Backup in sync
 * with the carrier's rotating /64.
 *
 * Reads the modem's firmware-assigned gre1 address over SSH, uses it as the
 * tunnel remote, and rebuilds the local address as <that /64> + a fixed IID.
 * Nothing is written to the modem.
 *
 * Scope: tunnel addressing only. The gateway is left entirely alone --
 * pfSense derives the peer of a point-to-point GRE link on its own, and a
 * hardcoded value would go stale on every rotation because the modem's IID
 * is randomised per session.
 *
 * Idempotent: exits silently when the prefix has not moved.
 */

require_once("config.inc");
require_once("interfaces.inc");
require_once("filter.inc");
require_once("gwlb.inc");
require_once("system.inc");
require_once("util.inc");

/* ------------------------------------------------------------------ */
/* Configuration                                                       */
/* ------------------------------------------------------------------ */

$MODEM     = "10.23.2.229";                 /* U5G LAN address (reserved)  */
$SSH_USER  = "regulad";
$SSH_KEY   = "/root/.ssh/u5g";
$IF        = "opt4";                        /* pfSense internal iface name */
$LOCAL_IID = "be24:11ff:feaf:e1cf";         /* EUI-64 from vtnet0           */

/* ------------------------------------------------------------------ */

openlog("u5g-gre6", LOG_PID, LOG_USER);

function logmsg($m, $pri = LOG_NOTICE) {
        syslog($pri, $m);
        if (posix_isatty(STDOUT)) {
                echo "$m\n";
        }
}

function bail($m) {
        logmsg($m, LOG_ERR);
        exit(1);
}

/* --- 1. Read the modem's tunnel address --------------------------- */

$cmd = sprintf(
        "ssh -i %s -o BatchMode=yes -o ConnectTimeout=10 " .
        "-o StrictHostKeyChecking=accept-new %s@%s %s 2>/dev/null",
        escapeshellarg($SSH_KEY),
        escapeshellarg($SSH_USER),
        escapeshellarg($MODEM),
        escapeshellarg("ip -6 addr show dev gre1 scope global")
);

$out = shell_exec($cmd);

if (!preg_match('/inet6\s+([0-9a-f:]+)\/\d+/i', (string) $out, $m)) {
        /* Cellular down, modem rebooting, SSH key rejected -- all land here.
           Leave the existing config alone rather than tearing the tunnel down. */
        bail("no global IPv6 on modem gre1; leaving configuration untouched");
}

$remote = $m[1];

/* --- 2. Derive the local address ---------------------------------- */

$rb = @inet_pton($remote);
$ib = @inet_pton("::" . $LOCAL_IID);

if ($rb === false || strlen($rb) !== 16 || $ib === false) {
        bail("could not parse remote address '{$remote}'");
}

$prefix = inet_ntop(substr($rb, 0, 8) . str_repeat("\0", 8));
$local  = inet_ntop(substr($rb, 0, 8) . substr($ib, 8, 8));

if ($local === $remote) {
        bail("local IID collides with the modem's; pick a different LOCAL_IID");
}

/* --- 3. Locate the GRE tunnel ------------------------------------- */

$realif = get_real_interface($IF);

if (empty($realif)) {
        bail("could not resolve a real interface for '{$IF}'");
}

$gres   = config_get_path("gres/gre", []);
$greidx = null;

foreach ($gres as $i => $gre) {
        if (($gre['greif'] ?? null) === $realif) {
                $greidx = $i;
                break;
        }
}

/* Older configs may predate greif being populated; fall back to the
   tunnel's outer remote address, which is stable across rotations. */
if ($greidx === null) {
        foreach ($gres as $i => $gre) {
                if (($gre['remote-addr'] ?? null) === $MODEM) {
                        $greidx = $i;
                        logmsg("matched GRE by remote-addr {$MODEM} " .
                               "(greif was '" . ($gre['greif'] ?? '') . "')",
                               LOG_WARNING);
                        break;
                }
        }
}

if ($greidx === null) {
        bail("no gres/gre entry matching interface '{$realif}' or " .
             "remote-addr '{$MODEM}'");
}

$cur_local  = $gres[$greidx]['tunnel-local-addr6']  ?? null;
$cur_remote = $gres[$greidx]['tunnel-remote-addr6'] ?? null;
$cur_net    = $gres[$greidx]['tunnel-remote-net6']  ?? null;

if ($cur_local === $local && $cur_remote === $remote && $cur_net === "64") {
        exit(0);
}

logmsg("prefix change detected: " . ($cur_local ?? '(unset)') .
       " -> {$local} (via {$prefix}/64)");

/* --- 4. Drop stale global addresses ------------------------------- */

$lines = [];
exec("/sbin/ifconfig " . escapeshellarg($realif) . " inet6 2>/dev/null", $lines);

foreach ($lines as $line) {
        if (preg_match('/^\s*inet6\s+([0-9a-f:]+)/i', $line, $mm) &&
            stripos($mm[1], 'fe80') !== 0) {
                logmsg("removing stale address {$mm[1]} from {$realif}");
                mwexec("/sbin/ifconfig " . escapeshellarg($realif) .
                       " inet6 " . escapeshellarg($mm[1]) . " -alias");
        }
}

/* --- 5. Write the tunnel addressing ------------------------------- */

logmsg("gre[{$greidx}] local:  " . ($cur_local  ?? '(unset)') . " -> {$local}");
logmsg("gre[{$greidx}] remote: " . ($cur_remote ?? '(unset)') . " -> {$remote}");

config_set_path("gres/gre/{$greidx}/tunnel-local-addr6",  $local);
config_set_path("gres/gre/{$greidx}/tunnel-remote-addr6", $remote);
config_set_path("gres/gre/{$greidx}/tunnel-remote-net6",  "64");

/* If the assigned interface carries a static IPv6 of its own, keep it
   consistent. Interfaces set to 'none' take their addressing from the
   tunnel and are left alone. */
$if_type = config_get_path("interfaces/{$IF}/ipaddrv6");

if (!empty($if_type) && @inet_pton($if_type) !== false) {
        if ($if_type !== $local) {
                logmsg("interface {$IF} static IPv6: {$if_type} -> {$local}");
        }
        config_set_path("interfaces/{$IF}/ipaddrv6", $local);
        config_set_path("interfaces/{$IF}/subnetv6", "64");
}

write_config("u5g-gre6: carrier prefix moved to {$prefix}/64");

/* --- 6. Apply ----------------------------------------------------- */

/* Rebuild the tunnel first so the new addresses are live, then let
   pfSense re-derive the gateway, routes, rules and monitors from it. */
$gre = config_get_path("gres/gre/{$greidx}");
interface_gre_configure($gre);

interface_configure($IF, true);
system_routing_configure();
filter_configure_sync();
setup_gateways_monitor();

/* --- 7. Verify what actually landed ------------------------------- */

$live = [];
exec("/sbin/ifconfig " . escapeshellarg($realif) . " inet6 2>/dev/null", $live);

if (strpos(implode("\n", $live), $local) === false) {
        logmsg("local address {$local} is not present on {$realif} after " .
               "apply", LOG_ERR);
}

logmsg("applied: local={$local} remote={$remote}");
exit(0);
