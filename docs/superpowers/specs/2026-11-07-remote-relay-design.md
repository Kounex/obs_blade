# Remote relay: reach OBS from anywhere (Pro)

2026-11-07. Supersedes the "headless Flutter desktop build" bridge in
`docs/private/backend-architecture.md` § Relay/bridge: the bridge now ships
as an **OBS plugin** (default: "just start OBS") **and** a **standalone
tray app**, from one codebase. Everything else in that doc (opaque tokens,
no Access policy on the public hostname, entitlement re-checks, no OBS
password over the internet) still holds.

Decided with the user (2026-11-07):

| Question | Answer |
|---|---|
| Platforms, v1 | Windows, macOS **and** Linux, plugin and standalone |
| Standalone vs plugin | The standalone also watches OBS: tells the phone "OBS closed / crashed" vs "PC offline", and starts OBS on request |
| Pairing | In the app, while on the same network as OBS. No desktop UI needed; the desktop's QR code is the fallback |
| v1 scope | Remote control (incl. a lighter preview). Status snapshots are collected, push alerts come next |

## Journeys

1. **IRL streamer, plugin.** Streams from a backpack PC or leaves the home
   PC running; phone on mobile data. Installed the plugin once, paired at
   home on Wi-Fi. Opens OBS Blade on 5G → the saved connection can't reach
   the LAN IP → connects through the relay, dashboard as usual.
2. **Home streamer who leaves the room.** Same as 1 but rarely uses the
   relay: the app always tries the LAN first, so the relay only carries
   the moments away from Wi-Fi.
3. **Standalone user, OBS not running.** Opens the app away from home →
   relay → bridge answers "OBS isn't running on GAMING-PC" → taps
   **Start OBS** → the standalone launches OBS, connects, the dashboard
   loads. After a crash the app says "OBS closed unexpectedly" instead.
4. **PC asleep / offline.** No bridge connected → the app says the PC is
   offline (last seen time), not "wrong password" or a spinner.
5. **Subscription lapses.** Next connect (or the periodic re-check during
   a long session) refuses with a Pro reason; the app shows the paywall
   reason instead of a generic connection error. LAN use is unaffected.
6. **Second phone / iPad.** Pairs the same way on the LAN; the bridge
   keeps both. Desktop settings and the app list paired devices and can
   remove one.
7. **Both plugin and standalone installed.** The standalone sees the
   plugin's vendor in OBS and leaves the relay to it (keeps watching OBS
   so journey 3 still works when OBS is closed).

## Facts (verified, sources noted)

- obs-websocket stores its server settings, incl. the password, in
  `<OBS config>/plugin_config/obs-websocket/config.json`
  (`src/Config.cpp`, `GetModuleConfigPath`; migrated out of
  `global.ini` in 5.x). Config roots: Windows `%APPDATA%\obs-studio`,
  macOS `~/Library/Application Support/obs-studio`, Linux
  `~/.config/obs-studio`, Flatpak
  `~/.var/app/com.obsproject.Studio/config/obs-studio`.
  → the bridge needs no password entry. The plugin and the standalone
  both read it.
- Plugin API (`lib/obs-websocket-api.h`): `obs_websocket_call_request`
  (since 2022-05) and `obs_websocket_register_event_callback` (commit
  `ee283c7`, first in **obs-websocket 5.5.0**, OBS 30.2). Vendor
  requests (`obs_websocket_register_vendor`, only from
  `obs_module_post_load`) are callable by any client via
  `CallVendorRequest`.
- High-volume events (`InputVolumeMeters` etc.) are only produced while a
  websocket client subscribed to them (`EventHandler` hooks on
  subscription changes); plugin event callbacks don't subscribe.
  → this is why the bridge **does not** use the C API for sessions (see
  design), only for pairing (vendor request).
- The app already connects to `wss://` hosts (`NetworkHelper.websocketUri`)
  and sends Identify without `authentication` when Hello has none
  (`authentication_helper.dart`), i.e. a relay session looks like a
  password-less OBS to it.
- RevenueCat: every Pro buyer is in RevenueCat (`docs/revenuecat-setup.md`
  § legacy products). Server check: REST v2
  `GET /v2/projects/{project_id}/customers/{id}/active_entitlements`, v2
  secret key with `customer_information:customers:read`, 480 req/min,
  `expires_at` null = no expiry, `entitlement_id` is the RC id (resolve
  the `pro` lookup key once). v1 `GET /subscribers/{id}` **creates** a
  customer for unknown ids - don't use it. To verify with a live call
  before building on it: v2 accepts the app user id as `customer_id`, and
  its answer for an unknown id.
- Traffic estimates and the scaling table: the 2026-11-06 session
  (as-is ~2 Mbit/s per user, tuned ~0.24 Mbit/s; the preview dominates).

## Design

```
phone ──wss──► relay.obs-blade.com (VPS, Quadlet) ◄──wss── bridge (plugin | standalone) ──ws──► OBS :4455
```

### Bridge (one core, two shells)

- **Core** (Rust, static library with a C ABI; `desktop/core/`):
  - one outbound wss connection to the relay (`/v1/bridge`, bridge token),
    reconnect with backoff, version handshake (the relay can say "update
    required");
  - per remote app session, its **own local websocket to OBS** on
    `127.0.0.1:<port from config.json>`. It answers OBS's Hello/auth
    itself, forwards Hello to the app **without** `authentication`, and
    injects its auth into the app's Identify. Everything else is passed
    through, so subscriptions, batches and meters behave exactly like
    OBS (the app's existing protocol code and the fakes stay valid);
  - **lighter preview:** rewrites `GetSourceScreenshot` /
    `GetCurrentProgramScene` screenshots to `imageWidth ≤ 640`,
    `imageCompressionQuality ~50` on relay sessions (OBS does the
    scaling, no image code in the bridge). Binary frames: later;
  - status snapshot every 20 s while connected to the relay, with or
    without a phone (streaming / recording, bitrate, dropped frames,
    disk free, OBS state). The relay keeps the last one; alerts later;
  - pairing: redeem a one-time code at the relay, store the bridge token
    in the OS keychain (fallback: a 0600 file next to the settings);
  - a C ABI for the shells: start/stop, state callbacks, paired devices
    list / remove, settings.
  - Rust over C++ because this is the network-facing part (TLS via
    rustls, no OpenSSL to bundle on three OSes), and it has no libobs
    dependency (it talks websocket like any client).
- **Plugin** (`desktop/plugin/`, C++, obs-plugintemplate CMake/CI):
  thin. Starts the core on `obs_module_post_load`, registers vendor
  `obs-blade-bridge` with `Pair` / `Status`, stops the core on
  `OBS_FRONTEND_EVENT_EXIT` (sends "clean shutdown" so the relay can tell
  it apart from a crash). Settings panel under **Tools → OBS Blade
  Remote**. Minimum OBS 30.2.
- **Standalone** (`desktop/standalone/`, C++/Qt6, tray icon, autostart):
  same core, plus an **OBS watcher**: finds OBS (process + config dir),
  tells the relay running / closed / crashed (OBS's run sentinel in the
  config dir is left behind on a crash - verify the exact path in the
  OBS source before relying on it), and starts OBS on a relay request.
  If `CallVendorRequest obs-blade-bridge Status` answers, the plugin owns
  the relay link and the standalone only watches.
- **Shared UI** (`desktop/ui/`, Qt6 Widgets): one settings widget used by
  both shells - remote access on/off, relay state, paired devices (remove),
  fallback QR code, preview quality. The plugin builds it against OBS's
  Qt, the standalone bundles Qt.
- If obs-websocket is disabled, the bridge says so in its panel and in its
  status (the app shows "turn on the WebSocket server in OBS").

### Pairing (no desktop UI)

1. Pro app, connected to OBS on the LAN, **Remote access → Set up**.
2. App → relay `POST /v1/pairings` (RevenueCat app user id; relay checks
   Pro) → single-use code, 2 min.
3. App → OBS: plugin: `CallVendorRequest obs-blade-bridge Pair {code}`;
   standalone: `BroadcastCustomEvent {obs-blade-pair: code}`. Only the
   code passes through OBS, never a token.
4. Bridge redeems the code at the relay → bridge id + bridge token (once,
   stored) and names itself (PC name). App polls the pairing → gets an
   app token for this bridge + the bridge name.
5. The app stores the relay pairing on the saved connection. From then
   on: LAN first, relay when the LAN doesn't answer within the connect
   timeout (and a manual "Connect via relay").
- No bridge redeems within 2 min → the app explains: install the plugin /
  standalone, OBS Blade Remote enabled. Fallback: scan the desktop's QR
  (same code flow, reversed).

### Relay (`tool/remote_relay/`, VPS)

- Python 3 + aiohttp, like the Kick relays (shared ops: Quadlet,
  `CPUQuota`/`MemoryMax`, SQLite, health endpoint, fleet board). Fine
  for years at the estimated numbers; revisit (Go) past ~1,000 concurrent.
- Hostname `relay.obs-blade.com` on the `vps` tunnel, no Access policy
  (obs-blade.com: no Bot Fight Mode).
- Endpoints: `POST /v1/pairings`, `POST /v1/pairings/{code}/redeem`
  (bridge), `GET /v1/pairings/{id}` (app polls), `GET /v1/bridge` (ws),
  `GET /v1/app?bridge=` (ws, `Authorization: Bearer`), `DELETE
  /v1/devices/{id}`, `/health`.
- One bridge socket carries all of its app sessions: binary envelope
  `[type u8][session u32][payload]`; the payload is the untouched OBS
  frame, forwarded to the app as a text frame. Session open / close /
  "bridge gone" / "OBS not running" are control types.
- Tokens: opaque, stored hashed (SHA-256), revocable. Pro: checked when
  pairing and on every app connect, cached 10 min, re-checked every 30
  min during a session; a lapse closes the app socket with a Pro close
  reason. RevenueCat down → allow sessions whose last check passed
  within 24 h.
- Limits: per app token 1 session per bridge; per bridge 4 sessions;
  frame size cap; per-IP connect rate.
- Status: last snapshot + last-seen per bridge, in memory and SQLite.

### App

- Saved connection gains an optional relay pairing (bridge id, app token,
  bridge name), Hive model change → new field, default null, per
  `docs/persistence-risk.md`.
- Connect: LAN first; on failure with a pairing → relay (and the
  dashboard shows a small "via relay" marker). Close reasons map to clear
  copy: PC offline (last seen), OBS not running (+ Start OBS when the
  bridge is the standalone), WebSocket server off, Pro lapsed, update the
  bridge.
- Pro-gated; hidden in the FOSS build (`kFoss`).
- Preview loop unchanged (the bridge shrinks the frames).

## Build order

1. Relay server + tests (fakes for bridge and app), deployed to the VPS.
2. Core + standalone on Linux (dev on the NAS is not allowed for heavy
   builds - MacBook), end-to-end with `tool/obs_local` OBS.
3. App: pairing + relay connect + states; widget shots.
4. Plugin shell (plugin template CI builds Win/mac/Linux).
5. Shared Qt UI, standalone tray + watcher on all three OSes.
6. Packaging + signing: macOS Developer ID + notarization (.pkg for the
   plugin, .dmg for the standalone), Windows installer + Azure Trusted
   Signing, Linux: .deb/.tar for the plugin, Flatpak extension later,
   standalone AppImage.

## Left out of v1 (and why)

- Push alerts (next, on the same status snapshots).
- Binary preview frames / own encoder (needs an app protocol change; the
  rewrite above gets most of the saving).
- Studio view-only seats / request filtering (component #6).
- Plugin auto-update (OBS has no plugin updater; the relay's
  "update required" + a link covers it).

## Open

- Cloudflare's terms on JPEG previews through the tunnel at scale: fine at
  the tuned rates for now; a direct TLS port on the VPS is the escape
  hatch (user's call, from the 2026-11-06 session).
- Windows signing account (Azure Trusted Signing needs a business
  identity check).
