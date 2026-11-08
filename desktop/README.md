# OBS Blade Remote (desktop)

The bridge next to OBS that lets the app reach OBS through the relay
(`tool/remote_relay/`), Pro only. Design:
`docs/superpowers/specs/2026-11-07-remote-relay-design.md`.

| Folder | What | State |
|---|---|---|
| `core/` | Rust: relay link, one local OBS websocket per phone session, preview cap, OBS monitor (state, status snapshot, pairing via CustomEvent), stored pairing; C ABI `core/include/obs_blade_bridge.h`; `obb` CLI (headless host) | built, tested |
| `plugin/` | OBS plugin shell (C++, obs-plugintemplate 2025-12, OBS 31.1+): starts the core after load, vendor `obs-blade-bridge` `Pair` / `Status`, Tools -> OBS Blade Remote opens the panel, clean stop on OBS exit | builds + runs on macOS (OBS 32.2.2) |
| `standalone/` | Tray / menu bar app (C++/Qt6): the core as `standalone`, OBS watcher (process: `obs64.exe` / `OBS` / `obs`), Start OBS (macOS bundle id, Windows install dir from the uninstall key + `bin\\64bit`, Linux PATH / Flatpak), start at login (LaunchAgent / HKCU Run / XDG autostart, on by default), log `standalone.log` next to `bridge.json` | builds + runs on macOS |
| `ui/` | Shared Qt settings panel (`remote_panel.*`); `ui/preview/` renders every state to PNGs offscreen | built |

## Plugin (macOS)

```bash
desktop/core/build-lib.sh                 # universal libobb.a
cd desktop/plugin
cmake --preset macos                      # first run downloads OBS sources + obs-deps + Qt6 into .deps
cmake --build --preset macos --config RelWithDebInfo
cp -R build_macos/RelWithDebInfo/obs-blade-remote.plugin \
  ~/Library/Application\ Support/obs-studio/plugins/
```

Notes: the template left `PLUGIN_BUILD_NUMBER` empty outside CI (fixed in
`cmake/common/buildnumber.cmake`); obs-deps' Qt6 links AGL, which the
macOS 26 SDK dropped (filtered in `CMakeLists.txt`). The plugin and the
standalone share `bridge.json` - same bridge, same keys; the standalone
checks every 5 s whether the plugin answers `Status` and then steps back
(`relay: deferred`).

## Panel preview

```bash
cd desktop/ui/preview
cmake -B build -DCMAKE_PREFIX_PATH=<Qt6, e.g. desktop/plugin/.deps/obs-deps-qt6-*> && cmake --build build
QT_QPA_PLATFORM=offscreen QT_PLUGIN_PATH=<Qt6>/plugins build/panel_preview shots
```

## Core

Build and test on a dev machine (not the NAS):

```bash
cd desktop/core
cargo test && cargo clippy --all-targets
cargo build            # target/debug/obb, target/debug/libobb.a
```

End to end with a real OBS (macOS: `tool/obs_local/obs_test_env.sh start`)
and the relay running locally, this script playing the phone:

```bash
python3 -m venv venv && venv/bin/pip install aiohttp==3.14.5
venv/bin/python3 desktop/core/tests/e2e_relay.py --relay-dir tool/remote_relay \
  --obb desktop/core/target/debug/obb \
  [--obs-password PW]   # when OBS runs with --websocket_password PW
  [--stop-obs-cmd "tool/obs_local/obs_test_env.sh stop"]
```

It pairs through a `CustomEvent`, runs a full obs-websocket session through
the relay (no password on the phone), checks the preview cap (size and
aspect), `InputVolumeMeters`, the status snapshot and the 4901 close after
OBS quits. Last green run: OBS 32.2.2 / obs-websocket 5.7.4, macOS,
2026-11-07, with and without OBS auth.

The core reads obs-websocket's password from
`<OBS config>/plugin_config/obs-websocket/config.json` and stores its
pairing in `<user config>/obs-blade-remote/bridge.json` (0600), shared by
the plugin and the standalone.

## Standalone (macOS dev build)

```bash
desktop/core/build-lib.sh
cd desktop/standalone
cmake -B build -DCMAKE_PREFIX_PATH=<Qt6, e.g. desktop/plugin/.deps/obs-deps-qt6-*> -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build
open "build/OBS Blade Remote.app"
```

Menu bar only (`LSUIElement`); closing the window keeps it running; one
instance per user (lock file). A dev build's "Start at login" points the
LaunchAgent at the build folder - turn it off in the panel before
deleting the build.
