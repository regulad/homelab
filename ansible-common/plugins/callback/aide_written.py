"""Record the files each host's tasks wrote, for AIDE's baseline refresh.

The aide role's refresh play, the last in each stage's site.yml, reads the
list back and moves AIDE's baseline for exactly those paths, so that a change
Ansible made to a file it manages is not reported as one nobody explained.
"""

import os
import shutil
import tempfile

from ansible.plugins.callback import CallbackBase

DOCUMENTATION = """
name: aide_written
type: aggregate
short_description: record the files each host's tasks wrote, for AIDE's baseline refresh
description:
  - For each changed result of a module that writes a file at a path it is given,
    appends that path to a file named for the host, in a directory created for
    the run and named by the AIDE_WRITTEN_DIR environment variable, which the
    run's workers inherit. The directory is removed when the run ends.
  - For each changed result of a module that writes files it is not given,
    such as user's /etc/passwd, appends the files its code writes, from
    MODULE_FILES; and for selinux, the configuration file it is given or its
    default. Modules that write a tree, such as unarchive and git, and those
    that leave the writing to another tool, such as sefcontext and
    dnf_config_manager, are not among them.
  - For each changed result of a module that enables, disables or masks a
    systemd unit, appends the unit's name to a second file for the host, named
    for it with .units after. The module does not say which links it made or
    removed in /etc/systemd/system, so the refresh finds them by the unit.
  - For each changed result of a task whose vars list aide_writes, appends
    those absolute paths, the files a command rewrites without naming them,
    such as update-grub's /boot/grub/grub.cfg; a * in one stands for any part
    of one name, as grubby's /boot/loader/entries/*.conf.
  - A result hidden by no_log reaches callbacks without its module's arguments
    or return values; its task keeps the arguments it ran with, templated for
    each loop item, which are read in their place. Only paths and unit names
    are read from them.
  - Results delegated to another host are not recorded, as they do not say
    which of the host's files changed. A task's delegate_to marks them, as a
    result hidden by no_log loses its own mark of delegation.
requirements:
  - enabled in callbacks_enabled
  - inject_invocation, so that results carry their modules' arguments
  - ansible-core 2.19 or later, whose results name their task, host and values
    without a leading underscore
"""

# Modules that write a file, or one directory entry, at the path they are given.
MODULES = {
    "copy", "template", "file", "lineinfile", "blockinfile", "replace",
    "ini_file", "get_url", "xml",
}
# Modules that write files they are not given, each with what its code writes
# on Linux, by the strategy this repository uses.
ACCOUNT_LOCK = "/etc/.pwd.lock"
MODULE_FILES = {
    # shadow-utils' useradd, usermod and userdel, each file with the backup
    # beside it they write first, under the lock file they create.
    "user": ["/etc/passwd", "/etc/passwd-", "/etc/shadow", "/etc/shadow-", "/etc/group", "/etc/group-",
             "/etc/gshadow", "/etc/gshadow-", "/etc/subuid", "/etc/subuid-", "/etc/subgid", "/etc/subgid-",
             ACCOUNT_LOCK],
    # groupadd, groupmod and groupdel.
    "group": ["/etc/group", "/etc/group-", "/etc/gshadow", "/etc/gshadow-", ACCOUNT_LOCK],
    # hostnamectl --static --pretty, the systemd strategy base's task uses.
    "hostname": ["/etc/hostname", "/etc/machine-info"],
    # timedatectl's link, or without it Debian's /etc/timezone beside a copy.
    "timezone": ["/etc/localtime", "/etc/timezone"],
    # glibc's mechanism: the list, and the archive locale-gen compiles from it.
    "locale_gen": ["/etc/locale.gen", "/usr/lib/locale/locale-archive"],
}
# Modules that write a file named by another argument than dest or path, with
# that argument and its default.
PATH_ARGUMENTS = {"selinux": ("configfile", "/etc/selinux/config")}
# Modules that enable, disable or mask a systemd unit, through links in
# /etc/systemd/system they do not name.
UNIT_MODULES = {"systemd_service", "systemd", "service"}


class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "aggregate"
    CALLBACK_NAME = "aide_written"
    CALLBACK_NEEDS_ENABLED = True

    def __init__(self):
        super().__init__()
        self.directory = tempfile.mkdtemp(prefix="aide-written-")
        os.environ["AIDE_WRITTEN_DIR"] = self.directory

    def _record(self, result):
        values = result.result
        task = result.task
        if not values.get("changed"):
            return
        if values.get("_ansible_delegated_vars") or getattr(task, "delegate_to", None):
            return
        host = result.host.get_name()
        # What a task declares it writes, which its module does not name.
        declared = (getattr(task, "vars", None) or {}).get("aide_writes") or []
        declared = [path for path in declared if isinstance(path, str) and path.startswith("/")]
        if declared:
            with open(os.path.join(self.directory, host), "a") as handle:
                handle.writelines(path + "\n" for path in declared)
        action = task.action.rsplit(".", 1)[-1]
        # A result hidden by no_log has no invocation: its task's own arguments.
        arguments = values.get("invocation", {}).get("module_args") or dict(getattr(task, "args", None) or {})
        if action in UNIT_MODULES:
            unit = values.get("name") or arguments.get("name")
            if (arguments.get("enabled") is not None or arguments.get("masked") is not None) \
                    and isinstance(unit, str) and unit and "/" not in unit:
                with open(os.path.join(self.directory, host + ".units"), "a") as handle:
                    handle.write(unit + "\n")
            return
        if action in MODULE_FILES:
            with open(os.path.join(self.directory, host), "a") as handle:
                handle.writelines(path + "\n" for path in MODULE_FILES[action])
            return
        if action in PATH_ARGUMENTS:
            argument, default = PATH_ARGUMENTS[action]
            path = arguments.get(argument) or default
        elif action in MODULES:
            path = values.get("dest") or arguments.get("dest") or arguments.get("path") or values.get("path")
        else:
            return
        if not isinstance(path, str) or not path.startswith("/"):
            return
        with open(os.path.join(self.directory, host), "a") as handle:
            handle.write(path + "\n")

    def v2_runner_on_ok(self, result):
        if "results" not in result.result:
            self._record(result)

    def v2_runner_item_on_ok(self, result):
        self._record(result)

    def v2_playbook_on_stats(self, stats):
        shutil.rmtree(self.directory, ignore_errors=True)
