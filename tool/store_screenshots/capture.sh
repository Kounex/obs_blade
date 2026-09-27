#!/bin/bash
# Store screenshot capture (macOS): puts the local OBS into the demo state,
# runs integration_test/store_screenshots_test.dart on ONE dedicated
# simulator/emulator and saves a PNG per `SHOT: <name>` marker.
#
#   tool/store_screenshots/capture.sh ios     <sim-udid>        <out-dir>
#   tool/store_screenshots/capture.sh android <emulator-serial> <out-dir>
#
# Env: STORE_SHOTS_ONLY=a,b (re-take only these), KEEP_OBS=1 (skip the OBS
# teardown, e.g. between two devices).
#
# Use dedicated devices only - the test writes settings, stats, a saved
# connection and the Pro debug override. See README.md in this folder.
set -u

PLATFORM="${1:?ios|android}"
DEVICE="${2:?device id}"
OUT_DIR="${3:?out dir}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/flutter_test_output.log"

OBS_WS_CONFIG="$HOME/Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json"
OBS_WS_PASSWORD="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("server_password",""))' "$OBS_WS_CONFIG" 2>/dev/null)"

if [ "$PLATFORM" = "android" ]; then OBS_HOST=10.0.2.2; else OBS_HOST=127.0.0.1; fi

# ---- OBS demo state (own profile + collection, local RTMP sink) ----
[ -f build/store_screenshots/media/gameplay.png ] || tool/store_screenshots/prepare_media.sh
dart run tool/store_screenshots/obs_demo.dart setup || exit 1
pkill -f "ffmpeg -nostdin -loglevel error -listen 1" 2>/dev/null
nohup ffmpeg -nostdin -loglevel error -listen 1 -i rtmp://127.0.0.1:1935/live/demo -f null - \
  > "$OUT_DIR/rtmp-sink.log" 2>&1 &
SINK_PID=$!
sleep 1
dart run tool/store_screenshots/obs_demo.dart live || exit 1

cleanup() {
  # the watcher's `tail -f` would outlive the subshell and keep ssh open
  pkill -f "tail .*$LOG" 2>/dev/null
  kill "${WATCHER_PID:-}" 2>/dev/null
  if [ -z "${KEEP_OBS:-}" ]; then
    dart run tool/store_screenshots/obs_demo.dart teardown
  else
    dart run tool/store_screenshots/obs_demo.dart offline
  fi
  kill "$SINK_PID" 2>/dev/null
  if [ "$PLATFORM" = "ios" ]; then
    xcrun simctl status_bar "$DEVICE" clear 2>/dev/null
  else
    "$ADB" -s "$DEVICE" shell am broadcast -a com.android.systemui.demo -e command exit >/dev/null 2>&1
    "$ADB" -s "$DEVICE" forward --remove tcp:8977 >/dev/null 2>&1
  fi
}
trap cleanup EXIT

# ---- clean status bar ----
if [ "$PLATFORM" = "ios" ]; then
  xcrun simctl status_bar "$DEVICE" override --time "9:41" --dataNetwork wifi --wifiMode active \
    --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
else
  demo() { "$ADB" -s "$DEVICE" shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }
  "$ADB" -s "$DEVICE" shell settings put global sysui_demo_allowed 1
  demo enter
  demo clock -e hhmm 0941
  demo battery -e level 100 -e plugged false
  demo network -e wifi show -e level 4
  demo network -e mobile hide
  demo notifications -e visible false
  "$ADB" -s "$DEVICE" forward tcp:8977 tcp:8977 >/dev/null
fi

# ---- watcher: one capture per marker, then ack ----
: > "$LOG"
(
  tail -n +1 -f "$LOG" | while IFS= read -r line; do
    case "$line" in
      *"SHOT: "*)
        name="$(printf '%s' "${line##*SHOT: }" | tr -cd 'A-Za-z0-9_')"
        [ -z "$name" ] && continue
        if [ "$PLATFORM" = "ios" ]; then
          xcrun simctl io "$DEVICE" screenshot "$OUT_DIR/$name.png" >/dev/null 2>&1
        else
          "$ADB" -s "$DEVICE" exec-out screencap -p > "$OUT_DIR/$name.png"
        fi
        echo "[capture] $name.png"
        curl -s -m 2 "http://127.0.0.1:8977/ack?name=$name" >/dev/null 2>&1 || true
        ;;
    esac
  done
) &
WATCHER_PID=$!

flutter test integration_test/store_screenshots_test.dart -d "$DEVICE" \
  --dart-define=OBS_HOST="$OBS_HOST" \
  --dart-define=OBS_WS_PASSWORD="$OBS_WS_PASSWORD" \
  --dart-define=STORE_SHOTS_ONLY="${STORE_SHOTS_ONLY:-}" \
  2>&1 | tee -a "$LOG"
TEST_EXIT=${PIPESTATUS[0]}
sleep 1
echo "[capture] $(find "$OUT_DIR" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ') screenshots in $OUT_DIR (test exit $TEST_EXIT)"
exit "$TEST_EXIT"
