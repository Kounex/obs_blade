#!/usr/bin/env python3
"""Relay tests. No network: Kick is a fake transport, signatures use a
key pair generated here."""

from __future__ import annotations

import base64
import json
import os
import tempfile
import unittest
from datetime import datetime, timedelta, timezone

from aiohttp.test_utils import AioHTTPTestCase
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding, rsa

import kick
import relay
import signature
from store import Store

BROADCASTER = 4242
OTHER = 777


def _now_text(delta: timedelta = timedelta()) -> str:
    return (datetime.now(timezone.utc) + delta).strftime("%Y-%m-%dT%H:%M:%SZ")


class FakeKick:
    """Answers like api.kick.com / id.kick.com for the calls the relay makes."""

    def __init__(self):
        self.calls: list[tuple[str, str]] = []
        self.users = {"good-token": (BROADCASTER, "streamer")}
        self.subscriptions: dict[str, dict] = {}
        self.next_id = 0
        self.app_token_status = 200
        self.reject_events: set[str] = set()

    async def __call__(self, method, url, headers, body):
        self.calls.append((method, url))
        if url == kick.TOKEN_URL:
            if self.app_token_status != 200:
                return kick.Response(self.app_token_status, b"{}")
            assert b"client_secret=secret-1" in body
            return kick.Response(
                200, json.dumps({"access_token": "app", "expires_in": 3600}).encode()
            )
        if url.endswith("/public/v1/users"):
            token = headers.get("Authorization", "")[7:]
            user = self.users.get(token)
            if user is None:
                return kick.Response(401, b"{}")
            return kick.Response(
                200,
                json.dumps({"data": [{"user_id": user[0], "name": user[1]}]}).encode(),
            )
        if "/public/v1/events/subscriptions" in url:
            assert headers["Authorization"] == "Bearer app"
            if method == "GET":
                wanted = None
                if "broadcaster_user_id=" in url:
                    wanted = int(url.rsplit("=", 1)[1])
                data = [
                    sub
                    for sub in self.subscriptions.values()
                    if wanted is None or sub["broadcaster_user_id"] == wanted
                ]
                return kick.Response(200, json.dumps({"data": data}).encode())
            if method == "POST":
                request = json.loads(body)
                assert request["method"] == "webhook"
                out = []
                for event in request["events"]:
                    if event["name"] in self.reject_events:
                        out.append({"name": event["name"], "version": 1, "error": "nope"})
                        continue
                    self.next_id += 1
                    sub_id = f"sub-{self.next_id}"
                    self.subscriptions[sub_id] = {
                        "id": sub_id,
                        "broadcaster_user_id": request["broadcaster_user_id"],
                        "event": event["name"],
                        "version": event["version"],
                        "method": "webhook",
                    }
                    out.append(
                        {"name": event["name"], "version": 1, "subscription_id": sub_id}
                    )
                return kick.Response(200, json.dumps({"data": out}).encode())
            if method == "DELETE":
                query = url.split("?", 1)[1]
                for part in query.split("&"):
                    self.subscriptions.pop(part.split("=", 1)[1], None)
                return kick.Response(204, b"")
        return kick.Response(404, b"{}")


class RelayTestBase(AioHTTPTestCase):
    async def get_application(self):
        self.private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        self.fake = FakeKick()
        self.directory = tempfile.TemporaryDirectory()
        self.store = Store(os.path.join(self.directory.name, "relay.db"))
        self.api = kick.KickApi("client-1", "secret-1", transport=self.fake)
        return relay.build_app(
            self.store,
            self.api,
            keys=[self.private_key.public_key()],
            jobs=False,
        )

    async def asyncTearDown(self):
        await super().asyncTearDown()
        self.directory.cleanup()

    def sign(self, message_id: str, timestamp: str, body: bytes, key=None) -> str:
        signer = key or self.private_key
        raw = signer.sign(
            f"{message_id}.{timestamp}.".encode() + body,
            padding.PKCS1v15(),
            hashes.SHA256(),
        )
        return base64.b64encode(raw).decode()

    async def deliver(
        self,
        payload: dict,
        message_id: str = "01MSG",
        event_type: str = "channel.followed",
        timestamp: str | None = None,
        key=None,
        tamper: bool = False,
    ):
        stamp = timestamp or _now_text()
        body = json.dumps(payload).encode()
        signature_b64 = self.sign(message_id, stamp, body, key)
        if tamper:
            body = body.replace(b"follower", b"f0llower")
        return await self.client.post(
            "/kick/webhook",
            data=body,
            headers={
                "Kick-Event-Message-Id": message_id,
                "Kick-Event-Message-Timestamp": stamp,
                "Kick-Event-Signature": signature_b64,
                "Kick-Event-Type": event_type,
                "Kick-Event-Version": "1",
                "Kick-Event-Subscription-Id": "sub-1",
                "Content-Type": "application/json",
            },
        )

    async def register(self, token: str = "good-token") -> dict:
        response = await self.client.post("/v1/session", json={"access_token": token})
        self.assertEqual(response.status, 200)
        return await response.json()


def follow(user_id: int = BROADCASTER, follower: str = "fan") -> dict:
    return {
        "broadcaster": {"user_id": user_id, "username": "streamer", "channel_slug": "streamer"},
        "follower": {"user_id": 99, "username": follower, "channel_slug": follower},
    }


class SessionTest(RelayTestBase):
    async def test_session_proves_the_channel_and_subscribes_every_event(self):
        body = await self.register()
        self.assertEqual(body["broadcaster_user_id"], BROADCASTER)
        self.assertTrue(body["subscribed"])
        self.assertTrue(body["session_token"])
        events = {
            sub["event"]
            for sub in self.fake.subscriptions.values()
            if sub["broadcaster_user_id"] == BROADCASTER
        }
        self.assertEqual(events, {name for name, _ in kick.EVENTS})

    async def test_second_session_does_not_duplicate_subscriptions(self):
        await self.register()
        await self.register()
        self.assertEqual(len(self.fake.subscriptions), len(kick.EVENTS))

    async def test_a_token_kick_rejects_gets_401_and_no_subscription(self):
        response = await self.client.post("/v1/session", json={"access_token": "bad"})
        self.assertEqual(response.status, 401)
        self.assertEqual(self.fake.subscriptions, {})

    async def test_partial_subscribe_reports_not_subscribed(self):
        self.fake.reject_events = {"kicks.gifted"}
        body = await self.register()
        self.assertFalse(body["subscribed"])

    async def test_kick_down_still_gives_a_session_for_the_reconcile_job(self):
        self.fake.app_token_status = 500
        body = await self.register()
        self.assertFalse(body["subscribed"])
        self.assertTrue(self.store.is_registered(BROADCASTER))

    async def test_missing_or_oversized_token_is_a_400(self):
        for payload in ({}, {"access_token": ""}, {"access_token": "x" * 5000}):
            response = await self.client.post("/v1/session", json=payload)
            self.assertEqual(response.status, 400)

    async def test_last_session_deleted_unsubscribes_and_forgets_the_channel(self):
        first = (await self.register())["session_token"]
        second = (await self.register())["session_token"]
        await self.deliver(follow())
        response = await self.client.delete(
            "/v1/session", headers={"Authorization": f"Bearer {first}"}
        )
        self.assertEqual(response.status, 200)
        self.assertEqual(len(self.fake.subscriptions), len(kick.EVENTS))
        await self.client.delete(
            "/v1/session", headers={"Authorization": f"Bearer {second}"}
        )
        self.assertEqual(self.fake.subscriptions, {})
        self.assertFalse(self.store.is_registered(BROADCASTER))
        self.assertEqual(self.store.latest_seq(BROADCASTER), 0)

    async def test_old_sessions_beyond_the_cap_are_dropped(self):
        first = (await self.register())["session_token"]
        for _ in range(10):
            await self.register()
        self.assertIsNone(self.store.session_user(first))

    async def test_unknown_session_is_401_everywhere(self):
        headers = {"Authorization": "Bearer nope"}
        self.assertEqual((await self.client.get("/v1/events", headers=headers)).status, 401)
        self.assertEqual((await self.client.delete("/v1/session", headers=headers)).status, 401)
        self.assertEqual((await self.client.get("/v1/stream", headers=headers)).status, 401)


class WebhookTest(RelayTestBase):
    async def test_signed_delivery_is_stored_once(self):
        session = (await self.register())["session_token"]
        self.assertEqual((await self.deliver(follow())).status, 200)
        self.assertEqual((await self.deliver(follow())).status, 200)  # Kick retry
        response = await self.client.get(
            "/v1/events", headers={"Authorization": f"Bearer {session}"}
        )
        body = await response.json()
        self.assertEqual(len(body["events"]), 1)
        event = body["events"][0]
        self.assertEqual(event["event_type"], "channel.followed")
        self.assertEqual(event["payload"]["follower"]["username"], "fan")
        self.assertEqual(body["latest_seq"], event["seq"])

    async def test_bad_or_foreign_signature_is_403(self):
        await self.register()
        self.assertEqual((await self.deliver(follow(), tamper=True)).status, 403)
        stranger = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        self.assertEqual((await self.deliver(follow(), key=stranger)).status, 403)
        self.assertEqual(self.store.latest_seq(BROADCASTER), 0)

    async def test_missing_headers_is_400(self):
        response = await self.client.post("/kick/webhook", data=b"{}")
        self.assertEqual(response.status, 400)

    async def test_unregistered_channel_is_acknowledged_but_not_kept(self):
        response = await self.deliver(follow(user_id=OTHER))
        self.assertEqual(response.status, 200)
        self.assertEqual(self.store.latest_seq(OTHER), 0)

    async def test_old_delivery_is_acknowledged_but_not_kept(self):
        await self.register()
        response = await self.deliver(
            follow(), timestamp=_now_text(timedelta(days=-2))
        )
        self.assertEqual(response.status, 200)
        self.assertEqual(self.store.latest_seq(BROADCASTER), 0)

    async def test_events_after_cursor_and_per_channel(self):
        self.fake.users["other-token"] = (OTHER, "other")
        mine = (await self.register())["session_token"]
        theirs = (await self.register("other-token"))["session_token"]
        await self.deliver(follow(), message_id="m1")
        await self.deliver(follow(follower="second"), message_id="m2")
        await self.deliver(follow(user_id=OTHER), message_id="m3")
        headers = {"Authorization": f"Bearer {mine}"}
        first = await (await self.client.get("/v1/events", headers=headers)).json()
        self.assertEqual([e["message_id"] for e in first["events"]], ["m1", "m2"])
        after = first["events"][0]["seq"]
        rest = await (
            await self.client.get(f"/v1/events?after={after}", headers=headers)
        ).json()
        self.assertEqual([e["message_id"] for e in rest["events"]], ["m2"])
        other = await (
            await self.client.get(
                "/v1/events", headers={"Authorization": f"Bearer {theirs}"}
            )
        ).json()
        self.assertEqual([e["message_id"] for e in other["events"]], ["m3"])


class StreamTest(RelayTestBase):
    async def test_stream_sends_backlog_then_live_events(self):
        session = (await self.register())["session_token"]
        await self.deliver(follow(), message_id="m1")
        socket = await self.client.ws_connect(
            "/v1/stream?after=0", headers={"Authorization": f"Bearer {session}"}
        )
        hello = await socket.receive_json(timeout=5)
        self.assertEqual(hello["type"], "hello")
        backlog = await socket.receive_json(timeout=5)
        self.assertEqual(backlog["message_id"], "m1")
        synced = await socket.receive_json(timeout=5)
        self.assertEqual(synced, {"type": "synced", "seq": backlog["seq"]})
        await self.deliver(follow(follower="live"), message_id="m2")
        live = await socket.receive_json(timeout=5)
        self.assertEqual(live["message_id"], "m2")
        self.assertEqual(live["payload"]["follower"]["username"], "live")
        await socket.close()

    async def test_stream_resumes_after_cursor(self):
        session = (await self.register())["session_token"]
        await self.deliver(follow(), message_id="m1")
        await self.deliver(follow(follower="b"), message_id="m2")
        seq = self.store.events_after(BROADCASTER, 0)[0].seq
        socket = await self.client.ws_connect(
            f"/v1/stream?after={seq}", headers={"Authorization": f"Bearer {session}"}
        )
        await socket.receive_json(timeout=5)  # hello
        backlog = await socket.receive_json(timeout=5)
        self.assertEqual(backlog["message_id"], "m2")
        await socket.close()

    async def test_signing_out_closes_open_sockets(self):
        session = (await self.register())["session_token"]
        socket = await self.client.ws_connect(
            "/v1/stream", headers={"Authorization": f"Bearer {session}"}
        )
        await socket.receive_json(timeout=5)  # hello
        await socket.receive_json(timeout=5)  # synced
        await self.client.delete(
            "/v1/session", headers={"Authorization": f"Bearer {session}"}
        )
        message = await socket.receive(timeout=5)
        self.assertIn(message.type.name, ("CLOSE", "CLOSED", "CLOSING"))


class HousekeepingTest(RelayTestBase):
    async def test_reconcile_recreates_dropped_and_removes_orphans(self):
        await self.register()
        dropped = next(
            sub_id
            for sub_id, sub in self.fake.subscriptions.items()
            if sub["event"] == "kicks.gifted"
        )
        del self.fake.subscriptions[dropped]
        self.fake.subscriptions["orphan"] = {
            "id": "orphan",
            "broadcaster_user_id": OTHER,
            "event": "channel.followed",
            "version": 1,
        }
        await relay.reconcile(self.app)
        events = sorted(
            sub["event"]
            for sub in self.fake.subscriptions.values()
            if sub["broadcaster_user_id"] == BROADCASTER
        )
        self.assertEqual(events, sorted(name for name, _ in kick.EVENTS))
        self.assertNotIn("orphan", self.fake.subscriptions)

    async def test_purge_drops_idle_channels_and_old_events(self):
        await self.register()
        await self.deliver(follow())
        import time as clock

        future = clock.time() + 31 * 24 * 3600
        leftover = self.store.purge(now=future)
        self.assertEqual(leftover, [BROADCASTER])
        for user_id in leftover:
            await relay._forget(self.app, user_id)
        self.assertEqual(self.fake.subscriptions, {})
        self.assertEqual(self.store.latest_seq(BROADCASTER), 0)


class SignatureTest(unittest.TestCase):
    def test_documented_key_loads(self):
        signature.load_public_key(signature.KICK_PUBLIC_KEY_PEM)

    def test_garbage_signature_is_false_not_an_error(self):
        key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        self.assertFalse(
            signature.verify(key.public_key(), "id", "ts", b"{}", "not base64!!")
        )


if __name__ == "__main__":
    unittest.main()
