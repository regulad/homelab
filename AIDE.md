# Writing a role AIDE accepts

AIDE checks every Debian, Ubuntu and Enterprise Linux host's files each day. aide-report mails root what the host's packages don't explain, and each mail moves the baseline. A role that writes on such a host must let AIDE's refresh take in what it writes. Otherwise every change the role makes is mailed as one nobody explained.

## How a write reaches the baseline

1. **The callback records it.** The `aide_written` callback, which both stages' `ansible.cfg` enable, records each changed result of a task it knows.
   - Records go into `~/.cache/ansible/aide_written/<host>` on the controller, each with the time it was made.
   - Unit names go into `<host>.units`.
2. **Each run ends with the refresh.** Both stages' `site.yml` and `maintenance.yml` import `ansible-common/playbooks/aide-refresh.yml` as their last play. It is tagged `always`, so a run with `--tags` refreshes too.
3. **The refresh moves the baseline for exactly those entries.** Its tasks are `ansible-common/roles/aide/tasks/refresh.yml`.
   - It runs `aide-report --refresh` with the recorded paths and units.
   - It accepts each path as it is at that moment, then removes the records it used.
   - It leaves out records made before the host's baseline was last accepted.
   - A host with no records is left without being contacted.
   - A host without a baseline gets its first one here, at the end of the run that set it up.

Records outlast a run that fails or is interrupted, and the next run to reach the host refreshes them. Nothing is recorded or removed in check mode.

Packages need nothing from a role. aide-report explains what a package installs, upgrades or removes by asking the package manager to verify it.

## What the callback records

| The task | What is recorded |
|---|---|
| `copy`, `template`, `file`, `lineinfile`, `blockinfile`, `replace`, `ini_file`, `get_url`, `xml` | Its `dest` or `path` |
| `user`, `group`, `hostname`, `timezone`, `locale_gen` | The files that module's code writes, from `MODULE_FILES` in the callback: for `user`, the account files with their `-` backups and `/etc/.pwd.lock` |
| `selinux` | Its `configfile`, `/etc/selinux/config` by default |
| `systemd_service`, `systemd`, `service` with `enabled` or `masked` | The unit; the refresh finds its links in `/etc/systemd/system` from its `[Install]` section |
| Any task whose `vars` have `aide_writes` | Those paths, besides anything above |

Nothing else is recorded:
- a result that didn't change;
- a task run in check mode;
- a task delegated to another host;
- every other module: `command`, `shell`, `raw`, `unarchive`, `git`, `pip` and the package modules among them.

A no_log task is recorded like any other. The callback reads only paths and unit names from it.

## Rules for a role

1. **Write files with the file modules.** The callback finds their paths itself.
   - Write each file with its own `template` or `copy`, as host_files does.
   - Don't use a `command` that writes files, or a copy of a whole directory: a recorded path refreshes only its own entry, so the files below a directory aren't refreshed.
2. **Declare anything else a task writes in `aide_writes`.**
   - Use it for a command, or a module that writes files it isn't given, such as `update-grub`'s `/boot/grub/grub.cfg` (kernel_params) or firewalld's zone files.
   - Each entry is an absolute, literal path. A `*` stands for any part of one name, as in `/etc/firewalld/zones/*.xml`.
   - The callback reads `aide_writes` untemplated, so a `{{ item }}` in it is recorded as written. A looped task declares every item's path with `*` instead.
   - Include the files the tool keeps beside the one it writes, such as firewalld's `*.xml.old` backups.
   - Declare only what the task really writes. The refresh accepts each declared path whole, whoever changed it, so a broad pattern such as `/etc/*` would accept anything there. The tests check that every declaration is a literal flow list of absolute paths.
3. **Report changes truthfully.** Only a changed result is recorded, so a task that writes must not claim `changed_when: false`. A task forced to run with `check_mode: false` in a check run is recorded, because it did write.
4. **Write on the host itself.** A delegated task isn't recorded, even one delegated to the host it runs for, because the callback can't tell whose files it wrote.
5. **Handlers follow the same rules.** A handler that runs a command which writes files declares them in `aide_writes`, as kdump's and kernel_params' do.
6. **Exclude a service's runtime data; don't declare it.** Data a service writes as it works, such as state, caches, sockets and ledgers, changes outside any Ansible run.
   - Exclude it in the narrowest place:
     - `aide_exclude_paths` in the aide role's defaults, for every host;
     - `aide_exclude_paths_packages`, for the package manager's own state;
     - `aide_exclude_paths_group`, in group_vars;
     - `aide_exclude_paths_host`, in host_vars.
   - Each entry is a literal path, excluded with everything below it. Wildcards don't work, as aide-report escapes every character.
   - Exclude data only, never what is run or what configures the service. Its configuration stays watched.
   - Where the service lets you choose, keep its data below a path already excluded, such as `/var/cache`, rather than adding an exclusion.
   - Where something can write into an excluded directory, bind it noexec as well, with the noexec role's `noexec_paths_host`. mail does this for the monitoring agent's sockets: `aide_exclude_paths_host: "{{ noexec_paths_host }}"`.
7. **Leave package scripts' leftovers to aide-report.** Some files a package's own scripts make, such as caches, generated links and kernel files, aren't explained yet. Those need a rule in aide-report's `explain()`, with tests, not an exclusion or a declaration.
8. **Let a one-off operation be mailed once.** Installers such as `ipa-replica-install`, and release upgrades, rewrite more than can be declared. The next report mails the changes once and accepts them. Alternatively, review the changes and run `maintenance.yml --tags aide-accept --limit <host>`.
9. **Keep the refresh last.** A new play goes before the refresh import in `site.yml` or `maintenance.yml`. The tests check that each stage's two playbooks end with it.

Roles for hosts outside those three OS groups, such as pfSense and the switches, have nothing to do here: AIDE doesn't run on them. The callback still records their writes, but no refresh ever reads those records, so they are harmless.

## Checking a role

- **The tests:** `tests/README.md`. They cover the callback, aide-report's rules, the refresh tasks in check mode, and the playbooks' wiring. A change to any of those comes with tests that fail first.
- **After an apply:** the run's "AIDE's baseline for them" task lists every path it refreshed. A write of the role's that isn't there will be in the next day's mail. `--check` records nothing, so only an apply shows this.
- **Records waiting between runs:** `~/.cache/ansible/aide_written/<host>` holds records a refresh hasn't consumed yet, such as those of a run that failed.

## Where the pieces are

| Piece | File |
|---|---|
| The callback | `ansible-common/plugins/callback/aide_written.py` |
| The refresh play | `ansible-common/playbooks/aide-refresh.yml` |
| The refresh tasks | `ansible-common/roles/aide/tasks/refresh.yml` |
| The daily report, the baseline and the refresh itself | `ansible-common/roles/aide/files/aide-report` |
| Exclusions, and the rest of the role's settings | `ansible-common/roles/aide/defaults/main.yml` |
| Accepting a host's files by hand | `maintenance.yml --tags aide-accept`, from `ansible-common/roles/aide/tasks/accept.yml` |
| The tests | `tests/` |
