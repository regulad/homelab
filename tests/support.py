"""What the tests of AIDE's acceptance system share.

The tests run under Python 3.9, the oldest Python a host runs aide-report with
(Oracle Linux 9's), and write no bytecode beside the code they load.
"""

import contextlib
import gzip
import importlib.machinery
import importlib.util
import json
import os
import shutil
import sys
import tempfile
import types
import unittest
from unittest import mock

sys.dont_write_bytecode = True

REPOSITORY = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AIDE_REPORT = os.path.join(REPOSITORY, "ansible-common", "roles", "aide", "files", "aide-report")
CALLBACK = os.path.join(REPOSITORY, "ansible-common", "plugins", "callback", "aide_written.py")
TESTS = os.path.join(REPOSITORY, "tests")


def load_source(name, path):
    """A module from a file of Python, whatever its name ends with."""
    loader = importlib.machinery.SourceFileLoader(name, path)
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def load_aide_report():
    return load_source("aide_report", AIDE_REPORT)


def load_callback():
    """aide_written, with a stand-in for ansible-core's CallbackBase, so that
    its own logic runs under the tests' Python. test_ansible runs the callback
    in ansible-core itself."""
    stand_ins = {name: types.ModuleType(name) for name in ("ansible", "ansible.plugins", "ansible.plugins.callback")}

    class CallbackBase:
        def __init__(self):
            pass

    stand_ins["ansible.plugins.callback"].CallbackBase = CallbackBase
    with mock.patch.dict(sys.modules, stand_ins):
        return load_source("aide_written", CALLBACK)


# --- AIDE's JSON report --------------------------------------------------------

def summary(kind, unchanged=(), width=20):
    """A changed entry's summary as AIDE 0.18 and later writes it: the entry's
    type, then a column per attribute, '.' where AIDE found it unchanged."""
    columns = ["C"] * width
    for position in unchanged:
        columns[position - 1] = "."
    return kind + "".join(columns)


ADDED_FILE = "f" + "+" * 17
ADDED_LINK = "l" + "+" * 17
ADDED_DIRECTORY = "d" + "+" * 17
REMOVED_FILE = "f" + "-" * 17
REMOVED_LINK = "l" + "-" * 17
REMOVED_DIRECTORY = "d" + "-" * 17


def report(added=None, removed=None, changed=None, details=None):
    return {"added": added or {}, "removed": removed or {}, "changed": changed or {}, "details": details or {}}


def attributes(*names):
    """A changed entry's details for these attributes."""
    return {name: {"old": "old", "new": "new"} for name in names}


class FakePackages:
    """aide-report's Packages, as the test sets it out."""

    def __init__(self, owner=None, installed=None, ghost=(), rpm=False, unverified=()):
        self.rpm = rpm
        self.merged = {}
        self.owner = dict(owner or {})
        self.installed = set(self.owner.values() if installed is None else installed)
        self.ghost = set(ghost)
        self.failing = set(unverified)
        self.asked = []

    def canonical(self, path):
        return path

    def versions(self):
        return dict(package_id.split("=", 1) for package_id in self.installed if "=" in package_id)

    def package(self, package_id):
        return package_id if self.rpm else package_id.split("=", 1)[0]

    def unverified(self, paths):
        self.asked.append(sorted(paths))
        return {path for path in paths if path in self.failing}


# --- Files and commands --------------------------------------------------------

class TreeTestCase(unittest.TestCase):
    """A test with a scratch directory of its own, removed after it."""

    def setUp(self):
        super().setUp()
        self.root = tempfile.mkdtemp(prefix="aide-tests-")
        self.addCleanup(shutil.rmtree, self.root, True)

    def path(self, relative):
        return os.path.join(self.root, relative.lstrip("/"))

    def write(self, relative, text=""):
        path = self.path(relative)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as handle:
            handle.write(text)
        return path

    def link(self, relative, target):
        path = self.path(relative)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        os.symlink(target, path)
        return path


FAKE_COMMAND = """#!{python}
# A stand-in for {name}: logs its arguments, and for sendmail its standard
# input, as UTF-8 with any other bytes kept as surrogates, to $FAKE_LOG; prints
# $FAKE_{key}_OUTPUT's file, writes "written" to $FAKE_{key}_WRITES's path, and
# exits with $FAKE_{key}_STATUS, or prints {name} --version's text. Only
# sendmail is given input; any other would wait on the standard input it
# inherits.
import json, os, sys
argv = sys.argv[1:]
stdin = sys.stdin.buffer.read().decode("utf-8", "surrogateescape") if "{name}" == "sendmail" else ""
with open(os.environ["FAKE_LOG"], "a") as handle:
    handle.write(json.dumps({{"command": "{name}", "argv": argv, "stdin": stdin}}) + "\\n")
if argv[:1] == ["--version"]:
    print(os.environ.get("FAKE_{key}_VERSION", "{name} 0"))
    sys.exit(0)
writes = os.environ.get("FAKE_{key}_WRITES")
if writes:
    with open(writes, "w") as handle:
        handle.write("written by {name} " + " ".join(argv) + "\\n")
output = os.environ.get("FAKE_{key}_OUTPUT")
if output:
    with open(output) as handle:
        sys.stdout.write(handle.read())
sys.exit(int(os.environ.get("FAKE_{key}_STATUS", "0")))
"""


class CommandsTestCase(TreeTestCase):
    """A test whose commands, by name, are stand-ins first on PATH."""

    commands = ()

    def setUp(self):
        super().setUp()
        self.bin = self.path("bin")
        os.makedirs(self.bin)
        for name in self.commands:
            key = name.upper().replace("-", "_")
            with open(os.path.join(self.bin, name), "w") as handle:
                handle.write(FAKE_COMMAND.format(python=sys.executable, name=name, key=key))
            os.chmod(os.path.join(self.bin, name), 0o755)
        self.log = self.path("commands.log")
        environment = mock.patch.dict(os.environ, {"PATH": self.bin + os.pathsep + os.environ.get("PATH", ""),
                                                   "FAKE_LOG": self.log})
        environment.start()
        self.addCleanup(environment.stop)

    def set_command(self, name, **settings):
        key = name.upper().replace("-", "_")
        for setting, value in settings.items():
            os.environ["FAKE_%s_%s" % (key, setting.upper())] = str(value)

    def calls(self, name=None):
        if not os.path.exists(self.log):
            return []
        with open(self.log) as handle:
            calls = [json.loads(line) for line in handle]
        return [call for call in calls if name is None or call["command"] == name]


def read_gzip_json(path):
    with gzip.open(path, "rt") as handle:
        return json.load(handle)


@contextlib.contextmanager
def umask_kept():
    """Restores the process's umask, which aide-report's main() sets."""
    mask = os.umask(0)
    os.umask(mask)
    try:
        yield
    finally:
        os.umask(mask)
