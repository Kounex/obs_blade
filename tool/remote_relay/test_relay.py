#!/usr/bin/env python3
"""Remote relay tests. No network: RevenueCat is a fake transport that
answers like REST v2 (404 for unknown customers, `expires_at` in ms or
null, entitlements referenced by id, not lookup key)."""

from __future__ import annotations

import asyncio
import json
import os
import tempfile
import unittest
import urllib.parse

import aiohttp
from aiohttp.test_utils import AioHTTPTestCase

import protocol
import relay
from entitlement import Entitlements, Response, Verdict
from store import PAIRING_SECONDS, Store

PRO = "$RCAnonymousID:pro"
FREE = "$RCAnonymousID:free"
PRO_ID = "entl_1a2b3c"


class Clock:
    def __init__(self):
        self.now = 1_800_000_000.0

    def __call__(self) -> float:
        return self.now


class FakeRevenueCat:
    def __init__(self, clock: Clock):
        self.clock = clock
        self.customers: dict[str, list[dict]] = {
            PRO: [{"object": "customer.active_entitlement", "entitlement_id": PRO_ID, "expires_at": None}],
            FREE: [],
        }
        self.down = False
        self.calls: list[str] = []

    async def __call__(self, url: str, headers: dict) -> Response:
        self.calls.append(url)
        if self.down:
            raise aiohttp.ClientConnectionError("down")
        if url.endswith("/entitlements?limit=100"):
            return Response(
                200,
                {
                    "object": "list",
                    "items": [
                        {"object": "entitlement", "id": "entl_other", "lookup_key": "themes"},
                        {"object": "entitlement", "id": PRO_ID, "lookup_key": "pro"},
                    ],
                },
            )
        customer = url.split("/customers/", 1)[1].split("/", 1)[0]
        customer = urllib.parse.unquote(customer)
        items = self.customers.get(customer)
        if items is None:
            return Response(404, {"object": "error", "type": "resource_missing"})
        return Response(200, {"object": "list", "items": items, "next_page": None})


class RelayCase(AioHTTPTestCase):
    async def get_application(self):
        self.clock = Clock()
        self.tmp = tempfile.TemporaryDirectory()
        self.store = Store(os.path.join(self.tmp.name, "relay.db"), clock=self.clock)
        self.rc = FakeRevenueCat(self.clock)
        self.ent = Entitlements(self.rc, "proj1", clock=self.clock)
        return relay.build_app(self.store, self.ent, jobs=False, min_version="0.3.0")

    async def asyncTearDown(self):
        await super().asyncTearDown()
        self.store.close()
        self.tmp.cleanup()

    # --- helpers ---

    async def pair(self, user=PRO, bridge_token=None, kind="standalone", name="GAMING-PC"):
        r = await self.client.post(
            "/v1/pairings", json={"app_user_id": user, "device_name": "iPhone", "platform": "ios"}
        )
        self.assertEqual(r.status, 201, await r.text())
        created = await r.json()
        headers = {"Authorization": f"Bearer {bridge_token}"} if bridge_token else {}
        r = await self.client.post(
            "/v1/pairings/redeem",
            json={"code": created["code"], "name": name, "kind": kind, "version": "0.3.0"},
            headers=headers,
        )
        self.assertEqual(r.status, 200, await r.text())
        redeemed = await r.json()
        r = await self.client.post("/v1/pairings/collect", json={"pairing_id": created["pairing_id"]})
        collected = await r.json()
        self.assertEqual(collected["state"], "paired")
        # The bridge files the phone's end-to-end key under this id.
        self.assertEqual(redeemed["device_id"], collected["device_id"])
        return (
            redeemed["bridge_id"],
            redeemed.get("bridge_token", bridge_token),
            collected["device_id"],
            collected["app_token"],
        )

    async def bridge(self, token, kind="standalone", version="0.3.0"):
        ws = await self.client.ws_connect(
            "/v1/bridge",
            headers={
                "Authorization": f"Bearer {token}",
                "X-Bridge-Version": version,
                "X-Bridge-Kind": kind,
            },
        )
        welcome = await self.next_json(ws)
        self.assertEqual(welcome["type"], "welcome")
        await ws.send_str(json.dumps({"type": "hello", "name": "GAMING-PC", "obs": "running"}))
        return ws

    async def phone(self, bridge_id, app_token, user=None):
        headers = {"Authorization": f"Bearer {app_token}"}
        if user:
            headers["X-RC-App-User-Id"] = user
        return await self.client.ws_connect(f"/v1/app?bridge={bridge_id}", headers=headers)

    async def next_json(self, ws):
        msg = await ws.receive(timeout=3)
        self.assertEqual(msg.type, aiohttp.WSMsgType.TEXT, msg)
        return json.loads(msg.data)

    async def next_frame(self, ws, skip_text=True):
        while True:
            msg = await ws.receive(timeout=3)
            if msg.type == aiohttp.WSMsgType.TEXT and skip_text:
                continue
            self.assertEqual(msg.type, aiohttp.WSMsgType.BINARY, msg)
            return protocol.unpack(msg.data)

    async def closed_with(self, ws):
        while True:
            msg = await ws.receive(timeout=3)
            if msg.type in (aiohttp.WSMsgType.CLOSE, aiohttp.WSMsgType.CLOSED):
                return ws.close_code
            if msg.type == aiohttp.WSMsgType.TEXT:
                continue
            self.fail(f"unexpected {msg}")

    async def session(self):
        """Paired standalone bridge + a phone with an open session."""
        bridge_id, bridge_token, device_id, app_token = await self.pair()
        b = await self.bridge(bridge_token)
        p = await self.phone(bridge_id, app_token)
        kind, sid, payload = await self.next_frame(b)
        self.assertEqual(kind, protocol.OPEN)
        self.assertEqual(json.loads(payload)["device"], device_id)
        return bridge_id, bridge_token, device_id, app_token, b, p, sid


class PairingTests(RelayCase):
    async def test_full_pairing_creates_bridge_and_device(self):
        r = await self.client.post("/v1/pairings", json={"app_user_id": PRO, "device_name": "iPhone"})
        created = await r.json()
        self.assertEqual(len(created["code"]), 8)
        self.assertEqual(created["expires_in"], PAIRING_SECONDS)
        r = await self.client.post("/v1/pairings/collect", json={"pairing_id": created["pairing_id"]})
        self.assertEqual((await r.json())["state"], "waiting")
        # The code is typed / shown with a dash and lower case: still valid.
        code = created["code"].lower()
        r = await self.client.post(
            "/v1/pairings/redeem",
            json={"code": f"{code[:4]}-{code[4:]}", "name": "PC", "kind": "plugin", "version": "0.3.0"},
        )
        redeemed = await r.json()
        self.assertIn("bridge_token", redeemed)
        r = await self.client.post("/v1/pairings/collect", json={"pairing_id": created["pairing_id"]})
        collected = await r.json()
        self.assertEqual(collected["bridge"], {"id": redeemed["bridge_id"], "name": "PC", "kind": "plugin"})
        # Collected once: the token is never handed out again.
        r = await self.client.post("/v1/pairings/collect", json={"pairing_id": created["pairing_id"]})
        self.assertEqual(r.status, 404)
        self.assertEqual(self.store.counts(), (1, 1, 0))

    async def test_code_is_single_use(self):
        r = await self.client.post("/v1/pairings", json={"app_user_id": PRO})
        code = (await r.json())["code"]
        body = {"code": code, "name": "PC", "kind": "plugin", "version": "0.3.0"}
        self.assertEqual((await self.client.post("/v1/pairings/redeem", json=body)).status, 200)
        r = await self.client.post("/v1/pairings/redeem", json=body)
        self.assertEqual(r.status, 404)
        self.assertEqual(self.store.counts()[0], 1)

    async def test_code_expires(self):
        r = await self.client.post("/v1/pairings", json={"app_user_id": PRO})
        code = (await r.json())["code"]
        self.clock.now += PAIRING_SECONDS + 1
        r = await self.client.post(
            "/v1/pairings/redeem", json={"code": code, "name": "PC", "kind": "plugin", "version": "1"}
        )
        self.assertEqual(r.status, 404)

    async def test_pairing_needs_pro(self):
        r = await self.client.post("/v1/pairings", json={"app_user_id": FREE})
        self.assertEqual((r.status, (await r.json())["error"]), (403, "pro_required"))
        # Unknown to RevenueCat (404) is "not Pro", not an error.
        r = await self.client.post("/v1/pairings", json={"app_user_id": "$RCAnonymousID:new"})
        self.assertEqual(r.status, 403)
        self.rc.down = True
        r = await self.client.post("/v1/pairings", json={"app_user_id": "$RCAnonymousID:x"})
        self.assertEqual((r.status, (await r.json())["error"]), (503, "verify_unavailable"))

    async def test_second_phone_joins_existing_bridge(self):
        bridge_id, bridge_token, first, _ = await self.pair()
        bridge_id2, token2, second, _ = await self.pair(bridge_token=bridge_token)
        self.assertEqual(bridge_id2, bridge_id)
        self.assertEqual(token2, bridge_token)  # no new bridge token
        self.assertNotEqual(first, second)
        self.assertEqual(self.store.counts()[:2], (1, 2))

    async def test_redeem_with_revoked_bridge_token_is_refused(self):
        r = await self.client.post("/v1/pairings", json={"app_user_id": PRO})
        code = (await r.json())["code"]
        r = await self.client.post(
            "/v1/pairings/redeem",
            json={"code": code, "name": "PC", "kind": "plugin", "version": "1"},
            headers={"Authorization": "Bearer nope"},
        )
        self.assertEqual(r.status, 401)


class SessionTests(RelayCase):
    async def test_frames_pass_untouched_both_ways(self):
        """End-to-end encrypted frames: opaque bytes, never decoded."""
        *_, b, p, sid = await self.session()
        from_bridge = bytes(range(256)) * 3  # not UTF-8
        await b.send_bytes(protocol.pack(protocol.DATA, sid, from_bridge))
        msg = await p.receive(timeout=3)
        self.assertEqual((msg.type, msg.data), (aiohttp.WSMsgType.BINARY, from_bridge))
        from_phone = b"\xff\x00noise message 1"
        await p.send_bytes(from_phone)
        self.assertEqual(await self.next_frame(b), (protocol.DATA, sid, from_phone))
        await p.close()
        self.assertEqual(await self.next_frame(b), (protocol.CLOSE, sid, b""))

    async def test_bridge_keepalive_ping_is_answered(self):
        *_, b, p, sid = await self.session()
        await b.send_str(json.dumps({"type": "ping"}))
        for _ in range(5):
            msg = await b.receive(timeout=3)
            if msg.type == aiohttp.WSMsgType.TEXT and json.loads(msg.data).get("type") == "pong":
                return
        self.fail("no pong")

    async def test_readable_text_from_the_phone_is_refused(self):
        *_, b, p, sid = await self.session()
        await p.send_str('{"op":1,"d":{"rpcVersion":1}}')
        self.assertEqual(await self.closed_with(p), 1003)
        self.assertEqual(await self.next_frame(b), (protocol.CLOSE, sid, b""))

    async def test_bridge_e2e_refusals_reach_the_phone(self):
        for code in (protocol.UNPAIRED, protocol.E2E_FAILED):
            *_, b, p, sid = await self.session()
            await b.send_bytes(protocol.pack(protocol.CLOSE, sid, json.dumps({"code": code}).encode()))
            self.assertEqual(await self.closed_with(p), code)
            await b.close()

    async def test_bridge_close_reaches_phone_after_its_frames(self):
        *_, b, p, sid = await self.session()
        await b.send_bytes(protocol.pack(protocol.DATA, sid, b'{"op":0}'))
        await b.send_bytes(
            protocol.pack(protocol.CLOSE, sid, json.dumps({"code": protocol.OBS_NOT_RUNNING, "reason": "obs not running"}).encode())
        )
        msg = await p.receive(timeout=3)
        self.assertEqual(msg.data, b'{"op":0}')
        self.assertEqual(await self.closed_with(p), protocol.OBS_NOT_RUNNING)

    async def test_bridge_cannot_send_reserved_close_codes(self):
        *_, b, p, sid = await self.session()
        await b.send_bytes(protocol.pack(protocol.CLOSE, sid, b'{"code":1006}'))
        self.assertEqual(await self.closed_with(p), 1011)

    async def test_obs_close_codes_pass_through(self):
        *_, b, p, sid = await self.session()
        await b.send_bytes(protocol.pack(protocol.CLOSE, sid, b'{"code":4002,"reason":"unknown op"}'))
        self.assertEqual(await self.closed_with(p), 4002)

    async def test_bridge_offline(self):
        bridge_id, _, _, app_token = await self.pair()
        p = await self.phone(bridge_id, app_token)
        self.assertEqual(await self.closed_with(p), protocol.BRIDGE_OFFLINE)

    async def test_bridge_drop_ends_sessions(self):
        *_, b, p, sid = await self.session()
        await b.close()
        self.assertEqual(await self.closed_with(p), protocol.BRIDGE_GONE)

    async def test_unknown_token_or_wrong_bridge(self):
        bridge_id, _, _, app_token = await self.pair()
        p = await self.phone(bridge_id, "nope")
        self.assertEqual(await self.closed_with(p), protocol.UNPAIRED)
        other_bridge, other_token, _, _ = await self.pair(name="LAPTOP")
        p = await self.phone(other_bridge, app_token)
        self.assertEqual(await self.closed_with(p), protocol.UNPAIRED)

    async def test_same_phone_again_replaces_old_session(self):
        bridge_id, _, _, app_token, b, old, old_sid = await self.session()
        new = await self.phone(bridge_id, app_token)
        self.assertEqual(await self.closed_with(old), protocol.SESSION_REPLACED)
        frames = [await self.next_frame(b), await self.next_frame(b)]
        self.assertIn((protocol.CLOSE, old_sid, b""), frames)
        opened = [f for f in frames if f[0] == protocol.OPEN]
        self.assertEqual(len(opened), 1)
        self.assertNotEqual(opened[0][1], old_sid)
        await new.close()

    async def test_session_limit_per_bridge(self):
        bridge_id, bridge_token, _, first = await self.pair()
        tokens = [first] + [
            (await self.pair(bridge_token=bridge_token))[3] for _ in range(relay.MAX_SESSIONS_PER_BRIDGE)
        ]
        b = await self.bridge(bridge_token)
        phones = []
        for token in tokens[: relay.MAX_SESSIONS_PER_BRIDGE]:
            phones.append(await self.phone(bridge_id, token))
            await self.next_frame(b)
        extra = await self.phone(bridge_id, tokens[-1])
        self.assertEqual(await self.closed_with(extra), protocol.TOO_MANY_SESSIONS)
        for p in phones:
            await p.close()

    async def test_new_bridge_connection_replaces_old(self):
        _, bridge_token, _, _, b, p, _ = await self.session()
        b2 = await self.bridge(bridge_token)
        self.assertEqual(await self.closed_with(b), protocol.SESSION_REPLACED)
        self.assertEqual(await self.closed_with(p), protocol.BRIDGE_GONE)
        await b2.close()

    async def test_slow_phone_is_dropped_and_bridge_told(self):
        *_, b, p, sid = await self.session()
        big = b"x" * (relay.MAX_QUEUED_BYTES // 4)
        session = next(iter(self.app[relay.KEY_HUB].by_device.values()))
        session.writer.cancel()  # a phone that stopped reading
        for _ in range(5):
            await b.send_bytes(protocol.pack(protocol.DATA, sid, big))
        self.assertEqual(await self.next_frame(b), (protocol.CLOSE, sid, b""))


class ProTests(RelayCase):
    async def test_app_connect_needs_pro(self):
        bridge_id, bridge_token, device_id, app_token = await self.pair()
        b = await self.bridge(bridge_token)
        self.rc.customers[PRO] = []  # lapsed
        self.clock.now += 3600  # past the positive cache
        p = await self.phone(bridge_id, app_token)
        self.assertEqual(await self.closed_with(p), protocol.PRO_REQUIRED)
        await b.close()

    async def test_lapse_during_session_ends_it(self):
        *_, b, p, sid = await self.session()
        self.rc.customers[PRO] = [{"entitlement_id": PRO_ID, "expires_at": int(self.clock.now * 1000) + 60_000}]
        self.clock.now += 3600
        await relay.recheck_pro(self.app)
        self.assertEqual(await self.closed_with(p), protocol.PRO_REQUIRED)
        self.assertEqual(await self.next_frame(b), (protocol.CLOSE, sid, b""))

    async def test_revenuecat_down_keeps_recent_pro_users(self):
        *_, b, p, _ = await self.session()
        self.rc.down = True
        self.clock.now += 3600
        await relay.recheck_pro(self.app)
        await p.send_bytes(b"sealed")
        kind, _, _ = await self.next_frame(b)
        self.assertEqual(kind, protocol.DATA)  # still open
        self.clock.now += 25 * 3600
        await relay.recheck_pro(self.app)
        self.assertEqual(await self.closed_with(p), protocol.VERIFY_UNAVAILABLE)

    async def test_app_user_id_header_updates_device(self):
        bridge_id, bridge_token, device_id, app_token = await self.pair()
        restored = "$RCAnonymousID:restored"
        self.rc.customers[restored] = self.rc.customers[PRO]
        self.rc.customers[PRO] = []
        self.clock.now += 3600
        b = await self.bridge(bridge_token)
        p = await self.phone(bridge_id, app_token, user=restored)
        kind, _, _ = await self.next_frame(b)
        self.assertEqual(kind, protocol.OPEN)
        self.assertEqual(self.store.device_by_token(app_token).app_user_id, restored)
        await p.close()



class StoreMigrationTests(unittest.TestCase):
    def test_a_database_from_before_0_0_4_gets_the_device_id_column(self):
        import sqlite3

        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "relay.db")
            old = sqlite3.connect(path)
            old.executescript(
                "CREATE TABLE pairings (id_hash TEXT PRIMARY KEY, code TEXT NOT NULL UNIQUE,"
                " app_user_id TEXT NOT NULL, device_name TEXT NOT NULL DEFAULT '',"
                " platform TEXT NOT NULL DEFAULT '', created_at REAL NOT NULL,"
                " expires_at REAL NOT NULL, bridge_id TEXT);"
            )
            old.close()
            store = Store(path)
            pairing_id, code = store.create_pairing(PRO, "iPhone", "ios")
            _, _, device_id = store.redeem_pairing(code, None, "PC", "plugin", "0.3.0")
            device, _ = store.collect_pairing(pairing_id)
            self.assertEqual(device.id, device_id)
            store.close()

class EntitlementTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.clock = Clock()
        self.rc = FakeRevenueCat(self.clock)
        self.ent = Entitlements(self.rc, "proj1", clock=self.clock)

    async def test_expiry_and_lifetime(self):
        now_ms = int(self.clock.now * 1000)
        self.rc.customers["a"] = [{"entitlement_id": PRO_ID, "expires_at": now_ms - 1}]
        self.rc.customers["b"] = [{"entitlement_id": PRO_ID, "expires_at": now_ms + 1000}]
        self.rc.customers["c"] = [{"entitlement_id": "entl_other", "expires_at": None}]
        self.assertIs(await self.ent.check("a"), Verdict.NOT_PRO)
        self.assertIs(await self.ent.check("b"), Verdict.PRO)
        self.assertIs(await self.ent.check("c"), Verdict.NOT_PRO)
        self.assertIs(await self.ent.check(PRO), Verdict.PRO)

    async def test_lookup_key_resolved_once_and_cached(self):
        await self.ent.check(PRO)
        await self.ent.check(PRO)
        await self.ent.check(FREE)
        self.assertEqual(sum(u.endswith("/entitlements?limit=100") for u in self.rc.calls), 1)
        self.assertEqual(sum("/customers/" in u for u in self.rc.calls), 2)

    async def test_customer_id_is_escaped(self):
        await self.ent.check("$RCAnonymousID:a/b")
        self.assertIn("/customers/%24RCAnonymousID%3Aa%2Fb/active_entitlements", self.rc.calls[-1])

    async def test_allow_list(self):
        ent = Entitlements(self.rc, "proj1", allow={"maintainer"}, clock=self.clock)
        self.assertIs(await ent.check("maintainer"), Verdict.PRO)
        self.assertEqual(self.rc.calls, [])


class BridgeApiTests(RelayCase):
    async def test_outdated_bridge_is_told_and_phone_sees_why(self):
        bridge_id, bridge_token, _, app_token = await self.pair()
        ws = await self.client.ws_connect(
            "/v1/bridge",
            headers={"Authorization": f"Bearer {bridge_token}", "X-Bridge-Version": "0.1.9", "X-Bridge-Kind": "plugin"},
        )
        message = await self.next_json(ws)
        self.assertEqual(message, {"type": "update_required", "min_version": "0.3.0"})
        self.assertEqual(await self.closed_with(ws), protocol.BRIDGE_OUTDATED)
        p = await self.phone(bridge_id, app_token)
        self.assertEqual(await self.closed_with(p), protocol.BRIDGE_OUTDATED)

    async def test_bridge_auth(self):
        r = await self.client.get("/v1/bridge", headers={"Authorization": "Bearer nope"})
        self.assertEqual(r.status, 401)

    async def test_status_and_info(self):
        bridge_id, bridge_token, device_id, app_token = await self.pair()
        b = await self.bridge(bridge_token)
        status = {"streaming": True, "recording": False, "bitrate": 6000, "dropped": 0.1}
        await b.send_str(json.dumps({"type": "status", "status": status}))
        await b.send_str(json.dumps({"type": "devices"}))  # round trip: the status was handled
        await self.next_json(b)
        r = await self.client.get(f"/v1/bridges/{bridge_id}", headers={"Authorization": f"Bearer {app_token}"})
        info = await r.json()
        self.assertTrue(info["online"])
        self.assertEqual((info["name"], info["kind"], info["obs"]), ("GAMING-PC", "standalone", "running"))
        self.assertEqual(info["status"], status)
        self.assertEqual(info["devices"][0]["id"], device_id)
        self.assertTrue(info["devices"][0]["self"])
        self.assertFalse(info["update_required"])
        await b.send_str(json.dumps({"type": "bye", "reason": "obs_exit"}))
        await b.close()
        await asyncio.sleep(0.05)
        r = await self.client.get(f"/v1/bridges/{bridge_id}", headers={"Authorization": f"Bearer {app_token}"})
        info = await r.json()
        self.assertFalse(info["online"])
        self.assertEqual(info["obs"], "closed")

    async def test_start_obs_only_on_standalone(self):
        bridge_id, bridge_token, device_id, app_token = await self.pair()
        auth = {"Authorization": f"Bearer {app_token}"}
        r = await self.client.post(f"/v1/bridges/{bridge_id}/start-obs", headers=auth)
        self.assertEqual((r.status, (await r.json())["error"]), (409, "bridge_offline"))
        b = await self.bridge(bridge_token, kind="plugin")
        r = await self.client.post(f"/v1/bridges/{bridge_id}/start-obs", headers=auth)
        self.assertEqual((r.status, (await r.json())["error"]), (409, "not_supported"))
        await b.close()
        b = await self.bridge(bridge_token, kind="standalone")
        r = await self.client.post(f"/v1/bridges/{bridge_id}/start-obs", headers=auth)
        self.assertEqual(r.status, 202)
        self.assertEqual(await self.next_json(b), {"type": "start_obs", "device": device_id})

    async def test_phone_removes_a_device(self):
        bridge_id, bridge_token, first, first_token = await self.pair()
        _, _, second, second_token = await self.pair(bridge_token=bridge_token)
        b = await self.bridge(bridge_token)
        p = await self.phone(bridge_id, second_token)
        await self.next_frame(b)
        r = await self.client.delete(f"/v1/devices/{second}", headers={"Authorization": f"Bearer {first_token}"})
        self.assertEqual(r.status, 204)
        self.assertEqual(await self.closed_with(p), protocol.UNPAIRED)
        pushed = await self.next_json(b)
        self.assertEqual([d["id"] for d in pushed["devices"]], [first])
        # Other bridges' devices are out of reach.
        other_bridge, _, other_device, _ = await self.pair(name="LAPTOP")
        r = await self.client.delete(f"/v1/devices/{other_device}", headers={"Authorization": f"Bearer {first_token}"})
        self.assertEqual(r.status, 404)

    async def test_phone_renames_a_device(self):
        bridge_id, bridge_token, first, first_token = await self.pair()
        _, _, second, _ = await self.pair(bridge_token=bridge_token)
        b = await self.bridge(bridge_token)
        auth = {"Authorization": f"Bearer {first_token}"}
        r = await self.client.patch(f"/v1/devices/{first}", json={"name": "  Rene's iPhone 17 Pro  "}, headers=auth)
        self.assertEqual(r.status, 204)
        pushed = await self.next_json(b)
        self.assertEqual([d["name"] for d in pushed["devices"] if d["id"] == first], ["Rene's iPhone 17 Pro"])
        # Any device of the same bridge, like removing one
        r = await self.client.patch(f"/v1/devices/{second}", json={"name": "iPad"}, headers=auth)
        self.assertEqual(r.status, 204)
        await self.next_json(b)
        r = await self.client.get(f"/v1/bridges/{bridge_id}", headers=auth)
        self.assertEqual({d["id"]: d["name"] for d in (await r.json())["devices"]}[second], "iPad")
        # Names are capped like at pairing; empty ones refused
        r = await self.client.patch(f"/v1/devices/{first}", json={"name": "x" * 100}, headers=auth)
        self.assertEqual(r.status, 204)
        self.assertEqual(len((await self.next_json(b))["devices"][0]["name"]), 64)
        r = await self.client.patch(f"/v1/devices/{first}", json={"name": "   "}, headers=auth)
        self.assertEqual((r.status, (await r.json())["error"]), (400, "missing_name"))
        # Other bridges' devices are out of reach; unknown tokens unpaired
        _, _, other_device, _ = await self.pair(name="LAPTOP")
        r = await self.client.patch(f"/v1/devices/{other_device}", json={"name": "mine"}, headers=auth)
        self.assertEqual(r.status, 404)
        r = await self.client.patch(f"/v1/devices/{first}", json={"name": "a"}, headers={"Authorization": "Bearer nope"})
        self.assertEqual(r.status, 401)
        await b.close()

    async def test_bridge_removes_device_and_unpairs(self):
        bridge_id, bridge_token, device_id, app_token, b, p, sid = await self.session()
        await b.send_str(json.dumps({"type": "remove_device", "id": device_id}))
        self.assertEqual(await self.closed_with(p), protocol.UNPAIRED)
        _, bridge_token2, _, _ = await self.pair()
        b2 = await self.bridge(bridge_token2)
        await b2.send_str(json.dumps({"type": "unpair"}))
        self.assertEqual(await self.closed_with(b2), protocol.UNPAIRED)
        r = await self.client.get("/v1/bridge", headers={"Authorization": f"Bearer {bridge_token2}"})
        self.assertEqual(r.status, 401)


class StoreTests(unittest.TestCase):
    def test_purge(self):
        clock = Clock()
        with tempfile.TemporaryDirectory() as tmp:
            store = Store(os.path.join(tmp, "db"), clock=clock)
            pairing_id, code = store.create_pairing(PRO, "iPhone", "ios")
            bridge_id, _, _ = store.redeem_pairing(code, None, "PC", "plugin", "1")
            device, _ = store.collect_pairing(pairing_id)
            clock.now += 181 * 24 * 3600
            self.assertEqual(store.purge(), [device.id])
            self.assertIsNone(store.bridge(bridge_id))
            store.close()

    def test_open_pairings_capped_per_user(self):
        with tempfile.TemporaryDirectory() as tmp:
            store = Store(os.path.join(tmp, "db"), clock=Clock())
            for _ in range(5):
                store.create_pairing(PRO, "", "")
            with self.assertRaises(Exception):
                store.create_pairing(PRO, "", "")
            store.close()


if __name__ == "__main__":
    unittest.main()
