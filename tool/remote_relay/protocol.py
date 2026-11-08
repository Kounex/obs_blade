"""Wire format between the relay and a bridge, and the close codes the app
sees. This module is the contract the bridge core (desktop/core) and the
app implement; README.md describes it in prose.

Bridge socket (one per bridge, carries all of its app sessions):

- Binary frames: ``[type u8][session u32 big-endian][payload]``.
  - ``OPEN``  relay → bridge: a phone connected. Payload: JSON
    ``{"device": id, "name": str}``. The bridge opens its own local
    websocket to OBS for this session.
  - ``DATA``  both ways: one end-to-end encrypted frame (a Noise
    transport message, or a handshake message), forwarded untouched to /
    from the phone's binary frames. The relay can't read it.
  - ``CLOSE`` both ways: the session ended. Payload: JSON
    ``{"code": int, "reason": str}`` (bridge → relay; the relay closes
    the phone's socket with that code) or empty (relay → bridge: the
    phone went away).
- Text frames: JSON control messages (``{"type": ...}``), see README.md.
"""

from __future__ import annotations

import struct

OPEN = 1
DATA = 2
CLOSE = 3

_HEADER = struct.Struct(">BI")
HEADER_SIZE = _HEADER.size
MAX_SESSION_ID = 0xFFFFFFFF


class FrameError(ValueError):
    pass


def pack(kind: int, session: int, payload: bytes = b"") -> bytes:
    return _HEADER.pack(kind, session) + payload


def unpack(frame: bytes) -> tuple[int, int, bytes]:
    if len(frame) < HEADER_SIZE:
        raise FrameError("short frame")
    kind, session = _HEADER.unpack_from(frame)
    if kind not in (OPEN, DATA, CLOSE):
        raise FrameError(f"unknown frame type {kind}")
    return kind, session, frame[HEADER_SIZE:]


# Close codes for the phone's socket. obs-websocket uses 4000-4012
# (WebSocketCloseCode in its protocol), so the relay's own reasons start
# at 4900 and never collide with a code OBS itself sent through.
BRIDGE_OFFLINE = 4900  # no bridge connected for this pairing
OBS_NOT_RUNNING = 4901  # bridge is up, OBS isn't
OBS_UNREACHABLE = 4902  # OBS runs, its websocket server is off / refused the bridge
PRO_REQUIRED = 4903  # entitlement missing or lapsed
UNPAIRED = 4904  # unknown / revoked app token, or wrong bridge
BRIDGE_OUTDATED = 4905  # bridge older than the relay's minimum
SESSION_REPLACED = 4906  # the same phone connected again
TOO_MANY_SESSIONS = 4907  # bridge already carries the maximum
BRIDGE_GONE = 4908  # bridge dropped mid-session; reconnecting may work
VERIFY_UNAVAILABLE = 4909  # Pro couldn't be checked right now; retry later
RATE_LIMITED = 4910
E2E_FAILED = 4911  # end-to-end handshake / frame failed (sent by the bridge or the app)

# Close codes a bridge may forward from OBS / its own session handling.
# Anything else becomes 1011 so a buggy bridge can't send reserved codes.
_FORWARDABLE = set(range(4000, 4100)) | {
    1000,
    1001,
    1003,
    1007,
    1008,
    1009,
    1011,
    OBS_NOT_RUNNING,
    OBS_UNREACHABLE,
    UNPAIRED,  # the bridge doesn't know this phone's end-to-end key
    E2E_FAILED,
}


def forwardable_code(code: object) -> int:
    if isinstance(code, int) and code in _FORWARDABLE:
        return code
    return 1011
