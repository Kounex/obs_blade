#!/usr/bin/env python3
"""Failover with the plugin AND the standalone installed: OBS crashes
while the plugin holds the relay link, the standalone takes over, a phone
starts OBS again through the relay, the plugin takes the link back - and
the phone reaches OBS end to end.

Runs on the PC with the real OBS (plugin installed) and the standalone
running, against a deployed relay:

    python3 failover.py --relay-url https://relay.obs-blade.com --user <id in RELAY_PRO_ALLOW>

Kills OBS hard (a crash, not a clean quit): the next start must not stop
at OBS's "Launch in Safe Mode?" question (the standalone clears the crash
marks). The test device is removed at the end. macOS only for now
(pkill / pgrep). Needs aiohttp, noiseprotocol, cryptography.
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import subprocess
import time

import aiohttp

from e2e_relay import Obs, Sealed, fail, new_key, ok

OBS = "ws://127.0.0.1:4455"


def obs_running() -> bool:
    return subprocess.run(["pgrep", "-ix", "obs"], capture_output=True).returncode == 0


async def bridge_info(http, relay, bridge_id, auth) -> dict:
    async with http.get(f"{relay}/v1/bridges/{bridge_id}", headers=auth) as r:
        return await r.json()


async def wait_for(what: str, seconds: float, check) -> float:
    started = time.monotonic()
    while time.monotonic() - started < seconds:
        if await check():
            return time.monotonic() - started
        await asyncio.sleep(0.5)
    fail(f"timed out after {seconds:.0f} s: {what}")
    return 0.0


async def pair(http, relay: str, user: str):
    async with http.post(
        f"{relay}/v1/pairings", json={"app_user_id": user, "device_name": "Failover test", "platform": "ios"}
    ) as r:
        pairing = await r.json()
    if "code" not in pairing:
        fail(f"pairing refused: {pairing}")
    app_private, app_public = new_key()
    async with http.ws_connect(OBS, protocols=("obswebsocket.json",)) as lan_ws:
        lan = Obs(lan_ws)
        await lan.identify(None)
        # The plugin's vendor request, as the app sends it on the LAN
        answer = await lan.request(
            "CallVendorRequest",
            {
                "vendorName": "obs-blade-bridge",
                "requestType": "Pair",
                "requestData": {"code": pairing["code"], "app_key": base64.b64encode(app_public).decode()},
            },
        )
        data = answer.get("responseData", {}).get("responseData", {})
        if not data.get("accepted") or not data.get("bridge_key"):
            fail(f"the plugin didn't take the pairing: {answer}")
        bridge_key = base64.b64decode(data["bridge_key"])
    for _ in range(40):
        async with http.post(f"{relay}/v1/pairings/collect", json={"pairing_id": pairing["pairing_id"]}) as r:
            body = await r.json()
        if body.get("state") == "paired":
            return body, app_private, bridge_key
        await asyncio.sleep(0.5)
    fail("the plugin never redeemed the code")


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--relay-url", required=True)
    parser.add_argument("--user", required=True)
    args = parser.parse_args()
    relay = args.relay_url.rstrip("/")

    if not obs_running():
        fail("start OBS (with the plugin) first")
    async with aiohttp.ClientSession() as http:
        collected, app_private, bridge_key = await pair(http, relay, args.user)
        bridge_id, device_id = collected["bridge"]["id"], collected["device_id"]
        auth = {"Authorization": f"Bearer {collected['app_token']}"}
        ok(f"paired through the plugin ({collected['bridge']['kind']}, {collected['bridge']['name']})")
        try:
            await run(http, relay, bridge_id, auth, app_private, bridge_key)
        finally:
            async with http.delete(f"{relay}/v1/devices/{device_id}", headers=auth) as r:
                print(f"     test device removed ({r.status})", flush=True)


async def run(http, relay, bridge_id, auth, app_private, bridge_key) -> None:
    async def plugin_online():
        info = await bridge_info(http, relay, bridge_id, auth)
        return info["online"] and info["kind"] == "plugin" and info["obs"] == "running"

    await wait_for("plugin online with OBS running", 20, plugin_online)
    ok("plugin holds the link, OBS running")

    subprocess.run(["pkill", "-9", "-ix", "obs"], check=False)
    await wait_for("OBS gone", 10, lambda: asyncio.sleep(0, result=not obs_running()))
    ok("OBS killed (SIGKILL - a crash, no clean exit)")

    async def standalone_online():
        info = await bridge_info(http, relay, bridge_id, auth)
        return info["online"] and info["kind"] == "standalone" and info["obs"] == "closed"

    took = await wait_for("the standalone taking over with OBS closed", 90, standalone_online)
    ok(f"standalone took over after {took:.1f} s, reports OBS closed")

    async with http.post(f"{relay}/v1/bridges/{bridge_id}/start-obs", headers=auth) as r:
        if r.status != 202:
            fail(f"start-obs: {r.status} {await r.text()}")
    ok("phone asked the standalone to start OBS (202)")

    took = await wait_for(
        "the plugin back on the link with OBS running (stuck at the Safe Mode question?)", 90, plugin_online
    )
    ok(f"OBS started without the Safe Mode question, plugin back after {took:.1f} s")

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
