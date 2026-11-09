"""The aide_written callback and the aide role's refresh tasks in ansible-core
itself, in check mode on localhost, so that nothing is written; and what
ansible-core hands callbacks, which the callback relies on.

Tests named for a gap record what happens today where the triage of
2026-11-08 found it wanting; a fix changes them on purpose."""

import json
import os
import shutil
import subprocess
import tempfile
import unittest

import support

PLAYBOOK = os.path.join(support.TESTS, "playbooks", "refresh.yml")
CALLBACKS = os.path.join(support.REPOSITORY, "ansible-common", "plugins", "callback")
RECORDER = os.path.join(support.TESTS, "callback_plugins")
ROLES = os.path.join(support.REPOSITORY, "ansible-common", "roles")


class CheckRun(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        playbook = shutil.which("ansible-playbook")
        if playbook is None:
            raise AssertionError("ansible-playbook is not on PATH; these tests run it in check mode on localhost.")
        cls.root = tempfile.mkdtemp(prefix="aide-tests-ansible-")
        cls.out = os.path.join(cls.root, "out")
        os.makedirs(cls.out)
        unchanged = os.path.join(cls.out, "unchanged")
        open(unchanged, "w").close()
        os.chmod(unchanged, 0o644)
        cls.database = os.path.join(cls.root, "aide.db")
        open(cls.database, "w").close()
        recorded = os.path.join(cls.root, "recorded.jsonl")
        environment = {name: value for name, value in os.environ.items() if not name.startswith("ANSIBLE_")}
        environment.update({
            "ANSIBLE_HOME": os.path.join(cls.root, "home"),
            "ANSIBLE_LOCAL_TEMP": os.path.join(cls.root, "tmp"),
            "ANSIBLE_CALLBACK_PLUGINS": os.pathsep.join([CALLBACKS, RECORDER]),
            "ANSIBLE_CALLBACKS_ENABLED": "aide_written,recorder",
            # As each stage's ansible.cfg sets it.
            "ANSIBLE_INJECT_INVOCATION": "true",
            "ANSIBLE_ROLES_PATH": ROLES,
            "ANSIBLE_PYTHON_INTERPRETER": "auto_silent",
            "ANSIBLE_LOCALHOST_WARNING": "false",
            "ANSIBLE_INVENTORY_UNPARSED_WARNING": "false",
            "ANSIBLE_RETRY_FILES_ENABLED": "false",
            "ANSIBLE_NOCOLOR": "1",
            # ansible-core writes no bytecode beside the callbacks it loads.
            "PYTHONDONTWRITEBYTECODE": "1",
            "RECORDER_OUT": recorded,
        })
        variables = os.path.join(cls.root, "variables.json")
        with open(variables, "w") as handle:
            json.dump({"out": cls.out, "aide_database": cls.database}, handle)
        cls.completed = subprocess.run([playbook, "--check", "-i", "localhost,", "-c", "local", PLAYBOOK, "-e", "@" + variables],
                                 cwd=cls.root, env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                 universal_newlines=True)
        cls.records = []
        if os.path.exists(recorded):
            with open(recorded) as handle:
                cls.records = [json.loads(line) for line in handle]

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.root, ignore_errors=True)

    def records_of(self, task, event=None):
        # A role's task is named for its role too: "aide : Files this run wrote".
        found = [r for r in self.records if r["task"] in (task, "aide : " + task)
                 and (event is None or r["event"] == event)]
        self.assertTrue(found, "no %s record of %r; the run said:\n%s" % (event or "", task, self.completed.stdout[-3000:]))
        return found

    def facts(self):
        (record,) = self.records_of("Files this run wrote", "ok")
        return record["result"]["ansible_facts"]

    def test_the_run_succeeds(self):
        self.assertEqual(self.completed.returncode, 0, self.completed.stdout[-3000:])

    def test_the_refresh_reads_back_the_changed_results_paths_and_declarations(self):
        self.assertEqual(self.facts()["aide_written"], [
            self.out + "/copied",
            self.out + "/hidden",
            self.out + "/one",
            self.out + "/two",
            self.out + "/directory",
            self.out + "/lines",
            "/declared/literal",
            "/declared/{{ out }}",
            self.out + "/declaring",
            "/etc/passwd", "/etc/passwd-", "/etc/shadow", "/etc/shadow-", "/etc/group", "/etc/group-",
            "/etc/gshadow", "/etc/gshadow-", "/etc/subuid", "/etc/subuid-", "/etc/subgid", "/etc/subgid-",
            "/etc/.pwd.lock",
        ])
        self.assertEqual(self.facts()["aide_written_units"], [])

    def test_not_what_a_skipped_task_declares(self):
        # Check mode skips a command, as it does the refresh's own.
        (record,) = self.records_of("A command declaring its writes")
        self.assertEqual(record["event"], "skipped")
        self.assertNotIn("/declared/by-command", self.facts()["aide_written"])

    def test_not_an_unchanged_or_delegated_result(self):
        written = self.facts()["aide_written"]
        self.assertNotIn(self.out + "/unchanged", written)
        self.assertNotIn(self.out + "/delegated", written)
        self.assertNotIn(self.out + "/delegated-hidden", written)

    def test_a_result_hidden_by_no_log(self):
        self.assertIn(self.out + "/hidden", self.facts()["aide_written"])

    def test_the_refresh_itself_is_skipped_in_check_mode(self):
        (record,) = self.records_of("AIDE's baseline for them")
        self.assertEqual(record["event"], "skipped")

    # What ansible-core hands callbacks, which aide_written relies on.

    def test_a_no_log_result_is_censored_but_its_task_keeps_its_arguments(self):
        (record,) = self.records_of("A copy under no_log", "ok")
        self.assertTrue(record["result"]["_ansible_no_log"])
        self.assertIn("censored", record["result"])
        self.assertTrue(set(record["result"]) <= {"_ansible_no_log", "censored", "changed", "warnings", "deprecations",
                                                  "exception", "attempts", "retries"}, record["result"])
        self.assertEqual(record["args"]["dest"], self.out + "/hidden")

    def test_each_loop_items_task_holds_its_templated_arguments(self):
        items = self.records_of("A loop of copies", "item_ok")
        self.assertEqual([r["args"]["dest"] for r in items], [self.out + "/one", self.out + "/two"])
        self.assertEqual([r["result"]["invocation"]["module_args"]["dest"] for r in items],
                         [self.out + "/one", self.out + "/two"])

    def test_a_tasks_variables_are_handed_over_untemplated(self):
        (record,) = self.records_of("A copy declaring other writes", "ok")
        self.assertEqual(record["vars"]["aide_writes"], ["/declared/literal", "relative/path", "/declared/{{ out }}"])

    def test_a_delegated_result_says_so(self):
        (record,) = self.records_of("A delegated copy", "ok")
        self.assertIn("_ansible_delegated_vars", record["result"])
        self.assertEqual(record["delegate_to"], "localhost")

    def test_a_delegated_result_under_no_log_says_so_only_by_its_task(self):
        (record,) = self.records_of("A delegated copy under no_log", "ok")
        self.assertNotIn("_ansible_delegated_vars", record["result"])
        self.assertEqual(record["delegate_to"], "localhost")

    def test_an_undelegated_task_names_no_host(self):
        (record,) = self.records_of("A copy", "ok")
        self.assertIsNone(record["delegate_to"])


if __name__ == "__main__":
    unittest.main()
