#!/usr/bin/env bash
# Copy the OBS Blade backend databases from the Hetzner VPS to the NAS.
#
# remote-relay's relay.db holds every remote access pairing (bridges and
# paired devices): losing it means every Pro user sets remote access up
# again on their local network. kick-events' relay.db holds the activity
# feed sessions and the last 7 days of events. Both live only on the VPS
# disk, so once a night (systemd user timer obs-blade-vps-backups.timer on
# the NAS, systemd/ next to this script) this takes a consistent snapshot of
# each (snapshot-remote.sh, SQLite's backup API, service keeps running),
# checks it opens and passes integrity_check, and keeps it KEEP_DAYS days in
# $DEST/<service>/. Tokens are stored hashed, but keep the folder private.
# Pushes an ntfy alert (~/.local/bin/notify) when a copy fails.
# Restore: README.md next to this script.
set -uo pipefail

DEST="${DEST:-/volume1/docker/obs-blade-backups}"
KEEP_DAYS="${KEEP_DAYS:-30}"
HOST="${HOST:-hetzner-vps}"
here=$(cd "$(dirname "$0")" && pwd)

# service | database on the VPS | table that must exist in the copy
DBS="
remote-relay|/var/lib/remote-relay/relay.db|devices
kick-events|/var/lib/kick-events/relay.db|events
"

alert() { ~/.local/bin/notify "$1" "OBS Blade backups" high || true; echo "ALERT: $1" >&2; }
failed=0
umask 077
stamp=$(date +%Y-%m-%d)

while IFS='|' read -r name db table; do
  [ -n "$name" ] || continue
  dir="$DEST/$name"
  mkdir -p "$dir" && chmod 700 "$DEST" "$dir"
  out="$dir/$name-$stamp.db.gz"
  part="$dir/.$name-$stamp.part"
  if ssh -o BatchMode=yes -o ConnectTimeout=20 "$HOST" bash -s -- "$db" \
       <"$here/snapshot-remote.sh" >"$part" &&
     python3 - "$part" "$table" <<'PY'
import gzip, os, sqlite3, sys, tempfile
part, table = sys.argv[1], sys.argv[2]
fd, path = tempfile.mkstemp(dir=os.path.dirname(part), prefix=".check-")
try:
    with os.fdopen(fd, "wb") as f, gzip.open(part) as g:
        f.write(g.read())
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
    echo "$name: saved $(basename "$out") ($(du -h "$out" | cut -f1))"
  else
    rm -f "$part"
    alert "$name: backing up $db from $HOST failed."
    failed=1
  fi
  find "$dir" -maxdepth 1 -type f -name "$name-*.db.gz" -mtime +"$KEEP_DAYS" -print -delete
done <<<"$DBS"
exit "$failed"
