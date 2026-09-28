#!/bin/bash
# Renders the demo OBS scene media for the store screenshots (macOS only):
# the obs_scene/*.html art -> PNG via headless Chrome, and looping audio
# beds -> WAV via ffmpeg (so the app's audio meters move). Output goes to
# build/store_screenshots/media/ (gitignored), which obs_demo.dart points
# the demo scene collection at.
#
#   prepare_media.sh           # stills + audio (screenshots)
#   prepare_media.sh --video   # + seamless gameplay/facecam loops (mp4) for
#                              #   video mode (obs_demo.dart setup --video)
#
# Needs: Google Chrome, ffmpeg (brew install ffmpeg); --video also python3
# with `websockets` (render_loop.py drives Chrome over DevTools).
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO_ROOT/tool/store_screenshots/obs_scene"
OUT="$REPO_ROOT/build/store_screenshots/media"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
mkdir -p "$OUT"

# render <html-with-query> <out.png> <w> <h> [transparent]
render() {
  local bg=()
  [ "${5:-}" = "transparent" ] && bg=(--default-background-color=00000000)
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --window-size="$3,$4" ${bg[@]+"${bg[@]}"} --virtual-time-budget=2000 \
    --screenshot="$2" "file://$SRC/$1" >/dev/null 2>&1
  echo "[media] $(basename "$2")"
}

render gameplay.html "$OUT/gameplay.png" 1920 1080
render facecam.html "$OUT/facecam.png" 1280 720
render overlay.html "$OUT/overlay.png" 1920 1080 transparent
render "screen.html?title=STARTING%20SOON&sub=GRAB%20A%20SNACK" "$OUT/starting.png" 1920 1080
render "screen.html?title=BE%20RIGHT%20BACK&sub=DON'T%20GO%20ANYWHERE" "$OUT/brb.png" 1920 1080
render "screen.html?title=THANKS%20FOR%20WATCHING&sub=SEE%20YOU%20TOMORROW" "$OUT/ending.png" 1920 1080
render "screen.html?title=INTERMISSION&sub=BACK%20IN%205" "$OUT/intermission.png" 1920 1080

# Audio beds (60 s loops). Levels are set so meters sit in the green/yellow.
# music: a pulsing minor chord
ffmpeg -nostdin -loglevel error -y -f lavfi \
  -i "aevalsrc='(0.25*sin(2*PI*110*t)+0.18*sin(2*PI*130.8*t)+0.15*sin(2*PI*164.8*t)+0.1*sin(2*PI*220*t))*(0.55+0.45*sin(2*PI*2*t))':s=48000:d=60" \
  -ac 2 "$OUT/music.wav"
echo "[media] music.wav"
# mic: speech-like bursts of shaped pink noise
ffmpeg -nostdin -loglevel error -y -f lavfi -i "anoisesrc=color=pink:amplitude=0.6:d=60:r=48000" \
  -af "volume='0.15+0.85*abs(sin(2.7*t)*sin(1.1*t+1))':eval=frame,lowpass=f=3500,highpass=f=120" \
  -ac 2 "$OUT/mic.wav"
echo "[media] mic.wav"
# game: engine rumble + whoosh
ffmpeg -nostdin -loglevel error -y -f lavfi -i "anoisesrc=color=brown:amplitude=0.8:d=60:r=48000" \
  -af "volume='0.35+0.3*sin(2*PI*0.4*t)':eval=frame" -ac 2 "$OUT/game.wav"
echo "[media] game.wav"

# Video mode: the same art in motion. render_loop.py seeks each page's
# render(t) frame by frame (deterministic, no screen recording) into an
# 8 s loop OBS plays as a looping media source - a still PNG makes the
# app's scene preview look frozen on camera.
if [ "${1:-}" = "--video" ]; then
  python3 "$REPO_ROOT/tool/store_screenshots/render_loop.py" "$SRC/gameplay.html" "$OUT/gameplay.mp4" --w 1920 --h 1080
  python3 "$REPO_ROOT/tool/store_screenshots/render_loop.py" "$SRC/facecam.html" "$OUT/facecam.mp4" --w 1280 --h 720
fi
