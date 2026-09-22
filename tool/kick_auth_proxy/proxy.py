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

import json
import os
import subprocess
import tempfile
import time
from collections import defaultdict, deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

KICK_TOKEN_URL = "https://id.kick.com/oauth/token"
ALLOWED_REDIRECT = os.environ.get(
    "KICK_OAUTH_REDIRECT_URI", "https://localhost/kick-callback"
)
LISTEN_HOST = os.environ.get("KICK_AUTH_LISTEN", "127.0.0.1")
LISTEN_PORT = int(os.environ.get("KICK_AUTH_PORT", "8422"))
MAX_BODY = 8192
WINDOW_SECONDS = 600
MAX_PER_WINDOW = 20

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
    from urllib.parse import quote

    return quote(value, safe="")


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

        def do_GET(self):
            if self.path.split("?", 1)[0] != "/health":
                self._json(404, "not_found")
                return
            self._json(200, "ok")

        def do_POST(self):
            if self.path.split("?", 1)[0] != "/oauth/token":
                self._json(404, "not_found")
                return
            if not _allow(self._client_ip()):
                self._json(429, "rate_limited")
                return
            length = int(self.headers.get("Content-Length", "0") or "0")
            if length <= 0 or length > MAX_BODY:
                self._json(400, "invalid_request")
                return
            raw = self.rfile.read(length)
            parsed = parse_qs(raw.decode("utf-8", "replace"), keep_blank_values=False)
            form = {key: values[0] for key, values in parsed.items() if values}
            try:
                upstream = build_upstream(form)
                status, payload = forward(upstream)
            except ProxyError as error:
                self._json(error.status, error.message)
                return
            except Exception:
                self._json(502, "upstream_failed")
                return
            content_type = "application/json"
            self._send(status, payload, content_type)

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
