"""SQLite storage for the remote relay.

Tables:
- bridges: one per desktop install (plugin or standalone). Opaque token,
  stored hashed. Last status snapshot and OBS state for the app and,
  later, alerts.
- devices: one per paired phone / tablet. Opaque app token, stored hashed,
  the RevenueCat app user id the Pro check runs against.
- pairings: short-lived single-use codes (2 min). The app token is minted
  when the app collects a finished pairing, so no plaintext token is ever
  stored.
"""

from __future__ import annotations

import hashlib
import json
import secrets
import sqlite3
import time
from dataclasses import dataclass

SCHEMA = """
CREATE TABLE IF NOT EXISTS bridges (
    id TEXT PRIMARY KEY,
    token_hash TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL DEFAULT '',
    kind TEXT NOT NULL DEFAULT '',
    version TEXT NOT NULL DEFAULT '',
    created_at REAL NOT NULL,
    last_seen REAL NOT NULL,
    obs_state TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT '{}',
    status_at REAL NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS devices (
    id TEXT PRIMARY KEY,
    bridge_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL DEFAULT '',
    platform TEXT NOT NULL DEFAULT '',
    app_user_id TEXT NOT NULL,
    created_at REAL NOT NULL,
    last_used REAL NOT NULL
);
CREATE INDEX IF NOT EXISTS devices_bridge ON devices(bridge_id);
CREATE TABLE IF NOT EXISTS pairings (
    id_hash TEXT PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    app_user_id TEXT NOT NULL,
    device_name TEXT NOT NULL DEFAULT '',
    platform TEXT NOT NULL DEFAULT '',
    created_at REAL NOT NULL,
    expires_at REAL NOT NULL,
    bridge_id TEXT,
    device_id TEXT
);
"""

PAIRING_SECONDS = 120
# A redeemed pairing waits this long for the app to collect it.
COLLECT_SECONDS = 600
DEVICE_IDLE_SECONDS = 180 * 24 * 3600
BRIDGE_ORPHAN_SECONDS = 30 * 24 * 3600
MAX_DEVICES_PER_BRIDGE = 10
MAX_OPEN_PAIRINGS_PER_USER = 5

# Unambiguous on a phone keyboard and when read aloud (no 0/O, 1/I/L).
CODE_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"
CODE_LENGTH = 8


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def new_token() -> str:
    return secrets.token_urlsafe(32)


def new_id(prefix: str) -> str:
    return f"{prefix}_{secrets.token_urlsafe(12)}"


def new_code() -> str:
    return "".join(secrets.choice(CODE_ALPHABET) for _ in range(CODE_LENGTH))


def normalize_code(code: str) -> str:
    return "".join(ch for ch in code.upper() if ch.isalnum())


@dataclass
class Bridge:
    id: str
    name: str
    kind: str
    version: str
    created_at: float
    last_seen: float
    obs_state: str
    status: dict
    status_at: float


@dataclass
class Device:
    id: str
    bridge_id: str
    name: str
    platform: str
    app_user_id: str
    created_at: float
    last_used: float


@dataclass
class Pairing:
    code: str
    app_user_id: str
    device_name: str
    platform: str
    expires_at: float
    bridge_id: str | None
    device_id: str | None = None


class PairingError(Exception):
    """Redeem / collect refused. ``reason`` is the API error string."""

    def __init__(self, reason: str):
        super().__init__(reason)
        self.reason = reason


class Store:
    def __init__(self, path: str, clock=time.time):
        self._db = sqlite3.connect(path, isolation_level=None, check_same_thread=False)
        self._db.execute("PRAGMA journal_mode=WAL")
        self._db.execute("PRAGMA foreign_keys=ON")
        self._db.executescript(SCHEMA)
        columns = {row[1] for row in self._db.execute("PRAGMA table_info(pairings)")}
        if "device_id" not in columns:  # databases from before 0.0.4
            self._db.execute("ALTER TABLE pairings ADD COLUMN device_id TEXT")
        self._now = clock

    def close(self) -> None:
        self._db.close()

    def now(self) -> float:
        return self._now()

    # --- pairings -----------------------------------------------------

    def create_pairing(
        self, app_user_id: str, device_name: str, platform: str
    ) -> tuple[str, str]:
        """Returns (pairing_id, code). The pairing id is the app's secret
        to collect the result; only its hash is stored."""
        now = self._now()
        self._db.execute("DELETE FROM pairings WHERE expires_at < ?", (now,))
        open_count = self._db.execute(
            "SELECT COUNT(*) FROM pairings WHERE app_user_id = ? AND bridge_id IS NULL",
            (app_user_id,),
        ).fetchone()[0]
        if open_count >= MAX_OPEN_PAIRINGS_PER_USER:
            raise PairingError("too_many_pairings")
        pairing_id = new_token()
        while True:
            code = new_code()
            try:
                self._db.execute(
                    "INSERT INTO pairings (id_hash, code, app_user_id, device_name,"
                    " platform, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    (
                        hash_token(pairing_id),
                        code,
                        app_user_id,
                        device_name[:64],
                        platform[:16],
                        now,
                        now + PAIRING_SECONDS,
                    ),
                )
                return pairing_id, code
            except sqlite3.IntegrityError:
                continue  # code collision, draw again

    def redeem_pairing(
        self,
        code: str,
        bridge_token: str | None,
        name: str,
        kind: str,
        version: str,
    ) -> tuple[str, str | None, str]:
        """The bridge redeems a code. Returns (bridge_id, new bridge token
        or None when the bridge was already paired, the device id the app
        gets when it collects)."""
        now = self._now()
        row = self._db.execute(
            "SELECT id_hash, expires_at, bridge_id FROM pairings WHERE code = ?",
            (normalize_code(code),),
        ).fetchone()
        if row is None or row[1] < now or row[2] is not None:
            raise PairingError("invalid_code")
        token = None
        if bridge_token:
            bridge = self.bridge_by_token(bridge_token)
            if bridge is None:
                raise PairingError("unknown_bridge")
            bridge_id = bridge.id
            count = self._db.execute(
                "SELECT COUNT(*) FROM devices WHERE bridge_id = ?", (bridge_id,)
            ).fetchone()[0]
            if count >= MAX_DEVICES_PER_BRIDGE:
                raise PairingError("too_many_devices")
            self._db.execute(
                "UPDATE bridges SET name = ?, kind = ?, version = ?, last_seen = ?"
                " WHERE id = ?",
                (name[:64], kind[:16], version[:32], now, bridge_id),
            )
        else:
            bridge_id = new_id("b")
            token = new_token()
            self._db.execute(
                "INSERT INTO bridges (id, token_hash, name, kind, version, created_at,"
                " last_seen) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (bridge_id, hash_token(token), name[:64], kind[:16], version[:32], now, now),
            )
        # Single use: a second redeem of the same code sees bridge_id set.
        device_id = new_id("d")
        updated = self._db.execute(
            "UPDATE pairings SET bridge_id = ?, device_id = ?, expires_at = ?"
            " WHERE id_hash = ? AND bridge_id IS NULL",
            (bridge_id, device_id, now + COLLECT_SECONDS, row[0]),
        ).rowcount
        if updated != 1:
            if token is not None:
                self._db.execute("DELETE FROM bridges WHERE id = ?", (bridge_id,))
            raise PairingError("invalid_code")
        return bridge_id, token, device_id

    def pairing(self, pairing_id: str) -> Pairing | None:
        row = self._db.execute(
            "SELECT code, app_user_id, device_name, platform, expires_at, bridge_id,"
            " device_id FROM pairings WHERE id_hash = ?",
            (hash_token(pairing_id),),
        ).fetchone()
        if row is None or row[4] < self._now():
            return None
        return Pairing(*row)

    def collect_pairing(self, pairing_id: str) -> tuple[Device, str]:
        """The app collects a redeemed pairing: creates the device and
        returns it with its app token (shown once)."""
        pairing = self.pairing(pairing_id)
        if pairing is None:
            raise PairingError("unknown_pairing")
        if pairing.bridge_id is None:
            raise PairingError("waiting")
        deleted = self._db.execute(
            "DELETE FROM pairings WHERE id_hash = ?", (hash_token(pairing_id),)
        ).rowcount
        if deleted != 1:
            raise PairingError("unknown_pairing")
        now = self._now()
        token = new_token()
        device = Device(
            id=pairing.device_id or new_id("d"),
            bridge_id=pairing.bridge_id,
            name=pairing.device_name,
            platform=pairing.platform,
            app_user_id=pairing.app_user_id,
            created_at=now,
            last_used=now,
        )
        self._db.execute(
            "INSERT INTO devices (id, bridge_id, token_hash, name, platform,"
            " app_user_id, created_at, last_used) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (
                device.id,
                device.bridge_id,
                hash_token(token),
                device.name,
                device.platform,
                device.app_user_id,
                now,
                now,
            ),
        )
        return device, token

    # --- bridges ------------------------------------------------------

    def _bridge(self, where: str, value: str) -> Bridge | None:
        row = self._db.execute(
            "SELECT id, name, kind, version, created_at, last_seen, obs_state,"
            f" status, status_at FROM bridges WHERE {where} = ?",
            (value,),
        ).fetchone()
        if row is None:
            return None
        return Bridge(*row[:7], json.loads(row[7] or "{}"), row[8])

    def bridge(self, bridge_id: str) -> Bridge | None:
        return self._bridge("id", bridge_id)

    def bridge_by_token(self, token: str) -> Bridge | None:
        return self._bridge("token_hash", hash_token(token))

    def bridge_connected(self, bridge_id: str, name: str, kind: str, version: str) -> None:
        self._db.execute(
            "UPDATE bridges SET name = COALESCE(NULLIF(?, ''), name), kind = ?,"
            " version = ?, last_seen = ? WHERE id = ?",
            (name[:64], kind[:16], version[:32], self._now(), bridge_id),
        )

    def bridge_seen(self, bridge_id: str) -> None:
        self._db.execute(
            "UPDATE bridges SET last_seen = ? WHERE id = ?", (self._now(), bridge_id)
        )

    def set_obs_state(self, bridge_id: str, state: str) -> None:
        self._db.execute(
            "UPDATE bridges SET obs_state = ?, last_seen = ? WHERE id = ?",
            (state[:16], self._now(), bridge_id),
        )

    def set_status(self, bridge_id: str, status: dict) -> None:
        now = self._now()
        self._db.execute(
            "UPDATE bridges SET status = ?, status_at = ?, last_seen = ? WHERE id = ?",
            (json.dumps(status, separators=(",", ":")), now, now, bridge_id),
        )

    def delete_bridge(self, bridge_id: str) -> list[str]:
        """Removes the bridge and its devices; returns the device ids."""
        ids = [
            row[0]
            for row in self._db.execute(
                "SELECT id FROM devices WHERE bridge_id = ?", (bridge_id,)
            )
        ]
        self._db.execute("DELETE FROM devices WHERE bridge_id = ?", (bridge_id,))
        self._db.execute("DELETE FROM pairings WHERE bridge_id = ?", (bridge_id,))
        self._db.execute("DELETE FROM bridges WHERE id = ?", (bridge_id,))
        return ids

    # --- devices ------------------------------------------------------

    def device_by_token(self, token: str) -> Device | None:
        row = self._db.execute(
            "SELECT id, bridge_id, name, platform, app_user_id, created_at, last_used"
            " FROM devices WHERE token_hash = ?",
            (hash_token(token),),
        ).fetchone()
        return Device(*row) if row else None

    def devices(self, bridge_id: str) -> list[Device]:
        return [
            Device(*row)
            for row in self._db.execute(
                "SELECT id, bridge_id, name, platform, app_user_id, created_at,"
                " last_used FROM devices WHERE bridge_id = ? ORDER BY created_at",
                (bridge_id,),
            )
        ]

    def device_used(self, device_id: str, app_user_id: str | None = None) -> None:
        if app_user_id:
            self._db.execute(
                "UPDATE devices SET last_used = ?, app_user_id = ? WHERE id = ?",
                (self._now(), app_user_id[:128], device_id),
            )
        else:
            self._db.execute(
                "UPDATE devices SET last_used = ? WHERE id = ?", (self._now(), device_id)
            )

    def delete_device(self, device_id: str, bridge_id: str) -> bool:
        return (
            self._db.execute(
                "DELETE FROM devices WHERE id = ? AND bridge_id = ?",
                (device_id, bridge_id),
            ).rowcount
            == 1
        )

    # --- housekeeping -------------------------------------------------

    def purge(self) -> list[str]:
        """Drops expired pairings, devices idle for 180 days and bridges
        with no devices left for 30 days. Returns removed device ids."""
        now = self._now()
        self._db.execute("DELETE FROM pairings WHERE expires_at < ?", (now,))
        stale = [
            row[0]
            for row in self._db.execute(
                "SELECT id FROM devices WHERE last_used < ?", (now - DEVICE_IDLE_SECONDS,)
            )
        ]
        self._db.execute(
            "DELETE FROM devices WHERE last_used < ?", (now - DEVICE_IDLE_SECONDS,)
        )
        self._db.execute(
            "DELETE FROM bridges WHERE last_seen < ? AND id NOT IN"
            " (SELECT bridge_id FROM devices) AND id NOT IN"
            " (SELECT bridge_id FROM pairings WHERE bridge_id IS NOT NULL)",
            (now - BRIDGE_ORPHAN_SECONDS,),
        )
        return stale

    def counts(self) -> tuple[int, int, int]:
        return tuple(
            self._db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            for table in ("bridges", "devices", "pairings")
        )
