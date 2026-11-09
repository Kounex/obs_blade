//! The bridge's own OBS connection, independent of phone sessions: OBS
//! state, the status snapshot for the relay, pairing codes sent as a
//! `CustomEvent`, and (standalone) whether the plugin is loaded in OBS.

use std::sync::Arc;
use std::time::{Duration, Instant};

use futures_util::{SinkExt, StreamExt};
use serde_json::{Value, json};
use tokio_tungstenite::tungstenite::Message;

use crate::obs_link::{self, ConnectError};
use crate::shared::{Kind, Shared};
use crate::wire::OBS_AUTH_FAILED;

pub const STATUS_INTERVAL: Duration = Duration::from_secs(20);
/// Standalone: how often it asks whether the plugin runs. Both on the same
/// pairing replace each other at the relay (4906) until it knows - at OBS
/// start the plugin registers its vendor after the websocket is up
/// (2026-11-08: 20 s of flapping with the status interval).
const PLUGIN_CHECK_INTERVAL: Duration = Duration::from_secs(5);
const RETRY: Duration = Duration::from_secs(3);
/// EventSubscription::General - CustomEvent and ExitStarted live there.
const SUBSCRIBE_GENERAL: u64 = 1;
pub const PAIR_EVENT_KEY: &str = "obs-blade-pair";
/// The bridge's answer to a pairing, with its end-to-end key.
pub const PAIR_ACK_EVENT_KEY: &str = "obs-blade-pair-ack";
pub const VENDOR: &str = "obs-blade-bridge";

pub async fn run(shared: Arc<Shared>) {
    let mut stop = shared.stop.subscribe();
    loop {
        if shared.stopping() {
            return;
        }
        let outcome = tokio::select! {
            outcome = connect_once(&shared) => outcome,
            _ = stop.changed() => return,
        };
        let running = *shared.obs_running.borrow();
        let state = match outcome {
            Outcome::ServerOff if running == Some(false) => "closed",
            Outcome::ServerOff => "ws_off",
            Outcome::Refused if running == Some(true) => "ws_off",
            Outcome::Refused => "closed",
            Outcome::AuthFailed => "auth_failed",
            Outcome::Lost => {
                if running == Some(true) {
                    "ws_off"
                } else {
                    "closed"
                }
            }
        };
        shared.set_obs_state(state);
        shared.plugin_present.send_replace(false);
        // No plugin without OBS - but an OBS still starting refuses too:
        // only a closed OBS (the shell's process watch) settles the check
        if running != Some(true) {
            shared.plugin_checked.send_replace(true);
        }
        tokio::select! {
            _ = tokio::time::sleep(RETRY) => {}
            _ = stop.changed() => return,
            _ = shared.wake.notified() => {}
        }
    }
}

enum Outcome {
    ServerOff,
    Refused,
    AuthFailed,
    Lost,
}

async fn connect_once(shared: &Arc<Shared>) -> Outcome {
    let ws_config = shared.ws_config();
    if !ws_config.enabled {
        return Outcome::ServerOff;
    }
    let mut ws = match obs_link::connect(ws_config.port).await {
        Ok(ws) => ws,
        Err(ConnectError::Refused) => return Outcome::Refused,
        Err(ConnectError::Other(_)) => return Outcome::Lost,
    };
    let Some((_, auth)) = obs_link::next_text(&mut ws).await.as_deref().and_then(obs_link::split_hello)
    else {
        return Outcome::Lost;
    };
    let identify = json!({"op": 1, "d": {"rpcVersion": 1, "eventSubscriptions": SUBSCRIBE_GENERAL}}).to_string();
    let identify = obs_link::identify_with_auth(&identify, auth.as_ref(), &ws_config).unwrap_or(identify);
    if ws.send(Message::text(identify)).await.is_err() {
        return Outcome::Lost;
    }

    let mut tick = tokio::time::interval(STATUS_INTERVAL);
    let mut plugin_tick = tokio::time::interval(PLUGIN_CHECK_INTERVAL);
    let mut previous_bytes: Option<(u64, Instant)> = None;
    let mut outbox = shared.obs_outbox.subscribe();
    loop {
        tokio::select! {
            _ = plugin_tick.tick(), if shared.cfg.kind == Kind::Standalone => {
                if ws.send(Message::text(plugin_request())).await.is_err() {
                    return Outcome::Lost;
                }
            }
            queued = outbox.recv() => {
                if let Ok(message) = queued
                    && ws.send(Message::text(message)).await.is_err()
                {
                    return Outcome::Lost;
                }
            }
            _ = tick.tick() => {
                for request in requests() {
                    if ws.send(Message::text(request)).await.is_err() {
                        return Outcome::Lost;
                    }
                }
            }
            incoming = ws.next() => match incoming {
                Some(Ok(Message::Text(text))) => {
                    let Ok(message) = serde_json::from_str::<Value>(text.as_str()) else { continue };
                    handle(shared, &message, &mut previous_bytes);
                }
                Some(Ok(Message::Close(frame))) => {
                    if frame.is_some_and(|f| u16::from(f.code) == OBS_AUTH_FAILED) {
                        return Outcome::AuthFailed;
                    }
                    return Outcome::Lost;
                }
                Some(Ok(_)) => {}
                Some(Err(_)) | None => return Outcome::Lost,
            },
        }
    }
}

/// Standalone, while the plugin handles remote access: show the plugin's
/// panel in OBS (one place for the settings and devices).
pub fn open_plugin_panel_request() -> String {
    json!({"op": 6, "d": {"requestType": "CallVendorRequest", "requestId": "obb-open-panel",
        "requestData": {"vendorName": VENDOR, "requestType": "OpenPanel", "requestData": {}}}})
    .to_string()
}

/// Is the plugin loaded in this OBS? (standalone: it then only watches OBS)
fn plugin_request() -> String {
    json!({"op": 6, "d": {"requestType": "CallVendorRequest", "requestId": "obb-plugin",
        "requestData": {"vendorName": VENDOR, "requestType": "Status", "requestData": {}}}})
    .to_string()
}

fn requests() -> Vec<String> {
    vec![
        json!({"op": 8, "d": {"requestId": "obb-status", "haltOnFailure": false, "requests": [
            {"requestType": "GetStreamStatus"},
            {"requestType": "GetRecordStatus"},
            {"requestType": "GetStats"},
            {"requestType": "GetVideoSettings"}
        ]}})
        .to_string(),
    ]
}

fn handle(shared: &Arc<Shared>, message: &Value, previous_bytes: &mut Option<(u64, Instant)>) {
    let d = &message["d"];
    match message["op"].as_u64() {
        Some(2) => shared.set_obs_state("running"),
        Some(5) => match d["eventType"].as_str() {
            Some("CustomEvent") => {
                let pair = &d["eventData"][PAIR_EVENT_KEY];
                if let Some(code) = pair["code"].as_str() {
                    let app_key = pair["app_key"].as_str().unwrap_or_default();
                    crate::pairing::pair(shared.clone(), code.to_owned(), app_key.to_owned());
                }
            }
            Some("ExitStarted") => shared.set_obs_state("closed"),
            _ => {}
        },
        Some(7) if d["requestId"] == "obb-plugin" => {
            let present = d["requestStatus"]["result"].as_bool().unwrap_or(false);
            if shared.plugin_present.send_replace(present) != present {
                shared.wake.notify_waiters();
            }
            shared.plugin_checked.send_replace(true);
        }
        Some(9) if d["requestId"] == "obb-status" => {
            if let Some(aspect) = canvas_aspect(d) {
                *shared.canvas_aspect.lock().unwrap() = Some(aspect);
            }
            if let Some(snapshot) = snapshot(d, previous_bytes) {
                shared.status.send_replace(Some(snapshot));
            }
        }
        _ => {}
    }
}

fn canvas_aspect(batch: &Value) -> Option<f64> {
    let video = batch["results"]
        .as_array()?
        .iter()
        .find(|r| r["requestType"] == "GetVideoSettings" && r["requestStatus"]["result"] == true)?;
    let width = video["responseData"]["baseWidth"].as_f64()?;
    let height = video["responseData"]["baseHeight"].as_f64()?;
    (width > 0.0 && height > 0.0).then(|| width / height)
}

/// The compact status the relay keeps per bridge (alerts build on it).
fn snapshot(batch: &Value, previous_bytes: &mut Option<(u64, Instant)>) -> Option<Value> {
    let results = batch["results"].as_array()?;
    let data = |kind: &str| {
        results
            .iter()
            .find(|r| r["requestType"] == kind && r["requestStatus"]["result"] == true)
            .map(|r| r["responseData"].clone())
            .unwrap_or(Value::Null)
    };
    let stream = data("GetStreamStatus");
    let record = data("GetRecordStatus");
    let stats = data("GetStats");
    let streaming = stream["outputActive"].as_bool().unwrap_or(false);
    let bytes = stream["outputBytes"].as_u64().unwrap_or(0);
    let now = Instant::now();
    let kbps = match previous_bytes {
        Some((before, at)) if streaming && bytes >= *before => {
            let seconds = now.duration_since(*at).as_secs_f64();
            (seconds > 0.0).then(|| ((bytes - *before) as f64 * 8.0 / 1000.0 / seconds).round())
        }
        _ => None,
    };
    *previous_bytes = streaming.then_some((bytes, now));
    Some(json!({
        "streaming": streaming,
        "stream_reconnecting": stream["outputReconnecting"].as_bool().unwrap_or(false),
        "stream_congestion": stream["outputCongestion"],
        "stream_kbps": kbps,
        "stream_duration_ms": stream["outputDuration"],
        "stream_skipped": stream["outputSkippedFrames"],
        "stream_total": stream["outputTotalFrames"],
        "recording": record["outputActive"].as_bool().unwrap_or(false),
        "recording_paused": record["outputPaused"].as_bool().unwrap_or(false),
        "cpu": stats["cpuUsage"],
        "memory_mb": stats["memoryUsage"],
        "disk_free_mb": stats["availableDiskSpace"],
        "fps": stats["activeFps"],
        "render_skipped": stats["renderSkippedFrames"],
        "render_total": stats["renderTotalFrames"],
        "output_skipped": stats["outputSkippedFrames"],
        "output_total": stats["outputTotalFrames"],
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn snapshot_from_a_batch_answer() {
        let batch = json!({"requestId": "obb-status", "results": [
            {"requestType": "GetStreamStatus", "requestStatus": {"result": true, "code": 100},
             "responseData": {"outputActive": true, "outputReconnecting": false, "outputCongestion": 0.0,
                              "outputBytes": 1_000_000, "outputDuration": 60000, "outputSkippedFrames": 2,
                              "outputTotalFrames": 3600}},
            {"requestType": "GetRecordStatus", "requestStatus": {"result": false, "code": 501}},
            {"requestType": "GetStats", "requestStatus": {"result": true, "code": 100},
             "responseData": {"cpuUsage": 12.5, "memoryUsage": 800.0, "availableDiskSpace": 51200.0,
                              "activeFps": 60.0, "renderSkippedFrames": 0, "renderTotalFrames": 3600,
                              "outputSkippedFrames": 0, "outputTotalFrames": 3600}}
        ]});
        let mut previous = None;
        let first = snapshot(&batch, &mut previous).unwrap();
        assert_eq!(first["streaming"], true);
        assert_eq!(first["stream_kbps"], Value::Null); // needs two samples
        assert_eq!(first["recording"], false); // failed sub-request = not recording
        assert_eq!(first["disk_free_mb"], 51200.0);
        assert!(previous.is_some());
    }
}
