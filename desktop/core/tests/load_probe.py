#!/usr/bin/env python3
"""A phone session through the relay under the dashboard's real load, with
the app's liveness rule: dart:io pings every 15 s and closes the socket
when the pong isn't back 15 s later (only a pong resets it, data doesn't).

    python3 load_probe.py --relay-url https://relay.obs-blade.com --user <id in RELAY_PRO_ALLOW> [--seconds 120]

Pairs a test device through the plugin (OBS running), then for --seconds:
subscribes like the app (all + InputVolumeMeters), requests program
scene screenshots back to back (the dashboard preview loop) and pings
every 15 s. Prints pong delays, request round trips and bytes/s; the
device is removed at the end.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import time

import aiohttp

from e2e_relay import Sealed, fail, ok
from failover import pair

SUBSCRIBE = 0x7FF | (1 << 16)
PING_EVERY = 15.0


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--relay-url", required=True)
    parser.add_argument("--user", required=True)
    parser.add_argument("--seconds", type=float, default=120)
    parser.add_argument("--no-meters", action="store_true")
    parser.add_argument("--no-preview", action="store_true")
    args = parser.parse_args()
    relay = args.relay_url.rstrip("/")

    async with aiohttp.ClientSession() as http:
        collected, app_private, bridge_key = await pair(http, relay, args.user)
        bridge_id, device_id = collected["bridge"]["id"], collected["device_id"]
        auth = {"Authorization": f"Bearer {collected['app_token']}"}
        ok("paired through the plugin")
        try:
            await run(http, relay, bridge_id, auth, app_private, bridge_key, args)
        finally:
            async with http.delete(f"{relay}/v1/devices/{device_id}", headers=auth) as r:
                print(f"     test device removed ({r.status})", flush=True)


async def run(http, relay, bridge_id, auth, app_private, bridge_key, args) -> None:
    url = f"{relay.replace('http', 'ws', 1)}/v1/app?bridge={bridge_id}"
    async with http.ws_connect(url, headers=auth, protocols=("obswebsocket.json",), autoping=False) as ws:
        sealed = Sealed(ws, app_private, bridge_key)
        await sealed.handshake()
        start = time.monotonic()
        stats = {"bytes": 0, "events": 0, "meters": 0, "shots": 0, "rtts": []}
        waiters: dict[str, tuple[asyncio.Future, float]] = {}
        pong: asyncio.Future | None = None
        closed: list[str] = []
        pending = b""

        async def reader():
            nonlocal pending, pong
            while True:
                message = await ws.receive()
                if message.type == aiohttp.WSMsgType.PONG:
                    if pong and not pong.done():
                        pong.set_result(time.monotonic())
                    continue
                if message.type == aiohttp.WSMsgType.PING:
                    await ws.pong(message.data)
                    continue
                if message.type != aiohttp.WSMsgType.BINARY:
                    closed.append(f"{message.type.name} code={ws.close_code}")
                    return
                stats["bytes"] += len(message.data)
                plain = sealed.noise.decrypt(message.data)
                pending += plain[1:]
                if plain[0] != 1:
                    continue
                data = json.loads(pending.decode())
                pending = b""
                if data["op"] == 5:
                    stats["events"] += 1
                    if data["d"]["eventType"] == "InputVolumeMeters":
                        stats["meters"] += 1
                elif data["op"] == 7:
                    waiter = waiters.pop(data["d"]["requestId"], None)
                    if waiter:
                        stats["rtts"].append(time.monotonic() - waiter[1])
                        waiter[0].set_result(data["d"])
                elif data["op"] == 2:
                    identified.set_result(True)

        identified: asyncio.Future = asyncio.get_running_loop().create_future()
        reading = asyncio.create_task(reader())
        hello_wait = time.monotonic()
        while not stats["bytes"] and time.monotonic() - hello_wait < 10:
            await asyncio.sleep(0.05)
        subs = SUBSCRIBE if not args.no_meters else 0x7FF
        await sealed.send_str(json.dumps({"op": 1, "d": {"rpcVersion": 1, "eventSubscriptions": subs}}))
        await asyncio.wait_for(identified, 10)
        ok("identified through the relay")

        n = 0

        async def request(kind: str, data: dict | None = None) -> dict:
            nonlocal n
            n += 1
            rid = f"r{n}"
            future = asyncio.get_running_loop().create_future()
            waiters[rid] = (future, time.monotonic())
            await sealed.send_str(json.dumps({"op": 6, "d": {"requestType": kind, "requestId": rid, "requestData": data or {}}}))
            return await asyncio.wait_for(future, 60)

        scene = (await request("GetCurrentProgramScene"))["responseData"]["sceneName"]

        async def preview_loop():
            while True:
                await request("GetSourceScreenshot", {"sourceName": scene, "imageFormat": "jpg", "imageWidth": 1320, "imageCompressionQuality": -1})
                stats["shots"] += 1

        async def stats_loop():
            while True:
                await request("GetStats")
                await asyncio.sleep(1)

        tasks = [asyncio.create_task(stats_loop())]
        if not args.no_preview:
            tasks.append(asyncio.create_task(preview_loop()))
        last_report = time.monotonic()
        last_bytes = 0
        try:
            while time.monotonic() - start < args.seconds and not closed:
                await asyncio.sleep(PING_EVERY)
                pong = asyncio.get_running_loop().create_future()
                sent = time.monotonic()
                await ws.ping(b"dart")
                try:
                    got = await asyncio.wait_for(asyncio.shield(pong), PING_EVERY)
                    delay = got - sent
                except asyncio.TimeoutError:
                    delay = None
                now = time.monotonic()
                rate = (stats["bytes"] - last_bytes) / (now - last_report) / 1024
                rtts = sorted(stats["rtts"]) or [0]
                stats["rtts"] = []
                print(
                    f"t={now - start:5.1f}s pong {'%.2fs' % delay if delay is not None else 'MISSING (dart would close now)'}"
                    f" | {rate:6.0f} KB/s down, {stats['shots']} shots, {stats['meters']} meter events,"
                    f" request rtt median {rtts[len(rtts) // 2]:.2f}s max {rtts[-1]:.2f}s",
                    flush=True,
                )
                last_report, last_bytes = now, stats["bytes"]
                stats["shots"] = stats["meters"] = 0
                if delay is None:
                    fail("pong missing")
        finally:
            for task in tasks:
                task.cancel()
            reading.cancel()
        if closed:
            fail(f"socket closed: {closed}")
        ok(f"{args.seconds:.0f} s without a missing pong")


if __name__ == "__main__":
    asyncio.run(main())
