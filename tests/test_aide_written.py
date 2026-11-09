"""The aide_written callback's own logic: which results it records, and where.

It runs here with a stand-in for ansible-core's CallbackBase, on results
shaped as ansible-core 2.21 hands them to callbacks; test_ansible runs it in
ansible-core itself. Tests named for a gap record what it does today where
the triage of 2026-11-08 found it wanting; a fix changes them on purpose.

A result hidden by no_log reaches callbacks with only a few keys of its own,
CENSORED's; its task keeps the arguments it ran with."""

import os
import unittest
from unittest import mock

import support

aw = support.load_callback()

CENSORED = {"changed": True, "_ansible_no_log": True, "censored": "hidden"}


class Host:
    def __init__(self, name):
        self.name = name

    def get_name(self):
        return self.name


class Task:
    def __init__(self, action, args=None, variables=None, delegate_to=None):
        self.action = action
        self.args = args or {}
        self.vars = variables or {}
        self.delegate_to = delegate_to


class Result:
    """A result as ansible-core 2.19 and later hands it to callbacks."""

    def __init__(self, action, result, args=None, variables=None, host="host.example", delegate_to=None):
        self.host = Host(host)
        self.task = Task(action, args, variables, delegate_to)
        self.result = result


def invoked(**arguments):
    return {"invocation": {"module_args": arguments}}


class CallbackTestCase(unittest.TestCase):
    def setUp(self):
        environment = mock.patch.dict(os.environ)
        environment.start()
        self.addCleanup(environment.stop)
        self.callback = aw.CallbackModule()
        self.addCleanup(self.callback.v2_playbook_on_stats, None)

    def ok(self, *results):
        for result in results:
            self.callback.v2_runner_on_ok(result)

    def recorded(self, host="host.example", suffix=""):
        path = os.path.join(self.callback.directory, host + suffix)
        if not os.path.exists(path):
            return []
        with open(path) as handle:
            return handle.read().splitlines()


class Directory(CallbackTestCase):
    def test_a_directory_for_the_run_named_in_the_environment(self):
        self.assertTrue(os.path.isdir(self.callback.directory))
        self.assertEqual(os.environ["AIDE_WRITTEN_DIR"], self.callback.directory)
        self.assertEqual(os.stat(self.callback.directory).st_mode & 0o777, 0o700)

    def test_removed_when_the_run_ends(self):
        directory = self.callback.directory
        self.callback.v2_playbook_on_stats(None)
        self.assertFalse(os.path.exists(directory))

    def test_needs_enabling(self):
        self.assertTrue(aw.CallbackModule.CALLBACK_NEEDS_ENABLED)
        self.assertEqual((aw.CallbackModule.CALLBACK_NAME, aw.CallbackModule.CALLBACK_TYPE), ("aide_written", "aggregate"))


class FileModules(CallbackTestCase):
    def test_the_modules(self):
        self.assertEqual(aw.MODULES, {"copy", "template", "file", "lineinfile", "blockinfile", "replace", "ini_file",
                                      "get_url", "xml"})

    def test_the_dest_a_module_returns(self):
        self.ok(Result("ansible.builtin.copy", {"changed": True, "dest": "/etc/a"}))
        self.assertEqual(self.recorded(), ["/etc/a"])

    def test_the_dest_or_path_it_was_given(self):
        self.ok(Result("ansible.builtin.template", dict(changed=True, **invoked(dest="/etc/b"))),
                Result("ansible.builtin.lineinfile", dict(changed=True, **invoked(path="/etc/c"))),
                Result("ansible.builtin.file", {"changed": True, "path": "/etc/d"}))
        self.assertEqual(self.recorded(), ["/etc/b", "/etc/c", "/etc/d"])

    def test_the_returned_dest_before_the_arguments(self):
        self.ok(Result("ansible.builtin.copy", dict(changed=True, dest="/etc/final", **invoked(dest="/etc/"))))
        self.assertEqual(self.recorded(), ["/etc/final"])

    def test_by_the_actions_last_name(self):
        self.ok(Result("ansible.legacy.copy", {"changed": True, "dest": "/etc/a"}),
                Result("community.general.ini_file", dict(changed=True, **invoked(path="/etc/b.ini"))),
                Result("blockinfile", dict(changed=True, **invoked(path="/etc/c"))))
        self.assertEqual(self.recorded(), ["/etc/a", "/etc/b.ini", "/etc/c"])

    def test_not_an_unchanged_result(self):
        self.ok(Result("ansible.builtin.copy", {"changed": False, "dest": "/etc/a"}),
                Result("ansible.builtin.copy", {"dest": "/etc/b"}))
        self.assertEqual(self.recorded(), [])

    def test_not_a_relative_or_missing_path(self):
        self.ok(Result("ansible.builtin.copy", {"changed": True, "dest": "relative"}),
                Result("ansible.builtin.copy", {"changed": True}))
        self.assertEqual(self.recorded(), [])

    def test_not_a_result_delegated_to_another_host(self):
        self.ok(Result("ansible.builtin.copy", {"changed": True, "dest": "/etc/a",
                                                "_ansible_delegated_vars": {"ansible_host": "other"}}))
        self.assertEqual(self.recorded(), [])

    def test_a_result_hidden_by_no_log_by_its_tasks_arguments(self):
        self.ok(Result("ansible.builtin.copy", CENSORED, args={"dest": "/etc/secret.env", "content": "secret"}),
                Result("ansible.builtin.lineinfile", CENSORED, args={"path": "/etc/secret.conf", "line": "secret"}))
        self.assertEqual(self.recorded(), ["/etc/secret.env", "/etc/secret.conf"])

    def test_a_result_marked_no_log_that_kept_its_path(self):
        self.ok(Result("ansible.builtin.copy", {"changed": True, "_ansible_no_log": True, "dest": "/etc/secret.env"}))
        self.assertEqual(self.recorded(), ["/etc/secret.env"])

    def test_what_a_task_under_no_log_declares(self):
        self.ok(Result("ansible.builtin.command", CENSORED, variables={"aide_writes": ["/etc/ipa/default.conf"]}))
        self.assertEqual(self.recorded(), ["/etc/ipa/default.conf"])

    def test_not_an_unchanged_result_under_no_log(self):
        self.ok(Result("ansible.builtin.copy", {"changed": False, "_ansible_no_log": True, "censored": "hidden"},
                       args={"dest": "/etc/secret.env"}))
        self.assertEqual(self.recorded(), [])

    def test_not_a_result_under_no_log_delegated_to_another_host(self):
        # Its result lost the mark of delegation with the rest; its task keeps it.
        self.ok(Result("ansible.builtin.copy", CENSORED, args={"dest": "/srv/secret"}, delegate_to="localhost"))
        self.assertEqual(self.recorded(), [])

    def test_not_a_task_delegated_to_another_host(self):
        self.ok(Result("ansible.builtin.copy", {"changed": True, "dest": "/srv/x"}, delegate_to="localhost"))
        self.assertEqual(self.recorded(), [])

    def test_gap_not_a_module_that_does_not_take_its_path(self):
        self.ok(Result("ansible.builtin.user", {"changed": True, "name": "synapse_user", "home": "/home/synapse_user"}),
                Result("ansible.builtin.hostname", dict(changed=True, **invoked(name="host"))),
                Result("ansible.builtin.unarchive", dict(changed=True, dest="/opt/x", **invoked(dest="/opt/x"))),
                Result("ansible.builtin.command", {"changed": True, "cmd": ["ipa-replica-install"]}))
        self.assertEqual(self.recorded(), [])

    def test_each_host_in_its_own_file(self):
        self.ok(Result("ansible.builtin.copy", {"changed": True, "dest": "/etc/a"}, host="one"),
                Result("ansible.builtin.copy", {"changed": True, "dest": "/etc/b"}, host="two"),
                Result("ansible.builtin.copy", {"changed": True, "dest": "/etc/c"}, host="one"))
        self.assertEqual((self.recorded("one"), self.recorded("two")), (["/etc/a", "/etc/c"], ["/etc/b"]))


class Loops(CallbackTestCase):
    def test_each_item_and_not_the_loops_summary(self):
        items = [Result("ansible.builtin.copy", {"changed": True, "dest": "/etc/%d" % n}) for n in (1, 2)]
        for item in items:
            self.callback.v2_runner_item_on_ok(item)
        self.ok(Result("ansible.builtin.copy", {"changed": True, "results": [item.result for item in items]}))
        self.assertEqual(self.recorded(), ["/etc/1", "/etc/2"])

    def test_each_item_hidden_by_no_log_by_its_own_arguments(self):
        for n in (1, 2):
            self.callback.v2_runner_item_on_ok(Result("ansible.builtin.template", CENSORED, args={"dest": "/etc/%d" % n}))
        self.assertEqual(self.recorded(), ["/etc/1", "/etc/2"])


class Declared(CallbackTestCase):
    def test_the_absolute_paths_a_task_declares(self):
        self.ok(Result("ansible.builtin.command", {"changed": True},
                       variables={"aide_writes": ["/boot/grub/grub.cfg", "relative", 7, "/boot/loader/entries/*.conf"]}))
        self.assertEqual(self.recorded(), ["/boot/grub/grub.cfg", "/boot/loader/entries/*.conf"])

    def test_before_the_modules_own_path(self):
        self.ok(Result("ansible.builtin.copy", {"changed": True, "dest": "/etc/a"}, variables={"aide_writes": ["/etc/b"]}))
        self.assertEqual(self.recorded(), ["/etc/b", "/etc/a"])

    def test_as_written_untemplated(self):
        self.ok(Result("ansible.builtin.command", {"changed": True}, variables={"aide_writes": ["/etc/{{ item }}"]}))
        self.assertEqual(self.recorded(), ["/etc/{{ item }}"])

    def test_not_for_an_unchanged_result(self):
        self.ok(Result("ansible.builtin.command", {"changed": False}, variables={"aide_writes": ["/etc/b"]}))
        self.assertEqual(self.recorded(), [])


class Units(CallbackTestCase):
    def test_the_unit_modules(self):
        self.assertEqual(aw.UNIT_MODULES, {"systemd_service", "systemd", "service"})

    def test_a_unit_enabled_disabled_or_masked(self):
        self.ok(Result("ansible.builtin.systemd_service", dict(changed=True, name="a.service", **invoked(enabled=True))),
                Result("ansible.builtin.systemd", dict(changed=True, **invoked(name="b.timer", enabled=False))),
                Result("ansible.builtin.service", dict(changed=True, **invoked(name="c.service", masked=True))))
        self.assertEqual(self.recorded(suffix=".units"), ["a.service", "b.timer", "c.service"])
        self.assertEqual(self.recorded(), [])

    def test_not_a_unit_only_started_restarted_or_reloaded(self):
        self.ok(Result("ansible.builtin.systemd_service",
                       dict(changed=True, name="a.service", **invoked(state="restarted", enabled=None, masked=None))),
                Result("ansible.builtin.systemd_service", dict(changed=True, **invoked(daemon_reload=True))))
        self.assertEqual(self.recorded(suffix=".units"), [])

    def test_not_a_unit_named_by_path(self):
        self.ok(Result("ansible.builtin.systemd_service",
                       dict(changed=True, **invoked(name="/etc/systemd/system/a.service", enabled=True))))
        self.assertEqual(self.recorded(suffix=".units"), [])

    def test_with_its_declared_paths(self):
        self.ok(Result("ansible.builtin.systemd_service", dict(changed=True, name="a.service", **invoked(enabled=True)),
                       variables={"aide_writes": ["/etc/x"]}))
        self.assertEqual((self.recorded(), self.recorded(suffix=".units")), (["/etc/x"], ["a.service"]))

    def test_a_unit_changed_under_no_log(self):
        self.ok(Result("ansible.builtin.systemd_service", CENSORED, args={"name": "a.service", "enabled": True}))
        self.assertEqual(self.recorded(suffix=".units"), ["a.service"])


if __name__ == "__main__":
    unittest.main()
