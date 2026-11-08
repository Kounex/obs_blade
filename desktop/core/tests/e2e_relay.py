#!/usr/bin/env python3
"""End to end: real relay (tool/remote_relay) + the bridge CLI (obb) + a
real OBS, with this script as the phone.

    python3 e2e_relay.py --relay-dir ../../../tool/remote_relay --obb target/debug/obb \
        [--obs-password PW] [--stop-obs-cmd "obs_test_env.sh stop"]
        [--relay-url https://relay.obs-blade.com --user <id in RELAY_PRO_ALLOW>]

Needs aiohttp and noiseprotocol (an independent Noise implementation:
the phone's end-to-end side, as the app does it). Pro is granted through
RELAY_PRO_ALLOW (no RevenueCat). Prints one line per check and exits
non-zero on the first failure.
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
import types

import aiohttp
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey
from cryptography.hazmat.primitives.serialization import Encoding, NoEncryption, PrivateFormat, PublicFormat
from noise.connection import Keypair, NoiseConnection

USER = "e2e-phone"
PORT = 18426
RELAY = f"http://127.0.0.1:{PORT}"
OBS = "ws://127.0.0.1:4455"
# EventSubscription: All (0x7FF minus high-volume) | InputVolumeMeters (1 << 16)
SUBSCRIBE = 0x7FF | (1 << 16)
NOISE = b"Noise_IK_25519_ChaChaPoly_SHA256"
PROLOGUE = b"obs-blade-remote/1"
MAX_CHUNK = 65535 - 16 - 1


def new_key() -> tuple[bytes, bytes]:
    private = X25519PrivateKey.generate()
    return (
        private.private_bytes(Encoding.Raw, PrivateFormat.Raw, NoEncryption()),
        private.public_key().public_bytes(Encoding.Raw, PublicFormat.Raw),
    )


class Sealed:
    """The phone's relay socket with the end-to-end layer: looks like a
    websocket of text frames to [Obs], sends / gets Noise frames."""

    def __init__(self, ws, private: bytes, bridge_public: bytes):
        self.ws = ws
        self.noise = NoiseConnection.from_name(NOISE)
        self.noise.set_as_initiator()
        self.noise.set_keypair_from_private_bytes(Keypair.STATIC, private)
        self.noise.set_keypair_from_public_bytes(Keypair.REMOTE_STATIC, bridge_public)
        self.noise.set_prologue(PROLOGUE)
        self.noise.start_handshake()
        self.binary_frames = 0
        self.largest_message_frames = 0

    async def handshake(self) -> None:
        await self.ws.send_bytes(self.noise.write_message())
        message = await self.ws.receive(timeout=10)
        if message.type != aiohttp.WSMsgType.BINARY:
            raise ConnectionError(f"no handshake answer: {message.type} {self.ws.close_code}")
        self.noise.read_message(message.data)
        assert self.noise.handshake_finished

    async def send_str(self, text: str) -> None:
        data = text.encode()
        chunks = [data[i : i + MAX_CHUNK] for i in range(0, len(data), MAX_CHUNK)] or [b""]
        for i, chunk in enumerate(chunks):
            fin = b"\x01" if i == len(chunks) - 1 else b"\x00"
            await self.ws.send_bytes(self.noise.encrypt(fin + chunk))

    async def receive(self, timeout: float):
        pending = b""
        frames = 0
        while True:
            message = await self.ws.receive(timeout=timeout)
            if message.type != aiohttp.WSMsgType.BINARY:
                raise ConnectionError(f"readable or closing frame: {message.type} {self.ws.close_code}")
            self.binary_frames += 1
            frames += 1
            plain = self.noise.decrypt(message.data)
            pending += plain[1:]
            if plain[0] == 1:
                self.largest_message_frames = max(self.largest_message_frames, frames)
                return types.SimpleNamespace(type=aiohttp.WSMsgType.TEXT, data=pending.decode())


def ok(message: str) -> None:
    print(f"ok   {message}", flush=True)


def fail(message: str) -> None:
    print(f"FAIL {message}", flush=True)
    raise SystemExit(1)


def auth_string(password: str, salt: str, challenge: str) -> str:
    secret = base64.b64encode(hashlib.sha256((password + salt).encode()).digest()).decode()
    return base64.b64encode(hashlib.sha256((secret + challenge).encode()).digest()).decode()


def jpeg_size(data: bytes) -> tuple[int, int]:
    i = 2
    while i < len(data):
        if data[i] != 0xFF:
            i += 1
            continue
        marker = data[i + 1]
        length = int.from_bytes(data[i + 2 : i + 4], "big")
        if marker in (0xC0, 0xC1, 0xC2):
            return int.from_bytes(data[i + 7 : i + 9], "big"), int.from_bytes(data[i + 5 : i + 7], "big")
        i += 2 + length
    raise ValueError("no SOF")


class Obs:
    """A minimal obs-websocket client (the phone's protocol)."""

    def __init__(self, ws):
        self.ws = ws
        self.n = 0
        self.events: list[dict] = []

    async def identify(self, password: str | None) -> dict:
        hello = json.loads((await self.ws.receive(timeout=5)).data)
        assert hello["op"] == 0, hello
        d = {"rpcVersion": 1, "eventSubscriptions": SUBSCRIBE}
        if "authentication" in hello["d"]:
            a = hello["d"]["authentication"]
            d["authentication"] = auth_string(password or "", a["salt"], a["challenge"])
        await self.ws.send_str(json.dumps({"op": 1, "d": d}))
        identified = json.loads((await self.ws.receive(timeout=5)).data)
        assert identified["op"] == 2, identified
        return hello

    async def request(self, kind: str, data: dict | None = None) -> dict:
        self.n += 1
        rid = f"r{self.n}"
        await self.ws.send_str(json.dumps({"op": 6, "d": {"requestType": kind, "requestId": rid, "requestData": data or {}}}))
        while True:
            message = json.loads((await self.ws.receive(timeout=10)).data)
            if message["op"] == 5:
                self.events.append(message["d"])
                continue
            if message["op"] == 7 and message["d"]["requestId"] == rid:
                return message["d"]

    async def event(self, kind: str, timeout: float = 3) -> dict | None:
        for e in self.events:
            if e["eventType"] == kind:
                return e
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try:
                message = await self.ws.receive(timeout=deadline - time.monotonic())
            except asyncio.TimeoutError:
                return None
            data = json.loads(message.data)
            if data["op"] == 5 and data["d"]["eventType"] == kind:
                return data["d"]
        return None


async def screenshot(obs: Obs, scene: str) -> tuple[int, tuple[int, int]]:
    # Exactly what DashboardStore._sendPreviewImageRequest sends.
    r = await obs.request("GetSourceScreenshot", {"sourceName": scene, "imageFormat": "jpg",
                                                  "imageWidth": 1179, "imageCompressionQuality": -1})
    if not r["requestStatus"]["result"]:
        fail(f"screenshot: {r['requestStatus']}")
    data = base64.b64decode(r["responseData"]["imageData"].split(",", 1)[1])
    return len(data), jpeg_size(data)


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--relay-dir", required=True)
    parser.add_argument("--obb", required=True)
    parser.add_argument("--obs-password")
    parser.add_argument("--stop-obs-cmd", help="shell command that quits OBS; then the phone must get 4901")
    parser.add_argument("--relay-url", help="use this deployed relay instead of starting one")
    parser.add_argument("--user", help="app user id the deployed relay treats as Pro (RELAY_PRO_ALLOW)")
    args = parser.parse_args()
    global RELAY, USER
    if args.relay_url:
        RELAY = args.relay_url.rstrip("/")
        USER = args.user or fail("--relay-url needs --user")

    tmp = tempfile.mkdtemp(prefix="obb-e2e-")
    env = dict(os.environ, RELAY_PORT=str(PORT), RELAY_DB=f"{tmp}/relay.db", RC_PROJECT_ID="e2e",
               RC_API_KEY="unused", RELAY_PRO_ALLOW=USER)
    relay = None if args.relay_url else subprocess.Popen(
        [sys.executable, "relay.py"], cwd=args.relay_dir, env=env,
        stdout=subprocess.DEVNULL, stderr=open(f"{tmp}/relay.log", "w"))
    obb_args = [args.obb, "--relay", RELAY, "--state", f"{tmp}/bridge.json", "--name", "E2E-PC"]
    bridge = subprocess.Popen(obb_args, stdin=subprocess.PIPE, stdout=open(f"{tmp}/obb.log", "w"),
                              stderr=subprocess.STDOUT, text=True)
    if args.obs_password:
        # OBS started with --websocket_password: its config file doesn't know it.
        bridge.stdin.write(json.dumps({"cmd": "set_obs_override", "password": args.obs_password}) + "\n")
        bridge.stdin.flush()
    try:
        async with aiohttp.ClientSession() as http:
            for _ in range(50):
                try:
                    async with http.get(f"{RELAY}/health") as r:
                        if r.status == 200:
                            break
                except aiohttp.ClientError:
                    await asyncio.sleep(0.1)
            ok("relay up")
            await run(http, args, tmp)
    finally:
        bridge.stdin.close()
        try:
            bridge.wait(timeout=5)
        except subprocess.TimeoutExpired:
            bridge.kill()
        if relay:
            relay.terminate()
            relay.wait(timeout=5)
        print(f"logs in {tmp}")


async def run(http: aiohttp.ClientSession, args, tmp: str) -> None:
    async with http.post(f"{RELAY}/v1/pairings", json={"app_user_id": USER, "device_name": "E2E phone", "platform": "ios"}) as r:
        pairing = await r.json()
    ok(f"pairing code {pairing['code']}")

    # The phone, still on the LAN, hands the code and its end-to-end key to
    # the bridge through OBS - right away, as the app does, and again every
    # 2 s until it has both the relay's pairing and the bridge's key back
    # (a CustomEvent reaches only bridges connected at that moment).
    app_private, app_public = new_key()
    collected = None
    bridge_key = None
    async with http.ws_connect(OBS, protocols=("obswebsocket.json",)) as lan_ws:
        lan = Obs(lan_ws)
        await lan.identify(args.obs_password)
        scenes = await lan.request("GetSceneList")
        scene = scenes["responseData"]["currentProgramSceneName"]
        lan_size, lan_dims = await screenshot(lan, scene)
        sends = 0
        pair = {"code": pairing["code"], "app_key": base64.b64encode(app_public).decode()}
        for attempt in range(80):
            if bridge_key is None and attempt % 8 == 0:
                r = await lan.request("BroadcastCustomEvent", {"eventData": {"obs-blade-pair": pair}})
                assert r["requestStatus"]["result"], r
                sends += 1
            if collected is None:
                async with http.post(f"{RELAY}/v1/pairings/collect", json={"pairing_id": pairing["pairing_id"]}) as r:
                    body = await r.json()
                if body.get("state") == "paired":
                    collected = body
            await lan.request("GetVersion")  # pumps events in
            for e in lan.events:
                ack = e.get("eventData", {}).get("obs-blade-pair-ack") if e["eventType"] == "CustomEvent" else None
                if ack and ack["code"] == pairing["code"]:
                    bridge_key = base64.b64decode(ack["bridge_key"])
            if collected and bridge_key:
                break
            await asyncio.sleep(0.25)
    if not collected:
        fail(f"bridge never redeemed the code (see {tmp}/obb.log)")
    if not bridge_key or len(bridge_key) != 32:
        fail(f"no bridge key came back through OBS (see {tmp}/obb.log)")
    ok(f"code + app key sent as CustomEvent ({sends}x), bridge key back through OBS; LAN screenshot {lan_dims[0]}x{lan_dims[1]}, {lan_size // 1024} KB")
    ok(f"paired with bridge {collected['bridge']['name']} ({collected['bridge']['kind']})")
    bridge_id, token = collected["bridge"]["id"], collected["app_token"]
    auth = {"Authorization": f"Bearer {token}"}

    for _ in range(40):
        async with http.get(f"{RELAY}/v1/bridges/{bridge_id}", headers=auth) as r:
            info = await r.json()
        if info["online"] and info["obs"] == "running":
            break
        await asyncio.sleep(0.25)
    else:
        fail(f"bridge not online with OBS running: {info}")
    ok("bridge online, OBS running")

    app_socket = f"{RELAY.replace('http', 'ws')}/v1/app?bridge={bridge_id}"
    async with http.ws_connect(app_socket, headers=auth, protocols=("obswebsocket.json",)) as phone_ws:
        await phone_ws.send_str('{"op":1,"d":{"rpcVersion":1}}')
        await phone_ws.receive(timeout=10)
        if phone_ws.close_code != 1003:
            fail(f"a readable frame wasn't refused: {phone_ws.close_code}")
    ok("readable (unencrypted) frame refused by the relay (1003)")

    stranger_private, _ = new_key()
    async with http.ws_connect(app_socket, headers=auth) as phone_ws:
        try:
            await Sealed(phone_ws, stranger_private, bridge_key).handshake()
            fail("a key the bridge never paired opened a session")
        except ConnectionError:
            pass
        if phone_ws.close_code != 4904:
            fail(f"unknown phone key: expected 4904, got {phone_ws.close_code}")
    ok("a phone key the bridge doesn't know is refused (4904)")

    async with http.ws_connect(app_socket, headers=auth, protocols=("obswebsocket.json",)) as phone_ws:
        sealed = Sealed(phone_ws, app_private, bridge_key)
        await sealed.handshake()
        ok("end-to-end handshake with the bridge (Noise IK, independent implementation)")
        phone = Obs(sealed)
        hello = await phone.identify(None)  # no password: the bridge authenticates
        if "authentication" in hello["d"]:
            fail("relay Hello still carries authentication")
        ok(f"identified through the relay (obs-websocket {hello['d']['obsWebSocketVersion']}), no password on the phone")
        version = await phone.request("GetVersion")
        ok(f"GetVersion: OBS {version['responseData']['obsVersion']}")
        size, dims = await screenshot(phone, scene)
        if max(dims) > 640:
            fail(f"relay screenshot not capped: {dims}")
        if abs(dims[0] / dims[1] - lan_dims[0] / lan_dims[1]) > 0.02:
            fail(f"relay screenshot distorted: {dims} vs LAN {lan_dims}")
        ok(f"relay screenshot {dims[0]}x{dims[1]}, {size // 1024} KB (LAN {lan_size // 1024} KB, {100 - size * 100 // max(lan_size, 1)}% smaller)")
        # A message far past Noise's 65535-byte limit, both ways: OBS echoes
        # a CustomEvent to every General subscriber, this phone included.
        blob = base64.b64encode(os.urandom(150_000)).decode()
        r = await phone.request("BroadcastCustomEvent", {"eventData": {"e2e-blob": blob}})
        if not r["requestStatus"]["result"]:
            fail(f"big CustomEvent refused: {r['requestStatus']}")
        echo = await phone.event("CustomEvent", timeout=5)
        if not echo or echo["eventData"].get("e2e-blob") != blob:
            fail("200 KB CustomEvent didn't come back whole")
        ok(f"{len(blob) // 1024} KB message out and back whole, {sealed.largest_message_frames} encrypted frames for one message")
        meters = await phone.event("InputVolumeMeters", timeout=3)
        ok("InputVolumeMeters flow through the relay" if meters else "no InputVolumeMeters (no audio inputs?) - not checked")
        ok(f"{sealed.binary_frames} frames from the relay, all encrypted binary")

    await asyncio.sleep(1)
    async with http.get(f"{RELAY}/health") as r:
        health = await r.json()
    if health["sessions"] != 0:
        fail(f"session left open after the phone closed: {health}")
    ok("phone closed, relay session gone")

    print("     waiting for a status snapshot (20 s cycle)...", flush=True)
    for _ in range(50):
        async with http.get(f"{RELAY}/v1/bridges/{bridge_id}", headers=auth) as r:
            info = await r.json()
        if info["status"]:
            break
        await asyncio.sleep(1)
    else:
        fail("no status snapshot after 50 s")
    status = info["status"]
    ok(f"status: streaming={status['streaming']} recording={status['recording']} disk_free_mb={status['disk_free_mb']:.0f} fps={status['fps']}")

    if not args.stop_obs_cmd:
        return
    subprocess.run(args.stop_obs_cmd, shell=True, check=True)
    for _ in range(40):
        async with http.get(f"{RELAY}/v1/bridges/{bridge_id}", headers=auth) as r:
            info = await r.json()
        if info["obs"] == "closed":
            break
        await asyncio.sleep(0.5)
    else:
        fail(f"bridge didn't report OBS closed: {info['obs']}")
    ok("OBS quit: bridge reports closed")
    async with http.ws_connect(f"{RELAY.replace('http', 'ws')}/v1/app?bridge={bridge_id}", headers=auth) as phone_ws:
        message = await phone_ws.receive(timeout=10)
        if message.type not in (aiohttp.WSMsgType.CLOSE, aiohttp.WSMsgType.CLOSED) or phone_ws.close_code != 4901:
            fail(f"expected close 4901, got {message.type} {phone_ws.close_code}")
    ok("phone told 4901 (OBS not running)")


if __name__ == "__main__":
    asyncio.run(main())
