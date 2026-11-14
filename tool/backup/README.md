# VPS database backups

The relay services on the Hetzner VPS keep their state in SQLite on the VPS
disk only. `pull-vps-backups.sh` copies it to the NAS once a night.

| Service | Database on the VPS | Why it matters |
|---|---|---|
| `remote-relay` | `/var/lib/remote-relay/relay.db` (uid 65532) | every remote access pairing; without it every Pro user sets remote access up again on their local network |
| `kick-events` | `/var/lib/kick-events/relay.db` (uid 65531) | activity feed sessions, subscriptions, last 7 days of events |

`kick-auth` keeps nothing on disk.

## How it runs

- NAS systemd **user** timer `obs-blade-vps-backups.timer`, 04:30 (+ up to
  5 min). Units in `systemd/`, installed by copying them to
  `~/.config/systemd/user/` and `systemctl --user enable --now
  obs-blade-vps-backups.timer`.
- `snapshot-remote.sh` is piped to the VPS over `ssh hetzner-vps` and takes
  the copy with SQLite's backup API while the service keeps running. It
  runs as the database owner's uid, so it never leaves root-owned
  `-wal`/`-shm` files behind.
- The NAS checks each copy (`PRAGMA integrity_check`, the main table can be
  read) before keeping it as
  `/volume1/docker/obs-blade-backups/<service>/<service>-<date>.db.gz`
  (`700`), 30 days. A failed copy pushes an ntfy alert.
- Run it by hand: `systemctl --user start obs-blade-vps-backups.service`,
  log in `journalctl --user -u obs-blade-vps-backups`.

## Restore

Pairings and sessions created after the backup are lost; those devices set
up remote access again. Example for `remote-relay` (kick-events: uid 65531,
`/var/lib/kick-events`):

```bash
gunzip -c /volume1/docker/obs-blade-backups/remote-relay/remote-relay-<date>.db.gz \
  | ssh hetzner-vps 'cat > /var/tmp/relay-restore.db'
ssh hetzner-vps '
  set -e
  systemctl stop remote-relay
  keep=/root/fleet-backups/remote-relay-$(date +%F-%H%M)
  mkdir -p "$keep" && mv /var/lib/remote-relay/relay.db* "$keep"/
  install -o 65532 -g 65532 -m 644 /var/tmp/relay-restore.db /var/lib/remote-relay/relay.db
  rm /var/tmp/relay-restore.db
  systemctl start remote-relay
  systemctl is-active remote-relay'
```

The replaced files stay in `/root/fleet-backups/` until you delete them.
