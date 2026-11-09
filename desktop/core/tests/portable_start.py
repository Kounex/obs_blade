#!/usr/bin/env python3
"""A portable OBS on Windows with the standalone: the standalone finds the
portable install's WebSocket settings from the running process, a phone
pairs, OBS crashes, the phone starts it again through the relay - the
portable copy, without the Safe Mode question - and reaches it end to end.

Runs on the Windows PC with the standalone running and a portable OBS
(`portable_mode.txt`) running whose WebSocket settings differ from the
regular install's, against a deployed relay:

    py portable_start.py --relay-url https://relay.obs-blade.com --user <id in RELAY_PRO_ALLOW> \
        --obs-dir C:\\obb-test\\OBS-portable --obs-port 4466 --obs-password <pw>

The test device is removed at the end. Needs aiohttp, noiseprotocol,
cryptography.
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import os
import subprocess
import time

import aiohttp

from e2e_relay import Obs, Sealed, fail, new_key, ok


def obs_exe_running() -> str:
    out = subprocess.run(
        ["powershell", "-NoProfile", "-Command", "(Get-Process obs64 -ErrorAction SilentlyContinue).Path"],
        capture_output=True,
        text=True,
    )
    return out.stdout.strip()


def crash_marks(obs_dir: str) -> set[str]:
    sentinel = os.path.join(obs_dir, "config", "obs-studio", ".sentinel")
    return {n for n in os.listdir(sentinel) if n.startswith("run_")} if os.path.isdir(sentinel) else set()


async def wait_for(what: str, seconds: float, check) -> float:
    started = time.monotonic()
    while time.monotonic() - started < seconds:
        if await check():
            return time.monotonic() - started
        await asyncio.sleep(0.5)
    fail(f"timed out after {seconds:.0f} s: {what}")
    return 0.0


async def pair_standalone(http, relay: str, user: str, obs_url: str, password: str):
    async with http.post(
        f"{relay}/v1/pairings", json={"app_user_id": user, "device_name": "Portable test", "platform": "ios"}
    ) as r:
        pairing = await r.json()
    if "code" not in pairing:
        fail(f"pairing refused: {pairing}")
    app_private, app_public = new_key()
    collected, bridge_key = None, None
    async with http.ws_connect(obs_url, protocols=("obswebsocket.json",)) as lan_ws:
        lan = Obs(lan_ws)
        await lan.identify(password)
        pair = {"code": pairing["code"], "app_key": base64.b64encode(app_public).decode()}
        for attempt in range(120):
            if bridge_key is None and attempt % 8 == 0:
                await lan.request("BroadcastCustomEvent", {"eventData": {"obs-blade-pair": pair}})
            if collected is None:
                async with http.post(f"{relay}/v1/pairings/collect", json={"pairing_id": pairing["pairing_id"]}) as r:
                    body = await r.json()
                if body.get("state") == "paired":
                    collected = body
            await lan.request("GetVersion")  # pumps events in
            for e in lan.events:
                ack = e.get("eventData", {}).get("obs-blade-pair-ack") if e["eventType"] == "CustomEvent" else None
                if ack and ack["code"] == pairing["code"]:
                    bridge_key = base64.b64decode(ack["bridge_key"])
            if collected and bridge_key:
                return collected, app_private, bridge_key
            await asyncio.sleep(0.25)
    fail(f"the standalone didn't pair (collected: {bool(collected)}, key: {bool(bridge_key)})")


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--relay-url", required=True)
    parser.add_argument("--user", required=True)
    parser.add_argument("--obs-dir", required=True)
    parser.add_argument("--obs-port", type=int, required=True)
    parser.add_argument("--obs-password", required=True)
    args = parser.parse_args()
    relay = args.relay_url.rstrip("/")
    portable_exe = os.path.normcase(os.path.join(args.obs_dir, "bin", "64bit", "obs64.exe"))

    if os.path.normcase(obs_exe_running()) != portable_exe:
        fail(f"start the portable OBS first (running: {obs_exe_running() or 'none'})")
    async with aiohttp.ClientSession() as http:
        collected, app_private, bridge_key = await pair_standalone(
            http, relay, args.user, f"ws://127.0.0.1:{args.obs_port}", args.obs_password
        )
        bridge_id, device_id = collected["bridge"]["id"], collected["device_id"]
        auth = {"Authorization": f"Bearer {collected['app_token']}"}
        ok(f"paired through the standalone ({collected['bridge']['kind']}, {collected['bridge']['name']})")
        try:
            await run(http, relay, bridge_id, auth, app_private, bridge_key, args, portable_exe)
        finally:
            async with http.delete(f"{relay}/v1/devices/{device_id}", headers=auth) as r:
                print(f"     test device removed ({r.status})", flush=True)


async def run(http, relay, bridge_id, auth, app_private, bridge_key, args, portable_exe) -> None:
    async def obs_is(state: str):
        async with http.get(f"{relay}/v1/bridges/{bridge_id}", headers=auth) as r:
            info = await r.json()
        return info["online"] and info["kind"] == "standalone" and info["obs"] == state

    await wait_for("the standalone online with OBS running", 30, lambda: obs_is("running"))
    ok("the standalone reaches the portable OBS (its own port and password)")

    subprocess.run(["taskkill", "/F", "/IM", "obs64.exe"], capture_output=True)
    await wait_for("OBS gone", 10, lambda: asyncio.sleep(0, result=not obs_exe_running()))
    marks = crash_marks(args.obs_dir)
    if not marks:
        fail("no crash mark left in the portable config - the test can't show they're cleared")
    ok(f"OBS killed (a crash), {len(marks)} crash mark(s) in the portable config")
    await wait_for("the relay hearing OBS closed", 30, lambda: obs_is("closed"))

    async with http.post(f"{relay}/v1/bridges/{bridge_id}/start-obs", headers=auth) as r:
        if r.status != 202:
            fail(f"start-obs: {r.status} {await r.text()}")
    ok("phone asked the standalone to start OBS (202)")

    await wait_for("OBS running again (stuck at the Safe Mode question?)", 90, lambda: obs_is("running"))
    started = obs_exe_running()
    if os.path.normcase(started) != portable_exe:
        fail(f"the wrong OBS started: {started}")
    left = marks & crash_marks(args.obs_dir)
    if left:
        fail(f"old crash marks still there: {left}")
    ok(f"the portable OBS started ({started}), crash marks cleared, no Safe Mode question")

    app_socket = f"{relay.replace('http', 'ws', 1)}/v1/app?bridge={bridge_id}"
    async with http.ws_connect(app_socket, headers=auth, protocols=("obswebsocket.json",)) as phone_ws:
        sealed = Sealed(phone_ws, app_private, bridge_key)
        await sealed.handshake()
        phone = Obs(sealed)
        await phone.identify(None)
        version = await phone.request("GetVersion")
        ok(f"phone reaches OBS {version['responseData']['obsVersion']} through the relay, end to end")


if __name__ == "__main__":
    asyncio.run(main())
