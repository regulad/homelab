"""How the playbooks and each stage's ansible.cfg wire the acceptance system
together, read from their text: the callback enabled, the refresh last, and
every declaration of written paths literal.

Tests named for a gap record what the repository does today where the triage
of 2026-11-08 found it wanting; a fix changes them on purpose."""

import configparser
import os
import re
import unittest

import support

STAGES = ("ansible-generated", "ansible-hardware")
ANSIBLE_DIRECTORIES = ("ansible-common", "ansible-generated", "ansible-hardware")


def read(relative):
    with open(os.path.join(support.REPOSITORY, relative)) as handle:
        return handle.read()


def plays(text):
    """A playbook's plays, as the text of each top-level list item."""
    return [chunk for chunk in re.split(r"(?m)^(?=- )", text) if chunk.startswith("- ")]


REFRESH_PLAYBOOK = "ansible-common/playbooks/aide-refresh.yml"
HOLD_PLAYBOOK = "ansible-common/playbooks/aide-hold.yml"


def playbooks():
    """Every playbook of the three Ansible directories, relative to the repository."""
    for directory in ANSIBLE_DIRECTORIES:
        folder = os.path.join(support.REPOSITORY, directory, "playbooks")
        for name in sorted(os.listdir(folder)):
            if name.endswith(".yml"):
                yield "%s/playbooks/%s" % (directory, name)


def yaml_files():
    for directory in ANSIBLE_DIRECTORIES:
        for root, directories, files in os.walk(os.path.join(support.REPOSITORY, directory)):
            directories[:] = [d for d in directories if d not in ("collections", "__pycache__")]
            for name in files:
                if name.endswith((".yml", ".yaml")):
                    yield os.path.join(root, name)


class Configuration(unittest.TestCase):
    def test_each_stage_enables_the_callback_with_its_modules_arguments(self):
        for stage in STAGES:
            parser = configparser.ConfigParser(interpolation=None)
            parser.read_string(read(stage + "/ansible.cfg"))
            defaults = parser["defaults"]
            self.assertEqual(defaults["callback_plugins"], "../ansible-common/plugins/callback", stage)
            self.assertIn("aide_written", [name.strip() for name in defaults["callbacks_enabled"].split(",")], stage)
            self.assertEqual(defaults["inject_invocation"], "true", stage)


class SitePlaybooks(unittest.TestCase):
    def test_each_stage_imports_the_shared_plays_first(self):
        for stage in STAGES:
            first = plays(read(stage + "/playbooks/site.yml"))[0]
            self.assertIn("ansible.builtin.import_playbook: ../../ansible-common/playbooks/site.yml", first, stage)

    def test_each_stage_ends_both_playbooks_with_the_refresh(self):
        for stage in STAGES:
            for playbook in ("site.yml", "maintenance.yml"):
                last = plays(read("%s/playbooks/%s" % (stage, playbook)))[-1]
                self.assertIn("ansible.builtin.import_playbook: ../../ansible-common/playbooks/aide-refresh.yml", last,
                              "%s/%s" % (stage, playbook))

    def test_the_refresh_play(self):
        play, release = plays(read(REFRESH_PLAYBOOK))
        for each in (play, release):
            self.assertIn("hosts: debian:ubuntu:rhel", each)
            self.assertIn("gather_facts: false", each)
            self.assertIn("become: true", each)
            self.assertIn("tags: [always, aide, aide_refresh]", each)
        self.assertRegex(play, r"import_role:\s+name: aide\s+tasks_from: refresh")
        # The hold on each host's check ends after the refresh, on every host,
        # those the refresh ended at once included, and starts any check held.
        self.assertRegex(release, r"argv: \[/usr/local/bin/aide-report, --run-ended\]\s+"
                                  r"removes: /usr/local/bin/aide-report")
        self.assertIn("changed_when: \"'Started' in aide_run_ended.stdout\"", release)

    def test_each_run_holds_the_daily_check_from_its_start(self):
        (hold,) = plays(read(HOLD_PLAYBOOK))
        self.assertIn("hosts: debian:ubuntu:rhel", hold)
        self.assertIn("become: true", hold)
        # Under any --tags, as the refresh that ends it.
        self.assertIn("tags: [always, aide, aide_hold]", hold)
        self.assertRegex(hold, r"argv: \[/usr/local/bin/aide-report, --run-started\]\s+"
                               r"removes: /usr/local/bin/aide-report\s+changed_when: false")
        for shared in ("ansible-common/playbooks/site.yml", "ansible-common/playbooks/maintenance.yml"):
            first = plays(read(shared))[0]
            self.assertIn("ansible.builtin.import_playbook: aide-hold.yml", first, shared)
        for path in playbooks():
            expected = 1 if path in ("ansible-common/playbooks/site.yml", "ansible-common/playbooks/maintenance.yml") else 0
            self.assertEqual(read(path).count("import_playbook: aide-hold.yml"), expected, path)

    def test_the_refresh_once_in_one_playbook(self):
        for path in playbooks():
            text = read(path)
            expected = 1 if path == REFRESH_PLAYBOOK else 0
            self.assertEqual(text.count("tasks_from: refresh"), expected, path)
            imports = text.count("ansible-common/playbooks/aide-refresh.yml")
            stage_playbook = path.split("/")[0] in STAGES and path.endswith(("/site.yml", "/maintenance.yml"))
            self.assertEqual(imports, 1 if stage_playbook else 0, path)

    def test_the_first_baseline_starts_from_the_refresh_once_the_run_has_written_everything(self):
        main = read("ansible-common/roles/aide/tasks/main.yml")
        # The role installs the unit, and starts it nowhere.
        self.assertIn("loop: [aide-report.service, aide-baseline.service]", main)
        self.assertNotIn("name: aide-baseline.service", main)
        self.assertNotIn("First baseline", main)
        refresh = read("ansible-common/roles/aide/tasks/refresh.yml")
        self.assertRegex(refresh, r"- name: First baseline\s+ansible\.builtin\.systemd_service:\s+"
                                  r"name: aide-baseline\.service\s+state: started\s+no_block: true\s+daemon_reload: true")
        order = [refresh.index(name) for name in ("- name: Nothing to refresh", "- name: First baseline",
                                                  "- name: AIDE's baseline for them")]
        self.assertEqual(order, sorted(order))

    def test_the_daily_report_at_a_fixed_time_of_the_hosts_own(self):
        # RandomizedDelaySec= counts a missed check's delay from the boot, so a
        # reboot before the host's delay put its report off by the whole delay.
        timer = read("ansible-common/roles/aide/templates/aide-report.timer.j2")
        self.assertRegex(timer, r"(?m)^OnCalendar=\*-\*-\* \{\{ .*aide_report_minute.* \}\}:00 UTC$")
        self.assertRegex(timer, r"(?m)^Persistent=true$")
        self.assertNotIn("RandomizedDelaySec", timer)
        defaults = read("ansible-common/roles/aide/defaults/main.yml")
        self.assertRegex(defaults, r"(?m)^aide_report_minute: .*inventory_hostname.* % 1440 \}\}\"$")

    def test_the_units_directory_is_one_setting(self):
        defaults = read("ansible-common/roles/aide/defaults/main.yml")
        self.assertRegex(defaults, r"(?m)^aide_unit_dir: /usr/local/lib/systemd/system$")
        for path in ("ansible-common/roles/aide/tasks/main.yml", "ansible-common/roles/aide/tasks/refresh.yml"):
            self.assertNotIn("/usr/local/lib/systemd/system", read(path), path)


class AideRole(unittest.TestCase):
    def test_reads_the_connecting_users_home_as_that_user_whatever_the_host_sets(self):
        # dodo's host_vars set ansible_become, a variable, which outranks the
        # become keyword; a task's own variable outranks the host's.
        main = read("ansible-common/roles/aide/tasks/main.yml")
        self.assertRegex(main, r"- name: Read the connecting user's home\s+ansible\.builtin\.command: printenv HOME\s+"
                               r"become: false\s+vars:\s+ansible_become: false\s")


def task(text, name):
    """The text of a task in a tasks file, from its name to the next task's."""
    match = re.search(r"(?ms)^( *)- name: %s\n.*?(?=^\1- name: |\Z)" % re.escape(name), text)
    return match.group(0) if match else ""


class AppArmorCache(unittest.TestCase):
    """snapd compiles its snaps' profiles with a parser of its own, which
    skip-cache in /etc/apparmor/parser.conf does not reach, and loads them at
    each boot from the cache it writes in /var/cache/apparmor."""

    MAIN = "ansible-common/roles/aide/tasks/main.yml"

    def test_a_tmpfs_where_snapd_is_installed(self):
        unit = read("ansible-common/roles/aide/files/var-cache-apparmor.mount")
        self.assertRegex(unit, r"(?m)^What=tmpfs$")
        self.assertRegex(unit, r"(?m)^Where=/var/cache/apparmor$")
        self.assertRegex(unit, r"(?m)^Type=tmpfs$")
        options = re.search(r"(?m)^Options=(.*)$", unit).group(1).split(",")
        for option in ("noexec", "nosuid", "nodev"):
            self.assertIn(option, options)
        # What it holds is lost at its unmount either way.
        self.assertRegex(unit, r"(?m)^LazyUnmount=yes$")
        self.assertRegex(unit, r"(?m)^WantedBy=local-fs\.target$")
        main = read(self.MAIN)
        copy = task(main, "AppArmor's policy cache in memory, where snapd keeps one")
        self.assertRegex(copy, r"src: var-cache-apparmor\.mount\n")
        self.assertRegex(copy, r"dest: \"\{\{ aide_unit_dir \}\}/var-cache-apparmor\.mount\"")
        self.assertIn("'snapd' in ansible_facts.packages", copy)
        started = task(main, "AppArmor's policy cache mounted, and at each boot")
        self.assertRegex(started, r"name: var-cache-apparmor\.mount\s+enabled: true\s+state: started")
        self.assertIn("'snapd' in ansible_facts.packages", started)

    def test_the_cache_on_disk_removed_unless_the_tmpfs_holds_it(self):
        # Removing the tmpfs's mount point would fail, and what it holds
        # outlives no boot; the cache on disk is removed before the tmpfs
        # covers it, rather than left hidden below.
        main = read(self.MAIN)
        removed = task(main, "AppArmor's old policy cache removed")
        self.assertRegex(removed, r"state: absent")
        self.assertIn("aide_apparmor_cache.stdout | trim != 'tmpfs'", removed)
        self.assertLess(main.index("- name: AppArmor's old policy cache removed"),
                        main.index("- name: AppArmor's policy cache mounted, and at each boot"))


class NoexecUnits(unittest.TestCase):
    """A path taken off the noexec role's lists stays bound until its unit goes,
    and its bind makes it a mount point, which aide-report keeps AIDE out of."""

    MAIN = "ansible-common/roles/noexec/tasks/main.yml"

    def test_units_the_role_made_for_paths_no_longer_listed_go(self):
        main = read(self.MAIN)
        header = read("ansible-common/roles/noexec/templates/bind.mount.j2").splitlines()[0]
        self.assertTrue(header.startswith("# Managed by Ansible (noexec). "))
        found = task(main, "Find the mount units the role made")
        self.assertIn("paths: /etc/systemd/system", found)
        self.assertIn(r'contains: "^# Managed by Ansible \\(noexec\\)\\. "', found)
        named = task(main, "Name the units of paths no longer listed")
        self.assertIn("noexec_stale_units: \"{{ noexec_made.files | map(attribute='path') | map('basename')"
                      " | difference(noexec_units.stdout.split()) }}\"", named)
        stale = 'loop: "{{ noexec_stale_units }}"'
        # Each unmounts lazily by its template's LazyUnmount=, rather than
        # failing while something holds its path open.
        self.assertNotIn("line: LazyUnmount", main)
        stopped = task(main, "Their units stopped and disabled")
        self.assertRegex(stopped, r"state: stopped\s+enabled: false\s+daemon_reload: true")
        self.assertIn(stale, stopped)
        removed = task(main, "Their unit files removed")
        self.assertRegex(removed, r"path: /etc/systemd/system/\{\{ item \}\}\s+state: absent")
        self.assertIn(stale, removed)
        order = [main.index("- name: " + name) for name in (
            "Name the units of paths no longer listed", "Their units stopped and disabled",
            "Their unit files removed")]
        self.assertEqual(order, sorted(order))

    def test_binds_unmount_lazily(self):
        # Bound over itself, a path shows the same files once unbound.
        unit = configparser.ConfigParser(interpolation=None, strict=False)
        unit.read_string(read("ansible-common/roles/noexec/templates/bind.mount.j2"))
        self.assertEqual(unit["Mount"]["Options"], "bind,noexec")
        self.assertEqual(unit["Mount"]["LazyUnmount"], "yes")

    def test_services_that_alone_use_a_path_require_its_bind(self):
        defaults = read("ansible-common/roles/noexec/defaults/main.yml")
        for service in ("dpkg-db-backup.service", "apt-daily.service", "apt-daily-upgrade.service"):
            self.assertIn("  %s: [/var/backups]\n" % service, defaults)
        self.assertIn("noexec_services_host: {}\n", defaults)
        main = read(self.MAIN)
        gathered = task(main, "Gather the services that alone use the paths, each with those of its paths bound")
        self.assertIn("map('intersect', noexec_bind_paths)", gathered)
        self.assertIn('noexec_services_all: "{{ noexec_services | combine(noexec_services_host) }}"', gathered)
        dropin = task(main, "Services requiring their paths' binds")
        self.assertIn("src: requires.conf.j2", dropin)
        self.assertIn("dest: /etc/systemd/system/{{ item.key }}.d/noexec-paths.conf", dropin)
        self.assertIn("notify: Reload the units", dropin)
        template = read("ansible-common/roles/noexec/templates/requires.conf.j2")
        self.assertTrue(template.startswith("# Managed by Ansible (noexec). "))
        self.assertRegex(template, r"(?m)^\[Unit\]\nRequiresMountsFor=\{\{ item\.value \| join\(' '\) \}\}$")

    def test_drop_ins_of_services_no_longer_listed_go_before_any_bind_stops(self):
        # A service requiring a bind that is stopped is stopped with it.
        main = read(self.MAIN)
        found = task(main, "Find the drop-ins the role made")
        self.assertIn("patterns: noexec-paths.conf", found)
        self.assertIn(r'contains: "^# Managed by Ansible \\(noexec\\)\\. "', found)
        removed = task(main, "Drop-ins of services no longer listed removed")
        self.assertIn("state: absent", removed)
        self.assertIn("difference(noexec_service_paths.keys()", removed)
        self.assertLess(main.index("- name: Drop-ins of services no longer listed removed"),
                        main.index("- name: Their units stopped and disabled"))
        self.assertIn("daemon_reload: true", task(main, "Their units stopped and disabled"))


class GoTelemetry(unittest.TestCase):
    """Go's default telemetry mode, local, counts each go command in root's
    .config/go/telemetry, which AIDE watches; off counts nothing."""

    MAIN = "ansible-common/roles/go_telemetry/tasks/main.yml"

    def test_root_s_mode_is_off_where_go_is_installed(self):
        main = read(self.MAIN)
        self.assertIn("path: /usr/bin/go", task(main, "Find Go"))
        directory = task(main, "Go's telemetry directory")
        self.assertRegex(directory, r"path: /root/\.config/go/telemetry\s+state: directory")
        mode = task(main, "Go's telemetry off")
        # Go reads the first word of the file, whitespace trimmed, as the mode.
        self.assertIn('content: "off\\n"', mode)
        self.assertIn("dest: /root/.config/go/telemetry/mode", mode)
        for written in (directory, mode):
            self.assertIn("when: go_telemetry_go.stat.exists", written)

    def test_its_play_runs_on_every_linux_host_before_the_aide_play(self):
        site = read("ansible-common/playbooks/site.yml")
        play = site[site.index("- name: Go's telemetry"):site.index("- name: File integrity")]
        self.assertIn("hosts: debian:ubuntu:rhel", play)
        self.assertIn("tags: [go_telemetry]", play)
        self.assertIn("- go_telemetry", play)


class AuditdSettings(unittest.TestCase):
    def test_space_left_action_out_of_reach_of_oci_linux_configs_rewrite(self):
        # oci-linux-config's passwd_mgmt.sh, which its %post runs at each
        # install and upgrade, runs
        #   sed -i "/^space_left_action = / s/=.*/= email/" /etc/audit/auditd.conf
        # auditd splits each line on runs of spaces, so two before the =
        # read the same to auditd and fall outside the sed's address.
        template = read("ansible-common/roles/auditd/templates/auditd.conf.j2")
        lines = [line for line in template.splitlines() if line.split()[:1] == ["space_left_action"]]
        self.assertEqual(len(lines), 1)
        self.assertEqual(lines[0].split(" "), ["space_left_action", "", "=", "SYSLOG"])
        self.assertIsNone(re.search(r"^space_left_action = ", lines[0]))


def timer_files():
    """Every systemd timer the repository installs, as a file or a template."""
    skipped = {".git", ".claude", "collections", ".terraform", "snapshot"}
    for top, directories, files in os.walk(support.REPOSITORY):
        directories[:] = [name for name in directories if name not in skipped]
        for name in files:
            if name.endswith((".timer", ".timer.j2")):
                yield os.path.relpath(os.path.join(top, name), support.REPOSITORY)


class Timers(unittest.TestCase):
    """systemd adds RandomizedDelaySec= to a run a Persistent= timer missed while
    the host was down counting from the boot, after moving the missed calendar
    time up to it (systemd#21166), so a reboot put a run off by up to the whole
    delay. Timers that spread hosts across a period do so with a fixed time of
    each host's own."""

    WEEKDAY = r"\['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'\]\[%s \| int // 1440\]"

    def test_no_persistent_timer_draws_a_random_delay(self):
        paths = list(timer_files())
        self.assertIn("ansible-common/roles/restic/templates/restic.timer.j2", paths)
        for path in paths:
            timer = read(path)
            if re.search(r"(?m)^Persistent=(true|yes)$", timer):
                self.assertNotRegex(timer, r"(?m)^(RandomizedDelaySec|FixedRandomDelay)=", path)

    def test_the_weekly_scan_at_a_fixed_time_of_the_hosts_own(self):
        timer = read("ansible-common/roles/clamav/templates/clamav-scan.timer.j2")
        self.assertRegex(timer, r"(?m)^OnCalendar=\{\{ %s \}\} \*-\*-\* \{\{ .*clamav_scan_minute.* \}\}:00 UTC$"
                                % (self.WEEKDAY % "clamav_scan_minute"))
        self.assertRegex(timer, r"(?m)^Persistent=true$")
        defaults = read("ansible-common/roles/clamav/defaults/main.yml")
        # A seed of its own: the name alone would give the scan the daily
        # report's time of day.
        self.assertRegex(defaults, r"(?m)^clamav_scan_minute: \"\{\{ \(\(inventory_hostname ~ ' clamav-scan'\) "
                                   r"\| hash\('sha1'\)\)\[:8\] \| int\(base=16\) % 10080 \}\}\"$")
        scan = read("ansible-common/roles/clamav/tasks/scan.yml")
        self.assertRegex(task(scan, "Weekly scan's timer"), r"ansible\.builtin\.template:\s+src: clamav-scan\.timer\.j2")

    def test_each_backup_job_at_a_fixed_time_of_its_own(self):
        timer = read("ansible-common/roles/restic/templates/restic.timer.j2")
        self.assertIn("{% set minute = ((inventory_hostname ~ ' restic-' ~ item.key) | hash('sha1'))[:8]"
                      " | int(base=16) % restic_job_periods[item.value.period] %}", timer)
        self.assertRegex(timer, r"(?m)^OnCalendar=\{\{ \['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'\]"
                                r"\[minute // 1440\] ~ ' ' if item\.value\.period == 'weekly' else '' \}\}"
                                r"\*-\*-\* \{\{ .*minute.* \}\}:00 UTC$")
        self.assertRegex(timer, r"(?m)^Persistent=true$")
        jobs = read("ansible-common/roles/restic/tasks/jobs.yml")
        self.assertRegex(jobs, r"restic_job_periods:\s+daily: 1440\s+weekly: 10080\s")


class RefreshTasks(unittest.TestCase):
    def test_runs_aide_report_with_the_paths_then_the_units(self):
        refresh = read("ansible-common/roles/aide/tasks/refresh.yml")
        self.assertIn("{{ ['/usr/local/bin/aide-report', '--refresh'] + aide_written\n"
                      "         + (['--units'] + aide_written_units if aide_written_units else []) }}", refresh)
        self.assertIn("aide_written_file: \"{{ lookup('ansible.builtin.env', 'AIDE_WRITTEN_DIR') ~ '/' ~ inventory_hostname }}\"",
                      refresh)
        self.assertIn("lookup('ansible.builtin.file', aide_written_file ~ '.units', errors='ignore')", refresh)


def exclude_paths():
    """aide_exclude_paths' literal entries, from the aide role's defaults."""
    lines = read("ansible-common/roles/aide/defaults/main.yml").splitlines()
    start = lines.index("aide_exclude_paths:") + 1
    entries = []
    for line in lines[start:]:
        if line and not line.startswith((" ", "#")):
            break
        match = re.match(r"^  - (\S+)$", line)
        if match:
            entries.append(match.group(1).strip("\"'"))
    return entries


class Exclusions(unittest.TestCase):
    def test_the_list_is_read(self):
        self.assertIn("/var/lib/aide", exclude_paths())

    def test_systemds_timer_stamps(self):
        # Empty files whose times are all they hold: a persistent timer's stamp
        # is made at its first run, often after the run that started it.
        self.assertIn("/var/lib/systemd/timers", exclude_paths())


class RecordsConsumed(unittest.TestCase):
    def test_removes_the_two_files_of_records_on_the_controller_outside_check_mode(self):
        refresh = read("ansible-common/roles/aide/tasks/refresh.yml")
        self.assertRegex(refresh, r"- name: The records consumed\s+ansible\.builtin\.file:\s+"
                                  r"path: \"\{\{ lookup\('ansible\.builtin\.env', 'AIDE_WRITTEN_DIR'\) ~ '/' ~ "
                                  r"inventory_hostname ~ item \}\}\"\s+state: absent\s+loop: \[\"\", \.units\]\s+"
                                  r"delegate_to: localhost\s+become: false\s+vars:\s+ansible_become: false\s+"
                                  r"when: not ansible_check_mode\s*$")

    def test_after_the_refresh(self):
        refresh = read("ansible-common/roles/aide/tasks/refresh.yml")
        self.assertLess(refresh.index("- name: AIDE's baseline for them"), refresh.index("- name: The records consumed"))


class Declarations(unittest.TestCase):
    def declarations(self):
        found = []
        for path in yaml_files():
            with open(path) as handle:
                for number, line in enumerate(handle, 1):
                    if re.match(r"^\s*aide_writes:", line):
                        found.append((os.path.relpath(path, support.REPOSITORY), number, line.strip()))
        return found

    def test_there_are_declarations(self):
        self.assertTrue(self.declarations())

    def test_each_is_a_flow_list_of_literal_absolute_paths(self):
        # The callback reads aide_writes untemplated.
        for path, number, line in self.declarations():
            where = "%s:%d" % (path, number)
            match = re.match(r"^aide_writes: \[(.*)\]$", line)
            self.assertIsNotNone(match, where)
            for entry in match.group(1).split(","):
                entry = entry.strip().strip("\"'")
                self.assertTrue(entry.startswith("/"), where)
                self.assertNotIn("{{", entry, where)

    def test_firewalld_declares_its_zones_and_their_backups(self):
        # firewalld keeps each zone's previous file beside it as it saves one.
        firewalld = [line for path, _, line in self.declarations() if path.startswith("ansible-common/roles/firewalld/")]
        self.assertEqual(firewalld, ["aide_writes: [/etc/firewalld/zones/*.xml, /etc/firewalld/zones/*.xml.old]"] * 3)


if __name__ == "__main__":
    unittest.main()
