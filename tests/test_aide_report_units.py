"""aide-report's reading of systemd units and init scripts: the links enabling
a unit makes, and the expressions the refresh moves the baseline by for them."""

import os
import unittest
from unittest import mock

import support

ar = support.load_aide_report()


class UnitTree(support.TreeTestCase):
    """A scratch tree standing in for /etc/systemd/system and systemd's unit paths."""

    def setUp(self):
        super().setUp()
        self.units = self.path("etc/systemd/system")
        self.library = self.path("usr/lib/systemd/system")
        os.makedirs(self.units)
        os.makedirs(self.library)
        for name, value in (("SYSTEMD_UNITS", self.units), ("UNIT_PATHS", (self.units, self.library))):
            patcher = mock.patch.object(ar, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def unit(self, name, install=""):
        return self.write("usr/lib/systemd/system/" + name, "[Unit]\nDescription=x\n\n[Service]\nExecStart=/bin/true\n"
                          + ("\n[Install]\n" + install if install else ""))


class InstallSettings(UnitTree):
    def test_reads_the_install_section_only(self):
        path = self.write("unit.service", "[Unit]\nWantedBy=ignored.target\n[Install]\nWantedBy=a.target b.target\n"
                          "# WantedBy=commented.target\n; Alias=also-commented.service\nAlias=x.service\n"
                          "WantedBy = c.target\n[X-Other]\nAlias=ignored.service\n")
        self.assertEqual(ar.install_settings(path), {"WantedBy": ["a.target", "b.target", "c.target"],
                                                     "Alias": ["x.service"]})

    def test_nothing_without_the_file(self):
        self.assertEqual(ar.install_settings(self.path("missing.service")), {})


class InstallLinks(UnitTree):
    def test_a_link_for_each_target_and_alias(self):
        path = self.unit("foo.service", "WantedBy=multi-user.target\nRequiredBy=a.target\nUpheldBy=b.target\n"
                                        "Alias=bar.service\n")
        self.assertEqual(ar.install_links(path), {
            self.units + "/multi-user.target.wants/foo.service",
            self.units + "/a.target.requires/foo.service",
            self.units + "/b.target.upholds/foo.service",
            self.units + "/bar.service",
        })

    def test_an_instance_of_a_template_is_named_for_the_instance(self):
        path = self.unit("getty@.service", "WantedBy=getty.target\n")
        self.assertEqual(ar.install_links(path, "getty@tty1.service"), {self.units + "/getty.target.wants/getty@tty1.service"})


class LsbRunlevels(support.TreeTestCase):
    def test_default_start_and_stop(self):
        script = self.write("etc/init.d/foo", "#!/bin/sh\n### BEGIN INIT INFO\n# Default-Start:     2 3 4 5\n"
                                              "# Default-Stop:      0 1 6\n### END INIT INFO\n")
        self.assertEqual(ar.lsb_runlevels(script), ({"2", "3", "4", "5"}, {"0", "1", "6"}))

    def test_none_without_the_script(self):
        self.assertEqual(ar.lsb_runlevels(self.path("missing")), (set(), set()))


class UnitFile(UnitTree):
    def test_the_first_along_the_search_path(self):
        self.unit("foo.service")
        override = self.write("etc/systemd/system/foo.service", "[Service]\n")
        self.assertEqual(ar.unit_file("foo.service"), os.path.realpath(override))

    def test_a_mask_is_no_file(self):
        library = self.unit("foo.service")
        os.symlink("/dev/null", self.units + "/foo.service")
        self.assertEqual(ar.unit_file("foo.service"), os.path.realpath(library))

    def test_an_instance_falls_back_to_its_template(self):
        template = self.unit("getty@.service")
        self.assertEqual(ar.unit_file("getty@tty1.service"), os.path.realpath(template))

    def test_none_for_an_unknown_unit(self):
        self.assertIsNone(ar.unit_file("missing.service"))


class UnitLinks(UnitTree):
    def any_directory(self, unit):
        return "%s/([^/]+\\.(wants|requires|upholds)/)?%s" % (ar.regex(self.units), ar.regex(unit))

    def test_a_unit_named_without_a_suffix_is_a_service(self):
        self.assertEqual(ar.unit_links(["foo"]), [self.any_directory("foo.service")])

    def test_an_unknown_or_masked_unit_has_only_its_own_name(self):
        os.symlink("/dev/null", self.units + "/masked.service")
        self.assertEqual(ar.unit_links(["masked.timer"]), [self.any_directory("masked.timer")])

    def test_its_install_links_with_each_directory_that_holds_one_now(self):
        self.unit("foo.service", "WantedBy=multi-user.target timers.target\nAlias=bar.service\n")
        os.makedirs(self.units + "/multi-user.target.wants")
        os.symlink(self.library + "/foo.service", self.units + "/multi-user.target.wants/foo.service")
        patterns = ar.unit_links(["foo.service"])
        self.assertCountEqual(patterns, [
            self.any_directory("foo.service"),
            # The directory holding a link of the unit now, found by its name.
            ar.regex(self.units + "/multi-user.target.wants"),
            # Each link its [Install] names, there now or not.
            ar.regex(self.units + "/multi-user.target.wants/foo.service"),
            ar.regex(self.units + "/timers.target.wants/foo.service"),
            ar.regex(self.units + "/bar.service"),
            # The directory of each link its [Install] names, there now or not.
            ar.regex(self.units + "/multi-user.target.wants"),
            ar.regex(self.units + "/timers.target.wants"),
        ])

    def test_the_directory_of_a_link_gone_with_it(self):
        # A disable that empties a .wants directory removes it with the link.
        self.unit("foo.service", "WantedBy=remote-fs.target\n")
        patterns = ar.unit_links(["foo.service"])
        self.assertIn(ar.regex(self.units + "/remote-fs.target.wants/foo.service"), patterns)
        self.assertIn(ar.regex(self.units + "/remote-fs.target.wants"), patterns)

    def test_an_instance_of_a_template(self):
        self.unit("getty@.service", "WantedBy=getty.target\n")
        self.assertCountEqual(ar.unit_links(["getty@tty1.service"]), [
            self.any_directory("getty@tty1.service"),
            ar.regex(self.units + "/getty.target.wants/getty@tty1.service"),
            ar.regex(self.units + "/getty.target.wants"),
        ])

    def test_an_alias_file_is_named_for_the_unit_it_names(self):
        target = self.unit("real.service", "WantedBy=multi-user.target\n")
        os.symlink(target, self.library + "/alias.service")
        self.assertIn(ar.regex(self.units + "/multi-user.target.wants/real.service"), ar.unit_links(["alias.service"]))

    def test_the_units_its_also_names(self):
        self.unit("foo.service", "WantedBy=multi-user.target\nAlso=foo.socket\n")
        self.unit("foo.socket", "WantedBy=sockets.target\n")
        patterns = ar.unit_links(["foo.service"])
        self.assertIn(self.any_directory("foo.socket"), patterns)
        self.assertIn(ar.regex(self.units + "/sockets.target.wants/foo.socket"), patterns)

    def test_each_unit_once(self):
        self.unit("a.service", "Also=b.service\n")
        self.unit("b.service", "Also=a.service\n")
        patterns = ar.unit_links(["a.service", "b.service", "a"])
        self.assertEqual(sorted(patterns), sorted([self.any_directory("a.service"), self.any_directory("b.service")]))


if __name__ == "__main__":
    unittest.main()
