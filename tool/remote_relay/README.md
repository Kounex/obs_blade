# Remote relay

Connects a paired phone to the bridge next to OBS (the OBS Blade Remote
plugin or the standalone app) from anywhere, Pro only. Design:
`docs/superpowers/specs/2026-11-07-remote-relay-design.md`. This README is
the protocol contract for the bridge core (`desktop/core`) and the app;
`protocol.py` holds the frame format and close codes.

Public at `https://relay.obs-blade.com` (Cloudflare tunnel `vps`, no
Access policy: the tokens below are the auth).

## Pairing

| Step | Who | Call | Answer |
|---|---|---|---|
| 1 | app (on the LAN, Pro) | `POST /v1/pairings` `{"app_user_id", "device_name", "platform"}` | `201 {"pairing_id", "code", "expires_in": 120}`; `403 pro_required`, `503 verify_unavailable` |
| 2 | app → bridge, through OBS | plugin: `CallVendorRequest` vendor `obs-blade-bridge`, request `Pair`, `{"code", "app_key"}`; standalone: `BroadcastCustomEvent` `{"obs-blade-pair": {"code", "app_key"}}` (`app_key`: the phone's X25519 public key for this pairing, base64) | - |
| 3 | bridge | `POST /v1/pairings/redeem` `{"code", "name", "kind", "version"}`, `Authorization: Bearer <bridge token>` if already paired | `200 {"bridge_id", "device_id", "bridge_token"?}` (token only for a new bridge, store it; `device_id` is what the app will get - file the app key under it); `404 invalid_code` (unknown, used or expired), `401 unknown_bridge`, `409 too_many_devices` |
| 3b | bridge → app, through OBS | `BroadcastCustomEvent` `{"obs-blade-pair-ack": {"code", "bridge_key"}}` after a successful redeem, again for every repeat of the code | - |
| 4 | app, every ~2 s | `POST /v1/pairings/collect` `{"pairing_id"}` | `200 {"state": "waiting", "expires_in"}`, then once `200 {"state": "paired", "device_id", "app_token", "bridge": {"id", "name", "kind"}}`; `404 unknown_pairing` (expired, or already collected) |

Step 2 is fire-and-forget (a CustomEvent reaches only bridges connected to
OBS at that moment, e.g. not one that is still starting): the app sends it
right away and again every 2 s until it has both step 4's `paired` and
step 3b's ack; the bridge answers a repeat of a code it already redeemed
with the ack again. **The keys travel only through OBS** (steps 2 and
3b), never through the relay, so the relay can't substitute one: it
can't read or alter session traffic (end-to-end encryption, below).

The code is 8 characters from `23456789ABCDEFGHJKMNPQRSTUVWXYZ`; case,
spaces and dashes are ignored. A code is single use and lives 2 minutes;
a redeemed pairing waits 10 minutes to be collected. The `pairing_id` is a
secret (it yields the app token): POST body only, never in a URL.

## App

- `GET /v1/app?bridge=<bridge_id>` - websocket, `Authorization: Bearer
  <app_token>`, optional `X-RC-App-User-Id: <current RevenueCat app user
  id>` (the Pro check uses it and remembers it). Subprotocol
  `obswebsocket.json` is offered. After the upgrade the phone sends the
  end-to-end handshake (below) as its first binary frame; then it **is**
  an obs-websocket session inside it: OBS's Hello (without
  `authentication`, the bridge authenticates locally), Identify and
  everything else as usual. **Binary frames only**; a text frame closes
  the session with 1003 (it would be readable by the relay).

### End-to-end encryption

`Noise_IK_25519_ChaChaPoly_SHA256`, prologue `obs-blade-remote/1`. The
phone is the initiator: static key = its pairing's app key, remote static
= the bridge key from the pairing ack. Message 1 (phone → bridge, empty
payload), message 2 (bridge → phone, empty payload), then every frame is
one transport message (≤ 65535 bytes). An obs-websocket message is split
into chunks of at most 65518 bytes, each sent as plaintext `[fin u8]
[chunk]` (`fin` 1 on the last chunk). The relay forwards these frames
untouched and can't read them; it still sees who connects to which
bridge, when, sizes and timing, close codes and the bridge's status
snapshot (control messages). Implementations: `desktop/core/src/e2e.rs`,
`lib/utils/remote/noise_ik.dart`.
- Close codes (besides OBS's own 4000-4012, which pass through):

  | Code | Meaning | App shows |
  |---|---|---|
  | 4900 | bridge offline | "<PC> is offline", last seen from `GET /v1/bridges/{id}` |
  | 4901 | OBS not running | "OBS isn't running on <PC>" (+ Start OBS on a standalone) |
  | 4902 | OBS unreachable (websocket server off / refused the bridge) | "Turn on the WebSocket server in OBS" |
  | 4903 | Pro required | the paywall reason |
  | 4904 | unpaired (token revoked, device removed) | set up remote access again |
  | 4905 | bridge outdated | "Update OBS Blade Remote on <PC>" |
  | 4906 | replaced by a newer connection of this device | nothing (the newer one is live) |
  | 4907 | too many sessions on this bridge (4) | try again |
  | 4908 | bridge dropped mid-session | reconnect |
  | 4909 | Pro couldn't be verified right now | try again later |
  | 4910 | rate limited | try again later |
  | 4911 | end-to-end handshake failed (sent by the bridge, or set by the app when the bridge's key didn't verify) | "Couldn't verify <PC>" - set up again |
  | 1013 | the phone didn't read fast enough | reconnect |

- `GET /v1/bridges/{bridge_id}` (Bearer app token) → `{"id", "name",
  "kind", "version", "online", "last_seen", "obs", "update_required",
  "status", "status_at", "devices": [{"id", "name", "platform",
  "created_at", "last_used", "connected", "self"?}]}`.
- `POST /v1/bridges/{bridge_id}/start-obs` (Bearer app token) → `202`;
  `409 bridge_offline` / `409 not_supported` (plugin bridges die with OBS).
- `DELETE /v1/devices/{device_id}` (Bearer app token; any device of the
  same bridge, incl. itself) → `204`.

## Bridge

`GET /v1/bridge` - websocket, `Authorization: Bearer <bridge_token>`,
`X-Bridge-Version: <semver>`, `X-Bridge-Kind: plugin|standalone`.
`401` for an unknown token: the bridge was unpaired, drop the token.

- Binary frames `[type u8][session u32 BE][payload]`:
  - `1 OPEN` relay → bridge, payload `{"device", "name"}`: open a local
    websocket to OBS for this session, answer OBS's auth yourself, send
    OBS's Hello on **without** `authentication` and add yours to the
    phone's Identify. OBS not running → `CLOSE {"code": 4901}`; server off
    or auth refused → `CLOSE {"code": 4902}`.
  - `2 DATA` both ways: one end-to-end encrypted frame, exactly as the
    phone sent / gets it as a binary frame. The bridge decrypts, talks
    plain obs-websocket to OBS (the preview screenshot rewrite happens
    there) and encrypts the answers. A phone whose static key isn't one
    of the bridge's paired keys → `CLOSE {"code": 4904}`; a handshake or
    frame that doesn't decrypt → `CLOSE {"code": 4911}`.
  - `3 CLOSE` relay → bridge: the phone left (empty payload). Bridge →
    relay: `{"code", "reason"}`; codes 4000-4099, 4901, 4902, 4904, 4911,
    1000, 1001, 1003, 1007-1009, 1011 are forwarded, anything else
    becomes 1011.
- Text frames, JSON:
  - relay → bridge: `welcome {"bridge_id", "server_version", "devices"}`,
    `devices {"devices"}` (after a pairing or removal),
    `start_obs {"device"}` (standalone), `update_required {"min_version"}`
    (then close 4905), `unpaired` (then close 4904).
  - bridge → relay: `hello {"name", "obs"}` right after connecting,
    `obs {"state"}` on change (`running`, `closed`, `crashed`, `ws_off`,
    `auth_failed`), `status {"status": {...}}` every 20 s (≤ 8 KB, at most
    every 5 s), `bye {"reason": "obs_exit"}` before a clean OBS exit
    (plugin), `devices` (ask for the list), `remove_device {"id"}`,
    `unpair` (forget this bridge entirely).
- A second connection with the same token replaces the first (close
  4906 to the old one; its sessions get 4908).

## Limits

Sessions per bridge 4, devices per bridge 10, open pairings per app user
5, frames 16 MB from the bridge / 4 MB from the phone, 24 MB queued per
phone. Per IP: 10 pairings per 10 min, 20 redeems/min, 60 app and 30
bridge connects/min, 120 REST calls/min. Pro: checked at pairing, at
every app connect and every 30 min per session (cached 10 min); while
RevenueCat is unreachable, users who passed within 24 h keep access.

## Run, test, deploy

```bash
podman build -f Containerfile --target test .   # the suite (docker build works too)
```

Image: `ghcr.io/kounex/remote-relay:<semver>`, built by GitHub Actions
(`.github/workflows/image-remote-relay.yml`, test stage first) on every
push touching this folder. Host: the Hetzner VPS (it-env
`docs/machines/hetzner-vps.md`). Install `remote-relay.container` as a
quadlet; `/etc/remote-relay.env` (root, 0600) holds `RC_PROJECT_ID`,
`RC_API_KEY` (RevenueCat v2 secret key with read access to customer
information and project configuration), optionally
`RC_PRO_ENTITLEMENT_ID`, `RELAY_PRO_ALLOW`, `RELAY_MIN_BRIDGE_VERSION`;
data in `/var/lib/remote-relay` owned by uid 65532.
