#!/usr/bin/env python3
"""Kick events relay for the OBS Blade activity feed.

Kick only delivers follows, KICKs, subs and stream status as webhooks to
one URL per app. This service is that URL: it verifies each delivery,
keeps it for 7 days for channels whose owner signed in from the app,
and hands it to the app over a WebSocket (live) or a plain GET
(catch-up). The phone proves which channel it owns with its Kick token
once; the relay never stores that token.

Nothing is logged except method, path and status. Payloads, tokens and
the client secret never go to stdout.

See docs/superpowers/specs/2026-10-02-activity-feed-design.md.
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import time
from collections import defaultdict, deque
from datetime import datetime, timezone

from aiohttp import WSMsgType, web

import kick as kick_api
import signature
from store import Store

LISTEN_HOST = os.environ.get("KICK_EVENTS_LISTEN", "127.0.0.1")
LISTEN_PORT = int(os.environ.get("KICK_EVENTS_PORT", "8423"))
DB_PATH = os.environ.get("KICK_EVENTS_DB", "/var/lib/kick-events/relay.db")
CLIENT_ID = os.environ.get("KICK_OAUTH_CLIENT_ID", "").strip()
CLIENT_SECRET = os.environ.get("KICK_OAUTH_CLIENT_SECRET", "").strip()

MAX_WEBHOOK_BODY = 64 * 1024
MAX_SESSION_BODY = 8 * 1024
# Signed deliveries older than this are acknowledged but not kept (a
# replay of a real, old message must not re-enter the feed).
MAX_DELIVERY_AGE_SECONDS = 24 * 3600
MAX_SOCKETS_PER_CHANNEL = 5
RATE_WINDOW_SECONDS = 600
RATE_MAX_SESSIONS = 20
RATE_MAX_READS = 600
RECONCILE_SECONDS = 15 * 60
PURGE_SECONDS = 3600
KEY_REFRESH_SECONDS = 6 * 3600

KEY_STORE = web.AppKey("store", Store)
KEY_API = web.AppKey("api", kick_api.KickApi)
KEY_HUB = web.AppKey("hub", object)
KEY_KEYS = web.AppKey("keys", list)
KEY_LIMITS = web.AppKey("limits", object)
KEY_TASKS = web.AppKey("tasks", list)

log = logging.getLogger("kick-events")


class RateLimiter:
    def __init__(self):
        self._hits: dict[str, deque[float]] = defaultdict(deque)

    def allow(self, key: str, limit: int, now: float | None = None) -> bool:
        moment = time.monotonic() if now is None else now
        bucket = self._hits[key]
        while bucket and moment - bucket[0] > RATE_WINDOW_SECONDS:
            bucket.popleft()
        if len(bucket) >= limit:
            return False
        bucket.append(moment)
        return True


class Hub:
    """Open app sockets per channel."""

    def __init__(self):
        self._queues: dict[int, list[asyncio.Queue]] = defaultdict(list)

    def join(self, user_id: int) -> asyncio.Queue:
        queue: asyncio.Queue = asyncio.Queue(maxsize=1000)
        queues = self._queues[user_id]
        queues.append(queue)
        while len(queues) > MAX_SOCKETS_PER_CHANNEL:
            # Oldest socket goes; it sees None and closes.
            oldest = queues.pop(0)
            oldest.put_nowait(None)
        return queue

    def leave(self, user_id: int, queue: asyncio.Queue) -> None:
        queues = self._queues.get(user_id)
        if not queues:
            return
        if queue in queues:
            queues.remove(queue)
        if not queues:
            self._queues.pop(user_id, None)

    def publish(self, user_id: int, wire: dict) -> None:
        for queue in list(self._queues.get(user_id, [])):
            try:
                queue.put_nowait(wire)
            except asyncio.QueueFull:
                # A stuck client: drop it, the app catches up via ?after=.
                self.leave(user_id, queue)
                try:
                    queue.get_nowait()
                except asyncio.QueueEmpty:
                    pass
                queue.put_nowait(None)

    def close_channel(self, user_id: int) -> None:
        for queue in self._queues.pop(user_id, []):
            try:
                queue.put_nowait(None)
            except asyncio.QueueFull:
                pass

    def count(self) -> int:
        return sum(len(queues) for queues in self._queues.values())


def _client_ip(request: web.Request) -> str:
    forwarded = request.headers.get("CF-Connecting-IP", "").strip()
    return forwarded or (request.remote or "")


def _json(status: int, payload: dict) -> web.Response:
    return web.json_response(
        payload, status=status, headers={"Cache-Control": "no-store"}
    )


def _bearer(request: web.Request) -> str:
    header = request.headers.get("Authorization", "")
    if header.startswith("Bearer "):
        return header[7:].strip()
    return ""


def _parse_time(text: str) -> datetime | None:
    try:
        moment = datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError:
        return None
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=timezone.utc)
    return moment


def _session_user(request: web.Request) -> int | None:
    return request.app[KEY_STORE].session_user(_bearer(request))


# Webhook


async def handle_webhook(request: web.Request) -> web.Response:
    headers = request.headers
    message_id = headers.get("Kick-Event-Message-Id", "")
    timestamp = headers.get("Kick-Event-Message-Timestamp", "")
    signature_b64 = headers.get("Kick-Event-Signature", "")
    event_type = headers.get("Kick-Event-Type", "")
    version = headers.get("Kick-Event-Version", "")
    if not (message_id and timestamp and signature_b64 and event_type):
        return _json(400, {"error": "missing_headers"})
    if len(message_id) > 64 or len(event_type) > 64 or len(version) > 8:
        return _json(400, {"error": "invalid_headers"})
    if request.content_length is not None and request.content_length > MAX_WEBHOOK_BODY:
        return _json(413, {"error": "too_large"})
    body = await request.content.read(MAX_WEBHOOK_BODY + 1)
    if len(body) > MAX_WEBHOOK_BODY:
        return _json(413, {"error": "too_large"})

    keys = request.app[KEY_KEYS]
    if not any(
        signature.verify(key, message_id, timestamp, body, signature_b64)
        for key in keys
    ):
        return _json(403, {"error": "bad_signature"})

    sent_at = _parse_time(timestamp)
    if sent_at is not None:
        age = (datetime.now(timezone.utc) - sent_at).total_seconds()
        if age > MAX_DELIVERY_AGE_SECONDS:
            return _json(200, {"status": "stale"})

    try:
        payload = json.loads(body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return _json(200, {"status": "unreadable"})
    if not isinstance(payload, dict):
        return _json(200, {"status": "unreadable"})
    broadcaster = payload.get("broadcaster")
    user_id = broadcaster.get("user_id") if isinstance(broadcaster, dict) else None
    if not isinstance(user_id, int):
        return _json(200, {"status": "no_broadcaster"})

    store: Store = request.app[KEY_STORE]
    if not store.is_registered(user_id):
        # Leftover subscription; the reconcile job removes it.
        return _json(200, {"status": "unregistered"})
    stored = store.add_event(
        message_id, user_id, event_type, version or "1", timestamp, payload
    )
    if stored is not None:
        request.app[KEY_HUB].publish(user_id, {"type": "event", **stored.to_wire()})
    return _json(200, {"status": "ok"})


# App API


async def handle_create_session(request: web.Request) -> web.Response:
    limits: RateLimiter = request.app[KEY_LIMITS]
    if not limits.allow(f"session:{_client_ip(request)}", RATE_MAX_SESSIONS):
        return _json(429, {"error": "rate_limited"})
    if request.content_length is None or request.content_length > MAX_SESSION_BODY:
        return _json(400, {"error": "invalid_request"})
    try:
        body = await request.json()
    except (json.JSONDecodeError, UnicodeDecodeError):
        return _json(400, {"error": "invalid_request"})
    token = body.get("access_token") if isinstance(body, dict) else None
    if not isinstance(token, str) or not token or len(token) > 4096:
        return _json(400, {"error": "invalid_request"})

    api: kick_api.KickApi = request.app[KEY_API]
    try:
        user_id, username = await api.user_for_token(token)
    except kick_api.KickError as error:
        status = 401 if error.status in (401, 403) else 502
        return _json(status, {"error": "kick_rejected_token" if status == 401 else "kick_unreachable"})

    store: Store = request.app[KEY_STORE]
    session = store.create_session(user_id, username)
    subscribed = await _ensure(request.app, user_id)
    return _json(
        200,
        {
            "session_token": session,
            "broadcaster_user_id": user_id,
            "username": username,
            "subscribed": subscribed,
            "latest_seq": store.latest_seq(user_id),
        },
    )


async def handle_delete_session(request: web.Request) -> web.Response:
    token = _bearer(request)
    store: Store = request.app[KEY_STORE]
    if not store.session_user(token):
        return _json(401, {"error": "unknown_session"})
    last_for = store.delete_session(token)
    if last_for is not None:
        await _forget(request.app, last_for)
    return _json(200, {"status": "ok"})


async def handle_events(request: web.Request) -> web.Response:
    limits: RateLimiter = request.app[KEY_LIMITS]
    if not limits.allow(f"read:{_client_ip(request)}", RATE_MAX_READS):
        return _json(429, {"error": "rate_limited"})
    user_id = _session_user(request)
    if user_id is None:
        return _json(401, {"error": "unknown_session"})
    try:
        after = max(0, int(request.query.get("after", "0")))
        limit = min(500, max(1, int(request.query.get("limit", "200"))))
    except ValueError:
        return _json(400, {"error": "invalid_request"})
    store: Store = request.app[KEY_STORE]
    events = store.events_after(user_id, after, limit)
    return _json(
        200,
        {
            "events": [event.to_wire() for event in events],
            "latest_seq": store.latest_seq(user_id),
            "subscribed": bool(store.subscriptions_of(user_id)),
        },
    )


async def handle_stream(request: web.Request) -> web.StreamResponse:
    limits: RateLimiter = request.app[KEY_LIMITS]
    if not limits.allow(f"read:{_client_ip(request)}", RATE_MAX_READS):
        return _json(429, {"error": "rate_limited"})
    user_id = _session_user(request)
    if user_id is None:
        return _json(401, {"error": "unknown_session"})
    try:
        after = max(0, int(request.query.get("after", "0")))
    except ValueError:
        return _json(400, {"error": "invalid_request"})

    socket = web.WebSocketResponse(heartbeat=25, max_msg_size=4096)
    await socket.prepare(request)
    hub: Hub = request.app[KEY_HUB]
    store: Store = request.app[KEY_STORE]
    # Join first, then send the backlog: anything that lands in between
    # sits in the queue and is skipped by seq if the backlog had it.
    queue = hub.join(user_id)
    sent = after
    reader: asyncio.Future | None = None
    getter: asyncio.Future | None = None
    try:
        await socket.send_json(
            {
                "type": "hello",
                "broadcaster_user_id": user_id,
                "latest_seq": store.latest_seq(user_id),
                "subscribed": bool(store.subscriptions_of(user_id)),
            }
        )
        while True:
            backlog = store.events_after(user_id, sent, 500)
            for event in backlog:
                await socket.send_json({"type": "event", **event.to_wire()})
                sent = event.seq
            if len(backlog) < 500:
                break
        await socket.send_json({"type": "synced", "seq": sent})

        reader = asyncio.ensure_future(socket.receive())
        while True:
            getter = asyncio.ensure_future(queue.get())
            done, _ = await asyncio.wait(
                {reader, getter}, return_when=asyncio.FIRST_COMPLETED
            )
            if reader in done:
                message = reader.result()
                if message.type in (WSMsgType.CLOSE, WSMsgType.CLOSED, WSMsgType.ERROR, WSMsgType.CLOSING):
                    break
                # The app never needs to talk; ignore anything it sends.
                reader = asyncio.ensure_future(socket.receive())
                if getter not in done:
                    getter.cancel()
                    continue
            # Both may finish in one wait() - the dequeued item must still go out.
            wire = getter.result()
            if wire is None:
                break
            if wire.get("seq", 0) <= sent:
                continue
            await socket.send_json(wire)
            sent = wire["seq"]
    except (ConnectionResetError, asyncio.CancelledError):
        pass
    finally:
        for future in (reader, getter):
            if future is not None and not future.done():
                future.cancel()
        hub.leave(user_id, queue)
        if not socket.closed:
            await socket.close()
    return socket


async def handle_health(request: web.Request) -> web.Response:
    return _json(200, {"status": "ok"})


# Subscriptions + housekeeping


async def _ensure(app: web.Application, user_id: int) -> bool:
    try:
        subscriptions = await kick_api.ensure_subscriptions(app[KEY_API], user_id)
    except kick_api.KickError as error:
        log.warning("subscribe %s failed: %s", user_id, error.status)
        return False
    app[KEY_STORE].replace_subscriptions(user_id, subscriptions)
    return len(subscriptions) >= len(kick_api.EVENTS)


async def _forget(app: web.Application, user_id: int) -> None:
    store: Store = app[KEY_STORE]
    ids = list(store.subscriptions_of(user_id).values())
    try:
        # Kick's own list is the truth; ours may be stale.
        for item in await app[KEY_API].list_subscriptions(user_id):
            if item.get("broadcaster_user_id") == user_id and item.get("id"):
                ids.append(str(item["id"]))
        await app[KEY_API].unsubscribe(sorted(set(ids)))
    except kick_api.KickError as error:
        log.warning("unsubscribe %s failed: %s", user_id, error.status)
    store.forget_broadcaster(user_id)
    app[KEY_HUB].close_channel(user_id)


async def reconcile(app: web.Application) -> None:
    """Re-create missing subscriptions (Kick drops them after a day of
    failures) and remove ones for channels nobody uses any more."""
    store: Store = app[KEY_STORE]
    registered = set(store.registered_broadcasters())
    for user_id in registered:
        await _ensure(app, user_id)
    try:
        orphans = [
            str(item["id"])
            for item in await app[KEY_API].list_subscriptions()
            if item.get("id") and item.get("broadcaster_user_id") not in registered
        ]
        await app[KEY_API].unsubscribe(orphans)
    except kick_api.KickError as error:
        log.warning("orphan cleanup failed: %s", error.status)


async def purge(app: web.Application) -> None:
    for user_id in app[KEY_STORE].purge():
        await _forget(app, user_id)


async def refresh_keys(app: web.Application) -> None:
    pem = await app[KEY_API].fetch_public_key()
    if pem is None:
        return
    try:
        key = signature.load_public_key(pem)
    except ValueError:
        return
    app[KEY_KEYS][:] = [key]


async def _every(seconds: float, job, app: web.Application, first_delay: float):
    await asyncio.sleep(first_delay)
    while True:
        try:
            await job(app)
        except Exception as error:  # keep the loop alive
            log.warning("%s failed: %s", job.__name__, type(error).__name__)
        await asyncio.sleep(seconds)


async def _start_jobs(app: web.Application) -> None:
    app[KEY_TASKS] = [
        asyncio.create_task(_every(KEY_REFRESH_SECONDS, refresh_keys, app, 0)),
        asyncio.create_task(_every(RECONCILE_SECONDS, reconcile, app, 30)),
        asyncio.create_task(_every(PURGE_SECONDS, purge, app, 60)),
    ]


async def _stop_jobs(app: web.Application) -> None:
    for task in app.get(KEY_TASKS, []):
        task.cancel()
    app[KEY_STORE].close()


def build_app(
    store: Store,
    api: kick_api.KickApi,
    keys: list | None = None,
    jobs: bool = True,
) -> web.Application:
    app = web.Application(client_max_size=MAX_WEBHOOK_BODY)
    app[KEY_STORE] = store
    app[KEY_API] = api
    app[KEY_HUB] = Hub()
    app[KEY_LIMITS] = RateLimiter()
    app[KEY_KEYS] = (
        keys
        if keys is not None
        else [signature.load_public_key(signature.KICK_PUBLIC_KEY_PEM)]
    )
    app.router.add_post("/kick/webhook", handle_webhook)
    app.router.add_post("/v1/session", handle_create_session)
    app.router.add_delete("/v1/session", handle_delete_session)
    app.router.add_get("/v1/events", handle_events)
    app.router.add_get("/v1/stream", handle_stream)
    app.router.add_get("/health", handle_health)
    if jobs:
        app.on_startup.append(_start_jobs)
        app.on_cleanup.append(_stop_jobs)
    return app


@web.middleware
async def _access_log(request: web.Request, handler):
    response = await handler(request)
    log.info("%s %s %s", request.method, request.path, response.status)
    return response


def main() -> None:
    if not CLIENT_ID or not CLIENT_SECRET:
        raise SystemExit("KICK_OAUTH_CLIENT_ID and KICK_OAUTH_CLIENT_SECRET are required")
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    app = build_app(Store(DB_PATH), kick_api.KickApi(CLIENT_ID, CLIENT_SECRET))
    app.middlewares.append(_access_log)
    web.run_app(app, host=LISTEN_HOST, port=LISTEN_PORT, access_log=None, print=None)


if __name__ == "__main__":
    main()
