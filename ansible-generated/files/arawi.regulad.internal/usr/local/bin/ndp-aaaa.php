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
 * under each of those names and a PTR record back to the first, each with its
 * NDP entry's remaining lifetime as its TTL.
 *
 * The records live in Unbound's "local" view, the one LAN clients use;
 * guests' view refuses regulad.internal outright. A view that holds a name
 * answers every type of it from its own records, so each name's records in
 * the global zone, pfSense's A records among them, are copied in beside its
 * AAAA records. Every zone under the domain or ip6.arpa in that view is this
 * script's: each run removes them, so that queries fall back to the global
 * zone meanwhile, then adds the current records back.
 *
 * Run by cron every minute. pfSense's own reloads of Unbound drop the view's
 * runtime records, which the next run restores. With --dry-run it prints the
 * records it would publish and changes nothing.
 */

/* ------------------------------------------------------------------ */
/* Configuration                                                       */
/* ------------------------------------------------------------------ */

$UNBOUND_CONTROL = "/usr/local/sbin/unbound-control -c /var/unbound/unbound.conf";
$VIEW            = "local";
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

/* Run a command, feeding it $stdin; fail unless it exits 0. */
function run(string $command, string $stdin = ""): string
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
    $rc = proc_close($proc);
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

/* Parse unbound-control's list of records into [name, ttl, class, type, rdata]. */
function records(string $listing): array
{
    $records = [];
    foreach (explode("\n", $listing) as $line) {
        $fields = preg_split('/\s+/', trim($line), 5);
        if (count($fields) === 5) {
            $fields[0] = strtolower($fields[0]);
            $records[] = $fields;
        }
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

/* The IPv4 addresses each MAC holds. */
$ips_of_mac = [];
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
 * lease; Kea escapes commas within fields. */
$leases = [];
$lines = @file($KEA_LEASES, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [];
$header = $lines ? explode(",", array_shift($lines)) : [];
foreach ($lines as $line) {
    $fields = explode(",", $line);
    if (count($fields) >= count($header)) {
        $lease = array_combine($header, array_slice($fields, 0, count($header)));
        $leases[$lease["address"]] = $lease;
    }
}
foreach ($leases as $address => $lease) {
    $mac = strtolower($lease["hwaddr"] ?? "");
    if (is_mac($mac) && ($lease["state"] ?? "") === "0" && (int)($lease["expire"] ?? 0) > time()) {
        $ips_of_mac[$mac][$address] = true;
    }
}

/* The global zone's records under the domain, by name, and the names whose A
 * records point at each IPv4 address. */
$global = [];
$names_of_ip = [];
foreach (records(run("$UNBOUND_CONTROL list_local_data")) as [$name, $ttl, $class, $type, $rdata]) {
    if (str_ends_with($name, ".$DOMAIN")) {
        $global[$name][] = "$name $ttl $class $type $rdata";
        if ($type === "A") {
            $names_of_ip[$rdata][$name] = true;
        }
    }
}

/* Each named host's IPv6 addresses, with their NDP lifetimes. Link-local
 * addresses carry a scope, and arawi's own are permanent: neither is published. */
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
    ksort($names);
    $address = inet_ntop($binary);
    foreach (array_keys($names) as $name) {
        $aaaa[$name][$address] = max($ttl, $aaaa[$name][$address] ?? 0);
    }
    $ptr[$address] = [array_key_first($names), max($ttl, $ptr[$address][1] ?? 0)];
}

$wanted = [];
foreach ($aaaa as $name => $addresses) {
    array_push($wanted, ...$global[$name]);
    foreach ($addresses as $address => $ttl) {
        $wanted[] = "$name $ttl IN AAAA $address";
    }
}
foreach ($ptr as $address => [$name, $ttl]) {
    $wanted[] = reverse_name($address) . " $ttl IN PTR $name";
}

if ($dry_run) {
    echo implode("\n", $wanted), "\n";
    exit(0);
}

/* The view's zones this script owns, and the AAAA records they hold, to log
 * what changed. */
$owned = [];
foreach (explode("\n", run("$UNBOUND_CONTROL view_list_local_zones $VIEW")) as $line) {
    $zone = strtolower(preg_split('/\s+/', trim($line))[0] ?? "");
    if (str_ends_with($zone, ".$DOMAIN") || str_ends_with($zone, ".ip6.arpa.")) {
        $owned[] = $zone;
    }
}
$before = [];
foreach (records(run("$UNBOUND_CONTROL view_list_local_data $VIEW")) as [$name, , , $type, $rdata]) {
    if ($type === "AAAA" && str_ends_with($name, ".$DOMAIN")) {
        $before["$name $rdata"] = true;
    }
}
$after = [];
foreach ($aaaa as $name => $addresses) {
    foreach (array_keys($addresses) as $address) {
        $after["$name $address"] = true;
    }
}

foreach ($owned as $zone) {
    run("$UNBOUND_CONTROL view_local_zone_remove $VIEW " . escapeshellarg($zone));
}
if ($wanted) {
    run("$UNBOUND_CONTROL view_local_datas $VIEW", implode("\n", $wanted) . "\n");
}

/* A line per change: syslogd drops a message longer than its line. */
foreach (array_keys(array_diff_key($after, $before)) as $record) {
    syslog(LOG_INFO, "added $record");
}
foreach (array_keys(array_diff_key($before, $after)) as $record) {
    syslog(LOG_INFO, "removed $record");
}
