"""Pro check against RevenueCat's REST API v2.

``GET /v2/projects/{project}/customers/{id}/active_entitlements`` with a v2
secret key (permissions: customer_information:customers:read, plus
project_configuration:entitlements:read unless RC_PRO_ENTITLEMENT_ID is
set). v2, not v1: v1 ``GET /subscribers/{id}`` creates a customer for any
unknown id. Items carry the entitlement's RevenueCat id, not its lookup
key, so the ``pro`` lookup key is resolved to an id once.
Docs: https://www.revenuecat.com/docs/api-v2 (read 2026-11-07).
"""

from __future__ import annotations

import enum
import logging
import time
import urllib.parse
from dataclasses import dataclass
from typing import Awaitable, Callable

import aiohttp

log = logging.getLogger("remote-relay.entitlement")

API = "https://api.revenuecat.com/v2"
PRO_LOOKUP_KEY = "pro"
POSITIVE_TTL = 600
NEGATIVE_TTL = 60
# RevenueCat unreachable: a user whose last check passed this recently
# keeps access (a RevenueCat incident must not cut every stream).
GRACE_SECONDS = 24 * 3600


@dataclass
class Response:
    status: int
    json: object


Transport = Callable[[str, dict], Awaitable[Response]]


class Verdict(enum.Enum):
    PRO = "pro"
    NOT_PRO = "not_pro"
    UNAVAILABLE = "unavailable"


class Entitlements:
    def __init__(
        self,
        transport: Transport,
        project_id: str,
        entitlement_id: str = "",
        allow: set[str] | None = None,
        clock=time.time,
    ):
        self._get = transport
        self._project = project_id
        self._entitlement_id = entitlement_id
        self._allow = allow or set()
        self._now = clock
        self._cache: dict[str, tuple[Verdict, float]] = {}
        self._last_pro: dict[str, float] = {}

    async def check(self, app_user_id: str, fresh: bool = False) -> Verdict:
        if not app_user_id:
            return Verdict.NOT_PRO
        if app_user_id in self._allow:
            return Verdict.PRO
        now = self._now()
        cached = self._cache.get(app_user_id)
        if cached and not fresh and now < cached[1]:
            return cached[0]
        verdict = await self._ask(app_user_id)
        if verdict is Verdict.PRO:
            self._last_pro[app_user_id] = now
            self._cache[app_user_id] = (verdict, now + POSITIVE_TTL)
        elif verdict is Verdict.NOT_PRO:
            self._last_pro.pop(app_user_id, None)
            self._cache[app_user_id] = (verdict, now + NEGATIVE_TTL)
        else:
            last = self._last_pro.get(app_user_id)
            if last is not None and now - last < GRACE_SECONDS:
                return Verdict.PRO
        return verdict

    def forget_expired(self) -> None:
        now = self._now()
        self._cache = {k: v for k, v in self._cache.items() if v[1] > now}
        self._last_pro = {
            k: v for k, v in self._last_pro.items() if now - v < GRACE_SECONDS
        }

    async def _pro_id(self) -> str | None:
        if self._entitlement_id:
            return self._entitlement_id
        try:
            response = await self._get(
                f"{API}/projects/{self._project}/entitlements?limit=100", {}
            )
        except Exception as error:
            log.warning("entitlement lookup failed: %s", type(error).__name__)
            return None
        if response.status != 200 or not isinstance(response.json, dict):
            log.warning("entitlement lookup answered %s", response.status)
            return None
        for item in response.json.get("items") or []:
            if isinstance(item, dict) and item.get("lookup_key") == PRO_LOOKUP_KEY:
                self._entitlement_id = str(item.get("id") or "")
                return self._entitlement_id or None
        log.error("no entitlement with lookup key %r in project", PRO_LOOKUP_KEY)
        return None

    async def _ask(self, app_user_id: str) -> Verdict:
        pro_id = await self._pro_id()
        if pro_id is None:
            return Verdict.UNAVAILABLE
        customer = urllib.parse.quote(app_user_id, safe="")
        try:
            response = await self._get(
                f"{API}/projects/{self._project}/customers/{customer}"
                "/active_entitlements?limit=100",
                {},
            )
        except Exception as error:
            log.warning("entitlement check failed: %s", type(error).__name__)
            return Verdict.UNAVAILABLE
        if response.status == 404:
            return Verdict.NOT_PRO
        if response.status != 200 or not isinstance(response.json, dict):
            if response.status in (401, 403):
                log.error("RevenueCat refused the key (%s)", response.status)
            else:
                log.warning("entitlement check answered %s", response.status)
            return Verdict.UNAVAILABLE
        now_ms = self._now() * 1000
        for item in response.json.get("items") or []:
            if not isinstance(item, dict) or item.get("entitlement_id") != pro_id:
                continue
            expires = item.get("expires_at")
            if expires is None or (isinstance(expires, (int, float)) and expires > now_ms):
                return Verdict.PRO
        return Verdict.NOT_PRO


def aiohttp_transport(session, api_key: str) -> Transport:
    async def get(url: str, headers: dict) -> Response:
        async with session.get(
            url,
            headers={"Authorization": f"Bearer {api_key}", **headers},
            timeout=aiohttp.ClientTimeout(total=10),
        ) as response:
            try:
                body = await response.json(content_type=None)
            except ValueError:
                body = None
            return Response(response.status, body)

    return get
