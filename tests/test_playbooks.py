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
        (play,) = plays(read(REFRESH_PLAYBOOK))
        self.assertIn("hosts: debian:ubuntu:rhel", play)
        self.assertIn("gather_facts: false", play)
        self.assertIn("become: true", play)
        self.assertIn("tags: [always, aide, aide_refresh]", play)
        self.assertRegex(play, r"import_role:\s+name: aide\s+tasks_from: refresh")

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
        self.assertIn("loop: [aide-report.service, aide-baseline.service, aide-report.timer]", main)
        self.assertNotIn("name: aide-baseline.service", main)
        self.assertNotIn("First baseline", main)
        refresh = read("ansible-common/roles/aide/tasks/refresh.yml")
        self.assertRegex(refresh, r"- name: First baseline\s+ansible\.builtin\.systemd_service:\s+"
                                  r"name: aide-baseline\.service\s+state: started\s+no_block: true\s+daemon_reload: true")
        order = [refresh.index(name) for name in ("- name: Nothing to refresh", "- name: First baseline",
                                                  "- name: AIDE's baseline for them")]
        self.assertEqual(order, sorted(order))

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


class RefreshTasks(unittest.TestCase):
    def test_runs_aide_report_with_the_paths_then_the_units(self):
        refresh = read("ansible-common/roles/aide/tasks/refresh.yml")
        self.assertIn("{{ ['/usr/local/bin/aide-report', '--refresh'] + aide_written\n"
                      "         + (['--units'] + aide_written_units if aide_written_units else []) }}", refresh)
        self.assertIn("aide_written_file: \"{{ lookup('ansible.builtin.env', 'AIDE_WRITTEN_DIR') ~ '/' ~ inventory_hostname }}\"",
                      refresh)
        self.assertIn("lookup('ansible.builtin.file', aide_written_file ~ '.units', errors='ignore')", refresh)


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

    def test_gap_firewalld_declares_its_zones_without_their_backups(self):
        for path, number, line in self.declarations():
            if path.startswith("ansible-common/roles/firewalld/"):
                self.assertEqual(line, "aide_writes: [/etc/firewalld/zones/*.xml]", "%s:%d" % (path, number))


if __name__ == "__main__":
    unittest.main()
