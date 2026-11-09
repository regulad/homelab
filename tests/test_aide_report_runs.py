"""aide-report's runs: the daily check and what its mail accepts, the first
baseline, the refresh after an Ansible run, and the command line. aide and
mail are stand-ins that log how they were called."""

import gzip
import json
import os
import subprocess
import sys
import unittest
from unittest import mock

import support
from support import ADDED_FILE, FakePackages, attributes, report, summary

ar = support.load_aide_report()


class RunTestCase(support.CommandsTestCase):
    commands = ("aide", "mail")

    def setUp(self):
        super().setUp()
        self.settings = {
            "config": self.path("etc/aide.conf"),
            "exclusions": self.path("etc/exclusions.conf"),
            "filesystems": ["/"],
            "excluded": [],
            "excluded_secure_boot": [],
            "database": self.path("var/lib/aide/aide.db"),
            "database_new": self.path("var/lib/aide/aide.db.new"),
            "state": self.path("var/lib/aide-report"),
            "manifest": self.path("var/lib/aide-report/packages.json.gz"),
            "lock": self.path("run/aide-report.lock"),
            "accept": "ACCEPT-COMMAND",
            "repair": "REPAIR-COMMAND",
        }
        os.makedirs(os.path.dirname(self.settings["database"]))
        os.makedirs(os.path.dirname(self.settings["lock"]))
        self.set_command("aide", version="AIDE 0.19.2", writes=self.settings["database_new"])
        self.packages = FakePackages()
        # The host's own mounts, swap, Secure Boot, packages and image stores stay out of it.
        for patcher in (mock.patch.object(ar, "mount_points", return_value=set()),
                        mock.patch.object(ar, "swap_files", return_value=set()),
                        mock.patch.object(ar, "secure_boot", return_value=False),
                        mock.patch.object(ar, "diversions", return_value=None),
                        mock.patch.object(ar, "Packages", lambda: self.packages),
                        mock.patch.object(ar, "podman_check", return_value=[]),
                        mock.patch.object(ar, "docker_check", return_value=[])):
            patcher.start()
            self.addCleanup(patcher.stop)

    def baseline_exists(self, manifest=None, accepted=1_700_000_000):
        with open(self.settings["database"], "w") as handle:
            handle.write("baseline\n")
        os.makedirs(self.settings["state"], exist_ok=True)
        with gzip.open(self.settings["manifest"], "wt") as handle:
            json.dump(manifest or {"owner": {}, "installed": []}, handle)
        os.utime(self.settings["manifest"], (accepted, accepted))

    def aide_reports(self, entries, status=1):
        self.set_command("aide", output=self.write("report.json", json.dumps(entries)), status=status)

    def database(self):
        with open(self.settings["database"]) as handle:
            return handle.read()

    def mails(self):
        return self.calls("mail")

    def state(self, name):
        with open(os.path.join(self.settings["state"], name)) as handle:
            return json.load(handle)


class CheckNoBaseline(RunTestCase):
    def test_mails_that_there_is_none_and_accepts_nothing(self):
        self.assertEqual(ar.check(self.settings), 1)
        (sent,) = self.mails()
        self.assertTrue(sent["argv"][1].endswith(": no baseline"))
        self.assertIn("Create one with: ACCEPT-COMMAND", sent["stdin"])
        self.assertEqual(self.calls("aide"), [])
        self.assertFalse(os.path.exists(self.settings["manifest"]))

    def test_a_database_without_the_manifest_is_none(self):
        with open(self.settings["database"], "w") as handle:
            handle.write("the package's own\n")
        self.assertEqual(ar.check_files(self.settings)[0], "no baseline")


class CheckFiles(RunTestCase):
    def setUp(self):
        super().setUp()
        self.baseline_exists()

    def test_no_changes_no_mail(self):
        self.aide_reports(report(), status=0)
        self.assertEqual(ar.check(self.settings), 0)
        self.assertEqual(self.mails(), [])
        self.assertEqual(self.state("kept.json")["kept"], {"added": {}, "removed": {}, "changed": {}})
        self.assertEqual(self.database(), "baseline\n")
        self.assertFalse(os.path.exists(self.settings["database_new"]))

    def test_the_walk_is_aide_update_with_the_json_report(self):
        self.aide_reports(report(), status=0)
        ar.check(self.settings)
        update = [call["argv"] for call in self.calls("aide") if "--update" in call["argv"]]
        self.assertEqual(update, [["--config", self.settings["config"], "--update", "-A", "report_format=json"]])

    def test_a_failed_check_mails_and_accepts_nothing(self):
        self.aide_reports(report(), status=14)
        self.assertEqual(ar.check(self.settings), 1)
        (sent,) = self.mails()
        self.assertTrue(sent["argv"][1].endswith(": the check failed"))
        self.assertIn("aide exited 14.", sent["stdin"])
        self.assertEqual(self.database(), "baseline\n")

    def test_changes_all_explained_mail_nothing_and_accept_nothing(self):
        self.packages = FakePackages(owner={"/usr/bin/new": "new=1"})
        self.aide_reports(report(added={"/usr/bin/new": ADDED_FILE}))
        before = os.path.getmtime(self.settings["manifest"])
        self.assertEqual(ar.check(self.settings), 0)
        self.assertEqual(self.mails(), [])
        self.assertEqual(self.state("kept.json")["explained"], 1)
        self.assertEqual(self.database(), "baseline\n")
        self.assertEqual(os.path.getmtime(self.settings["manifest"]), before)
        self.assertFalse(os.path.exists(self.settings["database_new"]))

    def test_a_mail_accepts_the_walks_database_with_the_packages_as_it_left_them(self):
        self.packages = FakePackages(owner={"/usr/bin/new": "new=1"})
        self.aide_reports(report(added={"/usr/bin/new": ADDED_FILE, "/etc/stray": ADDED_FILE}))
        self.assertEqual(ar.check(self.settings), 0)
        (sent,) = self.mails()
        self.assertEqual(sent["argv"][:2], ["-s", sent["argv"][1]])
        self.assertTrue(sent["argv"][1].startswith("AIDE on ") and sent["argv"][1].endswith(": 1 changes"))
        self.assertEqual(sent["argv"][2:], ["root"])
        self.assertIn("Once this mail is sent, the baseline moves", sent["stdin"])
        self.assertIn("/etc/stray", sent["stdin"])
        self.assertNotIn("/usr/bin/new", sent["stdin"])
        self.assertTrue(self.database().startswith("written by aide"))
        self.assertEqual(support.read_gzip_json(self.settings["manifest"]),
                         {"owner": {"/usr/bin/new": "new=1"}, "installed": ["new=1"]})
        self.assertEqual(self.state("mailed.json")["subject"], sent["argv"][1])

    def test_the_head_counts_and_dates_from_the_manifest(self):
        self.aide_reports(report(added={"/etc/stray": ADDED_FILE}))
        _, lines, _, _ = ar.check_files(self.settings)
        accepted = ar.time.strftime("%Y-%m-%d %H:%M %Z", ar.time.localtime(1_700_000_000))
        self.assertEqual(lines[0], "1 changes since the baseline accepted %s that the host's packages do not explain;"
                         % accepted)
        self.assertEqual(lines[1], "0 others, which they do or which left a file as it was, were left out.")
        self.assertIn("  %s  /etc/stray" % ADDED_FILE, lines)

    def test_the_report_and_what_it_kept_are_saved(self):
        entries = report(added={"/etc/stray": ADDED_FILE})
        self.aide_reports(entries)
        ar.check(self.settings)
        self.assertEqual(self.state("report.json"), entries)
        self.assertEqual(self.state("kept.json")["kept"]["added"], {"/etc/stray": ADDED_FILE})

    def test_the_rules_are_given_the_exclusions_scratch_and_accepted_time(self):
        self.aide_reports(report(added={"/etc/stray": ADDED_FILE}))
        self.settings["excluded"] = ["/var/log"]
        with mock.patch.object(ar, "explain", return_value=({"added": {}, "removed": {}, "changed": {}}, 0)) as rules:
            ar.check_files(self.settings)
        args = rules.call_args[0]
        self.assertEqual(args[2], {"owner": {}, "installed": []})
        self.assertEqual(args[3:], (["/var/log"], os.path.dirname(self.settings["exclusions"]), 1_700_000_000))

    def test_a_report_too_long_for_one_mail_accepts_nothing(self):
        stray = {"/etc/stray%03d" % n: ADDED_FILE for n in range(ar.MAIL_LINES)}
        self.aide_reports(report(added=stray))
        ar.check(self.settings)
        (sent,) = self.mails()
        self.assertIn("This mail cannot hold the whole report, so the baseline stays where it was.", sent["stdin"])
        self.assertIn("  ACCEPT-COMMAND", sent["stdin"])
        lines = sent["stdin"].rstrip("\n").split("\n")
        # The report: 3 lines of head, 3 on the baseline, a blank line and the
        # section's heading, then an entry a line; 8 past the limit.
        self.assertEqual(lines[-1], "... and 8 more lines.")
        self.assertEqual(len(lines), 2 + ar.MAIL_LINES + 2)
        self.assertEqual(self.database(), "baseline\n")
        self.assertFalse(os.path.exists(self.settings["database_new"]))

    def test_a_report_that_is_not_json_is_mailed_unfiltered(self):
        self.set_command("aide", output=self.write("report.json", "{not json"), status=1)
        ar.check(self.settings)
        (sent,) = self.mails()
        self.assertTrue(sent["argv"][1].endswith(": changes, unfiltered"))
        self.assertIn("{not json", sent["stdin"])
        self.assertTrue(self.database().startswith("written by aide"))

    def test_a_mail_that_fails_is_not_recorded_and_accepts_nothing(self):
        self.aide_reports(report(added={"/etc/stray": ADDED_FILE}))
        self.set_command("mail", status=1)
        with self.assertRaises(subprocess.CalledProcessError):
            ar.check(self.settings)
        self.assertFalse(os.path.exists(os.path.join(self.settings["state"], "mailed.json")))
        self.assertEqual(self.database(), "baseline\n")
        self.assertFalse(os.path.exists(self.settings["database_new"]))


class ContainerImages(RunTestCase):
    def setUp(self):
        super().setUp()
        self.baseline_exists()
        self.images = ["podman system check exited 1:", "  damaged", ""]

    def test_a_mail_of_images_alone_accepts_nothing(self):
        self.aide_reports(report(), status=0)
        with mock.patch.object(ar, "podman_check", return_value=self.images):
            ar.check(self.settings)
        (sent,) = self.mails()
        self.assertTrue(sent["argv"][1].endswith(": container images"))
        self.assertEqual(self.database(), "baseline\n")

    def test_images_beside_files_changes_and_the_files_accepted(self):
        self.aide_reports(report(added={"/etc/stray": ADDED_FILE}))
        with mock.patch.object(ar, "docker_check", return_value=self.images):
            ar.check(self.settings)
        (sent,) = self.mails()
        self.assertTrue(sent["argv"][1].endswith(": 1 changes, container images"))
        self.assertIn("  damaged", sent["stdin"])
        self.assertTrue(self.database().startswith("written by aide"))


class PreviousMail(RunTestCase):
    def test_none_recorded(self):
        self.assertEqual(ar.previous_mail(self.settings), "No earlier mail from aide-report here is recorded.")

    def test_the_recorded_time_and_subject(self):
        self.write("var/lib/aide-report/mailed.json", json.dumps({"time": "T", "subject": "S"}))
        self.assertEqual(ar.previous_mail(self.settings),
                         "The previous mail from aide-report here was sent T, with the subject: S")

    def test_an_unreadable_record(self):
        record = self.write("var/lib/aide-report/mailed.json", "{")
        self.assertTrue(ar.previous_mail(self.settings).startswith(
            "The record of the previous mail from aide-report here, %s, cannot be read: " % record))

    def test_each_mail_begins_with_it(self):
        ar.mail(self.settings, "subject", ["line"])
        ar.mail(self.settings, "second", ["line"])
        first, second = self.mails()
        self.assertTrue(first["stdin"].startswith("No earlier mail from aide-report here is recorded.\n\nline\n"))
        self.assertIn("with the subject: %s\n" % first["argv"][1], second["stdin"])


class Acceptance(RunTestCase):
    def test_a_mail_that_holds_the_report_accepts_with_the_manifest(self):
        lines, manifest = ar.acceptance(self.settings, ["head"], ["body"], {"m": 1})
        self.assertEqual(manifest, {"m": 1})
        self.assertEqual(lines, ["head", "Once this mail is sent, the baseline moves to the files as this check found them,",
                                 "and no later report lists these changes again.", "body"])

    def test_one_that_cannot_accepts_nothing(self):
        body = ["x"] * ar.MAIL_LINES
        lines, manifest = ar.acceptance(self.settings, ["head"], body, {"m": 1})
        self.assertIsNone(manifest)
        self.assertEqual(lines[:4], ["head", "This mail cannot hold the whole report, so the baseline stays where it was. Once each",
                                     "change is accounted for, accept the files as they are with:", "  ACCEPT-COMMAND"])

    def test_the_limit_is_the_whole_mail(self):
        self.assertEqual(ar.MAIL_LINES, 400)
        self.assertIsNotNone(ar.acceptance(self.settings, [], ["x"] * (ar.MAIL_LINES - 2), {})[1])
        self.assertIsNone(ar.acceptance(self.settings, [], ["x"] * (ar.MAIL_LINES - 1), {})[1])


class Accept(RunTestCase):
    def test_moves_the_new_database_in_and_writes_the_manifest(self):
        self.write("var/lib/aide/aide.db.new", "new\n")
        ar.accept(self.settings, {"owner": {"/a": "a=1"}, "installed": ["a=1"]})
        self.assertEqual(self.database(), "new\n")
        self.assertFalse(os.path.exists(self.settings["database_new"]))
        self.assertEqual(support.read_gzip_json(self.settings["manifest"]), {"owner": {"/a": "a=1"}, "installed": ["a=1"]})
        self.assertFalse(os.path.exists(self.settings["manifest"] + ".tmp"))


class Baseline(RunTestCase):
    def test_records_the_packages_then_walks_with_aide_init(self):
        order = []
        real_aide = ar.aide

        def walk(settings, action):
            order.append(action)
            return real_aide(settings, action)

        def packages():
            order.append("packages")
            return FakePackages(owner={"/a": "a=1"})
        with mock.patch.object(ar, "aide", walk), mock.patch.object(ar, "Packages", packages), mock.patch("sys.stdout"):
            self.assertEqual(ar.baseline(self.settings), 0)
        # The manifest is of the packages before the walk, so that a package
        # installed or removed while it walks counts as changed since.
        self.assertEqual(order, ["packages", "--init"])
        self.assertTrue(self.database().startswith("written by aide --config"))
        self.assertEqual(support.read_gzip_json(self.settings["manifest"])["installed"], ["a=1"])

    def test_a_failed_walk_accepts_nothing(self):
        self.set_command("aide", status=1)
        with mock.patch.object(sys, "stderr"):
            self.assertEqual(ar.baseline(self.settings), 1)
        self.assertFalse(os.path.exists(self.settings["manifest"]))
        self.assertFalse(os.path.exists(self.settings["database"]))


class Refresh(RunTestCase):
    def setUp(self):
        super().setUp()
        self.baseline_exists()

    def limit(self):
        (update,) = [call["argv"] for call in self.calls("aide") if "--update" in call["argv"]]
        self.assertEqual(update[:4], ["--config", self.settings["config"], "--update", "--limit"])
        self.assertEqual(update[5:], ["-A", "report_format=json"])
        return update[4]

    def test_moves_the_baseline_for_exactly_those_paths(self):
        with mock.patch("sys.stdout"):
            self.assertEqual(ar.refresh(self.settings, ["/etc/b", "/etc/firewalld/zones/*.xml", "/etc/b"]), 0)
        self.assertEqual(self.limit(), "(/etc/b|/etc/firewalld/zones/[^/]*\\.xml)$")
        self.assertTrue(self.database().startswith("written by aide"))
        self.assertFalse(os.path.exists(self.settings["database_new"]))

    def test_and_for_the_links_of_the_units(self):
        with mock.patch.object(ar, "unit_links", return_value=["U1", "U2"]) as links, mock.patch("sys.stdout"):
            ar.refresh(self.settings, ["/etc/a"], ["foo.service"])
        links.assert_called_once_with(["foo.service"])
        self.assertEqual(self.limit(), "(/etc/a|U1|U2)$")

    def test_leaves_the_manifest_and_so_the_accepted_time(self):
        before = os.path.getmtime(self.settings["manifest"])
        with mock.patch("sys.stdout"):
            ar.refresh(self.settings, ["/etc/a"])
        self.assertEqual(os.path.getmtime(self.settings["manifest"]), before)

    def test_writes_the_exclusions_first(self):
        with mock.patch("sys.stdout"):
            ar.refresh(self.settings, ["/etc/a"])
        self.assertTrue(os.path.exists(self.settings["exclusions"]))

    def test_nothing_to_do_without_a_baseline(self):
        os.remove(self.settings["database"])
        self.assertEqual(ar.refresh(self.settings, ["/etc/a"]), 0)
        self.assertEqual(self.calls("aide"), [])

    def test_nothing_to_do_without_paths_or_units(self):
        self.assertEqual(ar.refresh(self.settings, []), 0)
        self.assertEqual([c for c in self.calls("aide") if "--update" in c["argv"]], [])

    def test_aide_finding_changes_is_no_failure(self):
        for status in (0, 1, 7, 13):
            self.set_command("aide", status=status)
            with mock.patch("sys.stdout"):
                self.assertEqual(ar.refresh(self.settings, ["/etc/a"]), 0, status)

    def test_a_failed_update_leaves_the_baseline(self):
        self.set_command("aide", status=14)
        with mock.patch.object(sys, "stderr"):
            self.assertEqual(ar.refresh(self.settings, ["/etc/a"]), 1)
        self.assertEqual(self.database(), "baseline\n")


class Main(RunTestCase):
    def run_main(self, *argv):
        settings_path = self.write("etc/settings.json", json.dumps(self.settings))
        calls = []
        stand_ins = {name: mock.patch.object(ar, name, lambda *a, _name=name: calls.append((_name, a)) or 0)
                     for name in ("check", "baseline", "refresh", "repair_images")}
        for patcher in stand_ins.values():
            patcher.start()
            self.addCleanup(patcher.stop)
        with support.umask_kept(), mock.patch.object(sys, "argv", ["aide-report", "--settings", settings_path] + list(argv)):
            self.assertEqual(ar.main(), 0)
        return calls

    def test_checks_by_default(self):
        self.assertEqual(self.run_main(), [("check", (self.settings,))])

    def test_baseline(self):
        self.assertEqual(self.run_main("--baseline"), [("baseline", (self.settings,))])

    def test_refresh_with_paths_and_units(self):
        self.assertEqual(self.run_main("--refresh", "/etc/a", "/etc/b*", "--units", "foo.service", "bar"),
                         [("refresh", (self.settings, ["/etc/a", "/etc/b*"], ["foo.service", "bar"]))])

    def test_refresh_with_units_alone(self):
        self.assertEqual(self.run_main("--refresh", "--units", "foo.service"),
                         [("refresh", (self.settings, [], ["foo.service"]))])

    def test_repair_images(self):
        self.assertEqual(self.run_main("--repair-images"), [("repair_images", ())])

    def test_holds_the_lock(self):
        self.run_main()
        self.assertTrue(os.path.exists(self.settings["lock"]))

    def test_one_action_at_a_time(self):
        with mock.patch.object(sys, "stderr"), self.assertRaises(SystemExit):
            self.run_main("--baseline", "--refresh", "/etc/a")


if __name__ == "__main__":
    unittest.main()
