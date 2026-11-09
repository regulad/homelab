"""aide-report's record of the host's packages: who owns each path, which
packages are installed, what they vouch for, and the manifest a baseline keeps."""

import builtins
import os
import unittest
from unittest import mock

import support

ar = support.load_aide_report()

DPKG_INFO = "/var/lib/dpkg/info"


class PackagesTestCase(support.CommandsTestCase):
    commands = ("dpkg-query", "dpkg", "rpm")

    def manager(self, rpm):
        """Makes the host one with rpm, or with dpkg, and no merged /usr."""
        real_exists = os.path.exists

        def exists(path):
            if path == "/usr/bin/rpm":
                return rpm
            if path == "/usr/bin/dpkg":
                return not rpm
            return real_exists(path)
        for patcher in (mock.patch.object(ar.os.path, "exists", exists),
                        mock.patch.object(ar, "USR_MERGE_LINKS", ())):
            patcher.start()
            self.addCleanup(patcher.stop)

    def dpkg_info(self, records):
        """dpkg's records, in a scratch directory read in place of /var/lib/dpkg/info."""
        info = self.path("dpkg-info")
        os.makedirs(info)
        for name, lines in records.items():
            with open(os.path.join(info, name), "w") as handle:
                handle.write("".join(line + "\n" for line in lines))
        real_listdir, real_open = os.listdir, builtins.open

        def moved(path):
            return info + path[len(DPKG_INFO):] if isinstance(path, str) and path.startswith(DPKG_INFO) else path
        for patcher in (mock.patch.object(ar.os, "listdir", lambda path=".": real_listdir(moved(path))),
                        mock.patch.object(ar, "open", lambda path, *a, **k: real_open(moved(path), *a, **k), create=True)):
            patcher.start()
            self.addCleanup(patcher.stop)

    def output(self, command, text):
        path = self.write("%s.out" % command, text)
        self.set_command(command, output=path)


class DpkgPackages(PackagesTestCase):
    def setUp(self):
        super().setUp()
        self.manager(rpm=False)
        self.output("dpkg-query", "foo\t1.0\tinstalled\nbar\t2.0\tconfig-files\nold\t3.0\tnot-installed\n"
                                  "multi:amd64\t4.0\tinstalled\nhalf\t5.0\thalf-configured\n")
        self.dpkg_info({
            "foo.list": ["/.", "/usr/bin/foo", "/etc/foo.conf"],
            "bar.list": ["/etc/bar.conf"],
            "multi:amd64.list": ["/usr/lib/multi.so"],
            "half.list": ["/usr/bin/half"],
            "foo.md5sums": ["ignored"],
        })

    def test_installed_packages_by_name_and_version(self):
        packages = ar.Packages()
        self.assertFalse(packages.rpm)
        self.assertEqual(packages.installed, {"foo=1.0", "multi:amd64=4.0", "half=5.0"})
        self.assertEqual(packages.versions(), {"foo": "1.0", "multi:amd64": "4.0", "half": "5.0"})

    def test_each_listed_path_owned_by_its_package(self):
        packages = ar.Packages()
        self.assertEqual(packages.owner["/usr/bin/foo"], "foo=1.0")
        self.assertEqual(packages.owner["/etc/foo.conf"], "foo=1.0")
        self.assertEqual(packages.owner["/usr/lib/multi.so"], "multi:amd64=4.0")
        self.assertEqual(packages.owner["/usr/bin/half"], "half=5.0")

    def test_a_removed_but_unpurged_package_is_not_installed_and_owns_nothing(self):
        packages = ar.Packages()
        self.assertNotIn("bar=2.0", packages.installed)
        self.assertNotIn("/etc/bar.conf", packages.owner)

    def test_dpkg_verifies_by_package_name(self):
        packages = ar.Packages()
        self.assertEqual(packages.package("foo=1.0"), "foo")

    def test_unverified_paths_from_dpkg_verify(self):
        packages = ar.Packages()
        self.output("dpkg", "??5??????   /usr/bin/foo\nmissing     /usr/lib/multi.so\n??5?????? c /etc/foo.conf\n"
                            "garbage line\n")
        failed = packages.unverified(["/usr/bin/foo", "/usr/lib/multi.so", "/etc/foo.conf", "/unowned"])
        self.assertEqual(failed, {"/usr/bin/foo", "/usr/lib/multi.so", "/etc/foo.conf"})
        self.assertEqual(self.calls("dpkg")[-1]["argv"], ["--verify", "foo", "multi:amd64"])


class RpmPackages(PackagesTestCase):
    def setUp(self):
        super().setUp()
        self.manager(rpm=True)
        self.output("rpm", "/usr/bin/foo\t\tfoo-1.0-1.x86_64\n/etc/foo.conf\tc\tfoo-1.0-1.x86_64\n"
                           "/var/log/foo.log\tg\tfoo-1.0-1.x86_64\n/boot/vmlinuz-6\tg\tkernel-core-6-1.x86_64\n"
                           "/boot/vmlinuz-6\t\tother-1-1.x86_64\n(contains no files)\n")

    def test_owner_installed_and_ghosts(self):
        packages = ar.Packages()
        self.assertTrue(packages.rpm)
        self.assertEqual(packages.installed, {"foo-1.0-1.x86_64", "kernel-core-6-1.x86_64", "other-1-1.x86_64"})
        self.assertEqual(packages.owner["/usr/bin/foo"], "foo-1.0-1.x86_64")
        self.assertIn("/var/log/foo.log", packages.ghost)

    def test_the_first_package_listing_a_path_owns_it_and_a_ghost_another_installs_is_none(self):
        packages = ar.Packages()
        self.assertEqual(packages.owner["/boot/vmlinuz-6"], "kernel-core-6-1.x86_64")
        self.assertNotIn("/boot/vmlinuz-6", packages.ghost)

    def test_rpm_verifies_by_the_whole_name(self):
        self.assertEqual(ar.Packages().package("foo-1.0-1.x86_64"), "foo-1.0-1.x86_64")

    def test_an_mtime_alone_leaves_the_file_as_the_package_has_it(self):
        packages = ar.Packages()
        self.output("rpm", ".......T.    /usr/bin/foo\nS.5....T.  c /etc/foo.conf\nmissing     /var/log/foo.log\n")
        self.assertEqual(packages.unverified(["/usr/bin/foo", "/etc/foo.conf", "/var/log/foo.log"]),
                         {"/etc/foo.conf", "/var/log/foo.log"})


class Canonical(unittest.TestCase):
    def test_a_path_below_a_merged_link_is_reported_below_usr(self):
        packages = support.FakePackages()
        packages.merged = {"/bin": "/usr/bin", "/lib": "/usr/lib"}
        self.assertEqual(ar.Packages.canonical(packages, "/bin/sh"), "/usr/bin/sh")
        self.assertEqual(ar.Packages.canonical(packages, "/lib/systemd/system/x.service"), "/usr/lib/systemd/system/x.service")
        self.assertEqual(ar.Packages.canonical(packages, "/bin"), "/bin")
        self.assertEqual(ar.Packages.canonical(packages, "/etc/passwd"), "/etc/passwd")


class Manifest(unittest.TestCase):
    def test_owner_installed_and_dpkg_diversions(self):
        packages = support.FakePackages(owner={"/usr/bin/foo": "foo=1"}, installed={"foo=1", "bar=2"})
        diversion = ("/usr/sbin/grub-install", "/usr/sbin/grub-install.real", "proxmox-kernel-helper")
        with mock.patch.object(ar, "diversions", return_value={diversion}):
            manifest = ar.package_manifest(packages)
        self.assertEqual(manifest, {"owner": {"/usr/bin/foo": "foo=1"}, "installed": ["bar=2", "foo=1"],
                                    "diversions": [diversion]})

    def test_no_diversions_with_rpm_or_without_the_file(self):
        with mock.patch.object(ar, "diversions", return_value={("a", "b", "c")}):
            self.assertNotIn("diversions", ar.package_manifest(support.FakePackages(rpm=True)))
        with mock.patch.object(ar, "diversions", return_value=None):
            self.assertNotIn("diversions", ar.package_manifest(support.FakePackages()))


class DpkgFiles(support.TreeTestCase):
    def test_diversions_in_threes(self):
        path = self.write("diversions", "/a\n/a.real\npkg\n/b\n/b.distrib\n:\n/partial\n")
        self.assertEqual(ar.diversions(path), {("/a", "/a.real", "pkg"), ("/b", "/b.distrib", ":")})
        self.assertIsNone(ar.diversions(self.path("missing")))

    def test_file_triggers_as_lines(self):
        path = self.write("File", "/usr/share/info install-info/noawait\n/usr/lib/x foo\n")
        with mock.patch.object(ar, "DPKG_FILE_TRIGGERS", path):
            self.assertEqual(ar.file_triggers(), {"/usr/share/info install-info/noawait", "/usr/lib/x foo"})
        with mock.patch.object(ar, "DPKG_FILE_TRIGGERS", self.path("missing")):
            self.assertIsNone(ar.file_triggers())

    def test_declared_file_triggers_of_path_interests(self):
        self.write("info/install-info.triggers", "interest-noawait /usr/share/info\n")
        self.write("info/foo.triggers", "interest /usr/lib/x # a comment\ninterest-await /usr/lib/y\n"
                                        "activate-noawait ldconfig\ninterest name-trigger\n")
        with mock.patch.object(ar, "DPKG_TRIGGER_RECORDS", self.path("info") + "/*.triggers"):
            self.assertEqual(ar.declared_file_triggers(), {
                "/usr/share/info install-info/noawait", "/usr/lib/x foo", "/usr/lib/y foo"})


class KernelPackage(unittest.TestCase):
    def test_the_owner_of_its_image(self):
        self.assertEqual(ar.kernel_package("6.8.0-1", {"/usr/lib/modules/6.8.0-1/vmlinuz": "k=1"}), "k=1")
        self.assertEqual(ar.kernel_package("6.8.0-1", {"/boot/vmlinuz-6.8.0-1": "k=2"}), "k=2")
        self.assertIsNone(ar.kernel_package("6.8.0-1", {"/boot/vmlinuz-6.8.0-2": "k=3"}))


if __name__ == "__main__":
    unittest.main()
