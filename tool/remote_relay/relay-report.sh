#!/usr/bin/env bash
# Relay traffic report from the VPS journal: bridge link ends (why, how long
# they held), phone sessions, pairings. Read-only.
#
#   tool/remote_relay/relay-report.sh                      # since the 0.0.11 deploy
#   tool/remote_relay/relay-report.sh --since "2026-11-20 00:49" [--notify]
#
# --notify pushes the summary (NAS ntfy helper). The bridge-end and expired-
# pairing lines exist since relay 0.0.11; the rest since 0.0.7.
set -euo pipefail

since="2026-11-20 00:49:30"
notify=0
while [ $# -gt 0 ]; do
  case "$1" in
    --since) since="$2"; shift 2 ;;
    --notify) notify=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 64 ;;
  esac
done

journal=$(ssh -o ConnectTimeout=15 hetzner-vps \
  "journalctl -u remote-relay --since '$since UTC' --no-pager -o short-iso" \
  | { grep -v 'GET /health ' || true; })

report=$(SINCE="$since" python3 -c '
import os, re, statistics, sys
from collections import Counter, defaultdict

lines = sys.stdin.read().splitlines()
bridge_re = re.compile(r"bridge (\S+) \((\S+) (\S+)\) end after (\d+)s: (.*?) \| quiet (\d+)s, sessions dropped (\d+)")
session_re = re.compile(r"session \d+ end after (\d+)s: (.*?) \| down (\d+) KB, up (\d+) KB")
expired_re = re.compile(r"pairing from (\S+) expired: (.*?) \(created")
access_re = re.compile(r"INFO (GET|POST|PATCH|DELETE) (/v1/[a-z/]+?)(?:/[A-Za-z0-9_-]{8,}[^ ]*)? (\d{3})$")

bridges = defaultdict(list)
sessions, expired, problems = [], [], []
calls = Counter()
for line in lines:
    if m := bridge_re.search(line):
        bridges[(m[1], m[2], m[3])].append((int(m[4]), m[5], int(m[6]), int(m[7]), line[11:16]))
    elif m := session_re.search(line):
        sessions.append((int(m[1]), m[2], int(m[3]), int(m[4])))
    elif m := expired_re.search(line):
        expired.append((m[1], m[2]))
    elif m := access_re.search(line):
        calls[f"{m[1]} {m[2]} {m[3]}"] += 1
    elif " WARNING " in line or " ERROR " in line or "Traceback" in line:
        problems.append(line[:200])

def span(s):
    return f"{s // 3600}h{s % 3600 // 60:02d}m" if s >= 3600 else f"{s // 60}m{s % 60:02d}s"

def buckets(held):
    edges = [(60, "<1m"), (600, "1-10m"), (3600, "10-60m"), (10**9, ">1h")]
    out = Counter()
    for h in held:
        out[next(name for edge, name in edges if h < edge)] += 1
    return ", ".join(f"{name} {out[name]}" for _, name in edges if out[name])

since = os.environ["SINCE"]
out = [f"Relay since {since} UTC"]
if not bridges:
    out.append("Bridges: no link ended")
for (bid, kind, version), ends in sorted(bridges.items(), key=lambda kv: -len(kv[1])):
    held = [e[0] for e in ends]
    quiet = [e[2] for e in ends]
    out.append(f"Bridge {bid} ({kind} {version}): {len(ends)} link ends, held median {span(int(statistics.median(held)))} ({buckets(held)})")
    out.append("  why: " + ", ".join(f"{r} x{n}" for r, n in Counter(e[1] for e in ends).most_common()))
    out.append(f"  quiet before end: median {statistics.median(quiet):.0f}s, max {max(quiet)}s; sessions dropped {sum(e[3] for e in ends)}")
    minutes = Counter(e[4][3:5] for e in ends).most_common(3)
    out.append("  most common minute past the hour: " + ", ".join(f":{m} x{n}" for m, n in minutes))
out.append(f"Phone sessions: {len(sessions)}" + (
    f", total {span(sum(s[0] for s in sessions))}, down {sum(s[2] for s in sessions) // 1024} MB, up {sum(s[3] for s in sessions) // 1024} MB; ends: "
    + ", ".join(f"{r} x{n}" for r, n in Counter(s[1] for s in sessions).most_common(5)) if sessions else ""))
pair = {k: v for k, v in calls.items() if "/v1/pairings" in k and "collect" not in k}
out.append("Pairings: " + (", ".join(f"{k.split(None, 1)[1]} x{v}" for k, v in sorted(pair.items())) or "none"))
if expired:
    out.append("  expired: " + ", ".join(f"{p} {why} x{n}" for (p, why), n in Counter(expired).most_common()))
other = Counter({k: v for k, v in calls.items() if "/v1/pairings" not in k})
if other:
    out.append("Other calls: " + ", ".join(f"{k} x{v}" for k, v in other.most_common(8)))
out.append(f"Warnings/errors: {len(problems)}")
out += ["  " + p for p in problems[:5]]
print("\n".join(out))
' <<<"$journal")

echo "$report"
if [ "$notify" = 1 ] && [ -x "$HOME/.local/bin/notify" ]; then
  "$HOME/.local/bin/notify" "$report" "OBS Blade relay report" default
fi
