#!/bin/bash
# Renders widget states to PNGs (build/widget_shots/) - headless, no
# simulator, no OBS. See tool/widget_shots/README.md.
#
# Usage:  tool/widget_shots/run.sh [tool/widget_shots/<spec>_shots_test.dart ...]
#         (no args = every spec)
set -u
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

if [ $# -eq 0 ]; then
  set -- tool/widget_shots/*_shots_test.dart
fi

OUT_DIR="build/widget_shots"
mkdir -p "$OUT_DIR"

# --update-goldens writes the PNGs instead of comparing (these are images to
# look at, not regression goldens). Retries the headless runner's load flake
# ("Unable to connect to flutter_tester process").
for attempt in 1 2 3; do
  LOG="$(flutter test -j 1 --update-goldens "$@" 2>&1)"
  if ! grep -q "Unable to connect to flutter_tester process" <<<"$LOG"; then
    break
  fi
  echo "[widget_shots] runner load flake, retrying ($attempt)"
done

grep -vE '^\[INFO\]|^Shell:' <<<"$LOG" | tail -5
echo "[widget_shots] PNGs in $REPO_ROOT/$OUT_DIR:"
ls -1 "$OUT_DIR"
grep -q "Some tests failed\|Failed to load" <<<"$LOG" && exit 1
exit 0
