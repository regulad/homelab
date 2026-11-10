# Tests

These are the tests of AIDE's acceptance system:

- aide-report, `ansible-common/roles/aide/files/aide-report`, which checks a host's files, mails what its packages don't explain, and moves the baseline;
- the `aide_written` callback, `ansible-common/plugins/callback/aide_written.py`, which records what each Ansible run wrote;
- the aide role's refresh tasks, which move the baseline for those writes;
- how the playbooks and each stage's `ansible.cfg` wire them together.

They use the standard library's `unittest` and need nothing installed beyond the Python they run under: Python 3.9, the oldest a host runs aide-report with (Oracle Linux 9's). `uv python install 3.9` provides it. Pre-commit's `tests` hook runs them; by hand, from the repository root:

```sh
uv run --no-project --no-python-downloads --python 3.9 -- python -B -m unittest discover -s tests
```

`test_ansible.py` also runs `ansible-playbook` from PATH, in check mode on localhost.

## Files

| File | What it tests |
|---|---|
| `test_aide_report_paths.py` | Paths as AIDE's rules read them, and the exclusions aide-report writes |
| `test_aide_report_units.py` | Unit files' `[Install]` links, and the expressions the refresh uses for a unit |
| `test_aide_report_packages.py` | The package record: owners, installed packages, what `dpkg --verify` and `rpm --verify` vouch for, and the manifest |
| `test_aide_report_explain.py` | Each rule `explain()` leaves a change out by, with a case it explains and one it keeps |
| `test_aide_report_runs.py` | The daily check; its mail, the relay's answer in Postfix's log, and when the mail accepts; the first baseline; the refresh; the command line |
| `test_aide_written.py` | The callback's own logic, with a stand-in for ansible-core |
| `test_ansible.py` | The callback and the refresh tasks in ansible-core itself, and what ansible-core hands callbacks |
| `test_playbooks.py` | The playbooks' and `ansible.cfg`'s wiring, read from their text |
| `support.py` | Shared helpers: loading the code, a stand-in `Packages`, AIDE report builders, and stand-in commands |
| `playbooks/`, `callback_plugins/` | The playbook `test_ansible.py` runs, and the callback that records each result for it |

## Rules

- **No bytecode beside the code under test.** The tests load aide-report and the callback with `sys.dont_write_bytecode` set and run with `python3 -B`. `test_ansible.py` sets `PYTHONDONTWRITEBYTECODE` for ansible-core.
- **Nothing outside a scratch directory.** Commands aide-report runs, such as `aide`, `sendmail`, `journalctl`, `dpkg-query` and `rpm`, are stand-ins first on PATH. Absolute paths that aide-report keeps as module constants are patched to a scratch tree. `ansible-playbook` runs only in check mode, on localhost.
- **Synthetic fixtures.** Reports and package lists are written for each test. A host's real `report.json` is discovery output, which never goes into git.
- **Gaps are named.** A test whose name contains `gap` records what the system does today where the AIDE triage of 2026-11-08 found it wanting. A fix changes that test on purpose, in the same commit.
