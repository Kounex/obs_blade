# Local OBS ↔ simulator E2E loop (MacBook)

How to run the app on the iPhone simulator against a **real local OBS** over
OBS WebSocket v5 — the loop for verifying connection, handshake, and dashboard
behavior end to end. MacBook-only; the NAS clone must never run OBS or the app.

## One-time state (already true on this machine)

- OBS 32.2.1 at `/Applications/OBS.app`, WebSocket server **enabled**:
  port **4455**, password `123456`, `auth_required: false`
  (`~/Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json`).
- Default profile `Untitled` with a real scene collection (`main`, `Scene`,
  `Scene 2`, `Scene 4`–`8`; text/image/color/media/camera/screen-capture
  sources) — tests run against this, not an empty profile.
- Simulator **iPhone 17 Pro** (`D6F98034-F7A7-4574-967C-A9E182A7ED3A`).
  The simulator shares the host network → OBS is reachable as `127.0.0.1:4455`.

## The loop

```bash
# 1. Launch OBS (no-op if the WS port is already up) and wait for the port
tool/obs_local/obs_test_env.sh start

# 2. Automated gate: handshake + basic requests against real OBS
dart run tool/obs_local/ws_smoke.dart --password 123456

# 3. Run the app on the booted simulator (login shell so PATH has Flutter)
flutter run -d D6F98034-F7A7-4574-967C-A9E182A7ED3A

# 4. In the app: connect manually — host 127.0.0.1, port 4455, password 123456
#    → dashboard should list the real scenes and inputs.

# 5. When done: stop OBS (only stops instances the script started)
tool/obs_local/obs_test_env.sh stop
```

`obs_test_env.sh status` shows OBS process / port / script-ownership at any
time.

### What to exercise in the app

- Scene switching (`main` ↔ `Scene` ↔ …) — dashboard follows program scene.
- Scene-item visibility toggles; input volume / mute sliders.
- Stats batch (CPU/FPS/bytes charts) ticking at 1 s.
- Kill OBS while connected → app should detect the lost socket and run its
  reconnect flow; restart OBS and confirm recovery.

### Testing auth on vs off

The app sends `authentication` in Identify **only when Hello challenges**
(conditional-Identify hardening). Cover both paths:

1. Auth off (default `auth_required: false`): smoke + app connect.
2. Auth on: OBS → Tools → WebSocket Server Settings → enable authentication
   (or flip `auth_required` in the config.json above while OBS is closed),
   then re-run the smoke (needs `--password 123456`) and connect in the app.
3. Restore `auth_required: false` afterwards.

Also try a **wrong password** once: expect close code 4009
(AuthenticationFailed — current obs-websocket 5.x numbering, matching the
app's `WebSocketCloseCode` enum) in the smoke and a real error message in the
app (`ConnectionAttemptResult`), not a generic failure.

## Resource notes

- Never boot extra simulators; reuse the booted iPhone 17 Pro.
- `start` minimizes the OBS window after launch (best-effort AppleScript) to
  cut preview rendering; camera + screen-capture sources are still active
  while OBS runs — that's the cost of testing against real scenes.
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
