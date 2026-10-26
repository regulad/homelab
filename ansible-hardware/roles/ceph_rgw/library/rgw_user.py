#!/usr/bin/python
# Copyright: Parker Wahle
# GNU Affero General Public License v3.0 (see https://www.gnu.org/licenses/agpl-3.0.txt)
"""Converge a Ceph RADOS Gateway user and its S3 keys through radosgw-admin."""

from __future__ import annotations

import json

from ansible.module_utils.basic import AnsibleModule

DOCUMENTATION = r"""
module: rgw_user
short_description: Converge a RADOS Gateway user and its S3 keys
description:
  - Creates the user when it is missing, sets its display name and bucket
    limit, and makes its S3 keys exactly the declared ones, through
    radosgw-admin on the gateway's host. It never deletes a user, and leaves
    Swift keys alone.
  - radosgw-admin takes a key only as arguments, so a key it creates is in the
    host's process list while it runs. Its output, which holds every key, is
    never returned.
options:
  uid:
    description: The user's ID.
    type: str
    required: true
  display_name:
    description: The user's display name.
    type: str
    required: true
  max_buckets:
    description: How many buckets the user may own.
    type: int
    default: 1000
  keys:
    description: The user's S3 keys, exactly; any other S3 key is removed.
    type: list
    elements: dict
    default: []
    suboptions:
      access_key:
        description: The key's ID.
        type: str
        required: true
      secret_key:
        description: Its secret.
        type: str
        required: true
"""


def radosgw_admin(module, *args):
    """Run radosgw-admin, failing without echoing the arguments, which can hold keys."""
    rc, out, err = module.run_command(["radosgw-admin", *args])
    if rc != 0:
        module.fail_json(msg=f"radosgw-admin {' '.join(args[:2])} failed (exit {rc}).")
    return out


def user_info(module, uid):
    rc, out, err = module.run_command(["radosgw-admin", "user", "info", "--uid", uid])
    if rc == 0:
        return json.loads(out)
    if "no user info saved" in err:
        return None
    module.fail_json(msg=f"radosgw-admin user info failed (exit {rc}).")


def main():
    module = AnsibleModule(
        argument_spec=dict(
            uid=dict(type="str", required=True),
            display_name=dict(type="str", required=True),
            max_buckets=dict(type="int", default=1000),
            keys=dict(
                type="list",
                elements="dict",
                default=[],
                no_log=True,
                options=dict(
                    access_key=dict(type="str", required=True, no_log=True),
                    secret_key=dict(type="str", required=True, no_log=True),
                ),
            ),
        ),
        supports_check_mode=True,
    )
    uid = module.params["uid"]
    display_name = module.params["display_name"]
    max_buckets = module.params["max_buckets"]
    declared = {k["access_key"]: k["secret_key"] for k in module.params["keys"]}
    # Changes are described without key IDs, which identify the account.
    changes = []

    info = user_info(module, uid)
    if info is None:
        changes.append("create the user")
        if not module.check_mode:
            args = ["user", "create", "--uid", uid, "--display-name", display_name,
                    "--max-buckets", str(max_buckets)]
            if declared:
                access, secret = next(iter(declared.items()))
                args += ["--access-key", access, "--secret-key", secret]
            radosgw_admin(module, *args)
            info = user_info(module, uid)
        else:
            info = {"display_name": display_name, "max_buckets": max_buckets, "keys": []}

    if info["display_name"] != display_name or info["max_buckets"] != max_buckets:
        changes.append("set the display name and bucket limit")
        if not module.check_mode:
            radosgw_admin(module, "user", "modify", "--uid", uid, "--display-name", display_name,
                          "--max-buckets", str(max_buckets))

    existing = {k["access_key"]: k["secret_key"] for k in info.get("keys", []) if k.get("user") == uid}
    for access, secret in declared.items():
        if existing.get(access) == secret:
            continue
        if access in existing:
            changes.append("replace a key's secret")
            if not module.check_mode:
                radosgw_admin(module, "key", "rm", "--uid", uid, "--key-type", "s3", "--access-key", access)
        else:
            changes.append("add a key")
        if not module.check_mode:
            radosgw_admin(module, "key", "create", "--uid", uid, "--key-type", "s3",
                          "--access-key", access, "--secret-key", secret)
    for access in existing:
        if access not in declared:
            changes.append("remove an undeclared key")
            if not module.check_mode:
                radosgw_admin(module, "key", "rm", "--uid", uid, "--key-type", "s3", "--access-key", access)

    module.exit_json(changed=bool(changes), changes=changes)


if __name__ == "__main__":
    main()
