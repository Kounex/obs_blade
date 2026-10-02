"""Kick API calls the relay makes, all through curl.

Kick's Cloudflare accepts curl's TLS fingerprint (see kick_auth_proxy).
Tokens and the client secret go into files in a private temp dir, never
into argv, so they don't show up in the process list.
"""

from __future__ import annotations

import asyncio
import json
import os
import tempfile
import time
from dataclasses import dataclass
from typing import Awaitable, Callable
from urllib.parse import urlencode

API = "https://api.kick.com"
TOKEN_URL = "https://id.kick.com/oauth/token"

# Every event the feed uses. Chat stays on Pusher (load + the 1,000-channel
# cap for unverified apps).
EVENTS: list[tuple[str, int]] = [
    ("channel.followed", 1),
    ("channel.subscription.new", 1),
    ("channel.subscription.renewal", 1),
    ("channel.subscription.gifts", 1),
    ("kicks.gifted", 1),
    ("channel.reward.redemption.updated", 1),
    ("livestream.status.updated", 1),
]


class KickError(Exception):
    def __init__(self, status: int, message: str = ""):
        super().__init__(f"{status} {message}".strip())
        self.status = status


@dataclass
class Response:
    status: int
    body: bytes

    def json(self):
        try:
            return json.loads(self.body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            return None


# (method, url, headers, body) -> Response
Transport = Callable[[str, str, dict[str, str], bytes | None], Awaitable[Response]]


async def curl_transport(
    method: str, url: str, headers: dict[str, str], body: bytes | None
) -> Response:
    with tempfile.TemporaryDirectory(prefix="kick-events-") as directory:
        header_path = os.path.join(directory, "headers")
        out_path = os.path.join(directory, "out")
        with open(header_path, "w", encoding="utf-8") as handle:
            for key, value in headers.items():
                handle.write(f"{key}: {value}\n")
        args = [
            "curl",
            "-sS",
            "-m",
            "20",
            "-o",
            out_path,
            "-w",
            "%{http_code}",
            "-X",
            method,
            "-H",
            f"@{header_path}",
            url,
        ]
        if body is not None:
            body_path = os.path.join(directory, "body")
            with open(body_path, "wb") as handle:
                handle.write(body)
            args += ["--data-binary", f"@{body_path}"]
        process = await asyncio.create_subprocess_exec(
            *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL,
        )
        stdout, _ = await process.communicate()
        status_text = stdout.decode().strip()
        if not status_text.isdigit() or status_text == "000":
            raise KickError(502, "upstream_unreachable")
        payload = b""
        if os.path.exists(out_path):
            with open(out_path, "rb") as handle:
                payload = handle.read(1 << 20)
        return Response(int(status_text), payload)


class KickApi:
    def __init__(
        self,
        client_id: str,
        client_secret: str,
        transport: Transport = curl_transport,
        clock: Callable[[], float] = time.time,
    ):
        self._client_id = client_id
        self._client_secret = client_secret
        self._transport = transport
        self._clock = clock
        self._app_token: str | None = None
        self._app_token_expires = 0.0
        self._token_lock = asyncio.Lock()

    async def user_for_token(self, access_token: str) -> tuple[int, str]:
        """(user_id, name) of the token's own user. KickError otherwise."""
        response = await self._transport(
            "GET",
            f"{API}/public/v1/users",
            {"Authorization": f"Bearer {access_token}", "Accept": "application/json"},
            None,
        )
        if response.status != 200:
            raise KickError(response.status, "user_lookup_failed")
        data = (response.json() or {}).get("data") or []
        if not data or not isinstance(data[0], dict):
            raise KickError(502, "user_lookup_empty")
        user_id = data[0].get("user_id")
        if not isinstance(user_id, int):
            raise KickError(502, "user_lookup_empty")
        return user_id, str(data[0].get("name") or "")

    async def _token(self, force: bool = False) -> str:
        async with self._token_lock:
            if (
                not force
                and self._app_token
                and self._clock() < self._app_token_expires - 300
            ):
                return self._app_token
            form = urlencode(
                {
                    "grant_type": "client_credentials",
                    "client_id": self._client_id,
                    "client_secret": self._client_secret,
                }
            ).encode()
            response = await self._transport(
                "POST",
                TOKEN_URL,
                {
                    "Content-Type": "application/x-www-form-urlencoded",
                    "Accept": "application/json",
                },
                form,
            )
            payload = response.json() or {}
            token = payload.get("access_token")
            if response.status != 200 or not token:
                raise KickError(response.status, "app_token_failed")
            try:
                lifetime = float(payload.get("expires_in") or 3600)
            except (TypeError, ValueError):
                lifetime = 3600.0
            self._app_token = str(token)
            self._app_token_expires = self._clock() + lifetime
            return self._app_token

    async def _app_call(
        self, method: str, url: str, body: dict | None = None
    ) -> Response:
        """App-token call; one retry with a fresh token on 401."""
        for attempt in range(2):
            token = await self._token(force=attempt == 1)
            headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}
            raw = None
            if body is not None:
                headers["Content-Type"] = "application/json"
                raw = json.dumps(body).encode()
            response = await self._transport(method, url, headers, raw)
            if response.status != 401:
                return response
        return response

    async def list_subscriptions(
        self, broadcaster_user_id: int | None = None
    ) -> list[dict]:
        url = f"{API}/public/v1/events/subscriptions"
        if broadcaster_user_id is not None:
            url += f"?broadcaster_user_id={broadcaster_user_id}"
        response = await self._app_call("GET", url)
        if response.status != 200:
            raise KickError(response.status, "list_subscriptions_failed")
        data = (response.json() or {}).get("data") or []
        return [item for item in data if isinstance(item, dict)]

    async def subscribe(
        self, broadcaster_user_id: int, events: list[tuple[str, int]]
    ) -> dict[str, tuple[str, int]]:
        """Create subscriptions; returns event -> (subscription id, version)
        for the ones Kick accepted."""
        response = await self._app_call(
            "POST",
            f"{API}/public/v1/events/subscriptions",
            {
                "broadcaster_user_id": broadcaster_user_id,
                "method": "webhook",
                "events": [
                    {"name": name, "version": version} for name, version in events
                ],
            },
        )
        if response.status != 200:
            raise KickError(response.status, "subscribe_failed")
        created: dict[str, tuple[str, int]] = {}
        for item in (response.json() or {}).get("data") or []:
            if not isinstance(item, dict) or item.get("error"):
                continue
            sub_id = item.get("subscription_id")
            name = item.get("name")
            if sub_id and name:
                created[str(name)] = (str(sub_id), int(item.get("version") or 1))
        return created

    async def unsubscribe(self, subscription_ids: list[str]) -> None:
        if not subscription_ids:
            return
        query = "&".join(f"id={sub_id}" for sub_id in subscription_ids)
        response = await self._app_call(
            "DELETE", f"{API}/public/v1/events/subscriptions?{query}"
        )
        if response.status not in (200, 204, 404):
            raise KickError(response.status, "unsubscribe_failed")

    async def fetch_public_key(self) -> bytes | None:
        response = await self._transport(
            "GET", f"{API}/public/v1/public-key", {"Accept": "application/json"}, None
        )
        if response.status != 200:
            return None
        data = (response.json() or {}).get("data") or {}
        key = data.get("public_key") if isinstance(data, dict) else None
        return key.encode() if isinstance(key, str) and "PUBLIC KEY" in key else None


async def ensure_subscriptions(
    api: KickApi, broadcaster_user_id: int
) -> dict[str, tuple[str, int]]:
    """Every event in EVENTS subscribed for the channel; returns the full
    event -> (id, version) map Kick has afterwards."""
    existing: dict[str, tuple[str, int]] = {}
    for item in await api.list_subscriptions(broadcaster_user_id):
        if item.get("broadcaster_user_id") != broadcaster_user_id:
            continue
        name = item.get("event")
        if name and item.get("id"):
            existing[str(name)] = (str(item["id"]), int(item.get("version") or 1))
    missing = [(name, version) for name, version in EVENTS if name not in existing]
    if missing:
        existing.update(await api.subscribe(broadcaster_user_id, missing))
    return existing
