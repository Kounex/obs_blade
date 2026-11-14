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
