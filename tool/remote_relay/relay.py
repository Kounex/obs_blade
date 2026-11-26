#!/usr/bin/env python3
"""OBS Blade remote relay: connects a paired phone to the bridge (OBS
plugin or standalone app) next to OBS, from anywhere.

Design: docs/superpowers/specs/2026-11-07-remote-relay-design.md.
Protocol: README.md and protocol.py.
"""

from __future__ import annotations

import asyncio
import contextlib
import json
import logging
import os
import re
import time
from collections import defaultdict, deque
from dataclasses import dataclass, field

import aiohttp
from aiohttp import web

import entitlement
import protocol
from entitlement import Entitlements, Verdict
from store import PairingError, Store, PAIRING_SECONDS

log = logging.getLogger("remote-relay")

LISTEN_HOST = os.environ.get("RELAY_LISTEN", "127.0.0.1")
LISTEN_PORT = int(os.environ.get("RELAY_PORT", "8426"))
DB_PATH = os.environ.get("RELAY_DB", "/var/lib/remote-relay/relay.db")
# 0.3.0: end-to-end encryption (older bridges send readable frames).
MIN_BRIDGE_VERSION = os.environ.get("RELAY_MIN_BRIDGE_VERSION", "0.3.0")
SERVER_VERSION = os.environ.get("RELAY_VERSION", "dev")
# The newest bridge release: bridges behind it get `update_available`, the
# app sees it in the bridge info. Set by hand (local tests) or polled from
# the bridge's latest GitHub release.
LATEST_BRIDGE_VERSION = os.environ.get("RELAY_LATEST_BRIDGE_VERSION", "")
LATEST_BRIDGE_URL = "https://api.github.com/repos/Kounex/obs-blade-remote/releases/latest"
LATEST_BRIDGE_SECONDS = 6 * 3600

MAX_SESSIONS_PER_BRIDGE = 4
# One OBS frame. Screenshots are the big ones; the bridge shrinks preview
# frames, but the app also asks for source screenshots at its own sizes.
MAX_BRIDGE_FRAME = 16 * 1024 * 1024
MAX_APP_FRAME = 4 * 1024 * 1024
# Bytes waiting for a phone that doesn't read. The preview loop waits for
# each answer, so a healthy session stays far below this.
MAX_QUEUED_BYTES = 24 * 1024 * 1024
MAX_STATUS_BYTES = 8 * 1024
STATUS_MIN_INTERVAL = 5.0
HEARTBEAT = 30.0
PRO_RECHECK_SECONDS = 30 * 60
PURGE_SECONDS = 3600
TOO_SLOW = 1013
# A phone that connects while its bridge is away, but the bridge was there
# moments ago (a relay restart, a short drop on the PC's line): wait until
# BRIDGE_GRACE_SECONDS after the bridge was last seen for it to come back,
# instead of answering BRIDGE_OFFLINE at once. The bridge reconnects within
# ~2 s of a relay restart; the phone's handshake timeout is 10 s
# (kObsHandshakeTimeout in the app). Measured from last_seen, not per
# attempt, so a PC that really went away costs a retrying phone (4.3.0
# retries 5x, 3 s apart) these seconds once, not on every attempt.
BRIDGE_GRACE_SECONDS = 6.0
# After a phone's Start OBS: how long until the log says OBS still isn't
# running (the app itself waits 60 s; OBS with many plugins can take 30+)
START_OBS_WATCH_SECONDS = 120.0

# (limit, window seconds) per client IP
LIMITS = {
    "pairing": (10, 600),
    "redeem": (20, 60),
    "app": (60, 60),
    "bridge": (30, 60),
    "api": (120, 60),
}

KEY_STORE = web.AppKey("store", Store)
KEY_ENT = web.AppKey("entitlements", Entitlements)
KEY_HUB = web.AppKey("hub", object)
KEY_LIMITS = web.AppKey("limits", object)
KEY_TASKS = web.AppKey("tasks", list)
KEY_HTTP = web.AppKey("http", object)
KEY_MIN_VERSION = web.AppKey("min_version", str)
KEY_GRACE = web.AppKey("bridge_grace", float)
KEY_START_WATCH = web.AppKey("start_obs_watch", float)
KEY_LATEST = web.AppKey("latest_bridge", dict)


def version_tuple(text: str) -> tuple[int, int, int]:
    parts = (text or "").split("-", 1)[0].split(".")
    try:
        numbers = [int(p) for p in parts[:3]]
    except ValueError:
        return (0, 0, 0)
    while len(numbers) < 3:
        numbers.append(0)
    return tuple(numbers)  # type: ignore[return-value]


_RELEASE = re.compile(r"v?(\d{1,4})\.(\d{1,4})\.(\d{1,4})")


def release_version(text: object) -> str:
    """"0.4.2" from a release tag / bridge version like "v0.4.2"; "" for
    anything else (a pre-release, an empty or garbled version)."""
    match = _RELEASE.fullmatch(text.strip()) if isinstance(text, str) else None
    return ".".join(str(int(n)) for n in match.groups()) if match else ""


class RateLimiter:
    def __init__(self, clock=time.monotonic):
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._now = clock

    def allow(self, kind: str, ip: str) -> bool:
        limit, window = LIMITS[kind]
        now = self._now()
        bucket = self._hits[f"{kind}:{ip}"]
        while bucket and now - bucket[0] > window:
            bucket.popleft()
        if len(bucket) >= limit:
            return False
        bucket.append(now)
        return True

    def prune(self) -> None:
        now = self._now()
        longest = max(window for _, window in LIMITS.values())
        for key in [k for k, b in self._hits.items() if not b or now - b[-1] > longest]:
            del self._hits[key]


@dataclass(eq=False)
class AppSession:
    sid: int
    device_id: str
    app_user_id: str
    ws: web.WebSocketResponse
    link: "BridgeLink"
    queue: asyncio.Queue = field(default_factory=asyncio.Queue)
    queued_bytes: int = 0
    writer: asyncio.Task | None = None
    ended_by_relay: bool = False
    # Diagnostics for the session-end log line (sizes of opaque frames only)
    started: float = field(default_factory=time.monotonic)
    bytes_down: int = 0
    bytes_up: int = 0
    peak_queued: int = 0
    end_reason: str = ""
    # (code, reason) once the relay ends the session. Only the socket's
    # handler closes it: aiohttp's close() from another task while the
    # handler reads skips waiting for the phone's close reply, the TCP
    # connection closes right behind the close frame, and cloudflared
    # drops that frame - the phone sees 1006 instead of the reason
    # (measured through the tunnel, 2026-11-07).
    close_signal: asyncio.Future = field(
        default_factory=lambda: asyncio.get_running_loop().create_future()
    )

    def start(self) -> None:
        self.writer = asyncio.create_task(self._write())

    async def _write(self) -> None:
        try:
            while True:
                item = await self.queue.get()
                if isinstance(item, bytes):
                    self.queued_bytes -= len(item)
                    await self.ws.send_bytes(item)
                    continue
                self._signal_close(*item)
                return
        except (ConnectionResetError, RuntimeError, aiohttp.ClientError):
            pass

    def _signal_close(self, code: int, reason: str) -> None:
        if not self.close_signal.done():
            self.close_signal.set_result((code, reason))

    def deliver(self, frame: bytes) -> None:
        """One end-to-end encrypted frame for the phone (opaque here)."""
        if self.ended_by_relay:
            return
        if self.queued_bytes + len(frame) > MAX_QUEUED_BYTES:
            log.info("session %s: phone too slow, closing", self.sid)
            self.end(TOO_SLOW, "too slow", drain=False)
            return
        self.queued_bytes += len(frame)
        self.bytes_down += len(frame)
        self.peak_queued = max(self.peak_queued, self.queued_bytes)
        self.queue.put_nowait(frame)

    def end(self, code: int, reason: str = "", drain: bool = True) -> None:
        """Close the phone's socket. ``drain`` lets queued frames go out
        first (a bridge CLOSE follows the frames it sent before)."""
        if self.ended_by_relay:
            return
        self.ended_by_relay = True
        self.end_reason = f"relay {code} {reason}".strip()
        if drain:
            self.queue.put_nowait((code, reason))
            return
        if self.writer:
            self.writer.cancel()
        self._signal_close(code, reason)


@dataclass(eq=False)
class BridgeLink:
    bridge_id: str
    kind: str
    version: str
    ws: web.WebSocketResponse
    obs_state: str = ""
    # The last OBS state written to the log (from the store at connect):
    # a reconnect only logs a state that really changed
    obs_logged: str = ""
    sessions: dict[int, AppSession] = field(default_factory=dict)
    next_sid: int = 1
    last_status: float = 0.0
    lock: asyncio.Lock = field(default_factory=asyncio.Lock)
    alive: bool = True
    # For the end-of-link log line
    started: float = field(default_factory=time.monotonic)
    last_frame: float = field(default_factory=time.monotonic)
    # What that frame was ("data", or a control type like "ping"): checks
    # "quiet 0s" on keepalive timeouts, which need 30 s of silence
    last_kind: str = "nothing"
    sessions_dropped: int = 0

    def allocate(self) -> int:
        sid = self.next_sid
        self.next_sid = 1 if sid >= protocol.MAX_SESSION_ID else sid + 1
        while self.next_sid in self.sessions:
            self.next_sid += 1
        return sid

    async def send_frame(self, frame: bytes) -> bool:
        if not self.alive:
            return False
        try:
            async with self.lock:
                await self.ws.send_bytes(frame)
            return True
        except (ConnectionResetError, RuntimeError, aiohttp.ClientError):
            return False

    async def send_json(self, payload: dict) -> bool:
        if not self.alive:
            return False
        try:
            async with self.lock:
                await self.ws.send_str(json.dumps(payload, separators=(",", ":")))
            return True
        except (ConnectionResetError, RuntimeError, aiohttp.ClientError):
            return False


class Hub:
    def __init__(self):
        self.bridges: dict[str, BridgeLink] = {}
        self.by_device: dict[str, AppSession] = {}
        self._waiting: dict[str, set[asyncio.Future]] = defaultdict(set)
        # bridge id -> when a phone last asked it to start OBS (monotonic),
        # until OBS runs or the watch gives up
        self.start_asked: dict[str, float] = {}

    async def wait_for_bridge(self, bridge_id: str, timeout: float) -> BridgeLink | None:
        """The bridge's link once it (re)connects, None after [timeout]."""
        link = self.bridges.get(bridge_id)
        if link is not None or timeout <= 0:
            return link
        waiter = asyncio.get_running_loop().create_future()
        self._waiting[bridge_id].add(waiter)
        try:
            return await asyncio.wait_for(waiter, timeout)
        except asyncio.TimeoutError:
            return self.bridges.get(bridge_id)
        finally:
            waiting = self._waiting.get(bridge_id)
            if waiting is not None:
                waiting.discard(waiter)
                if not waiting:
                    self._waiting.pop(bridge_id, None)

    def bridge_ready(self, link: BridgeLink) -> None:
        for waiter in list(self._waiting.get(link.bridge_id, ())):
            if not waiter.done():
                waiter.set_result(link)

    def sessions(self) -> list[AppSession]:
        return list(self.by_device.values())

    def end_device(self, device_id: str, code: int, reason: str) -> None:
        session = self.by_device.get(device_id)
        if session:
            session.end(code, reason, drain=False)


_background: set[asyncio.Task] = set()


def _spawn(coro) -> None:
    task = asyncio.ensure_future(coro)
    _background.add(task)
    task.add_done_callback(_background.discard)


def _client_ip(request: web.Request) -> str:
    forwarded = request.headers.get("CF-Connecting-IP", "").strip()
    return forwarded or (request.remote or "")


def _bearer(request: web.Request) -> str:
    header = request.headers.get("Authorization", "")
    return header[7:].strip() if header.startswith("Bearer ") else ""


def _json(status: int, payload: dict) -> web.Response:
    return web.json_response(payload, status=status, headers={"Cache-Control": "no-store"})


async def _body(request: web.Request) -> dict:
    try:
        body = await request.json()
    except (ValueError, UnicodeDecodeError):
        return {}
    return body if isinstance(body, dict) else {}


def _text(body: dict, key: str, limit: int) -> str:
    value = body.get(key)
    return value.strip()[:limit] if isinstance(value, str) else ""


def _limited(request: web.Request, kind: str) -> bool:
    return not request.app[KEY_LIMITS].allow(kind, _client_ip(request))


def _outdated(app: web.Application, version: str) -> bool:
    return version_tuple(version) < version_tuple(app[KEY_MIN_VERSION])


def _update_available(app: web.Application, version: str) -> bool:
    """A newer bridge release exists - only for a version that reads
    clearly (an unknown one isn't told to update)."""
    latest = app[KEY_LATEST]["version"]
    mine = release_version(version)
    return bool(latest and mine) and version_tuple(mine) < version_tuple(latest)


def _devices_payload(store: Store, bridge_id: str, hub: Hub, me: str = "") -> list[dict]:
    return [
        {
            "id": d.id,
            "name": d.name,
            "platform": d.platform,
            "created_at": int(d.created_at),
            "last_used": int(d.last_used),
            "connected": d.id in hub.by_device,
            **({"self": True} if d.id == me else {}),
        }
        for d in store.devices(bridge_id)
    ]


async def _push_devices(app: web.Application, bridge_id: str) -> None:
    hub: Hub = app[KEY_HUB]
    link = hub.bridges.get(bridge_id)
    if link:
        await link.send_json(
            {"type": "devices", "devices": _devices_payload(app[KEY_STORE], bridge_id, hub)}
        )


# --- pairing ------------------------------------------------------------


async def handle_create_pairing(request: web.Request) -> web.Response:
    if _limited(request, "pairing"):
        return _json(429, {"error": "rate_limited"})
    body = await _body(request)
    app_user_id = _text(body, "app_user_id", 128)
    if not app_user_id:
        return _json(400, {"error": "missing_app_user_id"})
    verdict = await request.app[KEY_ENT].check(app_user_id)
    if verdict is Verdict.NOT_PRO:
        return _json(403, {"error": "pro_required"})
    if verdict is Verdict.UNAVAILABLE:
        return _json(503, {"error": "verify_unavailable"})
    try:
        pairing_id, code = request.app[KEY_STORE].create_pairing(
            app_user_id, _text(body, "device_name", 64), _text(body, "platform", 16)
        )
    except PairingError as error:
        return _json(429, {"error": error.reason})
    return _json(201, {"pairing_id": pairing_id, "code": code, "expires_in": PAIRING_SECONDS})


async def handle_redeem(request: web.Request) -> web.Response:
    if _limited(request, "redeem"):
        return _json(429, {"error": "rate_limited"})
    body = await _body(request)
    code = _text(body, "code", 32)
    if not code:
        return _json(400, {"error": "missing_code"})
    try:
        bridge_id, token, device_id = request.app[KEY_STORE].redeem_pairing(
            code,
            _bearer(request) or None,
            name=_text(body, "name", 64),
            kind=_text(body, "kind", 16),
            version=_text(body, "version", 32),
        )
    except PairingError as error:
        status = {"invalid_code": 404, "unknown_bridge": 401}.get(error.reason, 409)
        return _json(status, {"error": error.reason})
    # The device id the app will get: the bridge files the phone's
    # end-to-end key under it (removing the device removes the key).
    answer = {"bridge_id": bridge_id, "device_id": device_id}
    if token:
        answer["bridge_token"] = token
    return _json(200, answer)


async def handle_collect(request: web.Request) -> web.Response:
    if _limited(request, "api"):
        return _json(429, {"error": "rate_limited"})
    body = await _body(request)
    pairing_id = _text(body, "pairing_id", 128)
    store: Store = request.app[KEY_STORE]
    pairing = store.pairing(pairing_id) if pairing_id else None
    if pairing is None:
        return _json(404, {"error": "unknown_pairing"})
    if pairing.bridge_id is None:
        return _json(
            200, {"state": "waiting", "expires_in": max(0, int(pairing.expires_at - store.now()))}
        )
    try:
        device, token = store.collect_pairing(pairing_id)
    except PairingError as error:
        return _json(404, {"error": error.reason})
    bridge = store.bridge(device.bridge_id)
    await _push_devices(request.app, device.bridge_id)
    return _json(
        200,
        {
            "state": "paired",
            "device_id": device.id,
            "app_token": token,
            "bridge": {
                "id": device.bridge_id,
                "name": bridge.name if bridge else "",
                "kind": bridge.kind if bridge else "",
            },
        },
    )


# --- app REST -------------------------------------------------------------


def _device_for(request: web.Request):
    token = _bearer(request)
    return request.app[KEY_STORE].device_by_token(token) if token else None


async def handle_bridge_info(request: web.Request) -> web.Response:
    if _limited(request, "api"):
        return _json(429, {"error": "rate_limited"})
    device = _device_for(request)
    bridge_id = request.match_info["bridge_id"]
    if device is None or device.bridge_id != bridge_id:
        return _json(401, {"error": "unpaired"})
    store: Store = request.app[KEY_STORE]
    hub: Hub = request.app[KEY_HUB]
    bridge = store.bridge(bridge_id)
    if bridge is None:
        return _json(401, {"error": "unpaired"})
    link = hub.bridges.get(bridge_id)
    return _json(
        200,
        {
            "id": bridge.id,
            "name": bridge.name,
            "kind": bridge.kind,
            "version": bridge.version,
            "online": link is not None,
            "last_seen": int(bridge.last_seen),
            "obs": link.obs_state if link else bridge.obs_state,
            "update_required": _outdated(request.app, bridge.version),
            "latest_version": request.app[KEY_LATEST]["version"] or None,
            "update_available": _update_available(request.app, bridge.version),
            "status": bridge.status,
            "status_at": int(bridge.status_at),
            "devices": _devices_payload(store, bridge_id, hub, me=device.id),
        },
    )


async def handle_delete_device(request: web.Request) -> web.Response:
    if _limited(request, "api"):
        return _json(429, {"error": "rate_limited"})
    device = _device_for(request)
    if device is None:
        return _json(401, {"error": "unpaired"})
    target = request.match_info["device_id"]
    if not request.app[KEY_STORE].delete_device(target, device.bridge_id):
        return _json(404, {"error": "unknown_device"})
    request.app[KEY_HUB].end_device(target, protocol.UNPAIRED, "device removed")
    await _push_devices(request.app, device.bridge_id)
    return web.Response(status=204)


async def handle_rename_device(request: web.Request) -> web.Response:
    """Renames any device of the caller's bridge (like removing one) - the
    name the PC's panel lists it under."""
    if _limited(request, "api"):
        return _json(429, {"error": "rate_limited"})
    device = _device_for(request)
    if device is None:
        return _json(401, {"error": "unpaired"})
    name = _text(await _body(request), "name", 64)
    if not name:
        return _json(400, {"error": "missing_name"})
    target = request.match_info["device_id"]
    if not request.app[KEY_STORE].rename_device(target, device.bridge_id, name):
        return _json(404, {"error": "unknown_device"})
    await _push_devices(request.app, device.bridge_id)
    return web.Response(status=204)


async def handle_start_obs(request: web.Request) -> web.Response:
    if _limited(request, "api"):
        return _json(429, {"error": "rate_limited"})
    device = _device_for(request)
    bridge_id = request.match_info["bridge_id"]
    if device is None or device.bridge_id != bridge_id:
        return _json(401, {"error": "unpaired"})
    verdict = await request.app[KEY_ENT].check(device.app_user_id)
    if verdict is not Verdict.PRO:
        return _json(403 if verdict is Verdict.NOT_PRO else 503, {"error": verdict.value})
    link = request.app[KEY_HUB].bridges.get(bridge_id)
    if link is None:
        return _json(409, {"error": "bridge_offline"})
    if link.kind != "standalone":
        return _json(409, {"error": "not_supported"})
    if not await link.send_json({"type": "start_obs", "device": device.id}):
        return _json(409, {"error": "bridge_offline"})
    # Did it work? The bridge reports OBS "running" once it reached OBS's
    # websocket: logged with the time it took, or a line after the watch
    # (also when the bridge said "running" all along: nothing changed).
    asked = time.monotonic()
    hub: Hub = request.app[KEY_HUB]
    hub.start_asked[bridge_id] = asked
    log.info("bridge %s start_obs asked | obs %s", bridge_id[:10], link.obs_state or "?")
    _spawn(_watch_start_obs(request.app, bridge_id, asked))
    return _json(202, {"state": "requested"})


async def _watch_start_obs(app: web.Application, bridge_id: str, asked: float) -> None:
    await asyncio.sleep(app[KEY_START_WATCH])
    hub: Hub = app[KEY_HUB]
    if hub.start_asked.get(bridge_id) != asked:
        return  # OBS came up, or a newer request watches now
    hub.start_asked.pop(bridge_id, None)
    link = hub.bridges.get(bridge_id)
    log.info(
        "bridge %s start_obs: no OBS start seen %.0fs later | obs %s",
        bridge_id[:10],
        time.monotonic() - asked,
        (link.obs_state or "?") if link else "bridge offline",
    )


def _set_obs(app: web.Application, link: BridgeLink, state: str) -> None:
    """The bridge's OBS state: kept for the app, logged when it changed."""
    state = state[:16]
    link.obs_state = state
    app[KEY_STORE].set_obs_state(link.bridge_id, state)
    if state == link.obs_logged:
        return
    previous, link.obs_logged = link.obs_logged, state
    hub: Hub = app[KEY_HUB]
    note = ""
    if state == "running" and link.bridge_id in hub.start_asked:
        note = f" | {time.monotonic() - hub.start_asked.pop(link.bridge_id):.0f}s after start_obs"
    log.info("bridge %s obs %s -> %s%s", link.bridge_id[:10], previous or "?", state, note)


# --- sockets ----------------------------------------------------------------


async def handle_app_socket(request: web.Request) -> web.WebSocketResponse:
    app = request.app
    store: Store = app[KEY_STORE]
    hub: Hub = app[KEY_HUB]
    ws = web.WebSocketResponse(
        protocols=("obswebsocket.json",),
        heartbeat=HEARTBEAT,
        max_msg_size=MAX_APP_FRAME,
    )
    await ws.prepare(request)

    async def refuse(code: int, reason: str) -> web.WebSocketResponse:
        # Phones turned away never get a session line: say why here.
        known = device is not None and device.bridge_id == bridge_id
        log.info("app refused for bridge %s: %d %s", bridge_id[:10] if known else "?", code, reason)
        await ws.close(code=code, message=reason.encode())
        return ws

    device = None
    bridge_id = request.query.get("bridge", "")
    if _limited(request, "app"):
        return await refuse(protocol.RATE_LIMITED, "rate limited")
    device = _device_for(request)
    if device is None or device.bridge_id != bridge_id:
        return await refuse(protocol.UNPAIRED, "unpaired")
    app_user_id = request.headers.get("X-RC-App-User-Id", "").strip()[:128] or device.app_user_id
    verdict = await app[KEY_ENT].check(app_user_id)
    if verdict is Verdict.NOT_PRO:
        return await refuse(protocol.PRO_REQUIRED, "pro required")
    if verdict is Verdict.UNAVAILABLE:
        return await refuse(protocol.VERIFY_UNAVAILABLE, "verify unavailable")
    store.device_used(device.id, app_user_id if app_user_id != device.app_user_id else None)

    link = hub.bridges.get(bridge_id)
    if link is None:
        bridge = store.bridge(bridge_id)
        if bridge is not None and _outdated(app, bridge.version):
            return await refuse(protocol.BRIDGE_OUTDATED, "bridge outdated")
        if bridge is not None:
            hold = app[KEY_GRACE] - (store.now() - bridge.last_seen)
            link = await hub.wait_for_bridge(bridge_id, hold)
        if link is None:
            return await refuse(protocol.BRIDGE_OFFLINE, "bridge offline")
    previous = hub.by_device.get(device.id)
    if previous is not None:
        previous.end(protocol.SESSION_REPLACED, "replaced", drain=False)
        hub.by_device.pop(device.id, None)
        previous.link.sessions.pop(previous.sid, None)
        await previous.link.send_frame(protocol.pack(protocol.CLOSE, previous.sid))
    if len(link.sessions) >= MAX_SESSIONS_PER_BRIDGE:
        return await refuse(protocol.TOO_MANY_SESSIONS, "too many sessions")

    session = AppSession(link.allocate(), device.id, app_user_id, ws, link)
    link.sessions[session.sid] = session
    hub.by_device[device.id] = session
    session.start()
    opened = await link.send_frame(
        protocol.pack(
            protocol.OPEN,
            session.sid,
            json.dumps({"device": device.id, "name": device.name}).encode(),
        )
    )
    async def release() -> None:
        """Still listed = the bridge didn't end it (the phone left, or the
        relay ended it): the bridge must close its OBS connection. Done
        before waiting on the phone's close reply - a phone that stopped
        reading would hold that up for the close timeout."""
        if hub.by_device.get(device.id) is session:
            hub.by_device.pop(device.id, None)
        if link.sessions.get(session.sid) is session:
            link.sessions.pop(session.sid, None)
            await link.send_frame(protocol.pack(protocol.CLOSE, session.sid))

    if not opened:
        session.end(protocol.BRIDGE_GONE, "bridge gone", drain=False)
    try:
        while True:
            receive = asyncio.ensure_future(ws.receive())
            await asyncio.wait(
                {receive, session.close_signal}, return_when=asyncio.FIRST_COMPLETED
            )
            if not receive.done():
                receive.cancel()
                with contextlib.suppress(asyncio.CancelledError):
                    await receive
                code, reason = session.close_signal.result()
                await release()
                await ws.close(code=code, message=reason.encode()[:120])
                break
            message = receive.result()
            if message.type == aiohttp.WSMsgType.BINARY:
                # End-to-end encrypted: forwarded as is, never read here.
                if session.ended_by_relay:
                    continue  # the close follows once the queue drained
                session.bytes_up += len(message.data)
                sent = await link.send_frame(
                    protocol.pack(protocol.DATA, session.sid, message.data)
                )
                if not sent:
                    session.end(protocol.BRIDGE_GONE, "bridge gone", drain=False)
            elif message.type == aiohttp.WSMsgType.TEXT:
                # Plain obs-websocket would be readable here: refused.
                session.end(1003, "end-to-end encryption required", drain=False)
            else:  # CLOSE / CLOSING / CLOSED / ERROR: the phone is gone
                break
    finally:
        await release()
        if session.writer and not session.writer.done():
            session.writer.cancel()
        store.device_used(device.id)
        # Who ended it and how it went: a phone's close code (1001 = its
        # ping timed out, 4998 = its data watchdog, 1006 = the line
        # dropped) or the relay's reason. No content - frame sizes only.
        # The bridge's own OBS state next to its answer: "obs not running"
        # while it reports OBS running means its process check and its
        # OBS connection disagree (a standalone refuses on the first)
        log.info(
            "session %s end after %.0fs: %s | down %d KB, up %d KB, peak queue %d KB"
            " | bridge %s obs %s",
            session.sid,
            time.monotonic() - session.started,
            session.end_reason or f"phone {ws.close_code}",
            session.bytes_down // 1024,
            session.bytes_up // 1024,
            session.peak_queued // 1024,
            link.bridge_id[:10],
            link.obs_state or "?",
        )
    return ws


def _close_payload(payload: bytes) -> tuple[int, str]:
    try:
        data = json.loads(payload) if payload else {}
    except (ValueError, UnicodeDecodeError):
        data = {}
    if not isinstance(data, dict):
        data = {}
    reason = data.get("reason")
    return protocol.forwardable_code(data.get("code", 1000)), (
        reason[:120] if isinstance(reason, str) else ""
    )


async def _bridge_control(app: web.Application, link: BridgeLink, text: str) -> bool:
    """Handles one control message; False closes the bridge socket."""
    store: Store = app[KEY_STORE]
    hub: Hub = app[KEY_HUB]
    try:
        message = json.loads(text)
    except ValueError:
        return True
    if not isinstance(message, dict):
        return True
    kind = message.get("type")
    if kind == "hello":
        name = message.get("name")
        store.bridge_connected(
            link.bridge_id, name if isinstance(name, str) else "", link.kind, link.version
        )
        obs = message.get("obs")
        if isinstance(obs, str):
            _set_obs(app, link, obs)
    elif kind == "obs":
        state = message.get("state")
        if isinstance(state, str):
            _set_obs(app, link, state)
    elif kind == "status":
        now = time.monotonic()
        status = message.get("status")
        if (
            isinstance(status, dict)
            and len(text) <= MAX_STATUS_BYTES
            and now - link.last_status >= STATUS_MIN_INTERVAL
        ):
            link.last_status = now
            store.set_status(link.bridge_id, status)
    elif kind == "bye":
        reason = message.get("reason")
        if reason == "obs_exit":
            _set_obs(app, link, "closed")
    elif kind == "ping":
        # The bridge's keepalive: websocket pings don't make it through the
        # Cloudflare tunnel, so it can only tell a live link by an answer
        # (bridges went "relay silent" every ~77 s, 2026-11-08)
        await link.send_json({"type": "pong"})
    elif kind == "devices":
        await _push_devices(app, link.bridge_id)
    elif kind == "remove_device":
        device_id = message.get("id")
        if isinstance(device_id, str) and store.delete_device(device_id, link.bridge_id):
            hub.end_device(device_id, protocol.UNPAIRED, "device removed")
        await _push_devices(app, link.bridge_id)
    elif kind == "unpair":
        for device_id in store.delete_bridge(link.bridge_id):
            hub.end_device(device_id, protocol.UNPAIRED, "unpaired")
        await link.send_json({"type": "unpaired"})
        await link.ws.close(code=protocol.UNPAIRED, message=b"unpaired")
        return False
    return True


async def handle_bridge_socket(request: web.Request) -> web.StreamResponse:
    app = request.app
    store: Store = app[KEY_STORE]
    hub: Hub = app[KEY_HUB]
    if _limited(request, "bridge"):
        return _json(429, {"error": "rate_limited"})
    token = _bearer(request)
    bridge = store.bridge_by_token(token) if token else None
    if bridge is None:
        return _json(401, {"error": "unpaired"})
    version = request.headers.get("X-Bridge-Version", "").strip()[:32]
    kind = request.headers.get("X-Bridge-Kind", "").strip()[:16]
    if kind not in ("plugin", "standalone"):
        return _json(400, {"error": "bad_kind"})

    ws = web.WebSocketResponse(heartbeat=HEARTBEAT, max_msg_size=MAX_BRIDGE_FRAME)
    await ws.prepare(request)
    store.bridge_connected(bridge.id, "", kind, version)
    if _outdated(app, version):
        await ws.send_str(
            json.dumps({"type": "update_required", "min_version": app[KEY_MIN_VERSION]})
        )
        await ws.close(code=protocol.BRIDGE_OUTDATED, message=b"update required")
        return ws

    previous = hub.bridges.get(bridge.id)
    link = BridgeLink(bridge.id, kind, version, ws, obs_logged=bridge.obs_state)
    hub.bridges[bridge.id] = link
    if previous is not None:
        _drop_link(hub, previous, protocol.BRIDGE_GONE)
        _spawn(previous.ws.close(code=protocol.SESSION_REPLACED, message=b"replaced"))

    await link.send_json(
        {
            "type": "welcome",
            "bridge_id": bridge.id,
            "server_version": SERVER_VERSION,
            "devices": _devices_payload(store, bridge.id, hub),
        }
    )
    if _update_available(app, version):
        await link.send_json({"type": "update_available", "version": app[KEY_LATEST]["version"]})
    # After the welcome: phones held for this bridge open their sessions now
    hub.bridge_ready(link)
    ended = ""
    try:
        async for message in ws:
            if message.type in (aiohttp.WSMsgType.BINARY, aiohttp.WSMsgType.TEXT):
                # Frames only: an ERROR is how a link ends, not traffic
                link.last_frame = time.monotonic()
                link.last_kind = "data" if message.type == aiohttp.WSMsgType.BINARY else _control_kind(message.data)
            if message.type == aiohttp.WSMsgType.BINARY:
                try:
                    frame_kind, sid, payload = protocol.unpack(message.data)
                except protocol.FrameError:
                    continue
                session = link.sessions.get(sid)
                if session is None:
                    continue  # the phone left meanwhile
                if frame_kind == protocol.DATA:
                    session.deliver(payload)
                elif frame_kind == protocol.CLOSE:
                    code, reason = _close_payload(payload)
                    link.sessions.pop(sid, None)
                    session.end(code, reason)
            elif message.type == aiohttp.WSMsgType.TEXT:
                if not await _bridge_control(app, link, message.data):
                    ended = "unpaired"
                    break
            elif message.type == aiohttp.WSMsgType.ERROR:
                # aiohttp's heartbeat timing out lands here too
                break  # named below from ws.exception()
    finally:
        replaced = hub.bridges.get(bridge.id) is not link
        stopping = not replaced and not link.alive  # _stop got here first
        if not replaced:
            hub.bridges.pop(bridge.id, None)
            _drop_link(hub, link, protocol.BRIDGE_GONE)
        if store.bridge(bridge.id) is not None:
            store.bridge_seen(bridge.id)
        # Why bridges reconnect: who ended the link (the bridge's close code,
        # 1006 = the line dropped without one), how long it held and how
        # quiet it was before. No ids beyond the bridge's prefix.
        now = time.monotonic()
        error = ws.exception()
        if not ended:
            ended = (
                "replaced by a newer connection"
                if replaced
                else "relay stopping"
                if stopping
                else f"error {type(error).__name__}"
                if error is not None
                else f"closed {ws.close_code}"
            )
        log.info(
            "bridge %s (%s %s) end after %.0fs: %s | quiet %.0fs after %s, sessions dropped %d",
            bridge.id[:10],
            kind,
            version or "?",
            now - link.started,
            ended,
            now - link.last_frame,
            link.last_kind,
            link.sessions_dropped,
        )
    return ws


def _control_kind(text: str) -> str:
    try:
        kind = json.loads(text).get("type")
    except (ValueError, AttributeError):
        return "text"
    return kind[:16] if isinstance(kind, str) else "text"


def _drop_link(hub: Hub, link: BridgeLink, code: int) -> None:
    link.alive = False
    link.sessions_dropped += len(link.sessions)
    for session in list(link.sessions.values()):
        session.end(code, "bridge gone", drain=False)
    link.sessions.clear()


async def handle_health(request: web.Request) -> web.Response:
    hub: Hub = request.app[KEY_HUB]
    return _json(
        200,
        {"status": "ok", "bridges": len(hub.bridges), "sessions": len(hub.by_device)},
    )


# --- jobs ---------------------------------------------------------------------


async def recheck_pro(app: web.Application) -> None:
    """Long sessions: a lapsed subscription ends on the next check."""
    ent: Entitlements = app[KEY_ENT]
    for session in app[KEY_HUB].sessions():
        verdict = await ent.check(session.app_user_id)
        if verdict is Verdict.NOT_PRO:
            session.end(protocol.PRO_REQUIRED, "pro required", drain=False)
        elif verdict is Verdict.UNAVAILABLE:
            session.end(protocol.VERIFY_UNAVAILABLE, "verify unavailable", drain=False)


async def purge(app: web.Application) -> None:
    hub: Hub = app[KEY_HUB]
    # Pairings that went nowhere: how often a code never reaches a PC
    # (nothing installed / not running) or the app gave up before collecting
    for platform, created_at, redeemed in app[KEY_STORE].expire_pairings():
        log.info(
            "pairing from %s expired: %s (created %s UTC)",
            platform or "?",
            "app never collected it" if redeemed else "no bridge redeemed the code",
            time.strftime("%Y-%m-%d %H:%M", time.gmtime(created_at)),
        )
    for device_id in app[KEY_STORE].purge():
        hub.end_device(device_id, protocol.UNPAIRED, "expired")
    app[KEY_ENT].forget_expired()
    app[KEY_LIMITS].prune()


async def _every(seconds: float, job, app: web.Application, first_delay: float):
    await asyncio.sleep(first_delay)
    while True:
        try:
            await job(app)
        except Exception as error:  # keep the loop alive
            log.warning("%s failed: %s", job.__name__, type(error).__name__)
        await asyncio.sleep(seconds)


async def set_latest_bridge(app: web.Application, version: str) -> None:
    """A new latest bridge release: logged once, and every connected bridge
    behind it hears about it now (the others at their next welcome)."""
    version = release_version(version)
    if not version or version == app[KEY_LATEST]["version"]:
        return
    app[KEY_LATEST]["version"] = version
    told = 0
    for link in list(app[KEY_HUB].bridges.values()):
        if _update_available(app, link.version):
            told += await link.send_json({"type": "update_available", "version": version})
    log.info("latest bridge release %s | %d connected bridge(s) told to update", version, told)


async def check_latest_bridge(app: web.Application, http=None) -> None:
    http = http or app.get(KEY_HTTP)
    if http is None:
        return
    async with http.get(
        app[KEY_LATEST]["url"],
        headers={"Accept": "application/vnd.github+json", "User-Agent": "obs-blade-relay"},
        timeout=aiohttp.ClientTimeout(total=15),
    ) as response:
        if response.status != 200:
            log.warning("latest bridge release: HTTP %d", response.status)
            return
        body = await response.json()
    tag = body.get("tag_name") if isinstance(body, dict) else None
    if not release_version(tag):
        log.warning("latest bridge release: unexpected tag %r", tag)
        return
    await set_latest_bridge(app, tag)


async def _start_jobs(app: web.Application) -> None:
    app[KEY_TASKS] = [
        asyncio.create_task(_every(PRO_RECHECK_SECONDS, recheck_pro, app, PRO_RECHECK_SECONDS)),
        asyncio.create_task(_every(PURGE_SECONDS, purge, app, 60)),
    ]
    if app[KEY_LATEST]["url"]:
        app[KEY_TASKS].append(asyncio.create_task(_every(LATEST_BRIDGE_SECONDS, check_latest_bridge, app, 5)))


async def _stop(app: web.Application) -> None:
    for task in app.get(KEY_TASKS, []):
        task.cancel()
    hub: Hub = app[KEY_HUB]
    for session in hub.sessions():
        session.end(1001, "relay restarting", drain=False)
    for link in list(hub.bridges.values()):
        # Seen just now: the next relay holds phones for these bridges
        # while they reconnect (BRIDGE_GRACE_SECONDS)
        app[KEY_STORE].bridge_seen(link.bridge_id)
        link.alive = False
        await link.ws.close(code=1001, message=b"relay restarting")
    if app.get(KEY_HTTP) is not None:
        await app[KEY_HTTP].close()


def build_app(
    store: Store,
    ent: Entitlements,
    jobs: bool = True,
    min_version: str = MIN_BRIDGE_VERSION,
    bridge_grace: float = BRIDGE_GRACE_SECONDS,
    start_obs_watch: float = START_OBS_WATCH_SECONDS,
    latest_bridge: str = LATEST_BRIDGE_VERSION,
    latest_bridge_url: str | None = None,
) -> web.Application:
    app = web.Application(client_max_size=64 * 1024)
    app[KEY_STORE] = store
    app[KEY_ENT] = ent
    app[KEY_HUB] = Hub()
    app[KEY_LIMITS] = RateLimiter()
    app[KEY_MIN_VERSION] = min_version
    app[KEY_GRACE] = bridge_grace
    app[KEY_START_WATCH] = start_obs_watch
    # A fixed version (env / tests) isn't polled
    fixed = release_version(latest_bridge)
    url = latest_bridge_url if latest_bridge_url is not None else ("" if fixed else LATEST_BRIDGE_URL)
    app[KEY_LATEST] = {"version": fixed, "url": url}
    app.router.add_post("/v1/pairings", handle_create_pairing)
    app.router.add_post("/v1/pairings/redeem", handle_redeem)
    app.router.add_post("/v1/pairings/collect", handle_collect)
    app.router.add_get("/v1/bridges/{bridge_id}", handle_bridge_info)
    app.router.add_post("/v1/bridges/{bridge_id}/start-obs", handle_start_obs)
    app.router.add_delete("/v1/devices/{device_id}", handle_delete_device)
    app.router.add_patch("/v1/devices/{device_id}", handle_rename_device)
    app.router.add_get("/v1/app", handle_app_socket)
    app.router.add_get("/v1/bridge", handle_bridge_socket)
    app.router.add_get("/health", handle_health)
    if jobs:
        app.on_startup.append(_start_jobs)
    app.on_shutdown.append(_stop)
    return app


@web.middleware
async def _access_log(request: web.Request, handler):
    response = await handler(request)
    log.info("%s %s %s", request.method, request.path, response.status)
    return response


def main() -> None:
    project = os.environ.get("RC_PROJECT_ID", "")
    key = os.environ.get("RC_API_KEY", "")
    if not project or not key:
        raise SystemExit("RC_PROJECT_ID and RC_API_KEY are required")
    allow = {x.strip() for x in os.environ.get("RELAY_PRO_ALLOW", "").split(",") if x.strip()}
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    async def init() -> web.Application:
        http = aiohttp.ClientSession()
        ent = Entitlements(
            entitlement.aiohttp_transport(http, key),
            project,
            os.environ.get("RC_PRO_ENTITLEMENT_ID", ""),
            allow,
        )
        app = build_app(Store(DB_PATH), ent)
        log.info("relay %s starting", SERVER_VERSION)
        app[KEY_HTTP] = http
        app.middlewares.append(_access_log)
        return app

    web.run_app(init(), host=LISTEN_HOST, port=LISTEN_PORT, access_log=None, print=None)


if __name__ == "__main__":
    main()
