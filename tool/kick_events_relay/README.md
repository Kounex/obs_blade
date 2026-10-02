# Kick events relay

Receives Kick's webhooks (follows, KICKs, subs, gifted subs, channel
point redemptions, stream status) for channels whose owner signed in to
Kick in OBS Blade, keeps them 7 days, and hands them to the app.
Design: `docs/superpowers/specs/2026-10-02-activity-feed-design.md`.

| Endpoint | Who | What |
|---|---|---|
| `POST /kick/webhook` | Kick | Signature-checked delivery (the app's webhook URL) |
| `POST /v1/session` | app | `{"access_token"}` → the token's Kick user is the channel; subscribes it; returns a session token |
| `GET /v1/events?after=&limit=` | app | Stored events after a cursor |
| `GET /v1/stream?after=` | app | WebSocket: `hello`, backlog, `synced`, then live `event`s |
| `DELETE /v1/session` | app | Sign out; the last session unsubscribes and deletes the channel's data |
| `GET /health` | fleet board | `{"status": "ok"}` |

The user's Kick token is used once to look up who they are and is never
stored. Kick calls go through curl (Kick's Cloudflare), secrets via
files in a private temp dir, never argv.

Diagnosing rejected webhooks: set `KICK_EVENTS_DEBUG_DIR` (a directory
writable by uid 65531) in the quadlet; the first 10 rejected deliveries
are kept there as received. Remove it again afterwards - they contain
chat payloads.

Run the tests (needs aiohttp + cryptography, so in the image):

```bash
podman build --target test .
```

Deploy (maintainer host details: `it-env` `docs/machines/hetzner.md`):
build `localhost/kick-events:latest`, install `kick-events.container`
as a quadlet, data volume `/var/lib/kick-events` owned by uid 65531.
