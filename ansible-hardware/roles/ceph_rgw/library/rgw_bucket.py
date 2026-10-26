#!/usr/bin/python
# Copyright: Parker Wahle
# GNU Affero General Public License v3.0 (see https://www.gnu.org/licenses/agpl-3.0.txt)
"""Converge a Ceph RADOS Gateway bucket's ACL and policy through its S3 API."""

from __future__ import annotations

import hashlib
import hmac
import json
import time
import urllib.error
import urllib.parse
import urllib.request

from ansible.module_utils.basic import AnsibleModule

DOCUMENTATION = r"""
module: rgw_bucket
short_description: Converge a RADOS Gateway bucket, its canned ACL and its policy
description:
  - Creates the bucket when it is missing, then sets its canned ACL and bucket
    policy when they differ, through the S3 API as the bucket's owner. Requests
    are signed with AWS Signature Version 4 by the module itself, so it needs
    no AWS library.
  - The owner and ACL are read through radosgw-admin on the gateway's host,
    which radosgw-admin cannot set; a bucket whose owner differs fails rather
    than being handed over.
options:
  name:
    description: The bucket's name.
    type: str
    required: true
  owner:
    description: The user that owns it, whose key signs the requests.
    type: str
    required: true
  acl:
    description: Its canned ACL.
    type: str
    choices: [private, public-read]
    default: private
  policy:
    description: Its bucket policy, or none.
    type: dict
  endpoint:
    description: The gateway's S3 endpoint.
    type: str
    default: http://127.0.0.1:7480
  region:
    description: The zonegroup's API name, which signatures name.
    type: str
    default: default
  access_key:
    description: The owner's S3 key ID.
    type: str
    required: true
  secret_key:
    description: Its secret.
    type: str
    required: true
"""

# RGW's ACL grant types and permission flags.
GRANT_USER, GRANT_GROUP = 0, 2
ALL_USERS = 1
READ, FULL_CONTROL = 1, 15


def signed_request(module, method, path, query="", body=b"", headers=None,
                   content_type="application/octet-stream"):
    """Send one S3 request, signed with Signature Version 4; return its status and body."""
    p = module.params
    url = p["endpoint"].rstrip("/") + urllib.parse.quote(path) + (f"?{query}" if query else "")
    parts = urllib.parse.urlsplit(url)
    amz_date = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
    date = amz_date[:8]
    payload_hash = hashlib.sha256(body).hexdigest()
    signed = {"host": parts.netloc, "x-amz-content-sha256": payload_hash, "x-amz-date": amz_date}
    # urllib gives a request with a body a Content-Type of its own, which RGW
    # rejects unless it is signed, so every such request signs one.
    if method in ("PUT", "POST"):
        signed["content-type"] = content_type
    signed.update({k.lower(): v for k, v in (headers or {}).items()})
    names = sorted(signed)
    canonical_query = "&".join(
        f"{urllib.parse.quote(k, safe='-_.~')}={urllib.parse.quote(v, safe='-_.~')}"
        for k, v in sorted(urllib.parse.parse_qsl(parts.query, keep_blank_values=True))
    )
    canonical_request = "\n".join([
        method,
        urllib.parse.quote(urllib.parse.unquote(parts.path) or "/", safe="/-_.~"),
        canonical_query,
        "".join(f"{n}:{str(signed[n]).strip()}\n" for n in names),
        ";".join(names),
        payload_hash,
    ])
    scope = f"{date}/{p['region']}/s3/aws4_request"
    to_sign = "\n".join(["AWS4-HMAC-SHA256", amz_date, scope,
                         hashlib.sha256(canonical_request.encode()).hexdigest()])
    key = ("AWS4" + p["secret_key"]).encode()
    for part in (date, p["region"], "s3", "aws4_request"):
        key = hmac.new(key, part.encode(), hashlib.sha256).digest()
    signature = hmac.new(key, to_sign.encode(), hashlib.sha256).hexdigest()
    signed["authorization"] = (f"AWS4-HMAC-SHA256 Credential={p['access_key']}/{scope}, "
                               f"SignedHeaders={';'.join(names)}, Signature={signature}")
    request = urllib.request.Request(url, data=body if method in ("PUT", "POST") else None,
                                     method=method, headers=signed)
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


def expect(module, what, status, body, ok):
    if status not in ok:
        module.fail_json(msg=f"{what}: HTTP {status}", body=body.decode(errors="replace")[:500])


def radosgw_admin_json(module, *args, missing=None):
    rc, out, err = module.run_command(["radosgw-admin", *args])
    if rc != 0:
        if missing and missing in err:
            return None
        module.fail_json(msg=f"radosgw-admin {' '.join(args[:2])} failed (exit {rc}): {err.strip()[:300]}")
    return json.loads(out)


def canned_acl(policy, owner):
    """Name the canned ACL a bucket's grants amount to, or custom."""
    grants = set()
    for entry in policy.get("acl", {}).get("grant_map", []):
        grant = entry["grant"]
        kind = grant["type"]["type"]
        flags = grant["permission"]["flags"]
        if kind == GRANT_USER:
            grants.add(("user", grant.get("id"), flags))
        elif kind == GRANT_GROUP:
            grants.add(("group", grant.get("group"), flags))
        else:
            grants.add(("other", kind, flags))
    if grants == {("user", owner, FULL_CONTROL)}:
        return "private"
    if grants == {("user", owner, FULL_CONTROL), ("group", ALL_USERS, READ)}:
        return "public-read"
    return "custom"


def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type="str", required=True),
            owner=dict(type="str", required=True),
            acl=dict(type="str", choices=["private", "public-read"], default="private"),
            policy=dict(type="dict"),
            endpoint=dict(type="str", default="http://127.0.0.1:7480"),
            region=dict(type="str", default="default"),
            access_key=dict(type="str", required=True, no_log=True),
            secret_key=dict(type="str", required=True, no_log=True),
        ),
        supports_check_mode=True,
    )
    p = module.params
    name, owner = p["name"], p["owner"]
    path = f"/{name}"
    changes = []
    diff = {"before": {}, "after": {}}

    stats = radosgw_admin_json(module, "bucket", "stats", "--bucket", name, missing="No such file")
    if stats is None:
        changes.append("create the bucket")
        if not module.check_mode:
            status, body = signed_request(module, "PUT", path)
            expect(module, "creating the bucket", status, body, (200,))
            stats = radosgw_admin_json(module, "bucket", "stats", "--bucket", name)
    if stats is not None and stats["owner"] != owner:
        module.fail_json(msg=f"{name} is owned by {stats['owner']}, not {owner}: hand it over by hand "
                             "with radosgw-admin bucket link and bucket chown.")

    if stats is None:
        current_acl, current_policy = None, None
    else:
        current_acl = canned_acl(radosgw_admin_json(module, "policy", "--bucket", name), owner)
        status, body = signed_request(module, "GET", path, "policy")
        expect(module, "reading the policy", status, body, (200, 404))
        current_policy = json.loads(body) if status == 200 else None

    if current_acl != p["acl"]:
        changes.append(f"set the ACL to {p['acl']}")
        diff["before"]["acl"], diff["after"]["acl"] = current_acl, p["acl"]
        if not module.check_mode:
            status, body = signed_request(module, "PUT", path, "acl", headers={"x-amz-acl": p["acl"]})
            expect(module, "setting the ACL", status, body, (200,))

    if current_policy != p["policy"]:
        changes.append("set the policy" if p["policy"] else "remove the policy")
        diff["before"]["policy"], diff["after"]["policy"] = current_policy, p["policy"]
        if not module.check_mode:
            if p["policy"]:
                status, body = signed_request(module, "PUT", path, "policy",
                                              body=json.dumps(p["policy"], indent=2).encode(),
                                              content_type="application/json")
                expect(module, "setting the policy", status, body, (200, 204))
            else:
                status, body = signed_request(module, "DELETE", path, "policy")
                expect(module, "removing the policy", status, body, (200, 204))

    module.exit_json(changed=bool(changes), changes=changes,
                     diff={"before": json.dumps(diff["before"], indent=2, sort_keys=True) + "\n",
                           "after": json.dumps(diff["after"], indent=2, sort_keys=True) + "\n"})


if __name__ == "__main__":
    main()
