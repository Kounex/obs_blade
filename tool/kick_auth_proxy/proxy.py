#!/usr/bin/env python3
"""Kick OAuth token exchange.

The phone never sees the client secret. This process accepts one POST,
adds the secret, and forwards the form to Kick with curl (Kick's
Cloudflare blocks Python's TLS fingerprint). It binds to localhost; the
only public door is a Cloudflare tunnel to that port.

Nothing here is logged except status codes. Request bodies and the
secret never go to stdout.
"""

from __future__ import annotations

import hmac
import json
import os
import subprocess
import tempfile
import threading
import time
from collections import defaultdict, deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, quote

KICK_TOKEN_URL = "https://id.kick.com/oauth/token"
ALLOWED_REDIRECT = os.environ.get(
    "KICK_OAUTH_REDIRECT_URI", "https://kick-auth.kounex.com/oauth/callback"
)
LISTEN_HOST = os.environ.get("KICK_AUTH_LISTEN", "127.0.0.1")
LISTEN_PORT = int(os.environ.get("KICK_AUTH_PORT", "8422"))
MAX_BODY = 8192
WINDOW_SECONDS = 600
MAX_PER_WINDOW = 90
SESSION_TTL = 300

_sessions: dict[str, dict] = {}
_sessions_lock = threading.Lock()

_DONE_PAGE = """<!doctype html>
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>OBS Blade</title>
<body style="margin:0;min-height:100vh;display:grid;place-items:center;background:#111;color:#eee;font-family:system-ui">
<p style="padding:24px;text-align:center">Signed in. Return to OBS Blade.</p>
"""
_ERROR_PAGE = """<!doctype html>
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>OBS Blade</title>
<body style="margin:0;min-height:100vh;display:grid;place-items:center;background:#111;color:#eee;font-family:system-ui">
<p style="padding:24px;text-align:center">Kick did not approve the login. Return to OBS Blade and try again.</p>
"""

CLIENT_ID = os.environ.get("KICK_OAUTH_CLIENT_ID", "").strip()
CLIENT_SECRET = os.environ.get("KICK_OAUTH_CLIENT_SECRET", "").strip()

_hits: dict[str, deque[float]] = defaultdict(deque)


class ProxyError(Exception):
    def __init__(self, status: int, message: str):
        super().__init__(message)
        self.status = status
        self.message = message


def _allow(ip: str, now: float | None = None) -> bool:
    moment = time.monotonic() if now is None else now
    bucket = _hits[ip]
    while bucket and moment - bucket[0] > WINDOW_SECONDS:
        bucket.popleft()
    if len(bucket) >= MAX_PER_WINDOW:
        return False
    bucket.append(moment)
    return True


def build_upstream(form: dict[str, str]) -> dict[str, str]:
    """Return the form Kick should see, or raise ProxyError."""
    if not CLIENT_ID or not CLIENT_SECRET:
        raise ProxyError(500, "not_configured")
    grant = form.get("grant_type", "")
    if grant == "authorization_code":
        code = form.get("code", "")
        verifier = form.get("code_verifier", "")
        redirect = form.get("redirect_uri", "")
        if not code or not verifier:
            raise ProxyError(400, "invalid_request")
        if redirect != ALLOWED_REDIRECT:
            raise ProxyError(400, "invalid_redirect")
        if len(code) > 512 or len(verifier) > 256:
            raise ProxyError(400, "invalid_request")
        return {
            "grant_type": "authorization_code",
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "code": code,
            "redirect_uri": ALLOWED_REDIRECT,
            "code_verifier": verifier,
        }
    if grant == "refresh_token":
        refresh = form.get("refresh_token", "")
        if not refresh or len(refresh) > 4096:
            raise ProxyError(400, "invalid_request")
        return {
            "grant_type": "refresh_token",
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "refresh_token": refresh,
        }
    raise ProxyError(400, "unsupported_grant_type")


def forward_with_curl(form: dict[str, str]) -> tuple[int, bytes]:
    """POST [form] to Kick. The secret is on curl's stdin, not its argv."""
    body = "&".join(
        f"{key}={_urlencode(value)}" for key, value in form.items()
    ).encode()
    with tempfile.TemporaryDirectory(prefix="kick-auth-") as directory:
        out_path = os.path.join(directory, "body")
        completed = subprocess.run(
            [
                "curl",
                "-sS",
                "-m",
                "20",
                "-o",
                out_path,
                "-w",
                "%{http_code}",
                "-X",
                "POST",
                KICK_TOKEN_URL,
                "-H",
                "Accept: application/json",
                "-H",
                "Content-Type: application/x-www-form-urlencoded",
                "--data-binary",
                "@-",
            ],
            input=body,
            capture_output=True,
            check=False,
        )
        status_text = completed.stdout.decode().strip()
        if not status_text.isdigit():
            raise ProxyError(502, "upstream_failed")
        with open(out_path, "rb") as handle:
            payload = handle.read(65536)
        return int(status_text), payload


def _urlencode(value: str) -> str:
    return quote(value, safe="")


def _same(left: str, right: str) -> bool:
    if len(left) != len(right):
        return False
    return hmac.compare_digest(left, right)


def _purge(now: float) -> None:
    stale = [
        key
        for key, session in _sessions.items()
        if now - session["created"] > SESSION_TTL
    ]
    for key in stale:
        del _sessions[key]


def register_session(
    state: str, verifier: str, poll_token: str, now: float | None = None
) -> None:
    if (
        not state
        or not verifier
        or not poll_token
        or len(state) > 256
        or len(verifier) > 256
        or len(poll_token) > 256
    ):
        raise ProxyError(400, "invalid_request")
    moment = time.time() if now is None else now
    with _sessions_lock:
        _purge(moment)
        if state in _sessions:
            raise ProxyError(409, "state_exists")
        _sessions[state] = {
            "verifier": verifier,
            "poll_token": poll_token,
            "created": moment,
            "done": None,
        }


def accept_callback(query: dict[str, str], forward, now: float | None = None) -> bool:
    """Exchange the browser redirect. True when the state was known."""
    state = query.get("state", "")
    moment = time.time() if now is None else now
    with _sessions_lock:
        _purge(moment)
        session = _sessions.get(state)
        if session is None or session["done"] is not None:
            return False
        verifier = session["verifier"]
        poll_token = session["poll_token"]
    if query.get("error"):
        done = (400, json.dumps({"error": "access_denied"}).encode())
    else:
        code = query.get("code", "")
        if not code:
            return False
        status, payload = forward(
            build_upstream(
                {
                    "grant_type": "authorization_code",
                    "code": code,
                    "code_verifier": verifier,
                    "redirect_uri": ALLOWED_REDIRECT,
                }
            )
        )
        if status == 200:
            done = (200, payload)
        else:
            done = (400, json.dumps({"error": "exchange_failed"}).encode())
    with _sessions_lock:
        current = _sessions.get(state)
        if current is None or not _same(current["poll_token"], poll_token):
            return False
        current["done"] = done
        current["verifier"] = ""
    return True


def take_result(state: str, poll_token: str, now: float | None = None):
    """(status, body) once, or None while the browser has not returned."""
    moment = time.time() if now is None else now
    with _sessions_lock:
        _purge(moment)
        session = _sessions.get(state)
        if session is None or not _same(session["poll_token"], poll_token):
            raise ProxyError(404, "not_found")
        if session["done"] is None:
            return None
        status, payload = session["done"]
        del _sessions[state]
        return status, payload


def make_handler(forward):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def log_message(self, fmt, *args):
            # Status line only. BaseHTTPRequestHandler would include the path,
            # which is fine, but never the body. Keep this to method + status.
            return

        def _send(self, status: int, payload: bytes, content_type: str) -> None:
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(payload)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(payload)

        def _json(self, status: int, message: str) -> None:
            self._send(
                status,
                json.dumps({"error": message}).encode(),
                "application/json",
            )

        def _client_ip(self) -> str:
            forwarded = self.headers.get("CF-Connecting-IP", "").strip()
            if forwarded:
                return forwarded
            return self.client_address[0]

        def _read_json(self) -> dict:
            length = int(self.headers.get("Content-Length", "0") or "0")
            if length <= 0 or length > MAX_BODY:
                raise ProxyError(400, "invalid_request")
            raw = self.rfile.read(length)
            try:
                parsed = json.loads(raw.decode("utf-8"))
            except json.JSONDecodeError as error:
                raise ProxyError(400, "invalid_request") from error
            if not isinstance(parsed, dict):
                raise ProxyError(400, "invalid_request")
            return {str(key): str(value) for key, value in parsed.items()}

        def _query(self) -> dict[str, str]:
            path, _, query = self.path.partition("?")
            parsed = parse_qs(query, keep_blank_values=False)
            return {key: values[0] for key, values in parsed.items() if values} | {
                "_path": path
            }

        def do_GET(self):
            path = self.path.split("?", 1)[0]
            if path == "/health":
                self._json(200, "ok")
                return
            if path == "/oauth/done":
                self._send(200, _DONE_PAGE.encode(), "text/html; charset=utf-8")
                return
            if path != "/oauth/callback":
                self._json(404, "not_found")
                return
            if not _allow(self._client_ip()):
                self._send(429, _ERROR_PAGE.encode(), "text/html; charset=utf-8")
                return
            query = self._query()
            try:
                known = accept_callback(query, forward)
            except ProxyError:
                known = False
            except Exception:
                known = False
            if not known:
                self._send(400, _ERROR_PAGE.encode(), "text/html; charset=utf-8")
                return
            self.send_response(302)
            self.send_header("Location", "/oauth/done")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", "0")
            self.end_headers()

        def do_POST(self):
            path = self.path.split("?", 1)[0]
            if path not in ("/oauth/token", "/oauth/session", "/oauth/session/result"):
                self._json(404, "not_found")
                return
            if not _allow(self._client_ip()):
                self._json(429, "rate_limited")
                return
            try:
                if path == "/oauth/token":
                    length = int(self.headers.get("Content-Length", "0") or "0")
                    if length <= 0 or length > MAX_BODY:
                        raise ProxyError(400, "invalid_request")
                    raw = self.rfile.read(length)
                    parsed = parse_qs(
                        raw.decode("utf-8", "replace"), keep_blank_values=False
                    )
                    form = {key: values[0] for key, values in parsed.items() if values}
                    upstream = build_upstream(form)
                    status, payload = forward(upstream)
                    self._send(status, payload, "application/json")
                    return
                body = self._read_json()
                if path == "/oauth/session":
                    register_session(
                        body.get("state", ""),
                        body.get("code_verifier", ""),
                        body.get("poll_token", ""),
                    )
                    self._send(204, b"", "application/json")
                    return
                result = take_result(body.get("state", ""), body.get("poll_token", ""))
                if result is None:
                    self._json(202, "pending")
                    return
                status, payload = result
                self._send(status, payload, "application/json")
            except ProxyError as error:
                self._json(error.status, error.message)
            except Exception:
                self._json(502, "upstream_failed")

    return Handler


def main() -> None:
    if not CLIENT_ID or not CLIENT_SECRET:
        raise SystemExit("KICK_OAUTH_CLIENT_ID and KICK_OAUTH_CLIENT_SECRET are required")
    server = ThreadingHTTPServer(
        (LISTEN_HOST, LISTEN_PORT), make_handler(forward_with_curl)
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
