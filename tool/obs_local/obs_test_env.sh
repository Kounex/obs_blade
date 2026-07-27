#!/bin/bash
# obs_test_env.sh — manage the local OBS instance for OBS Blade E2E testing
# on the MacBook (docs/local-obs-e2e.md).
#
#   start   Launch OBS (default profile/collection) unless the WebSocket
#           server is already reachable; wait for port 4455.
#   stop    Quit OBS — only if this script started it (PID file).
#   status  Show whether OBS / the WebSocket port / the PID file are up.
#
# Resource-aware: never restarts or kills an OBS instance it did not start,
# minimizes the window after launch to cut preview rendering, and leaves no
# OBS process behind after `stop`.

set -u

OBS_BIN="/Applications/OBS.app/Contents/MacOS/obs"
OBS_PORT=4455
OBS_HOST=127.0.0.1
PID_FILE="$(cd "$(dirname "$0")/../.." && pwd)/build/obs_test_env.pid"
WAIT_SECONDS=30

port_open() {
  (exec 3<>"/dev/tcp/$OBS_HOST/$OBS_PORT") 2>/dev/null && exec 3>&- 3<&-
}

obs_pid_running() {
  [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

minimize_obs_window() {
  osascript -e 'tell application "System Events" to tell process "OBS" to set miniaturized of every window to true' \
    >/dev/null 2>&1 || true
}

cmd_start() {
  if [ ! -x "$OBS_BIN" ]; then
    echo "ERROR: OBS binary not found at $OBS_BIN" >&2
    exit 1
  fi

  if port_open; then
    echo "OBS WebSocket already reachable on $OBS_HOST:$OBS_PORT — reusing running instance (not managed by this script)."
    exit 0
  fi

  if pgrep -x obs >/dev/null 2>&1; then
    echo "ERROR: OBS is running but port $OBS_PORT is not open." >&2
    echo "Enable it in OBS: Tools → WebSocket Server Settings → Enable, port $OBS_PORT." >&2
    exit 1
  fi

  echo "Launching OBS (default profile/collection)…"
  mkdir -p "$(dirname "$PID_FILE")"
  # NOTE: --safe-mode would DISABLE WebSockets — never add it here.
  nohup "$OBS_BIN" --disable-updater --disable-missing-files-check \
    >/dev/null 2>&1 &
  echo $! >"$PID_FILE"

  for ((i = 1; i <= WAIT_SECONDS; i++)); do
    if port_open; then
      minimize_obs_window
      echo "OBS WebSocket up on $OBS_HOST:$OBS_PORT (OBS pid $(cat "$PID_FILE"), window minimized)."
      exit 0
    fi
    if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      rm -f "$PID_FILE"
      echo "ERROR: OBS exited before the WebSocket server came up." >&2
      exit 1
    fi
    sleep 1
  done

  echo "ERROR: timed out after ${WAIT_SECONDS}s waiting for $OBS_HOST:$OBS_PORT." >&2
  echo "OBS may still be starting (or showing a dialog). Check the app, then re-run 'status'." >&2
  exit 1
}

cmd_stop() {
  if obs_pid_running; then
    local pid
    pid="$(cat "$PID_FILE")"
    echo "Stopping OBS (pid $pid, started by this script)…"
    kill "$pid" 2>/dev/null
    for ((i = 1; i <= 15; i++)); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done
    if kill -0 "$pid" 2>/dev/null; then
      echo "WARNING: OBS did not exit within 15s; leaving it running." >&2
    else
      echo "OBS stopped."
    fi
    rm -f "$PID_FILE"
  else
    rm -f "$PID_FILE"
    echo "No script-managed OBS instance — nothing to stop."
  fi
}

cmd_status() {
  local ok=0
  if pgrep -x obs >/dev/null 2>&1; then
    echo "OBS process: running"
  else
    echo "OBS process: not running"
  fi
  if port_open; then
    echo "WebSocket $OBS_HOST:$OBS_PORT: open"
  else
    echo "WebSocket $OBS_HOST:$OBS_PORT: closed"
    ok=1
  fi
  if obs_pid_running; then
    echo "Managed by this script: yes (pid $(cat "$PID_FILE"))"
  else
    echo "Managed by this script: no"
  fi
  exit $ok
}

case "${1:-}" in
  start) cmd_start ;;
  stop) cmd_stop ;;
  status) cmd_status ;;
  *)
    echo "Usage: $0 {start|stop|status}" >&2
    exit 2
    ;;
esac
