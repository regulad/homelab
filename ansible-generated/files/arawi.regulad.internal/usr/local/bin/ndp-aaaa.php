#!/usr/local/bin/php -f
<?php
/*
 * ndp-aaaa.php
 *
 * Publishes AAAA and PTR records in Unbound for every IPv6 address a named
 * host holds. SLAAC keeps no registry of who has which address, so the NDP
 * table serves as one: each neighbour's MAC is matched to the IPv4 addresses
 * it holds (the ARP table, and Kea's leases and reservations), and through
 * them to the names whose A records point there. Every IPv6 address on record
 * for that MAC, ULA or GUA, stable or temporary, then gets an AAAA record
 * under each of those names and a PTR record back to the first. Its TTL is
 * the shorter of its NDP entry's remaining lifetime and what is left of the
 * MAC's DHCP lease, or the NDP lifetime alone without a lease.
 *
 * The records are handled as pfSense handles its A records: global
 * local-data in an include file, /var/unbound/ndp-aaaa.conf, which the DNS
 * resolver's custom options include through a glob, so Unbound starts
 * without it. As kea2unbound does, the file is replaced only when it changes,
 * and Unbound fast-reloaded; a file Unbound would reject is put back first.
 *
 * Run by cron every minute. With --dry-run it prints the file it would write
 * and changes nothing.
 */

/* ------------------------------------------------------------------ */
/* Configuration                                                       */
/* ------------------------------------------------------------------ */

$UNBOUND_CONF    = "/var/unbound/unbound.conf";
$UNBOUND_CONTROL = "/usr/local/sbin/unbound-control -c $UNBOUND_CONF";
$CHECKCONF       = "/usr/local/sbin/unbound-checkconf $UNBOUND_CONF";
$INCLUDE         = "/var/unbound/ndp-aaaa.conf";
$DOMAIN          = "regulad.internal.";
$KEA_CONF        = "/usr/local/etc/kea/kea-dhcp4.conf";
$KEA_LEASES      = "/var/db/kea/dhcp4.leases";

/* ------------------------------------------------------------------ */

openlog("ndp-aaaa", LOG_PID, LOG_USER);
$dry_run = in_array("--dry-run", $argv, true);

function fail(string $message): never
{
    syslog(LOG_ERR, $message);
    fwrite(STDERR, "ndp-aaaa: $message\n");
    exit(1);
}

/* Run a command, feeding it $stdin; return its exit status and output. */
function run_status(string $command, string $stdin = ""): array
{
    $proc = proc_open($command, [0 => ["pipe", "r"], 1 => ["pipe", "w"], 2 => ["pipe", "w"]], $pipes);
    if (!is_resource($proc)) {
        fail("cannot run $command");
    }
    fwrite($pipes[0], $stdin);
    fclose($pipes[0]);
    $out = stream_get_contents($pipes[1]);
    $err = stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    return [proc_close($proc), $out, $err];
}

/* Run a command; fail unless it exits 0. */
function run(string $command, string $stdin = ""): string
{
    [$rc, $out, $err] = run_status($command, $stdin);
    if ($rc !== 0) {
        fail("$command exited $rc: " . trim($err));
    }
    return $out;
}

function neighbours(): array
{
    $ndp = json_decode(run("/usr/sbin/ndp -an --libxo json"), true);
    return $ndp["ndp"]["neighbor-cache"] ?? [];
}

function is_mac(string $mac): bool
{
    return preg_match('/^([0-9a-f]{2}:){5}[0-9a-f]{2}$/', $mac) === 1;
}

/* The name of an IPv6 address's PTR record. */
function reverse_name(string $address): string
{
    return implode(".", array_reverse(str_split(bin2hex(inet_pton($address))))) . ".ip6.arpa.";
}

/* The AAAA records an include file holds, as "name address". */
function aaaa_of(string $include): array
{
    preg_match_all('/^local-data: "(\S+) \d+ IN AAAA (\S+)"$/m', $include, $matches, PREG_SET_ORDER);
    $records = [];
    foreach ($matches as [, $name, $address]) {
        $records["$name $address"] = true;
    }
    return $records;
}

/* Wake every neighbour, so that the addresses of the hosts that are up are in
 * the table. A host answers an all-nodes echo from its address nearest the
 * echo's source, resolving that source from it first, so an echo from each of
 * arawi's own ULAs and GUAs, its permanent entries, brings in the hosts' own;
 * one from its link-local address would bring in only theirs. */
foreach (neighbours() as $neighbour) {
    $source = $neighbour["address"] ?? "";
    $interface = $neighbour["interface"] ?? "";
    if (isset($neighbour["expires_sec"]) || str_contains($source, "%")
        || preg_match('/^[A-Za-z0-9_.]+$/', $interface) !== 1 || @inet_pton($source) === false) {
        continue;
    }
    exec("/sbin/ping -6 -c 1 -W 1000 -S " . escapeshellarg($source) . " "
        . escapeshellarg("ff02::1%$interface") . " >/dev/null 2>&1");
}
usleep(500000);
$neighbours = neighbours();

/* The IPv4 addresses each MAC holds, and how long its DHCP lease has left. */
$ips_of_mac = [];
$lease_left = [];
$arp = json_decode(run("/usr/sbin/arp -an --libxo json"), true);
foreach ($arp["arp"]["arp-cache"] ?? [] as $entry) {
    $mac = strtolower($entry["mac-address"] ?? "");
    if (is_mac($mac) && isset($entry["ip-address"])) {
        $ips_of_mac[$mac][$entry["ip-address"]] = true;
    }
}
$kea = json_decode((string)@file_get_contents($KEA_CONF), true);
foreach ($kea["Dhcp4"]["subnet4"] ?? [] as $subnet) {
    foreach ($subnet["reservations"] ?? [] as $reservation) {
        $mac = strtolower($reservation["hw-address"] ?? "");
        if (is_mac($mac) && isset($reservation["ip-address"])) {
            $ips_of_mac[$mac][$reservation["ip-address"]] = true;
        }
    }
}
/* Kea's memfile appends a line per change, so an address's last line is its
 * lease; Kea escapes commas within fields. Its lease file cleanup moves the
 * older lines out of the file itself, so the files are read as Kea loads them
 * at startup: .completed, or else .2 and then .1, and the file itself last.
 * An infinite lease's expiry is far off, which leaves the NDP lifetime as the
 * TTL. */
$leases = [];
$lease_files = file_exists("$KEA_LEASES.completed")
    ? ["$KEA_LEASES.completed", $KEA_LEASES]
    : ["$KEA_LEASES.2", "$KEA_LEASES.1", $KEA_LEASES];
foreach ($lease_files as $lease_file) {
    $lines = @file($lease_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [];
    $header = $lines ? explode(",", array_shift($lines)) : [];
    foreach ($lines as $line) {
        $fields = explode(",", $line);
        if (count($fields) >= count($header)) {
            $lease = array_combine($header, array_slice($fields, 0, count($header)));
            $leases[$lease["address"]] = $lease;
        }
    }
}
$now = time();
foreach ($leases as $address => $lease) {
    $mac = strtolower($lease["hwaddr"] ?? "");
    $left = (int)($lease["expire"] ?? 0) - $now;
    if (is_mac($mac) && ($lease["state"] ?? "") === "0" && $left > 0) {
        $ips_of_mac[$mac][$address] = true;
        $lease_left[$mac] = max($left, $lease_left[$mac] ?? 0);
    }
}

/* The names whose global A records point at each IPv4 address. */
$names_of_ip = [];
foreach (explode("\n", run("$UNBOUND_CONTROL list_local_data")) as $line) {
    $fields = preg_split('/\s+/', trim($line), 5);
    if (count($fields) === 5 && $fields[3] === "A" && str_ends_with(strtolower($fields[0]), ".$DOMAIN")) {
        $names_of_ip[$fields[4]][strtolower($fields[0])] = true;
    }
}

/* Each named host's IPv6 addresses, with their TTLs. Link-local addresses
 * carry a scope, and arawi's own are permanent: neither is published. */
$aaaa = [];
$ptr = [];
foreach ($neighbours as $neighbour) {
    $address = $neighbour["address"] ?? "";
    $mac = strtolower($neighbour["mac-address"] ?? "");
    $ttl = $neighbour["expires_sec"] ?? null;
    $binary = str_contains($address, "%") ? false : @inet_pton($address);
    if ($binary === false || strlen($binary) !== 16 || !is_mac($mac) || !is_int($ttl) || $ttl <= 0) {
        continue;
    }
    if (ord($binary[0]) === 0xfe && (ord($binary[1]) & 0xc0) === 0x80) {
        continue;
    }
    $names = [];
    foreach (array_keys($ips_of_mac[$mac] ?? []) as $ip) {
        $names += $names_of_ip[$ip] ?? [];
    }
    if (!$names) {
        continue;
    }
    if (isset($lease_left[$mac])) {
        $ttl = min($ttl, $lease_left[$mac]);
    }
    ksort($names);
    $address = inet_ntop($binary);
    foreach (array_keys($names) as $name) {
        $aaaa[$name][$address] = max($ttl, $aaaa[$name][$address] ?? 0);
    }
    $ptr[$address] = [array_key_first($names), max($ttl, $ptr[$address][1] ?? 0)];
}

ksort($aaaa);
ksort($ptr);
$include = "# Written by /usr/local/bin/ndp-aaaa.php from the NDP table; do not edit.\nserver:\n";
foreach ($aaaa as $name => $addresses) {
    foreach ($addresses as $address => $ttl) {
        $include .= "local-data: \"$name $ttl IN AAAA $address\"\n";
    }
}
foreach ($ptr as $address => [$name, $ttl]) {
    $include .= "local-data: \"" . reverse_name($address) . " $ttl IN PTR $name\"\n";
}

if ($dry_run) {
    echo $include;
    exit(0);
}

$previous = @file_get_contents($INCLUDE);
if ($previous === $include) {
    exit(0);
}

/* Replace the file, keeping the previous one until Unbound accepts the new. */
$temporary = "$INCLUDE.new";
if (file_put_contents($temporary, $include) === false || !chmod($temporary, 0640)
    || !chgrp($temporary, "unbound")) {
    fail("cannot write $temporary");
}
if ($previous !== false && !copy($INCLUDE, "$INCLUDE.previous")) {
    fail("cannot keep $INCLUDE.previous");
}
if (!rename($temporary, $INCLUDE)) {
    fail("cannot replace $INCLUDE");
}
[$rc, , $err] = run_status($CHECKCONF);
if ($rc !== 0) {
    if ($previous !== false) {
        rename("$INCLUDE.previous", $INCLUDE);
    } else {
        unlink($INCLUDE);
    }
    fail("Unbound rejects the new records, kept the previous ones: " . trim($err));
}
@unlink("$INCLUDE.previous");
/* fast_reload keeps Unbound answering; no fallback to a full reload, which
 * would stop it on a configuration it rejects. */
run("$UNBOUND_CONTROL fast_reload");

/* A line per change, at notice, the least pfSense keeps in system.log;
 * syslogd drops a message longer than its line. */
$before = aaaa_of((string)$previous);
$after = aaaa_of($include);
foreach (array_keys(array_diff_key($after, $before)) as $record) {
    syslog(LOG_NOTICE, "added $record");
}
foreach (array_keys(array_diff_key($before, $after)) as $record) {
    syslog(LOG_NOTICE, "removed $record");
}
