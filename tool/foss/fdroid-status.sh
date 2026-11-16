#!/bin/bash
# Where a FOSS release is on its way to F-Droid (docs/foss-build.md §
# Releasing): checkupdates bot MR -> fdroiddata master -> F-Droid build
# (must reproduce our GitHub APK) -> published.
#
#   tool/foss/fdroid-status.sh            # pubspec.yaml's version
#   tool/foss/fdroid-status.sh --notify   # + push the result (NAS ntfy helper)
#   FDROID_VERSION=4.2.0+2026102003 tool/foss/fdroid-status.sh  # another one
#
# Exit 0 = published, 1 = still on its way, 2 = stuck (needs a look).
set -uo pipefail
cd "$(dirname "$0")/../.."

APP=com.kounex.obsBlade
line="version: ${FDROID_VERSION:-$(grep -m1 '^version:' pubspec.yaml | sed 's/^version: *//')}"
NAME=$(sed -E 's/version: *([^+]+)\+.*/\1/' <<<"$line")
CODE=$(sed -E 's/.*\+([0-9]+).*/\1/' <<<"$line")
GL=https://gitlab.com/api/v4/projects/fdroid%2Ffdroiddata

state=1
if curl -fsS "https://f-droid.org/api/v1/packages/$APP" |
  python3 -c "import sys,json; sys.exit(0 if any(p['versionCode']==$CODE for p in json.load(sys.stdin)['packages']) else 1)"; then
  msg="$NAME is live on F-Droid"
  state=0
elif curl -fsS https://f-droid.org/repo/status/build.json |
  python3 -c "import sys,json; sys.exit(0 if ['$APP',$CODE] in json.load(sys.stdin).get('failedBuilds',[]) else 1)"; then
  msg="$NAME: F-Droid's build FAILED - log: https://monitor.f-droid.org/builds/log/$APP/$CODE (a mismatch with our APK lands here too)"
  state=2
else
  mr=$(curl -fsS "$GL/merge_requests?search=$(python3 -c "import urllib.parse;print(urllib.parse.quote('Update OBS Blade to $CODE'))")&in=title&per_page=5" |
    python3 -c '
import sys,json
ms=json.load(sys.stdin)
if ms:
    m=ms[0]
    print(m["state"], m["web_url"], (m.get("head_pipeline") or {}).get("status") or "")
')
  read -r mstate murl _ <<<"$mr"
  # A merged MR may not show head_pipeline in the list API; ask for it
  pipe=$( [ -n "${murl:-}" ] && curl -fsS "$GL/merge_requests/${murl##*/}" |
    python3 -c 'import sys,json; print((json.load(sys.stdin).get("head_pipeline") or {}).get("status") or "")')
  case "${mstate:-}" in
    merged) msg="$NAME: bot MR merged ($murl), waiting for F-Droid to build + publish (usually 1-3 days)" ;;
    opened)
      if [ "$pipe" = failed ]; then
        msg="$NAME: bot MR pipeline FAILED - $murl"
        state=2
      else
        msg="$NAME: bot MR open ($murl, pipeline ${pipe:-pending})"
      fi
      ;;
    closed) msg="$NAME: bot MR was CLOSED without merge - $murl"; state=2 ;;
    *) msg="$NAME: checkupdates hasn't opened an MR yet (daily run around 06:00 UTC, tag foss-$NAME)" ;;
  esac
fi

echo "$msg"
if [ "${1:-}" = --notify ] && [ -x "$HOME/.local/bin/notify" ]; then
  prio=default
  [ $state = 2 ] && prio=high
  "$HOME/.local/bin/notify" "$msg" "OBS Blade F-Droid" "$prio"
fi
exit $state
