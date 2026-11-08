//! Frames between bridge and relay; mirror of `tool/remote_relay/protocol.py`.

pub const OPEN: u8 = 1;
pub const DATA: u8 = 2;
pub const CLOSE: u8 = 3;

/// Close codes the bridge sends for a session (relay README).
pub const OBS_NOT_RUNNING: u16 = 4901;
pub const OBS_UNREACHABLE: u16 = 4902;
/// The phone's end-to-end key isn't paired with this bridge: the app
/// forgets the pairing (same code as the relay's "unpaired").
pub const UNKNOWN_DEVICE: u16 = 4904;
/// The end-to-end handshake or a frame failed (a wrong bridge key on the
/// phone, tampering): set up again.
pub const E2E_FAILED: u16 = 4911;
/// obs-websocket's AuthenticationFailed.
pub const OBS_AUTH_FAILED: u16 = 4009;

pub fn pack(kind: u8, session: u32, payload: &[u8]) -> Vec<u8> {
    let mut frame = Vec::with_capacity(5 + payload.len());
    frame.push(kind);
    frame.extend_from_slice(&session.to_be_bytes());
    frame.extend_from_slice(payload);
    frame
}

pub fn unpack(frame: &[u8]) -> Option<(u8, u32, &[u8])> {
    if frame.len() < 5 || !(OPEN..=CLOSE).contains(&frame[0]) {
        return None;
    }
    let session = u32::from_be_bytes([frame[1], frame[2], frame[3], frame[4]]);
    Some((frame[0], session, &frame[5..]))
}

pub fn close_payload(code: u16, reason: &str) -> Vec<u8> {
    serde_json::json!({"code": code, "reason": reason}).to_string().into_bytes()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip_matches_python_struct_be() {
        // struct.pack(">BI", 2, 258) + b"x" in protocol.py
        let frame = pack(DATA, 258, b"x");
        assert_eq!(frame, vec![2, 0, 0, 1, 2, b'x']);
        assert_eq!(unpack(&frame), Some((DATA, 258, &b"x"[..])));
        assert_eq!(unpack(&[9, 0, 0, 0, 1]), None);
        assert_eq!(unpack(&[2, 0]), None);
    }
}
