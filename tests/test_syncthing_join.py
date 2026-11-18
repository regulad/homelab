"""Tests of the Syncthing hub's joining service, syncthing_hub's syncthing-join:
which pending devices it accepts, and which offered folders it shares."""
import copy
import importlib.machinery
import importlib.util
import io
import pathlib
import sys
import unittest
import urllib.error

sys.dont_write_bytecode = True

SCRIPT = (pathlib.Path(__file__).resolve().parent.parent
          / "ansible-generated/roles/syncthing_hub/files/syncthing-join")


def load():
    loader = importlib.machinery.SourceFileLoader("syncthing_join", str(SCRIPT))
    spec = importlib.util.spec_from_loader("syncthing_join", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


join = load()

OWNER = "owner@example.com"
WINLITE = "RJ7FMWU-AAAAAAA"
NEWMAC = "NEWMAC1-BBBBBBB"


def whois(login=OWNER, tags=None, name="newmac.tail0000.ts.net."):
    node = {"Name": name}
    if tags:
        node["Tags"] = tags
    return {"Node": node, "UserProfile": {"LoginName": login}}


class FakeApi:
    """Syncthing's REST API over a config, its pending devices and folders.
    Records every write."""

    def __init__(self, devices=(), folders=None, pending_devices=None, pending_folders=None):
        self.devices = [{"deviceID": d} for d in devices]
        self.folders = copy.deepcopy(folders or {})
        self.pending_devices = pending_devices or {}
        self.pending_folders = pending_folders or {}
        self.writes = []

    def get(self, path):
        return self.request("GET", path)

    def request(self, method, path, body=None):
        if method == "GET" and path == "/rest/config/devices":
            return copy.deepcopy(self.devices)
        if method == "GET" and path == "/rest/cluster/pending/devices":
            return copy.deepcopy(self.pending_devices)
        if method == "GET" and path == "/rest/cluster/pending/folders":
            return copy.deepcopy(self.pending_folders)
        if method == "GET" and path == "/rest/config/defaults/device":
            return {"deviceID": "", "name": "", "addresses": ["dynamic"], "introducer": False}
        if path.startswith("/rest/config/folders/"):
            folder_id = path.rsplit("/", 1)[1]
            if folder_id not in self.folders:
                raise urllib.error.HTTPError(path, 404, "Not Found", {}, io.BytesIO())
            if method == "GET":
                return copy.deepcopy(self.folders[folder_id])
            if method == "PATCH":
                self.writes.append((method, path, body))
                self.folders[folder_id].update(body)
                return None
        if method == "POST" and path == "/rest/config/devices":
            self.writes.append((method, path, body))
            self.devices.append(body)
            return None
        raise AssertionError("unexpected request {} {}".format(method, path))


class TailnetAddressTest(unittest.TestCase):
    def test_ipv4_on_the_tailnet(self):
        self.assertEqual(join.tailnet_ip("100.101.102.103:22000"), "100.101.102.103")

    def test_ipv6_on_the_tailnet(self):
        self.assertEqual(join.tailnet_ip("[fd7a:115c:a1e0::1]:22000"), "fd7a:115c:a1e0::1")

    def test_scheme_is_ignored(self):
        self.assertEqual(join.tailnet_ip("tcp://100.64.0.1:22000"), "100.64.0.1")

    def test_off_the_tailnet(self):
        for address in ("192.168.1.10:22000", "[fd12:3456:789a::1]:22000", "100.128.0.1:22000", "relay"):
            self.assertIsNone(join.tailnet_ip(address), address)


class VouchedForTest(unittest.TestCase):
    def test_untagged_node_of_the_owner(self):
        self.assertTrue(join.vouched_for(whois(), OWNER)[0])

    def test_tagged_node_is_refused(self):
        ok, reason = join.vouched_for(whois(tags=["tag:server"]), OWNER)
        self.assertFalse(ok)
        self.assertIn("tagged", reason)

    def test_another_owner_is_refused(self):
        self.assertFalse(join.vouched_for(whois(login="someone@example.com"), OWNER)[0])

    def test_no_result_is_refused(self):
        self.assertFalse(join.vouched_for(None, OWNER)[0])


class AcceptDevicesTest(unittest.TestCase):
    def joiner(self, api, result=None):
        self.whois_calls = []

        def fake_whois(ip):
            self.whois_calls.append(ip)
            return result

        return join.Joiner(api, OWNER, ["claude"], whois=fake_whois)

    def test_accepts_a_vouched_device_with_defaults_and_its_magicdns_address(self):
        api = FakeApi(pending_devices={NEWMAC: {"name": "Mac", "address": "100.70.0.5:22000"}})
        self.assertEqual(self.joiner(api, whois()).accept_devices(), [NEWMAC])
        [(method, path, body)] = api.writes
        self.assertEqual((method, path), ("POST", "/rest/config/devices"))
        self.assertEqual(body["deviceID"], NEWMAC)
        self.assertEqual(body["name"], "newmac")
        self.assertEqual(body["addresses"], ["dynamic", "tcp://newmac.tail0000.ts.net:22000"])
        self.assertFalse(body["introducer"])

    def test_leaves_a_device_off_the_tailnet_pending_without_asking_whois(self):
        api = FakeApi(pending_devices={NEWMAC: {"name": "Mac", "address": "203.0.113.5:22000"}})
        self.assertEqual(self.joiner(api, whois()).accept_devices(), [])
        self.assertEqual(self.whois_calls, [])
        self.assertEqual(api.writes, [])

    def test_leaves_a_tagged_device_pending(self):
        api = FakeApi(pending_devices={NEWMAC: {"name": "x", "address": "100.70.0.5:22000"}})
        self.assertEqual(self.joiner(api, whois(tags=["tag:iot"])).accept_devices(), [])
        self.assertEqual(api.writes, [])

    def test_leaves_another_owners_device_pending(self):
        api = FakeApi(pending_devices={NEWMAC: {"name": "x", "address": "100.70.0.5:22000"}})
        self.assertEqual(self.joiner(api, whois(login="mark@example.com")).accept_devices(), [])
        self.assertEqual(api.writes, [])


class ShareFoldersTest(unittest.TestCase):
    def joiner(self, api):
        return join.Joiner(api, OWNER, ["claude", "prusaslicer"], whois=lambda ip: None)

    def test_shares_an_allowed_folder_with_a_configured_device(self):
        api = FakeApi(devices=[WINLITE], folders={"claude": {"devices": [{"deviceID": "HUB"}]}},
                      pending_folders={"claude": {"offeredBy": {WINLITE: {}}}})
        self.assertEqual(self.joiner(api).share_folders(), [("claude", WINLITE)])
        [(method, path, body)] = api.writes
        self.assertEqual((method, path), ("PATCH", "/rest/config/folders/claude"))
        self.assertEqual(body["devices"], [{"deviceID": "HUB"}, {"deviceID": WINLITE}])

    def test_leaves_other_folders_pending(self):
        api = FakeApi(devices=[WINLITE], folders={"photos": {"devices": []}},
                      pending_folders={"photos": {"offeredBy": {WINLITE: {}}}})
        self.assertEqual(self.joiner(api).share_folders(), [])
        self.assertEqual(api.writes, [])

    def test_ignores_offers_from_devices_not_configured(self):
        api = FakeApi(folders={"claude": {"devices": []}},
                      pending_folders={"claude": {"offeredBy": {NEWMAC: {}}}})
        self.assertEqual(self.joiner(api).share_folders(), [])

    def test_leaves_a_folder_the_hub_lacks_pending(self):
        api = FakeApi(devices=[WINLITE], pending_folders={"prusaslicer": {"offeredBy": {WINLITE: {}}}})
        self.assertEqual(self.joiner(api).share_folders(), [])
        self.assertEqual(api.writes, [])

    def test_is_idempotent(self):
        api = FakeApi(devices=[WINLITE], folders={"claude": {"devices": [{"deviceID": WINLITE}]}},
                      pending_folders={"claude": {"offeredBy": {WINLITE: {}}}})
        self.assertEqual(self.joiner(api).share_folders(), [])
        self.assertEqual(api.writes, [])

    def test_shares_with_each_device_in_turn(self):
        other = "YUIUM5P-CCCCCCC"
        api = FakeApi(devices=[WINLITE, other], folders={"claude": {"devices": []}},
                      pending_folders={"claude": {"offeredBy": {WINLITE: {}, other: {}}}})
        self.joiner(api).share_folders()
        # Each PATCH writes back the list the previous one left, so neither is lost.
        self.assertEqual(api.folders["claude"]["devices"], [{"deviceID": WINLITE}, {"deviceID": other}])
        self.assertEqual(len(api.writes), 2)


if __name__ == "__main__":
    unittest.main()
