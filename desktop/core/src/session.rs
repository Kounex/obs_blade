//! One phone session: its own local websocket to OBS, so subscriptions,
//! batches and high-volume events behave exactly like OBS.

use futures_util::{SinkExt, StreamExt};
use tokio::sync::mpsc;
use tokio_tungstenite::tungstenite::Message;

use crate::obs_config::WsConfig;
use crate::obs_link::{self, ConnectError};
use crate::rewrite::{PreviewCap, rewrite_request};
use crate::wire::{OBS_AUTH_FAILED, OBS_NOT_RUNNING, OBS_UNREACHABLE};

#[derive(Debug, Clone)]
pub struct Params {
    pub sid: u32,
    pub ws: WsConfig,
    pub cap: PreviewCap,
    /// What the shell knows about the OBS process (plugin: always true).
    pub obs_running: Option<bool>,
}

#[derive(Debug, PartialEq, Eq)]
pub enum Out {
    Data(u32, String),
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

pub async fn run(p: Params, mut from_phone: mpsc::Receiver<String>, out: mpsc::Sender<Out>) {
    let sid = p.sid;
    let close = |code: u16, reason: &str| Out::Close(sid, code, reason.to_owned());

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
    if out.send(Out::Data(sid, hello.to_string())).await.is_err() {
        return;
    }

    let mut identified = false;
    loop {
        tokio::select! {
            phone = from_phone.recv() => {
                let Some(text) = phone else {
                    // The phone left (relay CLOSE) or the relay link dropped.
                    let _ = local.close(None).await;
                    return;
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
                    if out.send(Out::Data(sid, text.to_string())).await.is_err() {
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
