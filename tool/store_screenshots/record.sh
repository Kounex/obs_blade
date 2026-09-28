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
set -u

. "$(dirname "$0")/common.sh"
store_init "${1:?ios|android}" "${2:?device id}" "${3:?out dir}"

# ---- OBS demo state with moving sources, local RTMP sink, offline ----
obs_demo_up --video || exit 1
dart run tool/store_screenshots/obs_demo.dart offline || exit 1

cleanup() {
  obs_demo_down
  device_restore
}
trap cleanup EXIT

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

python3 tool/store_screenshots/record_watch.py --platform "$PLATFORM" --device "$DEVICE" \
  --out "$OUT_DIR" --adb "$ADB" --log "$LOG" --android-recorder "${ANDROID_RECORDER:-auto}" -- \
  "${RUN[@]}" \
  --dart-define=OBS_HOST="$OBS_HOST" \
  --dart-define=OBS_WS_PASSWORD="$OBS_WS_PASSWORD" \
  --dart-define=STORE_VIDEO_ONLY="${STORE_VIDEO_ONLY:-}"
TEST_EXIT=$?
exit "$TEST_EXIT"
