"""explain(): which changes in AIDE's report the host's packages, and
aide-report's other rules, account for, and which the mail keeps.

Each rule has a case it explains and one it keeps. Tests named for a gap
record what aide-report does today where the triage of 2026-11-08 found it
wanting; a fix changes them on purpose."""

import os
import unittest
from unittest import mock

import support
from support import (ADDED_DIRECTORY, ADDED_FILE, ADDED_LINK, REMOVED_DIRECTORY, REMOVED_FILE, REMOVED_LINK,
                     FakePackages, attributes, report, summary)

ar = support.load_aide_report()

CHANGED_FILE = summary("f")
CHANGED_LINK = summary("l")
CHANGED_DIRECTORY = summary("d")
# Contents compared unchanged: a file's hashes, a symlink's target.
SAME_HASHES = summary("f", unchanged=(ar.SUMMARY_HASHES,))
SAME_TARGET = summary("l", unchanged=(ar.SUMMARY_LINK_NAME,))


def explain(entries, packages=None, manifest=None, **keywords):
    return ar.explain(entries, packages or FakePackages(), manifest if manifest is not None else {}, **keywords)


def kept_paths(kept):
    return {section: sorted(items) for section, items in kept.items() if items}


class ReportShape(unittest.TestCase):
    def test_nothing_to_explain(self):
        self.assertEqual(explain(report()), ({"added": {}, "removed": {}, "changed": {}}, 0))

    def test_a_section_may_be_a_list_of_paths(self):
        packages = FakePackages(owner={"/usr/bin/new": "new=1"})
        kept, explained = explain({"added": ["/usr/bin/new", "/usr/bin/stray"]}, packages)
        self.assertEqual(kept_paths(kept), {"added": ["/usr/bin/stray"]})
        self.assertEqual(kept["added"]["/usr/bin/stray"], "")
        self.assertEqual(explained, 1)

    def test_kept_entries_keep_their_summaries(self):
        kept, _ = explain(report(changed={"/etc/x": CHANGED_FILE}, details={"/etc/x": attributes("sha256")}))
        self.assertEqual(kept["changed"], {"/etc/x": CHANGED_FILE})


class Directories(unittest.TestCase):
    def test_a_directory_whose_timestamps_size_inode_or_links_changed(self):
        entries = report(changed={"/etc/d": CHANGED_DIRECTORY},
                         details={"/etc/d": attributes("modify_time", "change_time", "size", "block_count", "inode",
                                                       "link_count")})
        self.assertEqual(explain(entries), ({"added": {}, "removed": {}, "changed": {}}, 1))

    def test_kept_a_directory_whose_mode_changed(self):
        entries = report(changed={"/etc/d": CHANGED_DIRECTORY}, details={"/etc/d": attributes("modify_time", "perm")})
        self.assertEqual(kept_paths(explain(entries)[0]), {"changed": ["/etc/d"]})


class Rewritten(unittest.TestCase):
    def test_a_file_rewritten_with_what_it_held(self):
        entries = report(changed={"/etc/hostname": SAME_HASHES},
                         details={"/etc/hostname": attributes("modify_time", "change_time", "inode", "access_time")})
        self.assertEqual(explain(entries)[1], 1)

    def test_a_link_rewritten_with_its_target(self):
        entries = report(changed={"/etc/l": SAME_TARGET}, details={"/etc/l": attributes("change_time", "inode")})
        self.assertEqual(explain(entries)[1], 1)

    def test_kept_a_rewrite_that_changed_more_than_its_timestamps(self):
        entries = report(changed={"/etc/hostname": SAME_HASHES},
                         details={"/etc/hostname": attributes("modify_time", "perm")})
        self.assertEqual(kept_paths(explain(entries)[0]), {"changed": ["/etc/hostname"]})

    def test_kept_one_whose_contents_its_rule_does_not_compare(self):
        # As under Enterprise Linux's /etc PERMS: the hashes' column is blank,
        # so a change of times alone does not show the contents unchanged.
        not_compared = CHANGED_FILE[:ar.SUMMARY_HASHES] + " " + CHANGED_FILE[ar.SUMMARY_HASHES + 1:]
        entries = report(changed={"/etc/sudoers.d/x": not_compared},
                         details={"/etc/sudoers.d/x": attributes("modify_time", "change_time", "inode")})
        self.assertEqual(kept_paths(explain(entries)[0]), {"changed": ["/etc/sudoers.d/x"]})

    def test_kept_a_link_whose_target_was_not_compared(self):
        entries = report(changed={"/etc/l": CHANGED_LINK}, details={"/etc/l": attributes("change_time", "inode")})
        self.assertEqual(kept_paths(explain(entries)[0]), {"changed": ["/etc/l"]})

    def test_kept_new_contents_no_package_owns(self):
        entries = report(changed={"/etc/hostname": CHANGED_FILE},
                         details={"/etc/hostname": attributes("sha256", "modify_time")})
        self.assertEqual(kept_paths(explain(entries)[0]), {"changed": ["/etc/hostname"]})

    def test_a_service_rewriting_a_file_a_login_wrote(self):
        details = attributes("modify_time")
        details["selinux"] = {"old": "unconfined_u:object_r:etc_t:s0", "new": "system_u:object_r:etc_t:s0"}
        details["xattrs"] = {"old": ["user.x = 1", " security.selinux = a"], "new": ["user.x = 1", " security.selinux = b"]}
        entries = report(changed={"/etc/resolv.conf": SAME_HASHES}, details={"/etc/resolv.conf": details})
        self.assertEqual(explain(entries)[1], 1)

    def test_kept_a_label_whose_type_changed(self):
        details = attributes("modify_time")
        details["selinux"] = {"old": "system_u:object_r:etc_t:s0", "new": "system_u:object_r:shadow_t:s0"}
        entries = report(changed={"/etc/resolv.conf": SAME_HASHES}, details={"/etc/resolv.conf": details})
        self.assertEqual(kept_paths(explain(entries)[0]), {"changed": ["/etc/resolv.conf"]})


class DpkgVouches(unittest.TestCase):
    def packages(self, **keywords):
        return FakePackages(owner={"/usr/bin/foo": "foo=2", "/usr/share/doc/apt/changelog.gz": "apt=3.2.1"}, **keywords)

    def test_new_contents_dpkg_verifies(self):
        entries = report(changed={"/usr/bin/foo": CHANGED_FILE},
                         details={"/usr/bin/foo": attributes("sha256", "size", "modify_time", "inode")})
        packages = self.packages()
        self.assertEqual(explain(entries, packages)[1], 1)
        self.assertIn("/usr/bin/foo", packages.asked[0])

    def test_kept_contents_dpkg_does_not_verify(self):
        entries = report(changed={"/usr/bin/foo": CHANGED_FILE}, details={"/usr/bin/foo": attributes("sha256")})
        self.assertEqual(kept_paths(explain(entries, self.packages(unverified={"/usr/bin/foo"}))[0]),
                         {"changed": ["/usr/bin/foo"]})

    def test_kept_a_mode_dpkg_does_not_record(self):
        entries = report(changed={"/usr/bin/foo": CHANGED_FILE}, details={"/usr/bin/foo": attributes("perm")})
        self.assertEqual(kept_paths(explain(entries, self.packages())[0]), {"changed": ["/usr/bin/foo"]})

    def test_gap_kept_a_link_an_upgrade_made_a_file(self):
        # apt's docs on every Ubuntu host: dpkg verifies the new file, but its
        # type and mode changed with the upgrade.
        path = "/usr/share/doc/apt/changelog.gz"
        entries = report(changed={path: CHANGED_FILE},
                         details={path: attributes("file_type", "perm", "size", "sha256", "inode", "modify_time")})
        self.assertEqual(kept_paths(explain(entries, self.packages())[0]), {"changed": [path]})

    def test_a_file_a_package_installed(self):
        entries = report(added={"/usr/bin/foo": ADDED_FILE})
        self.assertEqual(explain(entries, self.packages())[1], 1)

    def test_kept_a_file_no_package_owns(self):
        entries = report(added={"/usr/local/bin/stray": ADDED_FILE})
        self.assertEqual(kept_paths(explain(entries, self.packages())[0]), {"added": ["/usr/local/bin/stray"]})


class RpmVouches(unittest.TestCase):
    def packages(self, **keywords):
        return FakePackages(owner={"/usr/bin/foo": "foo-2-1.x86_64", "/var/log/foo.log": "foo-2-1.x86_64"},
                            rpm=True, **keywords)

    def test_rpm_verifies_mode_ownership_and_type(self):
        entries = report(changed={"/usr/bin/foo": CHANGED_FILE},
                         details={"/usr/bin/foo": attributes("sha256", "perm", "uid", "file_type")})
        self.assertEqual(explain(entries, self.packages())[1], 1)

    def test_kept_what_rpm_does_not_record(self):
        for attribute in sorted(ar.UNRECORDED):
            entries = report(changed={"/usr/bin/foo": CHANGED_FILE}, details={"/usr/bin/foo": attributes(attribute)})
            self.assertEqual(kept_paths(explain(entries, self.packages())[0]), {"changed": ["/usr/bin/foo"]}, attribute)

    def test_kept_a_ghost_rpm_never_vouches_for(self):
        entries = report(changed={"/var/log/foo.log": CHANGED_FILE}, details={"/var/log/foo.log": attributes("sha256")})
        packages = self.packages(ghost={"/var/log/foo.log"})
        self.assertEqual(kept_paths(explain(entries, packages)[0]), {"changed": ["/var/log/foo.log"]})


class DpkgRecords(unittest.TestCase):
    def test_a_record_of_a_package_whose_version_changed(self):
        entries = report(changed={"/var/lib/dpkg/info/foo.md5sums": CHANGED_FILE},
                         details={"/var/lib/dpkg/info/foo.md5sums": attributes("sha256")})
        packages = FakePackages(installed={"foo=2"})
        self.assertEqual(explain(entries, packages, {"installed": ["foo=1"]})[1], 1)

    def test_a_record_whose_contents_are_unchanged(self):
        entries = report(changed={"/var/lib/dpkg/info/foo.list": CHANGED_FILE},
                         details={"/var/lib/dpkg/info/foo.list": attributes("change_time", "inode")})
        packages = FakePackages(installed={"foo=1"})
        self.assertEqual(explain(entries, packages, {"installed": ["foo=1"]})[1], 1)

    def test_kept_new_contents_of_a_record_whose_package_did_not_change(self):
        entries = report(changed={"/var/lib/dpkg/info/foo.postinst": CHANGED_FILE},
                         details={"/var/lib/dpkg/info/foo.postinst": attributes("sha256")})
        packages = FakePackages(installed={"foo=1"})
        self.assertEqual(kept_paths(explain(entries, packages, {"installed": ["foo=1"]})[0]),
                         {"changed": ["/var/lib/dpkg/info/foo.postinst"]})

    def test_a_record_gone_with_its_package(self):
        entries = report(removed={"/var/lib/dpkg/info/foo.list": REMOVED_FILE})
        self.assertEqual(explain(entries, FakePackages(installed=set()), {"installed": ["foo=1"]})[1], 1)

    def test_not_on_an_rpm_host(self):
        entries = report(changed={"/var/lib/dpkg/info/foo.md5sums": CHANGED_FILE},
                         details={"/var/lib/dpkg/info/foo.md5sums": attributes("sha256")})
        packages = FakePackages(installed={"foo=2"}, rpm=True)
        self.assertEqual(kept_paths(explain(entries, packages, {"installed": ["foo=1"]})[0]),
                         {"changed": ["/var/lib/dpkg/info/foo.md5sums"]})


class PackageLinks(support.TreeTestCase):
    def test_a_link_to_a_file_its_package_vouches_for(self):
        target = self.write("usr/lib/libfoo.so.2")
        link = self.link("usr/lib/libfoo.so", target)
        packages = FakePackages(owner={link: "foo=2", target: "foo=2"})
        entries = report(changed={link: CHANGED_LINK}, details={link: attributes("link_name", "change_time")})
        self.assertEqual(explain(entries, packages)[1], 1)

    def test_kept_a_link_to_a_file_no_package_owns(self):
        target = self.write("usr/local/lib/libfoo.so.2")
        link = self.link("usr/lib/libfoo.so", target)
        packages = FakePackages(owner={link: "foo=2"})
        entries = report(changed={link: CHANGED_LINK}, details={link: attributes("link_name")})
        self.assertEqual(kept_paths(explain(entries, packages)[0]), {"changed": [link]})


class KernelCopies(unittest.TestCase):
    release = "6.12.0-208.el9uek.aarch64"

    def test_a_copy_holding_what_the_file_it_copies_holds(self):
        copy, twin = "/boot/vmlinuz-" + self.release, "/usr/lib/modules/%s/vmlinuz" % self.release
        packages = FakePackages(owner={twin: "kernel-uek-core", copy: "kernel-uek-core"}, ghost={copy}, rpm=True)
        with mock.patch.object(ar, "same_contents", lambda a, b: (a, b) == (copy, twin)):
            self.assertEqual(explain(report(added={copy: ADDED_FILE}), packages)[1], 1)

    def test_kept_a_copy_whose_contents_differ(self):
        copy, twin = "/boot/vmlinuz-" + self.release, "/usr/lib/modules/%s/vmlinuz" % self.release
        packages = FakePackages(owner={twin: "kernel-uek-core"}, rpm=True)
        with mock.patch.object(ar, "same_contents", return_value=False):
            self.assertEqual(kept_paths(explain(report(added={copy: ADDED_FILE}), packages)[0]), {"added": [copy]})

    def test_the_copies_are_vmlinuz_system_map_config_hmac_and_symvers(self):
        names = {"/boot/vmlinuz-R": "/usr/lib/modules/R/vmlinuz", "/boot/System.map-R": "/usr/lib/modules/R/System.map",
                 "/boot/config-R": "/usr/lib/modules/R/config", "/boot/.vmlinuz-R.hmac": "/usr/lib/modules/R/.vmlinuz.hmac",
                 "/boot/symvers-R.gz": "/usr/lib/modules/R/symvers.gz"}
        for copy, twin in names.items():
            self.assertEqual([pattern.sub(template, copy) for pattern, template in ar.KERNEL_COPIES if pattern.match(copy)],
                             [twin])

    def test_gap_kept_device_tree_copies(self):
        path = "/boot/dtb-%s/apm/apm-merlin.dtb" % self.release
        packages = FakePackages(owner={path: "kernel-uek-core"}, ghost={path}, rpm=True)
        self.assertEqual(kept_paths(explain(report(added={path: ADDED_FILE}), packages)[0]), {"added": [path]})


class Caches(unittest.TestCase):
    def test_a_cache_its_tool_builds_the_same_now(self):
        entries = report(changed={"/etc/ld.so.cache": CHANGED_FILE},
                         details={"/etc/ld.so.cache": attributes("sha256", "size", "modify_time")})
        with mock.patch.object(ar, "rebuilds_same", return_value=True) as rebuilds:
            self.assertEqual(explain(entries, scratch="/scratch")[1], 1)
        rebuilds.assert_called_once_with("/etc/ld.so.cache", ["ldconfig", "-i", "-X", "-C"], "/scratch")

    def test_kept_without_a_scratch_directory_or_a_same_rebuild(self):
        entries = report(changed={"/etc/ld.so.cache": CHANGED_FILE}, details={"/etc/ld.so.cache": attributes("sha256")})
        with mock.patch.object(ar, "rebuilds_same", return_value=True):
            self.assertEqual(kept_paths(explain(entries)[0]), {"changed": ["/etc/ld.so.cache"]})
        with mock.patch.object(ar, "rebuilds_same", return_value=False):
            self.assertEqual(kept_paths(explain(entries, scratch="/scratch")[0]), {"changed": ["/etc/ld.so.cache"]})

    def test_gconv_in_the_native_library_directory(self):
        self.assertTrue(ar.REBUILT[1][0].match("/usr/lib64/gconv/gconv-modules.cache"))
        self.assertTrue(ar.REBUILT[1][0].match("/usr/lib/x86_64-linux-gnu/gconv/gconv-modules.cache"))
        self.assertFalse(ar.REBUILT[1][0].match("/usr/lib32/gconv/gconv-modules.cache"))


class KernelGenerated(unittest.TestCase):
    release = "6.8.0-149-generic"
    image = "/usr/lib/modules/6.8.0-149-generic/vmlinuz"
    package = "linux-image-6.8.0-149-generic=6.8.0-149.149"

    def test_added_with_a_kernel_installed_since_the_baseline(self):
        for path in ("/boot/initrd.img-" + self.release, "/boot/initramfs-%s.img" % self.release,
                     "/var/lib/initramfs-tools/" + self.release, "/usr/lib/modules/%s/modules.dep" % self.release,
                     "/boot/loader/entries/%s-%s.conf" % ("0" * 32, self.release)):
            packages = FakePackages(owner={self.image: self.package})
            self.assertEqual(explain(report(added={path: ADDED_FILE}), packages, {"installed": ["other=1"]})[1], 1, path)

    def test_kept_when_the_kernel_was_installed_at_the_baseline(self):
        path = "/boot/initrd.img-" + self.release
        packages = FakePackages(owner={self.image: self.package})
        self.assertEqual(kept_paths(explain(report(added={path: ADDED_FILE}), packages, {"installed": [self.package]})[0]),
                         {"added": [path]})

    def test_gone_with_a_kernel_removed_since(self):
        path = "/boot/initrd.img-" + self.release
        manifest = {"owner": {self.image: self.package}, "installed": [self.package]}
        self.assertEqual(explain(report(removed={path: REMOVED_FILE}), FakePackages(installed=set()), manifest)[1], 1)

    def test_kept_a_package_owned_path(self):
        path = "/usr/lib/modules/%s/modules.builtin" % self.release
        packages = FakePackages(owner={self.image: self.package, path: self.package}, unverified={path})
        self.assertEqual(kept_paths(explain(report(added={path: ADDED_FILE}), packages, {"installed": []})[0]),
                         {"added": [path]})

    def test_gap_kept_a_removed_kernels_indexes_rewritten(self):
        # depmod rewrites a removed kernel's indexes, which stay until a purge.
        path = "/usr/lib/modules/6.8.0-146-generic/modules.alias"
        entries = report(changed={path: CHANGED_FILE}, details={path: attributes("sha256", "size")})
        manifest = {"owner": {"/usr/lib/modules/6.8.0-146-generic/vmlinuz": "k=146"}, "installed": ["k=146"]}
        self.assertEqual(kept_paths(explain(entries, FakePackages(installed=set()), manifest)[0]), {"changed": [path]})

    def test_gap_kept_dkms_and_debian_kdump_files(self):
        packages = FakePackages(owner={self.image: self.package})
        for path in ("/var/lib/dkms/v4l2loopback/0.15.1/%s/x" % self.release,
                     "/usr/lib/modules/%s/updates/dkms/v4l2loopback.ko.zst" % self.release,
                     "/var/lib/kdump/initrd.img-" + self.release,
                     "/var/lib/dpkg/triggers/linux-update-" + self.release):
            self.assertEqual(kept_paths(explain(report(added={path: ADDED_FILE}), packages, {"installed": []})[0]),
                             {"added": [path]}, path)


class Kdump(unittest.TestCase):
    release = "6.12.0-208.112.5.el9uek.aarch64"
    accepted, booted = 1000, 2000

    def explained(self, written):
        path = "/boot/initramfs-%skdump.img" % self.release
        image = "/usr/lib/modules/%s/vmlinuz" % self.release
        packages = FakePackages(owner={image: "kernel-uek-core"}, rpm=True)
        manifest = {"installed": ["kernel-uek-core"]}
        real_getmtime = os.path.getmtime
        with mock.patch.object(ar, "boot_time", return_value=self.booted), \
                mock.patch.object(ar.os, "uname", return_value=mock.Mock(release=self.release)), \
                mock.patch.object(ar.os.path, "getmtime", lambda p: written if p == path else real_getmtime(p)):
            return explain(report(added={path: ADDED_FILE}), packages, manifest, accepted=self.accepted)[1]

    def test_built_during_this_boot_into_the_running_kernel(self):
        self.assertEqual(self.explained(written=self.booted + 60), 1)

    def test_gap_kept_one_built_during_an_earlier_boot_after_the_baseline(self):
        self.assertEqual(self.explained(written=self.booted - 60), 0)


class InstalledWith(support.TreeTestCase):
    def setUp(self):
        super().setUp()
        self.units = self.path("etc/systemd/system")
        self.dsh = self.path("var/lib/systemd/deb-systemd-helper-enabled")
        for name, value in (("SYSTEMD_UNITS", self.units), ("DSH_STATE", self.dsh)):
            patcher = mock.patch.object(ar, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)
        self.unit = self.write("usr/lib/systemd/system/foo.service", "[Install]\nWantedBy=multi-user.target\n")
        self.wants = self.units + "/multi-user.target.wants"
        self.enabled = self.link("etc/systemd/system/multi-user.target.wants/foo.service", self.unit)

    def entries(self):
        return report(added={self.wants: ADDED_DIRECTORY, self.enabled: ADDED_LINK})

    def test_a_link_its_new_packages_unit_makes_and_the_directory_holding_it(self):
        packages = FakePackages(owner={os.path.realpath(self.unit): "foo=1"})
        self.assertEqual(explain(self.entries(), packages, {"installed": ["other=1"]}), (
            {"added": {}, "removed": {}, "changed": {}}, 2))

    def test_kept_when_its_package_was_installed_at_the_baseline(self):
        packages = FakePackages(owner={os.path.realpath(self.unit): "foo=1"})
        self.assertEqual(kept_paths(explain(self.entries(), packages, {"installed": ["foo=1"]})[0]),
                         {"added": sorted([self.wants, self.enabled])})

    def test_kept_a_link_its_unit_does_not_name(self):
        other = self.link("etc/systemd/system/other.target.wants/foo.service", self.unit)
        packages = FakePackages(owner={os.path.realpath(self.unit): "foo=1"})
        kept, _ = explain(report(added={other: ADDED_LINK}), packages, {"installed": []})
        self.assertEqual(kept_paths(kept), {"added": [other]})

    def test_deb_systemd_helpers_record_of_the_links(self):
        mirror = self.write("var/lib/systemd/deb-systemd-helper-enabled/multi-user.target.wants/foo.service")
        also = self.write("var/lib/systemd/deb-systemd-helper-enabled/foo.service.dsh-also", self.enabled + "\n")
        packages = FakePackages(owner={"/lib/systemd/system/foo.service": "foo=1"})
        links = {"/lib/systemd/system/foo.service": {self.enabled}}
        with mock.patch.object(ar, "install_links", lambda source, name=None: links.get(source, set())):
            kept, explained = explain(report(added={mirror: ADDED_FILE, also: ADDED_FILE}), packages, {"installed": []})
        self.assertEqual((kept_paths(kept), explained), ({}, 2))

    def test_update_rc_d_links_by_the_scripts_runlevels(self):
        script = "/etc/init.d/aide-tests-foo"
        start = self.link("etc/rc2.d/S01aide-tests-foo", script)
        stop = self.link("etc/rc2.d/K01aide-tests-foo", script)
        packages = FakePackages(owner={script: "foo=1"})
        sysv = ar.re.compile("^" + ar.re.escape(self.root) + r"/etc/rc([0-6S])\.d/([SK])\d\d([^/]+)$")
        with mock.patch.object(ar, "SYSV_LINK", sysv), \
                mock.patch.object(ar, "lsb_runlevels", return_value=({"2", "3", "4", "5"}, {"0", "1", "6"})), \
                mock.patch.object(ar.os.path, "realpath", lambda p: script if p in (start, stop) else p):
            kept, explained = explain(report(added={start: ADDED_LINK, stop: ADDED_LINK}), packages, {"installed": []})
        self.assertEqual((kept_paths(kept), explained), ({"added": [stop]}, 1))


class RemovedWith(support.TreeTestCase):
    def setUp(self):
        super().setUp()
        self.units = self.path("etc/systemd/system")
        self.dsh = self.path("var/lib/systemd/deb-systemd-helper-enabled")
        for name, value in (("SYSTEMD_UNITS", self.units), ("DSH_STATE", self.dsh)):
            patcher = mock.patch.object(ar, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)
        self.link_path = self.units + "/multi-user.target.wants/bar.service"
        self.record = self.dsh + "/multi-user.target.wants/bar.service"
        self.manifest = {"owner": {"/lib/systemd/system/bar.service": "bar=1"}, "installed": ["bar=1"]}

    def test_links_and_records_gone_with_the_package_that_owned_their_unit(self):
        entries = report(removed={self.link_path: REMOVED_LINK, self.record: REMOVED_FILE})
        self.assertEqual(explain(entries, FakePackages(installed=set()), self.manifest)[1], 2)

    def test_kept_while_that_package_is_installed(self):
        entries = report(removed={self.link_path: REMOVED_LINK})
        self.assertEqual(kept_paths(explain(entries, FakePackages(installed={"bar=1"}), self.manifest)[0]),
                         {"removed": [self.link_path]})

    def test_the_directory_a_removal_emptied(self):
        # The NFS removal on the OCI instances: the link, and its directory,
        # which systemctl removed once empty.
        wants = self.units + "/remote-fs.target.wants"
        manifest = {"owner": {"/lib/systemd/system/nfs-client.target": "nfs-utils-2.5.4"}, "installed": ["nfs-utils-2.5.4"]}
        entries = report(removed={wants: REMOVED_DIRECTORY, wants + "/nfs-client.target": REMOVED_LINK})
        kept, explained = explain(entries, FakePackages(installed=set(), rpm=True), manifest)
        self.assertEqual((kept_paths(kept), explained), ({}, 2))

    def test_kept_a_removed_directory_holding_a_kept_removal(self):
        wants = self.units + "/remote-fs.target.wants"
        manifest = {"owner": {"/lib/systemd/system/nfs-client.target": "nfs-utils-2.5.4"}, "installed": ["nfs-utils-2.5.4"]}
        entries = report(removed={wants: REMOVED_DIRECTORY, wants + "/nfs-client.target": REMOVED_LINK,
                                  wants + "/stray.mount": REMOVED_LINK})
        kept, explained = explain(entries, FakePackages(installed=set(), rpm=True), manifest)
        self.assertEqual((kept_paths(kept), explained), ({"removed": sorted([wants, wants + "/stray.mount"])}, 1))


class Removed(unittest.TestCase):
    def test_gone_with_the_package_that_owned_it(self):
        manifest = {"owner": {"/usr/bin/foo": "foo=1"}, "installed": ["foo=1"]}
        self.assertEqual(explain(report(removed={"/usr/bin/foo": REMOVED_FILE}), FakePackages(installed={"foo=2"}),
                                 manifest)[1], 1)

    def test_kept_while_that_package_is_installed_in_that_version(self):
        manifest = {"owner": {"/usr/bin/foo": "foo=1"}, "installed": ["foo=1"]}
        self.assertEqual(kept_paths(explain(report(removed={"/usr/bin/foo": REMOVED_FILE}),
                                            FakePackages(installed={"foo=1"}), manifest)[0]),
                         {"removed": ["/usr/bin/foo"]})

    def test_kept_what_no_package_owned(self):
        self.assertEqual(kept_paths(explain(report(removed={"/etc/stray": REMOVED_FILE}))[0]), {"removed": ["/etc/stray"]})

    def test_now_below_an_excluded_path(self):
        self.assertEqual(explain(report(removed={"/var/log/x/y": REMOVED_FILE}), excluded=["/var/log"])[1], 1)

    def test_gap_kept_a_purged_packages_leftovers(self):
        # ufw on aboriginal: removed but not purged at the baseline, so its
        # leftovers had no recorded owner when Ansible purged it.
        manifest = {"owner": {}, "installed": ["other=1"]}
        self.assertEqual(kept_paths(explain(report(removed={"/etc/ufw/user.rules": REMOVED_FILE}),
                                            FakePackages(installed={"other=1"}), manifest)[0]),
                         {"removed": ["/etc/ufw/user.rules"]})

    def test_baseline_installed_defaults_to_the_owners(self):
        # A manifest without "installed" counts its owners' packages as installed.
        path = "/boot/initrd.img-6.8.0-1"
        packages = FakePackages(owner={"/usr/lib/modules/6.8.0-1/vmlinuz": "k=1"})
        manifest = {"owner": {"/usr/lib/modules/6.8.0-1/vmlinuz": "k=1"}}
        self.assertEqual(kept_paths(explain(report(added={path: ADDED_FILE}), packages, manifest)[0]), {"added": [path]})


class Diversions(unittest.TestCase):
    grub = ("/usr/sbin/grub-install", "/usr/sbin/grub-install.real", "proxmox-kernel-helper")

    def explained(self, current, before, installed_now, installed_then):
        entries = report(changed={ar.DPKG_DIVERSIONS: CHANGED_FILE}, details={ar.DPKG_DIVERSIONS: attributes("sha256")})
        with mock.patch.object(ar, "diversions", return_value=set(current)):
            return explain(entries, FakePackages(installed=installed_now),
                           {"installed": installed_then, "diversions": [list(d) for d in before]})[1]

    def test_added_by_a_package_installed_since(self):
        self.assertEqual(self.explained([self.grub], [], {"proxmox-kernel-helper=2"}, ["proxmox-kernel-helper=1"]), 1)

    def test_kept_one_added_by_hand(self):
        local = ("/usr/bin/x", "/usr/bin/x.real", ":")
        self.assertEqual(self.explained([local], [], {"a=1"}, ["a=1"]), 0)

    def test_kept_one_whose_package_did_not_change(self):
        self.assertEqual(self.explained([self.grub], [], {"proxmox-kernel-helper=1"}, ["proxmox-kernel-helper=1"]), 0)

    def test_gap_kept_a_diverted_files_new_path(self):
        # grub-install.real on prodingus: grub2-common's file, recorded only at
        # the path it was diverted from.
        path = "/usr/sbin/grub-install.real"
        packages = FakePackages(owner={"/usr/sbin/grub-install": "grub2-common=2"})
        self.assertEqual(kept_paths(explain(report(added={path: ADDED_FILE}), packages)[0]), {"added": [path]})


class FileTriggers(unittest.TestCase):
    def explained(self, listed, declared):
        entries = report(changed={ar.DPKG_FILE_TRIGGERS: CHANGED_FILE},
                         details={ar.DPKG_FILE_TRIGGERS: attributes("sha256")})
        with mock.patch.object(ar, "file_triggers", return_value=listed), \
                mock.patch.object(ar, "declared_file_triggers", return_value=declared):
            return explain(entries)[1]

    def test_dpkgs_list_as_the_packages_records_declare_it(self):
        self.assertEqual(self.explained({"/usr/share/info install-info/noawait"},
                                        {"/usr/share/info install-info/noawait"}), 1)

    def test_kept_a_list_that_differs(self):
        self.assertEqual(self.explained({"/usr/share/info install-info/noawait", "/x stray"},
                                        {"/usr/share/info install-info/noawait"}), 0)


class AddedDirectories(support.TreeTestCase):
    def test_a_new_directory_no_package_owns_holding_only_package_files(self):
        # rpm made /usr/libexec/dirsrv on riko as a parent no package owns.
        directory, owned = "/usr/libexec/dirsrv", "/usr/libexec/dirsrv/ds_systemd_ask_password_acl"
        packages = FakePackages(owner={owned: "389-ds-base-2"}, rpm=True)
        kept, explained = explain(report(added={directory: ADDED_DIRECTORY, owned: ADDED_FILE}), packages)
        self.assertEqual((kept_paths(kept), explained), ({}, 2))

    def test_new_directories_within_each_other(self):
        top, middle, owned = "/usr/share/tomcat", "/usr/share/tomcat/bin", "/usr/share/tomcat/bin/bootstrap.jar"
        packages = FakePackages(owner={owned: "tomcat-9"}, rpm=True)
        entries = report(added={top: ADDED_DIRECTORY, middle: ADDED_DIRECTORY, owned: ADDED_FILE})
        self.assertEqual(explain(entries, packages), ({"added": {}, "removed": {}, "changed": {}}, 3))

    def test_kept_a_new_directory_holding_nothing_the_report_lists(self):
        self.assertEqual(kept_paths(explain(report(added={"/usr/libexec/empty": ADDED_DIRECTORY}))[0]),
                         {"added": ["/usr/libexec/empty"]})

    def test_kept_a_removed_directory_that_held_nothing(self):
        self.assertEqual(kept_paths(explain(report(removed={"/etc/empty": REMOVED_DIRECTORY}))[0]),
                         {"removed": ["/etc/empty"]})

    def test_kept_a_new_directory_holding_a_kept_entry_and_its_parents(self):
        top, middle = "/opt/new", "/opt/new/bin"
        packages = FakePackages(owner={"/opt/new/bin/owned": "x=1"})
        entries = report(added={top: ADDED_DIRECTORY, middle: ADDED_DIRECTORY, middle + "/owned": ADDED_FILE,
                                middle + "/stray": ADDED_FILE})
        self.assertEqual(kept_paths(explain(entries, packages)[0]), {"added": sorted([top, middle, middle + "/stray"])})

    def test_kept_a_directory_a_sibling_of_a_kept_entry_shares_a_prefix_with(self):
        packages = FakePackages(owner={"/opt/a/owned": "x=1"})
        entries = report(added={"/opt/a": ADDED_DIRECTORY, "/opt/a/owned": ADDED_FILE, "/opt/ab": ADDED_FILE})
        self.assertEqual(kept_paths(explain(entries, packages)[0]), {"added": ["/opt/ab"]})

    def test_kept_a_new_units_directory_holding_a_kept_entry(self):
        units = self.path("etc/systemd/system")
        with mock.patch.object(ar, "SYSTEMD_UNITS", units):
            kept, _ = explain(report(added={units + "/x.target.wants": ADDED_DIRECTORY,
                                            units + "/x.target.wants/stray.service": ADDED_LINK}))
        self.assertEqual(kept_paths(kept), {"added": sorted([units + "/x.target.wants",
                                                             units + "/x.target.wants/stray.service"])})


class Unverified(unittest.TestCase):
    def test_one_question_for_every_candidate_target_copy_and_source(self):
        packages = FakePackages(owner={"/usr/bin/a": "a=1", "/usr/bin/b": "b=1"})
        explain(report(added={"/usr/bin/a": ADDED_FILE}, changed={"/usr/bin/b": CHANGED_FILE},
                       details={"/usr/bin/b": attributes("sha256")}), packages)
        self.assertEqual(packages.asked, [["/usr/bin/a", "/usr/bin/b"]])


if __name__ == "__main__":
    unittest.main()
