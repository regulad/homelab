#!/usr/bin/env python3
"""Dynamic inventory of generated hosts, built from OpenTofu outputs.

Each root in ROOTS exports an `ansible_hosts` output shaped
{name: {address, groups}}. Every host also joins the `generated` group, which
mirrors `hardware` in hardware.yml. Nothing is cached, and a root that cannot be
read fails the whole inventory. Reading outputs needs the state backend's
credentials in the environment, as sourcing tofu/oracle/prepare.sh sets them.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[2]

# Roots join this list in Phase 4, once they export ansible_hosts.
ROOTS: list[str] = []

GENERATED_GROUP = "generated"


def root_hosts(root: str) -> dict:
    result = subprocess.run(
        ["tofu", f"-chdir={REPOSITORY / root}", "output", "-json", "ansible_hosts"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        sys.exit(f"inventory.py: cannot read ansible_hosts from {root}: {result.stderr.strip()}")
    return json.loads(result.stdout)


def build() -> dict:
    inventory: dict = {"_meta": {"hostvars": {}}, GENERATED_GROUP: {"hosts": []}}
    for root in ROOTS:
        for name, host in root_hosts(root).items():
            if name in inventory["_meta"]["hostvars"]:
                sys.exit(f"inventory.py: {name} is exported by more than one root")
            inventory["_meta"]["hostvars"][name] = {"ansible_host": host["address"]}
            inventory[GENERATED_GROUP]["hosts"].append(name)
            for group in host["groups"]:
                inventory.setdefault(group, {"hosts": []})["hosts"].append(name)
    return inventory


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--list", action="store_true", help="print the whole inventory")
    mode.add_argument("--host", help="print one host's variables")
    args = parser.parse_args()

    inventory = build()
    result = inventory if args.list else inventory["_meta"]["hostvars"].get(args.host, {})
    json.dump(result, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
