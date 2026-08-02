#!/bin/bash
# Visual-QA screenshot harness for OBS Blade.
#
# Runs integration_test/screenshot_walk_test.dart on the booted iOS simulator
# and captures a host-side `xcrun simctl` screenshot for every `SHOT: <name>`
# marker the test prints. Screenshots land in /tmp/obs_shots/ (cleared first,
# except current.png which is preserved).
#
# The OBS websocket password is read at runtime from the local OBS config
# (never written into any tracked file) and passed via --dart-define.
#
# Usage:  tool/visual_qa/capture_screenshots.sh
# Env overrides: DEVICE_ID, OUT_DIR
set -u

DEVICE_ID="${DEVICE_ID:-D6F98034-F7A7-4574-967C-A9E182A7ED3A}"
OUT_DIR="${OUT_DIR:-/tmp/obs_shots}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

export FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/.dotfiles/flutter/sdk}"

OBS_WS_CONFIG="$HOME/Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json"
OBS_WS_PASSWORD=""
if [ -f "$OBS_WS_CONFIG" ]; then
  OBS_WS_PASSWORD="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("server_password",""))' "$OBS_WS_CONFIG" 2>/dev/null)"
fi
if [ -z "$OBS_WS_PASSWORD" ]; then
  echo "[capture] WARNING: no OBS websocket password found, connecting without one"
fi

mkdir -p "$OUT_DIR"
# Clear previous shots but keep current.png (per harness contract)
find "$OUT_DIR" -type f -name '*.png' ! -name 'current.png' -delete

LOG="$OUT_DIR/flutter_test_output.log"
: > "$LOG"

# Watcher: one screenshot per SHOT marker, as soon as it appears in the log,
# then confirm the capture back to the test (ack handshake over loopback)
(
  tail -n +1 -f "$LOG" | while IFS= read -r line; do
    case "$line" in
      # strict: only numbered shot markers (avoids e.g. STATE-INFO lines)
      *"SHOT: "[0-9]*)
        name="${line##*SHOT: }"
        # strip anything past the shot name (defensive)
        name="$(printf '%s' "$name" | tr -cd 'A-Za-z0-9_')"
        if [ -n "$name" ]; then
          if xcrun simctl io "$DEVICE_ID" screenshot "$OUT_DIR/$name.png" >/dev/null 2>&1; then
            echo "[capture] $name.png"
          else
            echo "[capture] FAILED: $name"
          fi
          curl -s -m 2 "http://127.0.0.1:8977/ack?name=$name" >/dev/null 2>&1 || true
        fi
        ;;
    esac
  done
) &
WATCHER_PID=$!
trap 'kill $WATCHER_PID 2>/dev/null' EXIT

echo "[capture] running walkthrough on device $DEVICE_ID ..."
# --no-uninstall: flutter test uninstalls the app at the end of the run BY
# DEFAULT, which wipes the simulator data container (learned the hard way -
# this once destroyed real user data: saved connections, themes, stats).
bash flutterw test integration_test/screenshot_walk_test.dart \
  -d "$DEVICE_ID" \
  --no-uninstall \
  --dart-define=OBS_WS_PASSWORD="$OBS_WS_PASSWORD" \
  2>&1 | tee -a "$LOG"
TEST_EXIT=${PIPESTATUS[0]}

# Give the watcher a moment for any in-flight marker, then shut it down
sleep 1
kill "$WATCHER_PID" 2>/dev/null
wait "$WATCHER_PID" 2>/dev/null
trap - EXIT

SHOT_COUNT="$(find "$OUT_DIR" -maxdepth 1 -type f -name '*.png' ! -name 'current.png' | wc -l | tr -d ' ')"
echo "[capture] done: $SHOT_COUNT screenshots in $OUT_DIR (test exit: $TEST_EXIT)"
exit "$TEST_EXIT"
