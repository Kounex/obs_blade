//! The bridge's one outbound connection to the relay, carrying every phone
//! session (protocol: `tool/remote_relay/README.md`).

use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use futures_util::{SinkExt, StreamExt};
use serde_json::{Value, json};
use tokio::sync::mpsc;
use tokio_tungstenite::connect_async;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::tungstenite::http::HeaderValue;
use tokio_tungstenite::tungstenite::{Error as WsError, Message};

use crate::monitor::STATUS_INTERVAL;
use crate::session::{self, Out};
use crate::shared::{Kind, RelayState, Shared};
use crate::state::AppKey;
use crate::wire;

/// This long without any frame from the relay = dead link.
const SILENCE_LIMIT: Duration = Duration::from_secs(75);
/// The bridge's own `ping` (answered with `pong`): websocket pings from the
/// relay never arrive through Cloudflare, so without it every idle link
/// "went silent" after 75 s (2026-11-08).
const KEEPALIVE: Duration = Duration::from_secs(25);
const MAX_BACKOFF: Duration = Duration::from_secs(60);
/// Standalone start: the longest the link waits for the plugin check (the
/// monitor answers in well under a second when OBS runs or is closed).
const PLUGIN_CHECK_WAIT: Duration = Duration::from_secs(8);
const SESSION_BUFFER: usize = 1024;

enum Ended {
    Stop,
    /// Pairing / settings changed: re-evaluate before reconnecting.
    Recheck,
    Lost(String),
    UpdateRequired(String),
}

pub async fn run(shared: Arc<Shared>) {
    let mut control_rx = shared.control_rx.lock().unwrap().take().expect("relay::run once");
    let mut stop = shared.stop.subscribe();
    let mut failures: u32 = 0;
    loop {
        if shared.stopping() {
            return;
        }
        let stored = shared.reload();
        let blocked = if !stored.enabled {
            Some(RelayState::Disabled)
        } else if !stored.paired() {
            Some(RelayState::Unpaired)
        } else if shared.cfg.kind == Kind::Standalone && *shared.plugin_present.borrow() {
            Some(RelayState::Deferred)
        } else {
            None
        };
        if let Some(state) = blocked {
            // Deferred: the plugin's link has the devices; a list kept from
            // before would go stale (removed phones still listed)
            if state == RelayState::Deferred {
                shared.set_devices(Vec::new());
            }
            shared.set_relay_state(state);
            let mut plugin = shared.plugin_present.subscribe();
            tokio::select! {
                _ = shared.wake.notified() => {}
                _ = plugin.changed() => {}
                _ = stop.changed() => return,
                // Another process (the plugin / standalone) may have paired.
                _ = tokio::time::sleep(Duration::from_secs(10)) => {}
            }
            continue;
        }

        // Standalone: know whether the plugin runs before taking the link
        // (bounded - a hung OBS must not keep remote access off)
        if shared.cfg.kind == Kind::Standalone && !*shared.plugin_checked.borrow() {
            shared.set_relay_state(RelayState::Connecting);
            let mut checked = shared.plugin_checked.subscribe();
            tokio::select! {
                _ = checked.wait_for(|known| *known) => {}
                _ = tokio::time::sleep(PLUGIN_CHECK_WAIT) => {
                    shared.plugin_checked.send_replace(true);
                }
                _ = stop.changed() => return,
            }
            continue;
        }

        shared.set_relay_state(RelayState::Connecting);
        let started = Instant::now();
        let ended = connect(&shared, stored.bridge_token.unwrap_or_default(), &mut control_rx).await;
        let wait = match ended {
            Ended::Stop => return,
            Ended::Recheck => Duration::ZERO,
            Ended::UpdateRequired(min) => {
                shared.set_relay_state(RelayState::UpdateRequired(min));
                Duration::from_secs(6 * 3600)
            }
            Ended::Lost(reason) => {
                shared.log("info", format!("relay link lost: {reason}"));
                failures = if started.elapsed() > Duration::from_secs(60) { 1 } else { failures + 1 };
                shared.set_relay_state(RelayState::Offline(reason));
                backoff(failures)
            }
        };
        if !wait.is_zero() {
            tokio::select! {
                _ = tokio::time::sleep(wait) => {}
                _ = shared.wake.notified() => {}
                _ = stop.changed() => return,
            }
        }
    }
}

fn backoff(failures: u32) -> Duration {
    let base = Duration::from_secs(1u64 << failures.min(6)).min(MAX_BACKOFF);
    // ±20 % jitter so bridges don't reconnect in lockstep after a relay restart.
    let nanos = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.subsec_nanos()).unwrap_or(0);
    let factor = 0.8 + f64::from(nanos % 1000) / 2500.0;
    base.mul_f64(factor)
}

async fn connect(
    shared: &Arc<Shared>,
    token: String,
    control_rx: &mut mpsc::UnboundedReceiver<Value>,
) -> Ended {
    let mut request = match shared.relay_ws().into_client_request() {
        Ok(request) => request,
        Err(error) => return Ended::Lost(error.to_string()),
    };
    let headers = request.headers_mut();
    for (name, value) in [
        ("Authorization", format!("Bearer {token}")),
        ("X-Bridge-Version", shared.cfg.version.clone()),
        ("X-Bridge-Kind", shared.cfg.kind.as_str().to_owned()),
        ("User-Agent", format!("obs-blade-bridge/{}", shared.cfg.version)),
    ] {
        if let Ok(value) = HeaderValue::from_str(&value) {
            headers.insert(name, value);
        }
    }
    let ws = match tokio::time::timeout(Duration::from_secs(15), connect_async(request)).await {
        Err(_) => return Ended::Lost("timeout".into()),
        Ok(Err(WsError::Http(response))) if response.status() == 401 => {
            // Unpaired on the relay (removed there): forget the token.
            shared.update(|stored| {
                stored.bridge_token = None;
                stored.bridge_id = None;
                stored.app_keys.clear();
            });
            shared.set_devices(Vec::new());
            return Ended::Recheck;
        }
        Ok(Err(error)) => return Ended::Lost(error.to_string()),
        Ok(Ok((ws, _))) => ws,
    };
    let (mut sink, mut stream) = ws.split();
    shared.set_relay_state(RelayState::Online);

    let hello = json!({"type": "hello", "name": shared.cfg.name, "obs": *shared.obs_state.borrow()});
    if sink.send(Message::text(hello.to_string())).await.is_err() {
        return Ended::Lost("closed".into());
    }

    let (out_tx, mut out_rx) = mpsc::channel::<Out>(SESSION_BUFFER);
    let mut sessions: HashMap<u32, mpsc::Sender<Vec<u8>>> = HashMap::new();
    let mut obs_state = shared.obs_state.subscribe();
    let mut plugin = shared.plugin_present.subscribe();
    let mut stop = shared.stop.subscribe();
    let mut status_tick = tokio::time::interval(STATUS_INTERVAL);
    let mut silence_tick = tokio::time::interval(Duration::from_secs(15));
    let mut keepalive_tick = tokio::time::interval(KEEPALIVE);
    keepalive_tick.reset(); // the first one after a full interval
    let mut last_frame = Instant::now();

    let ended = loop {
        tokio::select! {
            incoming = stream.next() => {
                last_frame = Instant::now();
                match incoming {
                    Some(Ok(Message::Binary(frame))) => {
                        let Some((kind, sid, payload)) = wire::unpack(&frame) else { continue };
                        match kind {
                            wire::OPEN => {
                                let (tx, rx) = mpsc::channel(SESSION_BUFFER);
                                sessions.insert(sid, tx);
                                let params = session::Params {
                                    sid,
                                    ws: shared.ws_config(),
                                    cap: shared.preview_cap(),
                                    obs_running: if shared.cfg.kind == Kind::Plugin {
                                        Some(true)
                                    } else {
                                        *shared.obs_running.borrow()
                                    },
                                    bridge_private: shared.e2e_keypair().0,
                                    app_keys: shared.app_keys(),
                                };
                                tokio::spawn(session::run(params, rx, out_tx.clone()));
                            }
                            wire::DATA => {
                                if let Some(tx) = sessions.get(&sid)
                                    && tx.send(payload.to_vec()).await.is_err()
                                {
                                    sessions.remove(&sid);
                                }
                            }
                            _ => {
                                // CLOSE: dropping the sender ends the session.
                                sessions.remove(&sid);
                            }
                        }
                    }
                    Some(Ok(Message::Text(text))) => {
                        if let Some(ended) = control(shared, text.as_str()) {
                            break ended;
                        }
                    }
                    Some(Ok(Message::Close(frame))) => {
                        let reason = frame.map(|f| format!("closed {}", u16::from(f.code))).unwrap_or_else(|| "closed".into());
                        break Ended::Lost(reason);
                    }
                    Some(Ok(_)) => {}
                    Some(Err(error)) => break Ended::Lost(error.to_string()),
                    None => break Ended::Lost("closed".into()),
                }
            }
            out = out_rx.recv() => {
                let Some(out) = out else { continue };
                let frame = match out {
                    Out::Data(sid, frame) => wire::pack(wire::DATA, sid, &frame),
                    Out::Close(sid, code, reason) => {
                        sessions.remove(&sid);
                        wire::pack(wire::CLOSE, sid, &wire::close_payload(code, &reason))
                    }
                };
                if sink.send(Message::binary(frame)).await.is_err() {
                    break Ended::Lost("send failed".into());
                }
            }
            command = control_rx.recv() => {
                let Some(command) = command else { continue };
                if sink.send(Message::text(command.to_string())).await.is_err() {
                    break Ended::Lost("send failed".into());
                }
            }
            changed = obs_state.changed() => {
                if changed.is_ok() {
                    let state = obs_state.borrow_and_update().clone();
                    let message = json!({"type": "obs", "state": state});
                    if sink.send(Message::text(message.to_string())).await.is_err() {
                        break Ended::Lost("send failed".into());
                    }
                }
            }
            _ = status_tick.tick() => {
                let status = shared.status.borrow().clone();
                if let Some(status) = status {
                    let message = json!({"type": "status", "status": status});
                    if sink.send(Message::text(message.to_string())).await.is_err() {
                        break Ended::Lost("send failed".into());
                    }
                }
            }
            _ = silence_tick.tick() => {
                if last_frame.elapsed() > SILENCE_LIMIT {
                    break Ended::Lost("relay silent".into());
                }
            }
            _ = keepalive_tick.tick() => {
                // Websocket pings don't cross the Cloudflare tunnel: ask the
                // relay itself, its `pong` counts as a frame.
                let ping = json!({"type": "ping"});
                if sink.send(Message::text(ping.to_string())).await.is_err() {
                    break Ended::Lost("send failed".into());
                }
            }
            _ = shared.wake.notified() => {
                let stored = shared.reload();
                let deferred = shared.cfg.kind == Kind::Standalone && *shared.plugin_present.borrow();
                if !stored.enabled || !stored.paired() || deferred {
                    break Ended::Recheck;
                }
            }
            _ = plugin.changed() => {
                if shared.cfg.kind == Kind::Standalone && *plugin.borrow_and_update() {
                    break Ended::Recheck;
                }
            }
            _ = stop.changed() => {
                if *stop.borrow() == Some(true) {
                    let bye = json!({"type": "bye", "reason": "obs_exit"});
                    let _ = sink.send(Message::text(bye.to_string())).await;
                }
                break Ended::Stop;
            }
        }
    };
    sessions.clear();
    let _ = sink.close().await;
    ended
}

/// A relay control message; Some(..) ends the connection.
fn control(shared: &Arc<Shared>, text: &str) -> Option<Ended> {
    let message: Value = serde_json::from_str(text).ok()?;
    match message["type"].as_str()? {
        "welcome" | "devices" => {
            let devices = message["devices"].as_array().cloned().unwrap_or_default();
            prune_app_keys(shared, &devices);
            shared.set_devices(devices);
            None
        }
        "start_obs" => {
            shared.emit(json!({"type": "start_obs", "device": message["device"]}));
            None
        }
        "update_required" => Some(Ended::UpdateRequired(
            message["min_version"].as_str().unwrap_or("").to_owned(),
        )),
        "unpaired" => {
            shared.update(|stored| {
                stored.bridge_token = None;
                stored.bridge_id = None;
                stored.app_keys.clear();
            });
            shared.set_devices(Vec::new());
            Some(Ended::Recheck)
        }
        _ => None,
    }
}

/// A device removed at the relay loses its key here too. Keys younger
/// than [KEY_GRACE] stay: the relay lists a device only once the app has
/// collected its pairing.
fn prune_app_keys(shared: &Arc<Shared>, devices: &[Value]) {
    let listed: Vec<&str> = devices.iter().filter_map(|d| d["id"].as_str()).collect();
    let now = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0);
    let stored = shared.reload();
    let keep = |k: &AppKey| listed.contains(&k.device_id.as_str()) || now.saturating_sub(k.added_at) < KEY_GRACE.as_secs();
    if stored.app_keys.iter().all(keep) {
        return;
    }
    shared.update(|s| s.app_keys.retain(keep));
}

const KEY_GRACE: Duration = Duration::from_secs(15 * 60);

#[cfg(test)]
mod tests {
    #[test]
    fn backoff_grows_and_caps() {
        let first = super::backoff(1).as_secs_f64();
        assert!((1.6..=2.4).contains(&first), "{first}");
        let late = super::backoff(20).as_secs_f64();
        assert!((48.0..=72.0).contains(&late), "{late}");
    }
}
