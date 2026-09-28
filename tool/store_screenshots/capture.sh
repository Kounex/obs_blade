#!/bin/bash
# Store screenshot capture (macOS): puts the local OBS into the demo state,
# runs integration_test/store_screenshots_test.dart on ONE dedicated
# simulator/emulator and saves a PNG per `SHOT: <name>` marker.
#
#   tool/store_screenshots/capture.sh ios     <sim-udid>        <out-dir>
#   tool/store_screenshots/capture.sh android <emulator-serial> <out-dir>
#
# Env: STORE_SHOTS_ONLY=a,b (re-take only these), KEEP_OBS=1 (skip the OBS
# teardown, e.g. between two devices), ORIENTATION=landscape (iOS: rotates
# the simulator through the Simulator app's Device menu - the shell needs
# macOS Accessibility access - and turns the captures upright; Android
# tablets capture in landscape on their own).
#
# Use dedicated devices only - the test writes settings, stats, a saved
# connection and the Pro debug override. See README.md in this folder
# (record.sh is the video sibling; both share common.sh).
set -u

. "$(dirname "$0")/common.sh"
store_init "${1:?ios|android}" "${2:?device id}" "${3:?out dir}"

# ---- OBS demo state (own profile + collection, local RTMP sink), live ----
obs_demo_up || exit 1
dart run tool/store_screenshots/obs_demo.dart live || exit 1

cleanup() {
  # the watcher's `tail -f` would outlive the subshell and keep ssh open
  pkill -f "tail .*$LOG" 2>/dev/null
  kill "${WATCHER_PID:-}" 2>/dev/null
  obs_demo_down
  device_restore
}
trap cleanup EXIT

device_prepare

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
          # Rotate Left puts the UI's top at the buffer's right edge
          [ "$ORIENTATION" = "landscape" ] && sips -r 270 "$OUT_DIR/$name.png" >/dev/null 2>&1
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
