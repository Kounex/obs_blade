//! One phone session: its own local websocket to OBS, so subscriptions,
//! batches and high-volume events behave exactly like OBS. Everything
//! between the phone and here is end-to-end encrypted (`e2e.rs`).

use futures_util::{SinkExt, StreamExt};
use tokio::sync::mpsc;
use tokio_tungstenite::tungstenite::Message;

use crate::e2e::{self, E2eError, Transport};
use crate::obs_config::WsConfig;
use crate::obs_link::{self, ConnectError};
use crate::rewrite::{PreviewCap, rewrite_request};
use crate::wire::{E2E_FAILED, OBS_AUTH_FAILED, OBS_NOT_RUNNING, OBS_UNREACHABLE, UNKNOWN_DEVICE};

/// The phone sends its handshake right after the relay connected it.
const HANDSHAKE_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(20);

#[derive(Debug, Clone)]
pub struct Params {
    pub sid: u32,
    pub ws: WsConfig,
    pub cap: PreviewCap,
    /// What the shell knows about the OBS process (plugin: always true).
    pub obs_running: Option<bool>,
    /// This bridge's end-to-end private key.
    pub bridge_private: Vec<u8>,
    /// The paired phones' static keys: only they open a session.
    pub app_keys: Vec<Vec<u8>>,
}

#[derive(Debug, PartialEq, Eq)]
pub enum Out {
    /// One encrypted frame for the phone.
    Data(u32, Vec<u8>),
    Close(u32, u16, String),
}

/// Close code when OBS can't be reached at all.
pub fn unreachable_code(ws: &WsConfig, refused: bool, obs_running: Option<bool>) -> (u16, &'static str) {
    if obs_running == Some(false) {
        return (OBS_NOT_RUNNING, "obs not running");
    }
    if !ws.enabled {
        return (OBS_UNREACHABLE, "websocket server off");
    }
    if refused && obs_running != Some(true) {
        return (OBS_NOT_RUNNING, "obs not running");
    }
    (OBS_UNREACHABLE, "obs unreachable")
}

pub async fn run(p: Params, mut from_phone: mpsc::Receiver<Vec<u8>>, out: mpsc::Sender<Out>) {
    let sid = p.sid;
    let close = |code: u16, reason: &str| Out::Close(sid, code, reason.to_owned());

    // OBS first: "not running" / "unreachable" answer before any handshake.
    if !p.ws.enabled || p.obs_running == Some(false) {
        let (code, reason) = unreachable_code(&p.ws, false, p.obs_running);
        let _ = out.send(close(code, reason)).await;
        return;
    }
    let mut local = match obs_link::connect(p.ws.port).await {
        Ok(ws) => ws,
        Err(error) => {
            let (code, reason) = unreachable_code(&p.ws, error == ConnectError::Refused, p.obs_running);
            let _ = out.send(close(code, reason)).await;
            return;
        }
    };
    let hello = tokio::time::timeout(obs_link::CONNECT_TIMEOUT, obs_link::next_text(&mut local)).await;
    let Some((hello, auth)) = hello.ok().flatten().as_deref().and_then(obs_link::split_hello) else {
        let _ = out.send(close(OBS_UNREACHABLE, "no hello from obs")).await;
        return;
    };

    let message1 = match tokio::time::timeout(HANDSHAKE_TIMEOUT, from_phone.recv()).await {
        Ok(Some(message1)) => message1,
        Ok(None) => {
            let _ = local.close(None).await;
            return;
        }
        Err(_) => {
            let _ = local.close(None).await;
            let _ = out.send(close(E2E_FAILED, "no handshake")).await;
            return;
        }
    };
    let (message2, mut transport) =
        match e2e::respond(&p.bridge_private, &message1, |key| p.app_keys.iter().any(|k| k == key)) {
            Ok(done) => done,
            Err(error) => {
                let _ = local.close(None).await;
                let (code, reason) = match error {
                    E2eError::UnknownDevice => (UNKNOWN_DEVICE, "this device isn't paired with the bridge"),
                    _ => (E2E_FAILED, "handshake failed"),
                };
                let _ = out.send(close(code, reason)).await;
                return;
            }
        };
    if out.send(Out::Data(sid, message2)).await.is_err() || !send_sealed(&mut transport, sid, &hello.to_string(), &out).await {
        return;
    }

    let mut identified = false;
    loop {
        tokio::select! {
            phone = from_phone.recv() => {
                let Some(frame) = phone else {
                    // The phone left (relay CLOSE) or the relay link dropped.
                    let _ = local.close(None).await;
                    return;
                };
                let text = match transport.open(&frame).map(|m| m.map(String::from_utf8)) {
                    Ok(None) => continue,
                    Ok(Some(Ok(text))) => text,
                    Ok(Some(Err(_))) | Err(_) => {
                        let _ = local.close(None).await;
                        let _ = out.send(close(E2E_FAILED, "frame didn't decrypt")).await;
                        return;
                    }
                };
                let text = if !identified && obs_link::op_of(&text) == Some(1) {
                    identified = true;
                    obs_link::identify_with_auth(&text, auth.as_ref(), &p.ws).unwrap_or(text)
                } else {
                    rewrite_request(&text, p.cap).unwrap_or(text)
                };
                if local.send(Message::text(text)).await.is_err() {
                    let _ = out.send(close(OBS_NOT_RUNNING, "obs closed")).await;
                    return;
                }
            }
            incoming = local.next() => match incoming {
                Some(Ok(Message::Text(text))) => {
                    if !send_sealed(&mut transport, sid, text.as_str(), &out).await {
                        return;
                    }
                }
                Some(Ok(Message::Close(frame))) => {
                    let (code, reason) = frame
                        .map(|f| (u16::from(f.code), f.reason.to_string()))
                        .unwrap_or((1000, String::new()));
                    let (code, reason) = if code == OBS_AUTH_FAILED {
                        (OBS_UNREACHABLE, "obs refused the bridge's password".to_owned())
                    } else {
                        (code, reason)
                    };
                    let _ = out.send(Out::Close(sid, code, reason)).await;
                    return;
                }
                Some(Ok(_)) => {}
                Some(Err(_)) | None => {
                    let _ = out.send(close(OBS_NOT_RUNNING, "obs closed")).await;
                    return;
                }
            },
        }
    }
}

/// False once the relay link is gone.
async fn send_sealed(transport: &mut Transport, sid: u32, text: &str, out: &mpsc::Sender<Out>) -> bool {
    let Ok(frames) = transport.seal(text.as_bytes()) else { return false };
    for frame in frames {
        if out.send(Out::Data(sid, frame)).await.is_err() {
            return false;
        }
    }
    true
}
