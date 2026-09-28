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
| `prepare_media.sh` | Renders the demo scene art (`obs_scene/*.html`, headless Chrome) and audio beds (ffmpeg) into `build/store_screenshots/media/`. `--video` also renders the gameplay + facecam loops (`render_loop.py`). |
| `obs_scene/` | Fictional demo content: a synthwave racer "game", an illustrated facecam, overlay, interstitials. No real people, games or brands. Opened plain a page is the still; `?drive` exposes a deterministic `render(t)` loop (gameplay, facecam). |
| `render_loop.py` | Drives one headless Chrome over DevTools: `render(n/fps)` + screenshot per frame, piped into ffmpeg - a seamless 8 s loop mp4, checked at the seam (PSNR of the wrap step vs a normal step). Encodes to `<name>.part.mp4` and renames only once the seam check passed. |
| `obs_demo.dart` | `setup [--video]` / `live` / `offline` / `teardown` for OBS over WebSocket v5. Creates a separate **"OBS Blade Store Demo"** profile + scene collection (never edits yours), streams to a local RTMP sink, records into `build/store_screenshots/obs_recordings/`. `--video` makes Game Capture and Webcam looping media sources. `teardown` switches back to the profile/collection and Studio Mode you had. See "OBS safety". |
| `common.sh` | Shared by both wrappers: environment, run-once cleanup trap, OBS demo state + respawning local `ffmpeg -listen` RTMP sink (pidfile), clean status bar (iOS `simctl status_bar`, Android demo mode), stopping the app, teardown. |
| `capture.sh` | Screenshots, one device end to end: OBS demo state (live + recording), runs the test, saves one PNG per `SHOT:` marker. |
| `record.sh` + `record_watch.py` | Video, one device end to end: OBS demo state with moving sources, **offline**; runs the video test through the watcher, which records per clip and normalizes (see "Video mode"). |
| `video_driver.dart` | Host side of `flutter drive --profile`, which record.sh uses on Android. |
| `../../integration_test/store_capture_support.dart` | Shared by both tests: seeding (stats history, saved connection, combined chat via fake-backed chat stores with fictional viewers), the ack server, navigation/scroll helpers, `deviceTap`. |
| `../../integration_test/store_screenshots_test.dart` | Seeds, connects, walks the screens, prints `SHOT:` and `CROP:` markers. |
| `../../integration_test/store_video_test.dart` | Seeds, records the intro from launch, goes live through the app, plays out each clip, prints `REC_START:` / `REC_STOP:` / `CUE:` markers. |

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

## OBS safety

The demo runs on the machine's real OBS, next to the user's own profile
(stream key included). What keeps it there:

- `obs_demo.dart` checks where OBS is before it acts: `setup` refuses an
  OBS that is live on another profile and re-reads the current
  profile/collection after each switch before it changes profile settings
  or removes a scene/source; `live` needs the demo profile + collection
  and a stream server on `127.0.0.1`; `offline` and `teardown` stop
  outputs only on the demo profile. `teardown` reads the restore file
  first and only switches back what is still the demo - running it twice,
  without a setup, or while the user streams on their own profile is a
  no-op.
- The wrappers install their cleanup first; it runs once, on every exit
  (done, error, Ctrl-C, TERM, HUP from a dropped `ssh -t`). It stops the
  test before OBS goes back: the app on the device (`simctl terminate` /
  `am force-stop com.kounex.obsBlade` - flutter leaves it running when it
  dies), flutter, the watcher and any recorder, then the teardown, the
  sink and the status bar. Its output lands in `<out>/cleanup.log` first.
- The tests fail at once on a missed ack (the wrapper is gone), and the
  video test asks OBS itself (an own obs-websocket connection) for the
  demo profile + collection and the local stream server at the start and
  before every step that changes OBS through the app - going live,
  recording, scene switches, mute, visibility, Studio Mode.
- `record_watch.py` stops its recorder and the test command's process
  group when it is interrupted; a lost terminal (broken pipe) only stops
  its echo.

## Markers

- `SHOT: <name>` — the wrapper screenshots the device, then acks over
  loopback (`127.0.0.1:8977`, `adb forward` on Android). No ack within
  12 s fails the test.
- `CROP: <shot> <key> l t w h` — a widget's rect as screen fractions, for
  enlarged callout cards in the composed images (e.g. `live_pills`,
  `fader`, `sources`).

## Video mode

Screen recordings of the real app for the App Store app previews (Apple
2.3.4: previews may only show captures of the app itself) and the Play
preview video. Same dedicated devices as the screenshots.

```bash
tool/store_screenshots/prepare_media.sh --video      # once: stills, audio, loops
KEEP_OBS=1 tool/store_screenshots/record.sh ios     <iphone-sim-udid> build/store_screenshots/recordings/ios-phone
           tool/store_screenshots/record.sh android <phone-serial>    build/store_screenshots/recordings/android-phone
# re-take single clips (the flow still runs every step, only these record):
STORE_VIDEO_ONLY=scenes,chat tool/store_screenshots/record.sh ios <udid> <out>
# summary of existing clips again (--normalize: re-encode the mp4s first):
python3 tool/store_screenshots/record_watch.py --analyze <out> [--normalize]
```

**Clips** (`store_video_test.dart`; each with ~1 s idle lead-in and tail):

| Clip | What plays |
|---|---|
| `intro` | Recording starts before the app boots: Welcome slide from its first frame (700 ms scale-in), held 10 s, then Dashboard (one 14 s loop), Customise, Stats slides via the page controller. |
| `golive` | Offline dashboard → Exposed Controls → Go Live → confirm → LIVE; Start recording → confirm → REC; controls closed, 5 s of running timers. |
| `scenes` | Live dashboard with the preview: Talk, BRB, Game about every 2.5 s. |
| `audio` | Mixer meters (Music, Game Audio, Mic), Mic mute + unmute, Scene Items tab, Webcam hidden + shown. |
| `chat` | Combined chat with new messages every 0.5-1.2 s, a reply typed into the focused input (no system keyboard) and sent. |
| `stats` | OBS Stats tiles ticking, Statistics tab, a past stream's detail, charts drawing in. |
| `customise` | Settings: Studio Mode on, Customisation: Replay Controls + Hotkeys on; dashboard: Studio Mode checkbox, BRB to preview (PVW), Transition. |
| `streaming_mode` | The streaming-mode cockpit (preview, scenes, chat feed), BRB and back. |
| `stopstream` | Go Offline → confirm, recording Stop → confirm. |

**Markers** (each waits for the wrapper's ack, like `SHOT:`; a missed
ack fails the test):

- `REC_START: <clip>` - the watcher starts `xcrun simctl io <udid>
  recordVideo --codec=h264 --force <clip>.mov` (iOS), the emulator's own
  recorder `adb emu screenrecord start --fps 60` (`<clip>.raw.webm`,
  Android emulators) or `adb shell screenrecord --bit-rate 20000000`
  (`<clip>.raw.mp4`, a real Android device or `ANDROID_RECORDER=device`),
  waits until it really records, then acks `start:<clip>`.
- `REC_STOP: <clip>` - SIGINT / `screenrecord stop` (screenrecord: on the
  device, then `adb pull`), waits for the finished file, acks
  `stop:<clip>`.
- `FRAMES: <clip> <n> <ms> <build> <raster>` - frames the app itself drew
  during the clip (and p90 build / raster ms), from the engine's frame
  timings; `clips.json` has it as `app`.
- `CUE: <clip> <label> <ms>` - a key moment (scene switched, muted, sent,
  page change...), ms since the start ack. `cues.json` has it as `t`,
  seconds into that clip's file.

**Output** per device directory: `<clip>.mov` / `<clip>.raw.webm` /
`<clip>.raw.mp4` (raw, variable frame rate),
`<clip>.mp4` (constant 30 fps H.264, CRF 13, yuv420p BT.709, native
resolution, no audio), `cues.json`, and `clips.json` - duration, size, the
frames per second the app really drew while something moved (median / min
over those seconds, from the raw frame times - the frames that changed;
compare with `app.fps`, what the app drew) and `lost_s`, how much
shorter the file is than the test's own clock. The simulator runs debug
builds: re-take a clip whose motion fps sags, and any clip the watcher
warns about - a simulator that stalls (a busy Mac) drops the stalled time
from the recording, so the clip jumps.

**Why the test looks the way it does:**

- `framePolicy = fullyLive`: the live test binding otherwise only paints
  when the test pumps (250 ms steps - about 4 fps on a recording).
- Android runs a profile build (`flutter drive --profile`, AOT; the debug
  JIT falls well behind on an emulator) with `PRO_RELEASE_TEST_UNLOCK`
  for the Pro debug override, after an `adb uninstall` - `flutter drive`
  keeps an installed app's data, the test needs a fresh boot. The iOS
  simulator only runs debug builds (`flutter test`).
- Android emulators record with the emulator's host-side recorder: the
  device's `screenrecord` (a virtual display plus a software encoder in
  the guest) takes GPU and CPU from the app - measured on the Store
  Pixel 7 AVD, 20 recorded / 42 drawn fps with it, 40 / 52 without.
- `deviceTap` instead of `tester.tap`: test-sourced pointers get a debug
  crosshair painted over the app; device-sourced ones (the test sets
  `shouldPropagateDevicePointerEvents`) are plain taps with the real press
  feedback. Page changes and scrolls go through their controllers.
  `deviceTap` only taps what hit-tests at its center - scene tiles are
  found as the `SceneButton` (its ring is stacked over the label), and a
  target under the translucent dashboard header does not count.
- The reply is typed with the test's fake text input registered: the
  field shows focus and cursor, but no simulator keyboard comes up (it is
  region-specific and shows a first-use onboarding sheet on iOS).
- The binding's "Test starting..." screen is covered with the app's
  scaffold color before the first recording starts.
- The demo OBS starts offline (`record.sh`); the RTMP sink respawns after
  every session, since `ffmpeg -listen 1` exits when a stream stops, and
  takes the stream without probing it (OBS reports "live" once the sink
  answered - the app's LIVE pill lights about a second after the tap).
- Game Capture and Webcam are looping media sources in video mode (the
  still PNGs make the app's preview look frozen); the stills stay for the
  screenshots. Media sources count as audio inputs, so video mode creates
  Game Audio and Mic before them - the app's mixer lists inputs in
  creation order and the moving meters stay on top.
