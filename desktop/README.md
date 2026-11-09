# OBS Blade Remote (desktop)

The bridge next to OBS that lets the app reach OBS through the relay
(`tool/remote_relay/`), Pro only. Design:
`docs/superpowers/specs/2026-11-07-remote-relay-design.md`.

| Folder | What | State |
|---|---|---|
| `core/` | Rust: relay link, one local OBS websocket per phone session, preview cap, OBS monitor (state, status snapshot, pairing via CustomEvent), stored pairing; C ABI `core/include/obs_blade_bridge.h`; `obb` CLI (headless host) | built, tested |
| `plugin/` | OBS plugin shell (C++, obs-plugintemplate 2025-12, OBS 31.1+): starts the core after load, vendor `obs-blade-bridge` `Pair` / `Status` / `OpenPanel`, Tools -> OBS Blade Remote opens the panel, clean stop on OBS exit | builds + runs on macOS (OBS 32.2.2) |
| `standalone/` | Tray / menu bar app (C++/Qt6): the core as `standalone`, OBS watcher (process: `obs64.exe` / `OBS` / `obs`), Start OBS (the executable last seen running - portable installs, with `--portable` when they have no marker file; else macOS bundle id, Windows install dir from the uninstall key + `bin\\64bit`, Linux PATH / Flatpak), start at login (LaunchAgent / HKCU Run / XDG autostart, on by default), log `standalone.log` next to `bridge.json` | builds + runs on macOS and Windows (CI: `.github/workflows/desktop.yml`) |
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
# The platform's own style (what the standalone shows) - on the Mac itself,
# also over ssh; check both, Fusion hides native-style problems
QT_SCALE_FACTOR=2 build/panel_preview native --native
```

Each run includes `panel_*_advanced.png` with the Advanced section open.

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

Failover with the plugin **and** the standalone installed (real OBS, the
standalone running, a deployed relay with a test id in `RELAY_PRO_ALLOW`):

```bash
venv/bin/python3 desktop/core/tests/failover.py --relay-url https://relay.obs-blade.com --user <id>
```

Pairs a test device through the plugin, kills OBS (SIGKILL), checks the
standalone takes over, starts OBS through the relay (no Safe Mode
question - the standalone clears OBS's crash marks for phone starts),
checks the plugin is back and a phone reaches OBS end to end, removes the
device. Last green run: OBS 32.2.2, macOS, 2026-11-09 (takeover 1.7 s,
plugin back 4.3 s after the start).

A portable OBS on Windows with the standalone (CI build from
`desktop.yml`, a portable OBS with `portable_mode.txt` whose WebSocket
port and password differ from the regular install's, both running, a test
id in `RELAY_PRO_ALLOW`):

```bash
py desktop/core/tests/portable_start.py --relay-url https://relay.obs-blade.com --user <id> \
  --obs-dir C:\obb-test\OBS-portable --obs-port 4466 --obs-password <pw>
```

Pairs through the standalone over the portable OBS, kills OBS, starts it
through the relay and checks the portable copy came up without the Safe
Mode question and is reachable end to end. Last green run: OBS 32.2.2
portable, Windows 11, 2026-11-09. GUI programs started over SSH land in
a session without a desktop: start the standalone and OBS through a
temporary scheduled task (`LogonType Interactive`).

The core reads obs-websocket's password from
`<OBS config>/plugin_config/obs-websocket/config.json` - for the
standalone also a portable install's `config/obs-studio` next to the OBS
executable it saw running (`bridge.json` `obs_exe`; with a marker file
it wins, after `--portable` the newest config does). Found nowhere: it
tries OBS's default port without a password and the panel asks for the
port and password under Advanced. It stores its
pairing in `<user config>/obs-blade-remote/bridge.json` (0600), shared by
the plugin and the standalone.

## CI builds and macOS signing

`.github/workflows/desktop.yml` builds on every push touching `desktop/`:
Windows x64 (plugin folder + standalone with Qt, unsigned), a Linux
compile check, and macOS universal - the plugin as `.pkg` (installs into
`~/Library/Application Support/obs-studio/plugins`) and the standalone as
`.dmg` (Qt bundled by `standalone/macos/package.sh`), both Developer ID
signed with the hardened runtime, notarized and stapled
(`desktop/notarize.sh`). Secrets: `MACOS_DEVID_APP_P12_BASE64`,
`MACOS_DEVID_INSTALLER_P12_BASE64`, `MACOS_DEVID_P12_PASSWORD` (from
the maintainer's `~/.config/obs-blade/developer-id/`) and
`MACOS_NOTARY_KEY_BASE64` / `_KEY_ID` / `_ISSUER_ID` (the App Store
Connect team key the app releases use). Without them (forks) the macOS
builds are ad hoc signed and not notarized. Developer ID certificates
can't be made in Xcode here (it sees the role as Admin): developer.apple.com
with a CSR.

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
