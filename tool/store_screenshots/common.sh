# Shared setup of the store capture scripts (macOS; sourced, not run):
# capture.sh (screenshots) and record.sh (video) both put the local OBS into
# the demo state behind a local RTMP sink and give the device a clean
# status bar. See README.md in this folder.
#
#   . "$(dirname "$0")/common.sh"
#   store_init <ios|android> <device-id> <out-dir>

# Sets PLATFORM, DEVICE, OUT_DIR, REPO_ROOT (and cds there), ADB, LOG,
# OBS_WS_PASSWORD, OBS_HOST, ORIENTATION.
store_init() {
  PLATFORM="$1"
  DEVICE="$2"
  OUT_DIR="$3"
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  cd "$REPO_ROOT" || exit 1
  ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
  mkdir -p "$OUT_DIR"
  OUT_DIR="$(cd "$OUT_DIR" && pwd)"
  LOG="$OUT_DIR/flutter_test_output.log"

  local ws_config="$HOME/Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json"
  OBS_WS_PASSWORD="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("server_password",""))' "$ws_config" 2>/dev/null)"

  if [ "$PLATFORM" = "android" ]; then OBS_HOST=10.0.2.2; else OBS_HOST=127.0.0.1; fi
  ORIENTATION="${ORIENTATION:-portrait}"
}

# iOS: simctl has no rotate command - use the Simulator app's menu on this
# device's window. simctl screenshots stay in the panel's portrait buffer,
# so landscape captures are rotated upright after each shot.
sim_rotate() {
  local name
  name="$(xcrun simctl list devices | grep "$DEVICE" | sed -E 's/^ *//; s/ \(.*//')"
  osascript -e 'tell application "Simulator" to activate' \
    -e 'tell application "System Events" to tell process "Simulator"' \
    -e "perform action \"AXRaise\" of (first window whose name contains \"$name\")" \
    -e 'delay 0.5' \
    -e "click menu item \"Rotate $1\" of menu \"Device\" of menu bar 1" \
    -e 'end tell' >/dev/null
}

# Demo OBS state: own profile + scene collection (obs_demo.dart setup), the
# local RTMP sink running. Stays offline - the caller goes live (capture.sh
# via obs_demo.dart, record.sh through the app). `--video`: moving sources.
obs_demo_up() {
  if [ "${1:-}" = "--video" ]; then
    [ -f build/store_screenshots/media/gameplay.mp4 ] || tool/store_screenshots/prepare_media.sh --video
    dart run tool/store_screenshots/obs_demo.dart setup --video || return 1
  else
    [ -f build/store_screenshots/media/gameplay.png ] || tool/store_screenshots/prepare_media.sh
    dart run tool/store_screenshots/obs_demo.dart setup || return 1
  fi
  sink_start
}

# `ffmpeg -listen 1` serves exactly one RTMP session and exits when OBS
# stops streaming - respawn it, so a stop + start (video mode goes live
# and offline through the app) finds a sink again. No input probing: the
# stream goes nowhere, and OBS reports "live" only once the sink took it.
SINK_CMD="ffmpeg -nostdin -loglevel error -listen 1"
SINK_ARGS="-probesize 32 -analyzeduration 0 -fflags nobuffer"
SINK_PIDFILE=build/store_screenshots/rtmp-sink.pid
sink_start() {
  sink_stop # a loop left behind by a killed run
  mkdir -p "$(dirname "$SINK_PIDFILE")"
  (
    while :; do
      $SINK_CMD $SINK_ARGS -i rtmp://127.0.0.1:1935/live/demo -f null -
      sleep 0.3
    done
  ) >> "$OUT_DIR/rtmp-sink.log" 2>&1 &
  echo $! > "$SINK_PIDFILE"
  sleep 1
}

sink_stop() {
  local pid
  pid="$(cat "$SINK_PIDFILE" 2>/dev/null)"
  # only if that pid still is one of these scripts (pids get reused)
  if [ -n "$pid" ] && ps -p "$pid" -o command= 2>/dev/null | grep -q store_screenshots; then
    kill "$pid" 2>/dev/null
  fi
  rm -f "$SINK_PIDFILE"
  pkill -f "$SINK_CMD" 2>/dev/null
}

# Stream/record off; KEEP_OBS=1 keeps the demo profile/collection (e.g.
# between two devices), otherwise teardown restores the user's own.
obs_demo_down() {
  if [ -z "${KEEP_OBS:-}" ]; then
    dart run tool/store_screenshots/obs_demo.dart teardown
  else
    dart run tool/store_screenshots/obs_demo.dart offline
  fi
  sink_stop
}

# Clean status bar (9:41, full battery, Wi-Fi) + orientation + the ack
# port forward on Android.
device_prepare() {
  if [ "$PLATFORM" = "ios" ]; then
    [ "$ORIENTATION" = "landscape" ] && sim_rotate Left && sleep 2
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
}

device_restore() {
  if [ "$PLATFORM" = "ios" ]; then
    xcrun simctl status_bar "$DEVICE" clear 2>/dev/null
    [ "$ORIENTATION" = "landscape" ] && sim_rotate Right
  else
    "$ADB" -s "$DEVICE" shell am broadcast -a com.android.systemui.demo -e command exit >/dev/null 2>&1
    "$ADB" -s "$DEVICE" forward --remove tcp:8977 >/dev/null 2>&1
  fi
}
