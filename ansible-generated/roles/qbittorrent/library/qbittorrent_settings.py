#!/usr/bin/python
# Copyright: Parker Wahle
# AGPL-3.0
"""Converge qBittorrent's declared preferences and categories through its Web API."""

DOCUMENTATION = r"""
module: qbittorrent_settings
short_description: Converge qBittorrent's declared preferences and categories
description:
  - Reads qBittorrent's preferences and categories through its Web API, with an
    API key, and sets only the declared ones that differ; undeclared
    preferences and categories are left alone. Supports check mode and diff.
options:
  url:
    description: The Web API's base, such as C(http://127.0.0.1:8080/api/v2).
    type: str
    required: true
  api_key:
    description: The API key qBittorrent created (Options, Web UI, API key).
    type: str
    required: true
  preferences:
    description:
      - Preferences by their Web API names, as C(app/preferences) reports
        them, such as paths without a trailing slash. A name it does not
        report fails. Each value is compared as the type qBittorrent reports.
    type: dict
    default: {}
  categories:
    description: Categories, each a C(name) and its C(save_path).
    type: list
    elements: dict
    default: []
author: Parker Wahle
"""

import json
from urllib.parse import urlencode

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.urls import open_url


def call(module, path, data=None):
    try:
        response = open_url(
            module.params["url"].rstrip("/") + "/" + path,
            method="POST" if data is not None else "GET",
            data=urlencode(data) if data is not None else None,
            headers={"Authorization": "Bearer " + module.params["api_key"]},
            timeout=60,
        )
        body = response.read()
    except Exception as e:  # HTTPError, URLError and socket errors alike
        module.fail_json(msg="qBittorrent's Web API %s failed: %s" % (path, e))
    return json.loads(body) if body[:1] in (b"{", b"[") else body


def coerce(name, want, have):
    """The declared value as the type qBittorrent reports for it."""
    if isinstance(have, bool):
        if not isinstance(want, bool):
            raise ValueError("%s takes true or false, not %r" % (name, want))
        return want
    if isinstance(have, int):
        return int(want)
    if isinstance(have, float):
        return float(want)
    if isinstance(have, str):
        return str(want)
    return want


def main():
    module = AnsibleModule(
        argument_spec=dict(
            url=dict(type="str", required=True),
            api_key=dict(type="str", required=True, no_log=True),
            preferences=dict(type="dict", default={}),
            categories=dict(type="list", elements="dict", default=[]),
        ),
        supports_check_mode=True,
    )
    before, after = {}, {}

    current = call(module, "app/preferences")
    unknown = set(module.params["preferences"]) - set(current)
    if unknown:
        module.fail_json(msg="Unknown preferences: %s" % ", ".join(sorted(unknown)))
    changes = {}
    for name, value in module.params["preferences"].items():
        try:
            want = coerce(name, value, current[name])
        except ValueError as e:
            module.fail_json(msg=str(e))
        if want != current[name]:
            before[name], after[name], changes[name] = current[name], want, want

    categories = call(module, "torrents/categories")
    category_calls = []
    for category in module.params["categories"]:
        name, save_path = category["name"], category["save_path"]
        have = (categories.get(name) or {}).get("savePath")
        if have != save_path:
            before["category " + name], after["category " + name] = have, save_path
            category_calls.append(("torrents/editCategory" if name in categories else "torrents/createCategory",
                                   {"category": name, "savePath": save_path}))

    changed = bool(changes or category_calls)
    if changed and not module.check_mode:
        if changes:
            call(module, "app/setPreferences", {"json": json.dumps(changes)})
        for path, data in category_calls:
            call(module, path, data)
    module.exit_json(changed=changed, preferences_set=sorted(changes),
                     diff=dict(before=json.dumps(before, indent=2, sort_keys=True) + "\n",
                               after=json.dumps(after, indent=2, sort_keys=True) + "\n"))


if __name__ == "__main__":
    main()
