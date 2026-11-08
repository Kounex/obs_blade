//! End-to-end encryption between a phone and this bridge: the relay only
//! forwards bytes it can't read (spec: "End-to-end encryption").
//!
//! - Handshake `Noise_IK_25519_ChaChaPoly_SHA256`, prologue [`PROLOGUE`]:
//!   the phone (initiator) knows this bridge's static key from pairing,
//!   this bridge checks the phone's static key against the paired ones.
//! - Afterwards every frame is one Noise transport message. An
//!   obs-websocket message is split into chunks `[fin u8][bytes]`, so it
//!   can exceed Noise's 65535-byte message limit (screenshots).
//!
//! Mirrored by `lib/utils/remote/noise_ik.dart` in the app.

use base64::Engine;
use base64::engine::general_purpose::STANDARD as B64;
use snow::{Builder, TransportState};

pub const PARAMS: &str = "Noise_IK_25519_ChaChaPoly_SHA256";
pub const PROLOGUE: &[u8] = b"obs-blade-remote/1";
/// Noise's limit for one message.
pub const MAX_MESSAGE: usize = 65535;
const TAG: usize = 16;
/// Message bytes per frame: the limit minus the AEAD tag and the fin byte.
pub const MAX_CHUNK: usize = MAX_MESSAGE - TAG - 1;
/// One reassembled message from the phone; the app sends small requests.
const MAX_INBOUND: usize = 16 * 1024 * 1024;

#[derive(Debug, PartialEq, Eq)]
pub enum E2eError {
    /// Message 1 didn't decrypt (wrong bridge key on the phone, garbage).
    Handshake,
    /// The phone's static key isn't one paired with this bridge.
    UnknownDevice,
    /// A transport frame didn't decrypt or broke the chunking.
    Frame,
}

pub struct Keypair {
    pub private: Vec<u8>,
    pub public: Vec<u8>,
}

pub fn generate() -> Keypair {
    let keypair = Builder::new(PARAMS.parse().expect("noise params"))
        .generate_keypair()
        .expect("x25519 keypair");
    Keypair { private: keypair.private, public: keypair.public }
}

/// A 32-byte key from its base64 form (as stored and exchanged).
pub fn key_from_b64(text: &str) -> Option<Vec<u8>> {
    B64.decode(text.trim()).ok().filter(|k| k.len() == 32)
}

pub fn key_to_b64(key: &[u8]) -> String {
    B64.encode(key)
}

/// The bridge's side of a session handshake: reads the phone's message 1,
/// checks its static key with [allowed], returns message 2 and the
/// transport.
pub fn respond(
    private: &[u8],
    message1: &[u8],
    allowed: impl Fn(&[u8]) -> bool,
) -> Result<(Vec<u8>, Transport), E2eError> {
    let mut handshake = Builder::new(PARAMS.parse().expect("noise params"))
        .local_private_key(private)
        .and_then(|b| b.prologue(PROLOGUE))
        .and_then(|b| b.build_responder())
        .map_err(|_| E2eError::Handshake)?;
    let mut payload = vec![0u8; MAX_MESSAGE];
    handshake.read_message(message1, &mut payload).map_err(|_| E2eError::Handshake)?;
    let phone = handshake.get_remote_static().ok_or(E2eError::Handshake)?;
    if !allowed(phone) {
        return Err(E2eError::UnknownDevice);
    }
    let mut message2 = vec![0u8; MAX_MESSAGE];
    let length = handshake.write_message(&[], &mut message2).map_err(|_| E2eError::Handshake)?;
    message2.truncate(length);
    let state = handshake.into_transport_mode().map_err(|_| E2eError::Handshake)?;
    Ok((message2, Transport { state, pending: Vec::new() }))
}

pub struct Transport {
    state: TransportState,
    pending: Vec<u8>,
}

impl Transport {
    pub fn new(state: TransportState) -> Self {
        Self { state, pending: Vec::new() }
    }

    /// One message -> its frames, in order.
    pub fn seal(&mut self, message: &[u8]) -> Result<Vec<Vec<u8>>, E2eError> {
        let chunks: Vec<&[u8]> = if message.is_empty() {
            vec![message]
        } else {
            message.chunks(MAX_CHUNK).collect()
        };
        let last = chunks.len() - 1;
        let mut frames = Vec::with_capacity(chunks.len());
        for (index, chunk) in chunks.into_iter().enumerate() {
            let mut plain = Vec::with_capacity(chunk.len() + 1);
            plain.push(u8::from(index == last));
            plain.extend_from_slice(chunk);
            let mut frame = vec![0u8; plain.len() + TAG];
            let length = self.state.write_message(&plain, &mut frame).map_err(|_| E2eError::Frame)?;
            frame.truncate(length);
            frames.push(frame);
        }
        Ok(frames)
    }

    /// One frame in; the whole message once its last chunk arrived.
    pub fn open(&mut self, frame: &[u8]) -> Result<Option<Vec<u8>>, E2eError> {
        if frame.len() > MAX_MESSAGE {
            return Err(E2eError::Frame);
        }
        let mut plain = vec![0u8; frame.len()];
        let length = self.state.read_message(frame, &mut plain).map_err(|_| E2eError::Frame)?;
        let (&fin, chunk) = plain[..length].split_first().ok_or(E2eError::Frame)?;
        if fin > 1 || self.pending.len() + chunk.len() > MAX_INBOUND {
            return Err(E2eError::Frame);
        }
        self.pending.extend_from_slice(chunk);
        Ok((fin == 1).then(|| std::mem::take(&mut self.pending)))
    }
}

#[cfg(test)]
pub mod tests {
    use super::*;

    /// The phone's side, as the app does it.
    pub fn initiate(phone: &Keypair, bridge_public: &[u8]) -> (snow::HandshakeState, Vec<u8>) {
        let mut handshake = Builder::new(PARAMS.parse().unwrap())
            .local_private_key(&phone.private)
            .unwrap()
            .remote_public_key(bridge_public)
            .unwrap()
            .prologue(PROLOGUE)
            .unwrap()
            .build_initiator()
            .unwrap();
        let mut message1 = vec![0u8; MAX_MESSAGE];
        let length = handshake.write_message(&[], &mut message1).unwrap();
        message1.truncate(length);
        (handshake, message1)
    }

    fn paired() -> (Transport, Transport) {
        let bridge = generate();
        let phone = generate();
        let (mut handshake, message1) = initiate(&phone, &bridge.public);
        let (message2, bridge_side) =
            respond(&bridge.private, &message1, |key| key == phone.public.as_slice()).unwrap();
        let mut payload = vec![0u8; MAX_MESSAGE];
        handshake.read_message(&message2, &mut payload).unwrap();
        (Transport::new(handshake.into_transport_mode().unwrap()), bridge_side)
    }

    #[test]
    fn a_paired_phone_talks_both_ways_also_past_the_noise_limit() {
        let (mut phone, mut bridge) = paired();
        for message in [b"{\"op\":1}".to_vec(), Vec::new(), vec![b'x'; 200_000]] {
            let frames = phone.seal(&message).unwrap();
            assert_eq!(frames.len(), message.len().div_ceil(MAX_CHUNK).max(1));
            assert!(frames.iter().all(|f| f.len() <= MAX_MESSAGE));
            let mut got = None;
            for frame in &frames {
                assert!(got.is_none(), "message complete before its last frame");
                got = bridge.open(frame).unwrap();
            }
            assert_eq!(got.unwrap(), message);

            let back = bridge.seal(&message).unwrap();
            let opened: Vec<_> = back.iter().map(|f| phone.open(f).unwrap()).collect();
            assert_eq!(opened.last().unwrap().as_deref(), Some(message.as_slice()));
        }
    }

    #[test]
    fn an_unpaired_phone_or_a_wrong_bridge_key_is_refused() {
        let bridge = generate();
        let phone = generate();
        let (_, message1) = initiate(&phone, &bridge.public);
        assert_eq!(respond(&bridge.private, &message1, |_| false).err(), Some(E2eError::UnknownDevice));

        let other = generate();
        let (_, message1) = initiate(&phone, &other.public);
        assert_eq!(respond(&bridge.private, &message1, |_| true).err(), Some(E2eError::Handshake));
    }

    #[test]
    fn tampered_reordered_or_cut_frames_never_open() {
        let (mut phone, mut bridge) = paired();
        let mut frames = phone.seal(&vec![b'y'; 3 * MAX_CHUNK]).unwrap();
        frames[0][10] ^= 1;
        assert_eq!(bridge.open(&frames[0]), Err(E2eError::Frame));

        let (mut phone, mut bridge) = paired();
        let frames = phone.seal(&vec![b'y'; 3 * MAX_CHUNK]).unwrap();
        assert_eq!(bridge.open(&frames[1]), Err(E2eError::Frame), "out of order");

        // Dropping the last chunk: nothing is delivered.
        let (mut phone, mut bridge) = paired();
        let frames = phone.seal(&vec![b'y'; 2 * MAX_CHUNK]).unwrap();
        assert_eq!(bridge.open(&frames[0]), Ok(None));
    }

    #[test]
    fn keys_round_trip_as_base64() {
        let keypair = generate();
        assert_eq!(key_from_b64(&key_to_b64(&keypair.public)), Some(keypair.public));
        assert_eq!(key_from_b64("dG9vIHNob3J0"), None);
    }
}
