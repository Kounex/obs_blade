#!/usr/bin/env bash
# Relay traffic report from the VPS journal: bridge link ends (why, how long
# they held), phone sessions, pairings. Read-only.
#
#   tool/remote_relay/relay-report.sh                      # since the 0.0.11 deploy
#   tool/remote_relay/relay-report.sh --since "2026-11-20 00:49" [--notify]
#
# --notify pushes the summary (NAS ntfy helper). The bridge-end and expired-
# pairing lines exist since relay 0.0.11; OBS state changes, Start OBS
# outcomes, refused phones and the last frame before a link end since
# 0.0.13 (the session-end OBS state since 0.0.14); the rest since 0.0.7.
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
bridge_re = re.compile(r"bridge (\S+) \((\S+) (\S+)\) end after (\d+)s: (.*?) \| quiet (\d+)s(?: after (\S+))?, sessions dropped (\d+)")
obs_re = re.compile(r"bridge (\S+) obs (\S+) -> (\S+)(?: \| (\d+)s after start_obs)?$")
asked_re = re.compile(r"bridge (\S+) start_obs asked \| obs (\S+)$")
gave_up_re = re.compile(r"bridge (\S+) start_obs: no OBS start seen (\d+)s later \| obs (.*)$")
refused_re = re.compile(r"app refused for bridge (\S+): (\d+) (.*)$")
session_re = re.compile(r"session \d+ end after (\d+)s: (.*?) \| down (\d+) KB, up (\d+) KB.*?(?:\| bridge (\S+) obs (\S+))?$")
expired_re = re.compile(r"pairing from (\S+) expired: (.*?) \(created")
started_re = re.compile(r"container start .*image=ghcr\.io/kounex/remote-relay:([^,]+),")
access_re = re.compile(r"INFO (GET|POST|PATCH|DELETE) (/v1/\S+) (\d{3})$")

bridges = defaultdict(list)
versions = {}
obs_changes, starts = defaultdict(list), defaultdict(list)
sessions, expired, refused, restarts, problems = [], [], [], [], []
calls = Counter()
mismatch = Counter()
for line in lines:
    if m := bridge_re.search(line):
        bridges[m[1]].append((int(m[4]), m[5], int(m[6]), m[7], int(m[8]), line[11:16]))
        versions[m[1]] = f"{m[2]} {m[3]}"
    elif m := obs_re.search(line):
        obs_changes[m[1]].append(f"{m[2]} -> {m[3]}")
        if m[4] is not None:
            starts[m[1]].append(f"running after {m[4]}s")
    elif m := asked_re.search(line):
        starts[m[1]].append(f"asked (obs {m[2]})")
    elif m := gave_up_re.search(line):
        starts[m[1]].append(f"no OBS start seen {m[2]}s later (obs {m[3]})")
    elif m := refused_re.search(line):
        refused.append(f"{m[2]} {m[3]}")
    elif m := session_re.search(line):
        sessions.append((int(m[1]), m[2], int(m[3]), int(m[4])))
        if m[5] and "obs not running" in m[2] and m[6] == "running":
            # its process check said no while its OBS connection is up
            mismatch[m[5]] += 1
    elif m := expired_re.search(line):
        expired.append((m[1], m[2]))
    elif m := started_re.search(line):
        restarts.append(f"{line[:10]} {line[11:16]} {m[1]}")
    elif m := access_re.search(line):
        # ids out: one line per route, start-obs apart from the status reads
        path = re.sub(r"/[a-z]_[A-Za-z0-9_-]{8,}", "/{id}", m[2].split("?")[0])
        calls[f"{m[1]} {path} {m[3]}"] += 1
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

def counted(items):
    return ", ".join(f"{k} x{n}" for k, n in Counter(items).most_common())

since = os.environ["SINCE"]
out = [f"Relay since {since} UTC"]
if restarts:
    out.append(f"Relay (re)starts: {len(restarts)} (" + "; ".join(restarts) + ")")
ids = sorted(set(bridges) | set(obs_changes) | set(starts) | set(mismatch), key=lambda b: -len(bridges.get(b, [])))
if not ids:
    out.append("Bridges: no link ended")
for bid in ids:
    ends = bridges.get(bid, [])
    if not ends:
        out.append(f"Bridge {bid}: no link ended")
    else:
        held = [e[0] for e in ends]
        quiet = [e[2] for e in ends]
        out.append(f"Bridge {bid} ({versions[bid]}): {len(ends)} link ends, held median {span(int(statistics.median(held)))} ({buckets(held)})")
        out.append("  why: " + counted(e[1] for e in ends))
        out.append(f"  quiet before end: median {statistics.median(quiet):.0f}s, max {max(quiet)}s; sessions dropped {sum(e[4] for e in ends)}")
        timeouts = [e for e in ends if e[1] == "error TimeoutError" and e[3]]
        if timeouts:
            # A keepalive timeout needs 30 s without a frame: quiet near 0
            # here would mean frames still came in
            out.append(f"  keepalive timeouts: quiet median {statistics.median(e[2] for e in timeouts):.0f}s, last frame " + counted(e[3] for e in timeouts))
        minutes = Counter(e[5][3:5] for e in ends).most_common(3)
        out.append("  most common minute past the hour: " + ", ".join(f":{m} x{n}" for m, n in minutes))
    if obs_changes.get(bid):
        out.append("  OBS: " + counted(obs_changes[bid]))
    if starts.get(bid):
        out.append("  Start OBS: " + "; ".join(starts[bid]))
    if mismatch.get(bid):
        out.append(f"  phones told OBS not running while the bridge reports it running: {mismatch[bid]}")
out.append(f"Phone sessions: {len(sessions)}" + (
    f", total {span(sum(s[0] for s in sessions))}, down {sum(s[2] for s in sessions) // 1024} MB, up {sum(s[3] for s in sessions) // 1024} MB; ends: "
    + ", ".join(f"{r} x{n}" for r, n in Counter(s[1] for s in sessions).most_common(5)) if sessions else ""))
if refused:
    out.append("  phones refused: " + counted(refused))
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
