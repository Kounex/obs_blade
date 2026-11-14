#!/usr/bin/env bash
# Runs on the Hetzner VPS as root, fed over ssh by pull-vps-backups.sh:
#   ssh hetzner-vps bash -s -- <db path> < snapshot-remote.sh > copy.db.gz
# Takes a consistent copy of a live SQLite database (WAL mode, service
# running) with SQLite's backup API and writes it gzipped to stdout.
# Runs as the database's owner uid, so SQLite never creates root-owned
# -wal/-shm files the service could not open afterwards.
set -euo pipefail
db=$1
[ -f "$db" ] || { echo "no database at $db" >&2; exit 2; }
uid=$(stat -c %u "$db")
gid=$(stat -c %g "$db")
# Room for the copy (at most the database plus its WAL) and some margin,
# so a backup can never fill the VPS disk the services write to.
need_kb=$(( ( $(stat -c %s "$db") + $(stat -c %s "$db-wal" 2>/dev/null || echo 0) ) / 1024 + 262144 ))
free_kb=$(df -Pk /var/tmp | awk 'NR==2 {print $4}')
if [ "$free_kb" -lt "$need_kb" ]; then
  echo "only $((free_kb / 1024)) MB free in /var/tmp, need $((need_kb / 1024)) MB" >&2
  exit 3
fi
tmp=$(mktemp -d /var/tmp/obs-blade-backup.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
chown "$uid:$gid" "$tmp"
setpriv --reuid="$uid" --regid="$gid" --clear-groups \
  python3 -c '
import sqlite3, sys
src = sqlite3.connect(sys.argv[1], timeout=30)
dst = sqlite3.connect(sys.argv[2])
src.backup(dst)
dst.close()
src.close()
' "$db" "$tmp/copy.db"
gzip -c "$tmp/copy.db"
