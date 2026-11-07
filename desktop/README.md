# OBS Blade Remote (desktop)

The bridge next to OBS that lets the app reach OBS through the relay
(`tool/remote_relay/`), Pro only. Design:
`docs/superpowers/specs/2026-11-07-remote-relay-design.md`.

| Folder | What | State |
|---|---|---|
| `core/` | Rust: relay link, one local OBS websocket per phone session, preview cap, OBS monitor (state, status snapshot, pairing via CustomEvent), stored pairing; C ABI `core/include/obs_blade_bridge.h`; `obb` CLI (headless host) | built, tested |
| `plugin/` | OBS plugin shell (C++, obs-plugintemplate), vendor `obs-blade-bridge` | next |
| `standalone/` | Tray app (C++/Qt6) + OBS watcher / Start OBS | later |
| `ui/` | Shared Qt settings panel | later |

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
