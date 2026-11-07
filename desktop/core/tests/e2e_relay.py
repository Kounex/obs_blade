#!/usr/bin/env python3
"""End to end: real relay (tool/remote_relay) + the bridge CLI (obb) + a
real OBS, with this script as the phone.

    python3 e2e_relay.py --relay-dir ../../../tool/remote_relay --obb target/debug/obb \
        [--obs-password PW] [--stop-obs-cmd "obs_test_env.sh stop"]

Needs aiohttp. Pro is granted through RELAY_PRO_ALLOW (no RevenueCat).
Prints one line per check and exits non-zero on the first failure.
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

import aiohttp

USER = "e2e-phone"
PORT = 18426
RELAY = f"http://127.0.0.1:{PORT}"
OBS = "ws://127.0.0.1:4455"
# EventSubscription: All (0x7FF minus high-volume) | InputVolumeMeters (1 << 16)
SUBSCRIBE = 0x7FF | (1 << 16)


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
    args = parser.parse_args()

    tmp = tempfile.mkdtemp(prefix="obb-e2e-")
    env = dict(os.environ, RELAY_PORT=str(PORT), RELAY_DB=f"{tmp}/relay.db", RC_PROJECT_ID="e2e",
               RC_API_KEY="unused", RELAY_PRO_ALLOW=USER, RELAY_MIN_BRIDGE_VERSION="0.1.0")
    relay = subprocess.Popen([sys.executable, "relay.py"], cwd=args.relay_dir, env=env,
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
        relay.terminate()
        relay.wait(timeout=5)
        print(f"logs in {tmp}")


async def run(http: aiohttp.ClientSession, args, tmp: str) -> None:
    async with http.post(f"{RELAY}/v1/pairings", json={"app_user_id": USER, "device_name": "E2E phone", "platform": "ios"}) as r:
        pairing = await r.json()
    ok(f"pairing code {pairing['code']}")

    # The phone, still on the LAN, hands the code to the bridge through OBS
    # - right away, as the app does, and again every 2 s until collected
    # (a CustomEvent reaches only bridges connected at that moment).
    collected = None
    async with http.ws_connect(OBS, protocols=("obswebsocket.json",)) as lan_ws:
        lan = Obs(lan_ws)
        await lan.identify(args.obs_password)
        scenes = await lan.request("GetSceneList")
        scene = scenes["responseData"]["currentProgramSceneName"]
        lan_size, lan_dims = await screenshot(lan, scene)
        sends = 0
        for attempt in range(60):
            if attempt % 8 == 0:
                r = await lan.request("BroadcastCustomEvent", {"eventData": {"obs-blade-pair": {"code": pairing["code"]}}})
                assert r["requestStatus"]["result"], r
                sends += 1
            async with http.post(f"{RELAY}/v1/pairings/collect", json={"pairing_id": pairing["pairing_id"]}) as r:
                body = await r.json()
            if body.get("state") == "paired":
                collected = body
                break
            await asyncio.sleep(0.25)
    if not collected:
        fail(f"bridge never redeemed the code (see {tmp}/obb.log)")
    ok(f"code sent as CustomEvent ({sends}x); LAN screenshot {lan_dims[0]}x{lan_dims[1]}, {lan_size // 1024} KB")
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

    async with http.ws_connect(f"{RELAY.replace('http', 'ws')}/v1/app?bridge={bridge_id}", headers=auth,
                               protocols=("obswebsocket.json",)) as phone_ws:
        phone = Obs(phone_ws)
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
        meters = await phone.event("InputVolumeMeters", timeout=3)
        ok("InputVolumeMeters flow through the relay" if meters else "no InputVolumeMeters (no audio inputs?) - not checked")

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
