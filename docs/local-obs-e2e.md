# Local OBS ↔ simulator E2E loop (macOS)

How to run the app on the iOS simulator against a **real local OBS** over
OBS WebSocket v5 — the loop for verifying connection, handshake, and dashboard
behavior end to end. Requires a macOS machine with OBS installed; headless
clones (no GUI) should only run `pub get` / `analyze` / unit tests.

## Prerequisites

- OBS Studio at `/Applications/OBS.app` with the WebSocket server **enabled**
  (Tools → WebSocket Server Settings), port **4455**, and a password of your
  choice (config:
  `~/Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json`).
- An OBS profile with some real scenes/sources (text, image, media, capture
  devices) so dashboard tests exercise actual state — not an empty profile.
- A booted iOS simulator (pick its id via `flutter devices`). The simulator
  shares the host network → OBS is reachable as `127.0.0.1:4455`.

## The loop

```bash
# 1. Launch OBS (no-op if the WS port is already up) and wait for the port
tool/obs_local/obs_test_env.sh start

# 2. Automated gate: handshake + basic requests against real OBS
dart run tool/obs_local/ws_smoke.dart --password <obs-ws-password>

# 3. Run the app on the booted simulator (id from `flutter devices`)
flutter run -d <sim-id>

# 4. In the app: connect manually — host 127.0.0.1, port 4455,
#    password <obs-ws-password> → dashboard should list scenes and inputs.

# 5. When done: stop OBS (only stops instances the script started)
tool/obs_local/obs_test_env.sh stop
```

`obs_test_env.sh status` shows OBS process / port / script-ownership at any
time.

### What to exercise in the app

- Scene switching — dashboard follows the program scene.
- Scene-item visibility toggles; input volume / mute sliders.
- Stats batch (CPU/FPS/bytes charts) ticking at 1 s.
- Kill OBS while connected → app should detect the lost socket and run its
  reconnect flow; restart OBS and confirm recovery.

### Testing auth on vs off

The app sends `authentication` in Identify **only when Hello challenges**
(conditional-Identify hardening). Cover both paths:

1. Auth off (`auth_required: false` in the OBS WS config): smoke + app connect.
2. Auth on: OBS → Tools → WebSocket Server Settings → enable authentication
   (or flip `auth_required` in the config while OBS is closed), then re-run
   the smoke (needs `--password <obs-ws-password>`) and connect in the app.
3. Restore your preferred setting afterwards.

Also try a **wrong password** once: expect close code 4009
(AuthenticationFailed — current obs-websocket 5.x numbering, matching the
app's `WebSocketCloseCode` enum) in the smoke and a real error message in the
app (`ConnectionAttemptResult`), not a generic failure.

## Resource notes

- Reuse an already-booted simulator; don't boot extra devices.
- `start` minimizes the OBS window after launch (best-effort AppleScript) to
  cut preview rendering; capture sources are still active while OBS runs —
  that's the cost of testing against real scenes.
- Always `stop` (or quit OBS) when the session ends; don't leave it running.
- The script never restarts or kills an OBS instance it didn't start — if the
  port is already up, it reuses the running instance and `stop` is a no-op.

## Troubleshooting

| Symptom | Check |
|---|---|
| `start` times out waiting for the port | OBS may be showing a dialog (first run, crash recovery) — open it and dismiss; WebSocket server disabled in settings |
| "OBS is running but port 4455 is not open" | Tools → WebSocket Server Settings → Enable |
| Port 4455 taken by something else | `lsof -iTCP:4455 -sTCP:LISTEN` (e.g. DroidCam) |
| Smoke fails with close 4009 | Wrong/missing password, or auth toggled mid-session |
| App can't connect from simulator | Use `127.0.0.1` (not the LAN IP); grant Local Network permission if iOS asks |
| App on a **physical device** crashes instantly at launch (SIGSEGV in first plugin's `register`) | Flutter debug-mode cold-launch quirk ([flutter#149214](https://github.com/flutter/flutter/issues/149214)) — install a **profile/release** build for on-device testing |
| OBS logs | `~/Library/Application Support/obs-studio/logs/` |

## Files

- `tool/obs_local/obs_test_env.sh` — start/stop/status for the local OBS.
- `tool/obs_local/ws_smoke.dart` — standalone Hello → Identify → Identified +
  GetVersion/GetSceneList/GetInputList probe (exit 0/1). Uses
  `package:web_socket_channel` + `package:crypto` from the app’s deps; no new
  dependencies.

Handshake semantics intentionally mirror
[`lib/utils/authentication_helper.dart`](../lib/utils/authentication_helper.dart)
and [`docs/websocket-connect-audit.md`](websocket-connect-audit.md).
