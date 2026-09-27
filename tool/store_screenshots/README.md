# Store screenshot captures

Real-app captures for the App Store / Play Store listings, taken on
simulators/emulators against a local OBS in a staged "streamer" state. The
captures are raw device screenshots; composing them into the designed store
images (headline, device frame, backdrop) happens in a separate composer.

**Use dedicated devices only.** The capture test writes settings, stats, a
saved connection, placeholder chat sessions and the Pro debug override into
the app's storage. Create separate simulators/AVDs for it (e.g. an iPhone
17 Pro Max and an iPad Pro 13" simulator, a Pixel 7 and a Pixel Tablet AVD)
and never point it at a device with real data.

## What's here

| File | Role |
|---|---|
| `prepare_media.sh` | Renders the demo scene art (`obs_scene/*.html`, headless Chrome) and audio beds (ffmpeg) into `build/store_screenshots/media/`. |
| `obs_scene/` | Fictional demo content: a synthwave racer "game", an illustrated facecam, overlay, interstitials. No real people, games or brands. |
| `obs_demo.dart` | `setup` / `live` / `offline` / `teardown` for OBS over WebSocket v5. Creates a separate **"OBS Blade Store Demo"** profile + scene collection (never edits yours), streams to a local RTMP sink, records into `build/`. `teardown` switches back to the profile/collection you had. |
| `capture.sh` | One device end to end: OBS demo state, local `ffmpeg -listen` RTMP sink, clean status bar (iOS `simctl status_bar`, Android demo mode), runs the test, saves one PNG per `SHOT:` marker. |
| `../../integration_test/store_screenshots_test.dart` | Seeds the app (stats history, saved connection, combined chat via fake-backed chat stores with fictional viewers), connects, walks the screens, prints `SHOT:` and `CROP:` markers. |

## Run (macOS with OBS, Chrome, ffmpeg, Flutter)

```bash
# one device at a time; KEEP_OBS=1 keeps the demo state between devices
KEEP_OBS=1 tool/store_screenshots/capture.sh ios     <iphone-sim-udid> build/store_screenshots/captures/ios-phone
ORIENTATION=landscape KEEP_OBS=1 \
           tool/store_screenshots/capture.sh ios     <ipad-sim-udid>   build/store_screenshots/captures/ios-tablet
KEEP_OBS=1 tool/store_screenshots/capture.sh android <phone-serial>    build/store_screenshots/captures/android-phone
           tool/store_screenshots/capture.sh android <tablet-serial>   build/store_screenshots/captures/android-tablet
```

- The OBS WebSocket password is read from the local obs-websocket config.
- iOS reaches OBS on `127.0.0.1`, Android emulators on `10.0.2.2`.
- `STORE_SHOTS_ONLY=chat_combined,streaming_mode` re-takes just those shots
  (the flow still runs, other markers are skipped).
- `flutter test` reinstalls the app, so every run starts fresh (intro →
  seeded state). The test expects that fresh boot: it swaps in the chat
  stores while the intro is still the root route, before the tab shell
  (built eagerly) binds to them.

## Markers

- `SHOT: <name>` — the wrapper screenshots the device, then acks over
  loopback (`127.0.0.1:8977`, `adb forward` on Android).
- `CROP: <shot> <key> l t w h` — a widget's rect as screen fractions, for
  enlarged callout cards in the composed images (e.g. `live_pills`,
  `fader`, `sources`).
