#!/bin/bash
# Store video capture (macOS) - the video sibling of capture.sh: demo OBS
# with moving sources, OFFLINE (the test goes live through the app), clean
# status bar, then integration_test/store_video_test.dart on ONE dedicated
# simulator/emulator with a screen recording per clip.
#
#   tool/store_screenshots/record.sh ios     <sim-udid>        <out-dir>
#   tool/store_screenshots/record.sh android <emulator-serial> <out-dir>
#
# Per clip (REC_START / REC_STOP markers, see record_watch.py):
#   <out>/<clip>.mov|<clip>.raw.mp4   raw recording (variable frame rate)
#   <out>/<clip>.mp4                  constant 30 fps H.264, native size
#   <out>/cues.json                   CUE markers, seconds into each clip
#
# Env: STORE_VIDEO_ONLY=a,b (record only these clips; the flow still runs
# every step), KEEP_OBS=1 (skip the OBS teardown, e.g. between two
# devices), ANDROID_RECORDER=device|emulator (default: the emulator's own
# host-side recorder for emulator-* serials, screenrecord otherwise - see
# record_watch.py).
#
# Use dedicated devices only - the test writes settings, stats, a saved
# connection and the Pro debug override. See README.md in this folder.
#
# However this ends (done, Ctrl-C, TERM, a dropped ssh), the cleanup stops
# the test FIRST - the app on the device, the watcher, the test command
# and any recorder left running - and only then puts OBS back: a test that
# kept running would go live on the user's own profile.
set -u

. "$(dirname "$0")/common.sh"
store_init "${1:?ios|android}" "${2:?device id}" "${3:?out dir}"
TEST_PIDFILE=build/store_screenshots/record-test.pid

test_stop() {
  app_stop
  # the watcher stops its recorder and the test command on TERM
  if [ -n "${WATCH_PID:-}" ] && kill -TERM "$WATCH_PID" 2>/dev/null; then
    wait_gone "$WATCH_PID" 30 || kill -KILL "$WATCH_PID" 2>/dev/null
  fi
  # what a watcher killed hard left behind: the test command's process
  # group (flutter + its children; the pidfile is this run's - a group id
  # is not reused while the group has members), a recorder still running
  local pgid i=0
  pgid="$(cat "$TEST_PIDFILE" 2>/dev/null)"
  rm -f "$TEST_PIDFILE"
  if [ -n "$pgid" ] && pgrep -g "$pgid" >/dev/null 2>&1; then
    kill -TERM -- "-$pgid" 2>/dev/null
    while pgrep -g "$pgid" >/dev/null 2>&1 && [ "$i" -lt 40 ]; do
      sleep 0.25
      i=$((i + 1))
    done
    kill -KILL -- "-$pgid" 2>/dev/null
  fi
  if [ "$PLATFORM" = "ios" ]; then
    if pkill -INT -f "simctl io $DEVICE recordVideo" 2>/dev/null; then
      sleep 2
      pkill -KILL -f "simctl io $DEVICE recordVideo" 2>/dev/null
    fi
  else
    "$ADB" -s "$DEVICE" emu screenrecord stop >/dev/null 2>&1
    "$ADB" -s "$DEVICE" shell pkill -INT screenrecord >/dev/null 2>&1
  fi
  app_stop # a launch that was still in flight
}

cleanup() {
  test_stop
  obs_demo_down
  device_restore
}
store_trap cleanup

# ---- OBS demo state with moving sources, local RTMP sink, offline ----
obs_demo_up --video || exit 1
dart run tool/store_screenshots/obs_demo.dart offline || exit 1

device_prepare

# iOS simulators run debug builds only (`flutter test` reinstalls the app).
# Android records a profile build (AOT - the debug JIT drops the emulator
# to ~20-25 fps) through `flutter drive`, which keeps an installed app's
# data: uninstall first, the test expects a fresh boot into the intro.
TARGET=integration_test/store_video_test.dart
if [ "$PLATFORM" = "android" ]; then
  "$ADB" -s "$DEVICE" uninstall com.kounex.obsBlade >/dev/null 2>&1
  # (the Pro debug override needs PRO_RELEASE_TEST_UNLOCK outside debug)
  RUN=(flutter drive --profile --driver=tool/store_screenshots/video_driver.dart
    --target="$TARGET" -d "$DEVICE" --dart-define=PRO_RELEASE_TEST_UNLOCK=true)
else
  RUN=(flutter test "$TARGET" -d "$DEVICE")
fi

# in the background + wait: a signal runs the cleanup at once (a
# foreground command would hold the trap until it ends)
rm -f "$TEST_PIDFILE" # only ever this run's in there
python3 tool/store_screenshots/record_watch.py --platform "$PLATFORM" --device "$DEVICE" \
  --out "$OUT_DIR" --adb "$ADB" --log "$LOG" --android-recorder "${ANDROID_RECORDER:-auto}" \
  --pidfile "$TEST_PIDFILE" -- \
  "${RUN[@]}" \
  --dart-define=OBS_HOST="$OBS_HOST" \
  --dart-define=OBS_WS_PASSWORD="$OBS_WS_PASSWORD" \
  --dart-define=STORE_VIDEO_ONLY="${STORE_VIDEO_ONLY:-}" &
WATCH_PID=$!
wait "$WATCH_PID"
TEST_EXIT=$?
WATCH_PID=
exit "$TEST_EXIT"
