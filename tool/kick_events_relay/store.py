"""SQLite storage for the relay.

Tables: broadcasters (channels with at least one app session), sessions
(opaque app tokens, stored hashed), subscriptions (Kick webhook
subscription ids), events (verified webhook deliveries, 7 days).
Nothing here holds a Kick user token.
"""

from __future__ import annotations

import hashlib
import json
import secrets
import sqlite3
import time
from dataclasses import dataclass

SCHEMA = """
CREATE TABLE IF NOT EXISTS broadcasters (
    user_id INTEGER PRIMARY KEY,
    username TEXT NOT NULL DEFAULT '',
    created_at REAL NOT NULL,
    last_seen REAL NOT NULL
);
CREATE TABLE IF NOT EXISTS sessions (
    token_hash TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    created_at REAL NOT NULL,
    last_used REAL NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_user ON sessions(user_id);
CREATE TABLE IF NOT EXISTS subscriptions (
    id TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    event TEXT NOT NULL,
    version INTEGER NOT NULL,
    created_at REAL NOT NULL
);
CREATE INDEX IF NOT EXISTS subscriptions_user ON subscriptions(user_id);
CREATE TABLE IF NOT EXISTS events (
    seq INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id TEXT NOT NULL UNIQUE,
    user_id INTEGER NOT NULL,
    type TEXT NOT NULL,
    version TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    payload TEXT NOT NULL,
    received_at REAL NOT NULL
);
CREATE INDEX IF NOT EXISTS events_user_seq ON events(user_id, seq);
"""

EVENT_RETENTION_SECONDS = 7 * 24 * 3600
SESSION_IDLE_SECONDS = 30 * 24 * 3600


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


@dataclass
class StoredEvent:
    seq: int
    message_id: str
    user_id: int
    type: str
    version: str
    timestamp: str
    payload: dict

    def to_wire(self) -> dict:
        return {
            "seq": self.seq,
            "message_id": self.message_id,
            "event_type": self.type,
            "event_version": self.version,
            "timestamp": self.timestamp,
            "payload": self.payload,
        }


class Store:
    def __init__(self, path: str):
        self._db = sqlite3.connect(path, isolation_level=None)
        self._db.execute("PRAGMA journal_mode=WAL")
        self._db.execute("PRAGMA synchronous=NORMAL")
        self._db.executescript(SCHEMA)

    def close(self) -> None:
        self._db.close()

    # Broadcasters / sessions

    def create_session(
        self, user_id: int, username: str, now: float | None = None
    ) -> str:
        moment = time.time() if now is None else now
        token = secrets.token_urlsafe(32)
        with self._db:
            self._db.execute(
                "INSERT INTO broadcasters(user_id, username, created_at, last_seen)"
                " VALUES (?, ?, ?, ?)"
                " ON CONFLICT(user_id) DO UPDATE SET"
                " username = excluded.username, last_seen = excluded.last_seen",
                (user_id, username, moment, moment),
            )
            self._db.execute(
                "INSERT INTO sessions(token_hash, user_id, created_at, last_used)"
                " VALUES (?, ?, ?, ?)",
                (hash_token(token), user_id, moment, moment),
            )
        return token

    def session_user(self, token: str, now: float | None = None) -> int | None:
        """The session's broadcaster, touching its last use. None if unknown."""
        if not token or len(token) > 256:
            return None
        moment = time.time() if now is None else now
        row = self._db.execute(
            "SELECT user_id, last_used FROM sessions WHERE token_hash = ?",
            (hash_token(token),),
        ).fetchone()
        if row is None:
            return None
        user_id, last_used = row
        if moment - last_used > SESSION_IDLE_SECONDS:
            self._db.execute(
                "DELETE FROM sessions WHERE token_hash = ?", (hash_token(token),)
            )
            return None
        # Touch at most every 10 min - keeps writes down on busy sockets.
        if moment - last_used > 600:
            with self._db:
                self._db.execute(
                    "UPDATE sessions SET last_used = ? WHERE token_hash = ?",
                    (moment, hash_token(token)),
                )
                self._db.execute(
                    "UPDATE broadcasters SET last_seen = ? WHERE user_id = ?",
                    (moment, user_id),
                )
        return user_id

    def delete_session(self, token: str) -> int | None:
        """Remove a session. Returns its broadcaster when it was the last one."""
        row = self._db.execute(
            "SELECT user_id FROM sessions WHERE token_hash = ?",
            (hash_token(token),),
        ).fetchone()
        if row is None:
            return None
        user_id = row[0]
        self._db.execute(
            "DELETE FROM sessions WHERE token_hash = ?", (hash_token(token),)
        )
        remaining = self._db.execute(
            "SELECT COUNT(*) FROM sessions WHERE user_id = ?", (user_id,)
        ).fetchone()[0]
        return user_id if remaining == 0 else None

    def is_registered(self, user_id: int) -> bool:
        return (
            self._db.execute(
                "SELECT 1 FROM sessions WHERE user_id = ? LIMIT 1", (user_id,)
            ).fetchone()
            is not None
        )

    def registered_broadcasters(self) -> list[int]:
        return [
            row[0]
            for row in self._db.execute("SELECT DISTINCT user_id FROM sessions")
        ]

    def forget_broadcaster(self, user_id: int) -> None:
        """Drop everything kept for a channel (events, subscriptions, row)."""
        with self._db:
            self._db.execute("DELETE FROM events WHERE user_id = ?", (user_id,))
            self._db.execute(
                "DELETE FROM subscriptions WHERE user_id = ?", (user_id,)
            )
            self._db.execute("DELETE FROM sessions WHERE user_id = ?", (user_id,))
            self._db.execute(
                "DELETE FROM broadcasters WHERE user_id = ?", (user_id,)
            )

    # Subscriptions

    def subscriptions_of(self, user_id: int) -> dict[str, str]:
        """event name -> subscription id"""
        return {
            event: sub_id
            for sub_id, event in self._db.execute(
                "SELECT id, event FROM subscriptions WHERE user_id = ?", (user_id,)
            )
        }

    def replace_subscriptions(
        self, user_id: int, subscriptions: dict[str, tuple[str, int]], now=None
    ) -> None:
        """Set a channel's subscriptions: event -> (id, version)."""
        moment = time.time() if now is None else now
        with self._db:
            self._db.execute(
                "DELETE FROM subscriptions WHERE user_id = ?", (user_id,)
            )
            self._db.executemany(
                "INSERT OR REPLACE INTO subscriptions"
                "(id, user_id, event, version, created_at) VALUES (?, ?, ?, ?, ?)",
                [
                    (sub_id, user_id, event, version, moment)
                    for event, (sub_id, version) in subscriptions.items()
                ],
            )

    # Events

    def add_event(
        self,
        message_id: str,
        user_id: int,
        event_type: str,
        version: str,
        timestamp: str,
        payload: dict,
        now: float | None = None,
    ) -> StoredEvent | None:
        """Insert a delivery. None when the message id was seen already."""
        moment = time.time() if now is None else now
        cursor = self._db.execute(
            "INSERT OR IGNORE INTO events"
            "(message_id, user_id, type, version, timestamp, payload, received_at)"
            " VALUES (?, ?, ?, ?, ?, ?, ?)",
            (
                message_id,
                user_id,
                event_type,
                version,
                timestamp,
                json.dumps(payload, separators=(",", ":")),
                moment,
            ),
        )
        if cursor.rowcount == 0:
            return None
        return StoredEvent(
            seq=cursor.lastrowid,
            message_id=message_id,
            user_id=user_id,
            type=event_type,
            version=version,
            timestamp=timestamp,
            payload=payload,
        )

    def events_after(
        self, user_id: int, after: int, limit: int = 500
    ) -> list[StoredEvent]:
        rows = self._db.execute(
            "SELECT seq, message_id, user_id, type, version, timestamp, payload"
            " FROM events WHERE user_id = ? AND seq > ? ORDER BY seq LIMIT ?",
            (user_id, after, limit),
        ).fetchall()
        return [
            StoredEvent(
                seq=row[0],
                message_id=row[1],
                user_id=row[2],
                type=row[3],
                version=row[4],
                timestamp=row[5],
                payload=json.loads(row[6]),
            )
            for row in rows
        ]

    def latest_seq(self, user_id: int) -> int:
        row = self._db.execute(
            "SELECT MAX(seq) FROM events WHERE user_id = ?", (user_id,)
        ).fetchone()
        return row[0] or 0

    # Housekeeping

    def purge(self, now: float | None = None) -> list[int]:
        """Drop old events and idle sessions. Returns channels left without
        any session (the caller unsubscribes them, then forgets them)."""
        moment = time.time() if now is None else now
        with self._db:
            self._db.execute(
                "DELETE FROM events WHERE received_at < ?",
                (moment - EVENT_RETENTION_SECONDS,),
            )
            self._db.execute(
                "DELETE FROM sessions WHERE last_used < ?",
                (moment - SESSION_IDLE_SECONDS,),
            )
        return [
            row[0]
            for row in self._db.execute(
                "SELECT user_id FROM broadcasters WHERE user_id NOT IN"
                " (SELECT DISTINCT user_id FROM sessions)"
            )
        ]
