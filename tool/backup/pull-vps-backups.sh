#!/usr/bin/env bash
# Copy the OBS Blade backend databases from the Hetzner VPS to the NAS.
#
# remote-relay's relay.db holds every remote access pairing (bridges and
# paired devices): losing it means every Pro user sets remote access up
# again on their local network. kick-events' relay.db holds the activity
# feed sessions and the last 7 days of events. Both live only on the VPS
# disk, so every 6 hours (systemd user timer obs-blade-vps-backups.timer on
# the NAS, systemd/ next to this script) this takes a consistent snapshot of
# each (snapshot-remote.sh, SQLite's backup API, service keeps running),
# checks it opens and passes integrity_check, and keeps it under
# $DEST/<service>/ by the retention below. Tokens are stored hashed, but
# keep the folder private. Pushes an ntfy alert (~/.local/bin/notify) when a
# copy fails, a copy is unexpectedly big, or the NAS is low on space.
# Restore: README.md next to this script.
set -uo pipefail

DEST="${DEST:-/volume1/docker/obs-blade-backups}"
HOST="${HOST:-hetzner-vps}"
MIN_FREE_GB="${MIN_FREE_GB:-20}"   # NAS: skip the run below this
MAX_COPY_MB="${MAX_COPY_MB:-200}"  # alert above this (still kept)
here=$(cd "$(dirname "$0")" && pwd)

# service | database on the VPS | table that must exist in the copy |
# retention: every copy for H hours, then the newest per day for D days,
# per ISO week for W weeks, per month for M months
DBS="
remote-relay|/var/lib/remote-relay/relay.db|devices|48|14|8|12
kick-events|/var/lib/kick-events/relay.db|events|48|7|4|0
"

alert() { ~/.local/bin/notify "$1" "OBS Blade backups" high || true; echo "ALERT: $1" >&2; }
failed=0
umask 077
mkdir -p "$DEST" && chmod 700 "$DEST"

free_gb=$(( $(df -Pk "$DEST" | awk 'NR==2 {print $4}') / 1024 / 1024 ))
if [ "$free_gb" -lt "$MIN_FREE_GB" ]; then
  alert "only ${free_gb} GB free on $(df -P "$DEST" | awk 'NR==2 {print $6}'), skipped the backup (needs ${MIN_FREE_GB} GB)."
  exit 1
fi

stamp=$(date +%Y-%m-%d_%H%M)
while IFS='|' read -r name db table hours days weeks months; do
  [ -n "$name" ] || continue
  dir="$DEST/$name"
  mkdir -p "$dir" && chmod 700 "$dir"
  out="$dir/$name-$stamp.db.gz"
  part="$dir/.$name-$stamp.part"
  if ssh -o BatchMode=yes -o ConnectTimeout=20 "$HOST" bash -s -- "$db" \
       <"$here/snapshot-remote.sh" >"$part" &&
     python3 - "$part" "$table" <<'PY'
import gzip, os, shutil, sqlite3, sys, tempfile
part, table = sys.argv[1], sys.argv[2]
fd, path = tempfile.mkstemp(dir=os.path.dirname(part), prefix=".check-")
try:
    with os.fdopen(fd, "wb") as f, gzip.open(part) as g:
        shutil.copyfileobj(g, f)
    db = sqlite3.connect(path)
    assert db.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    rows = db.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
    db.close()
    print(f"{table}: {rows} rows")
finally:
    os.unlink(path)
PY
  then
    mv "$part" "$out"
    size_mb=$(( $(stat -c %s "$out") / 1024 / 1024 ))
    echo "$name: saved $(basename "$out") ($(du -h "$out" | cut -f1))"
    if [ "$size_mb" -gt "$MAX_COPY_MB" ]; then
      alert "$name: backup is ${size_mb} MB (limit ${MAX_COPY_MB} MB) - check what grows in $db."
    fi
  else
    rm -f "$part"
    alert "$name: backing up $db from $HOST failed."
    failed=1
  fi
  python3 "$here/prune.py" "$dir" "$name" "$hours" "$days" "$weeks" "$months"
done <<<"$DBS"
exit "$failed"
