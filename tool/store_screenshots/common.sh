# Shared setup of the store capture scripts (macOS; sourced, not run):
# capture.sh (screenshots) and record.sh (video) both put the local OBS into
# the demo state behind a local RTMP sink and give the device a clean
# status bar. See README.md in this folder.
#
#   . "$(dirname "$0")/common.sh"
#   store_init <ios|android> <device-id> <out-dir>
#   store_trap <cleanup-function>   # before anything touches OBS

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

# Runs <cleanup> exactly once: on a normal exit and on Ctrl-C, TERM, HUP (a
# dropped ssh -t) or a broken pipe. Install it first - obs_demo.dart
# teardown is safe before/without setup. Nothing interrupts the cleanup,
# and its output goes to <out>/cleanup.log first (printed afterwards), so
# a terminal that went away cannot cut the OBS teardown short.
store_trap() {
  STORE_CLEANUP="$1"
  trap store_cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP
  trap 'exit 141' PIPE
}

store_cleanup() {
  [ -n "${STORE_CLEANED:-}" ] && return
  STORE_CLEANED=1
  trap '' INT TERM HUP PIPE
  local log="$OUT_DIR/cleanup.log"
  if : 2>/dev/null > "$log"; then
    "$STORE_CLEANUP" >> "$log" 2>&1
    cat "$log" 2>/dev/null
  else
    "$STORE_CLEANUP"
  fi
}

# The app under test (ios/Runner bundle id = android applicationId).
APP_ID=com.kounex.obsBlade

# Stops the app on the device. `flutter test` / `flutter drive` leave it
# running when they die, and the test inside it drives OBS - first thing
# in every cleanup, before OBS goes back to the user's profile.
app_stop() {
  if [ "$PLATFORM" = "ios" ]; then
    xcrun simctl terminate "$DEVICE" "$APP_ID" >/dev/null 2>&1
  else
    "$ADB" -s "$DEVICE" shell am force-stop "$APP_ID" >/dev/null 2>&1
  fi
}

# wait_gone <pid> <seconds>: true once <pid> is gone.
wait_gone() {
  local i=0
  while kill -0 "$1" 2>/dev/null; do
    [ "$i" -ge $(($2 * 4)) ] && return 1
    sleep 0.25
    i=$((i + 1))
  done
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
  local media=build/store_screenshots/media
  if [ "${1:-}" = "--video" ]; then
    if [ ! -f "$media/gameplay.mp4" ] || [ ! -f "$media/facecam.mp4" ]; then
      tool/store_screenshots/prepare_media.sh --video || return 1
    fi
    dart run tool/store_screenshots/obs_demo.dart setup --video || return 1
  else
    [ -f "$media/gameplay.png" ] || tool/store_screenshots/prepare_media.sh || return 1
    dart run tool/store_screenshots/obs_demo.dart setup || return 1
  fi
  sink_start
}

# `ffmpeg -listen 1` serves exactly one RTMP session and exits when OBS
# stops streaming - respawn it, so a stop + start (video mode goes live
# and offline through the app) finds a sink again. No input probing: the
# stream goes nowhere, and OBS reports "live" only once the sink took it.
# The loop is a `bash -c` of its own, named $SINK_NAME: sink_stop finds it
# by pidfile + name wherever the scripts were started from, and TERM makes
# it take the ffmpeg it waits on along.
SINK_CMD="ffmpeg -nostdin -loglevel error -listen 1"
SINK_ARGS="-probesize 32 -analyzeduration 0 -fflags nobuffer"
SINK_NAME=obs_blade_store_rtmp_sink
SINK_PIDFILE=build/store_screenshots/rtmp-sink.pid
sink_start() {
  sink_stop # a loop left behind by a killed run
  mkdir -p "$(dirname "$SINK_PIDFILE")"
  bash -c 'trap "kill \$ff 2>/dev/null; exit 0" TERM
    while :; do
      $1 $2 -i rtmp://127.0.0.1:1935/live/demo -f null - &
      ff=$!
      wait $ff
      sleep 0.3
    done' "$SINK_NAME" "$SINK_CMD" "$SINK_ARGS" >> "$OUT_DIR/rtmp-sink.log" 2>&1 &
  echo $! > "$SINK_PIDFILE"
  sleep 1
}

sink_stop() {
  local pid
  pid="$(cat "$SINK_PIDFILE" 2>/dev/null)"
  # only if that pid still is the loop (pids get reused)
  if [ -n "$pid" ] && ps -p "$pid" -o command= 2>/dev/null | grep -q "$SINK_NAME"; then
    kill "$pid" 2>/dev/null
  fi
  rm -f "$SINK_PIDFILE"
  sleep 0.3
  # an ffmpeg left behind - and a loop whose pidfile is gone: it has
  # $SINK_CMD in its arguments too
  pkill -f "$SINK_CMD" 2>/dev/null
  return 0
}

# Stream/record off; KEEP_OBS=1 keeps the demo profile/collection (e.g.
# between two devices), otherwise teardown restores the user's own. Both
# only act while OBS is on the demo (obs_demo.dart) - safe at any point.
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
  DEVICE_PREPARED=1
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
  [ -n "${DEVICE_PREPARED:-}" ] || return 0 # (a rotation to undo)
  if [ "$PLATFORM" = "ios" ]; then
    xcrun simctl status_bar "$DEVICE" clear 2>/dev/null
    [ "$ORIENTATION" = "landscape" ] && sim_rotate Right
  else
    "$ADB" -s "$DEVICE" shell am broadcast -a com.android.systemui.demo -e command exit >/dev/null 2>&1
    "$ADB" -s "$DEVICE" forward --remove tcp:8977 >/dev/null 2>&1
  fi
}
