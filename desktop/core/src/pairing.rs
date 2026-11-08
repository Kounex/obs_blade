//! Redeems a pairing code at the relay (`POST /v1/pairings/redeem`).

use std::sync::Arc;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use serde_json::{Value, json};

use crate::e2e;
use crate::monitor::PAIR_ACK_EVENT_KEY;
use crate::shared::{PairAttempt, Shared};
use crate::state::AppKey;

/// Runs in the background; the outcome arrives as a `pair_result` event.
/// [app_key]: the phone's end-to-end public key (base64), sent with the
/// code through OBS. After a successful redeem it is stored as a paired
/// key and this bridge's key goes back through OBS as the
/// `obs-blade-pair-ack` CustomEvent - the relay never carries a key.
pub fn pair(shared: Arc<Shared>, code: String, app_key: String) {
    let Some(app_key) = e2e::key_from_b64(&app_key) else {
        shared.log("warn", "pairing code without a valid app key ignored (OBS Blade too old?)");
        return;
    };
    match shared.pair_attempt(&code) {
        PairAttempt::InFlight => return,
        PairAttempt::Done(ack) => {
            // The app missed the ack: send it again.
            let _ = shared.obs_outbox.send(ack);
            return;
        }
        PairAttempt::New => {}
    }
    shared.log("info", "redeeming a pairing code");
    tokio::spawn(async move {
        let (_, bridge_public) = shared.e2e_keypair();
        let request_shared = shared.clone();
        let request_code = code.clone();
        let outcome = tokio::task::spawn_blocking(move || redeem(&request_shared, &request_code))
            .await
            .unwrap_or_else(|_| Err("internal".into()));
        match outcome {
            Ok(Redeemed { bridge_id, token, device_id }) => {
                let added_at = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0);
                shared.reload();
                shared.update(|stored| {
                    stored.bridge_id = Some(bridge_id.clone());
                    if let Some(token) = token {
                        stored.bridge_token = Some(token);
                    }
                    stored.enabled = true;
                    stored.app_keys.retain(|k| k.device_id != device_id);
                    stored.app_keys.push(AppKey {
                        device_id: device_id.clone(),
                        key: e2e::key_to_b64(&app_key),
                        added_at,
                    });
                });
                let ack = ack_request(&code, &bridge_public);
                shared.pair_finished(&code, Some(ack.clone()));
                let _ = shared.obs_outbox.send(ack);
                shared.emit(json!({"type": "pair_result", "ok": true, "bridge_id": bridge_id, "device_id": device_id}));
            }
            Err(reason) => {
                shared.pair_finished(&code, None);
                shared.log("warn", format!("pairing refused: {reason}"));
                if reason == "unknown_bridge" {
                    // Our token was revoked: forget it, the next code pairs fresh.
                    shared.update(|stored| {
                        stored.bridge_token = None;
                        stored.bridge_id = None;
                        stored.app_keys.clear();
                    });
                }
                shared.emit(json!({"type": "pair_result", "ok": false, "reason": reason}));
            }
        }
    });
}

/// The CustomEvent that hands this bridge's key to the pairing phone.
fn ack_request(code: &str, bridge_public: &[u8]) -> String {
    json!({"op": 6, "d": {
        "requestType": "BroadcastCustomEvent",
        "requestId": "obb-pair-ack",
        "requestData": {"eventData": {PAIR_ACK_EVENT_KEY: {
            "code": code,
            "bridge_key": e2e::key_to_b64(bridge_public),
        }}},
    }})
    .to_string()
}

struct Redeemed {
    bridge_id: String,
    token: Option<String>,
    device_id: String,
}

fn redeem(shared: &Shared, code: &str) -> Result<Redeemed, String> {
    let stored = shared.reload();
    let agent: ureq::Agent = ureq::Agent::config_builder()
        .http_status_as_error(false)
        .timeout_global(Some(Duration::from_secs(15)))
        .build()
        .into();
    let mut request = agent
        .post(format!("{}/v1/pairings/redeem", shared.relay_http()))
        .header("User-Agent", format!("obs-blade-bridge/{}", shared.cfg.version));
    if let Some(token) = stored.bridge_token.as_deref().filter(|t| !t.is_empty()) {
        request = request.header("Authorization", format!("Bearer {token}"));
    }
    let mut response = request
        .send_json(json!({
            "code": code,
            "name": shared.cfg.name,
            "kind": shared.cfg.kind.as_str(),
            "version": shared.cfg.version,
        }))
        .map_err(|e| {
            shared.log("warn", format!("pairing request failed: {e}"));
            "network".to_owned()
        })?;
    let status = response.status().as_u16();
    let body: Value = response.body_mut().read_json().unwrap_or(Value::Null);
    if status != 200 {
        return Err(body["error"].as_str().unwrap_or("relay_error").to_owned());
    }
    let bridge_id = body["bridge_id"].as_str().ok_or("relay_error")?.to_owned();
    let token = body["bridge_token"].as_str().map(str::to_owned);
    if token.is_none() && !stored.paired() {
        return Err("relay_error".into());
    }
    let device_id = body["device_id"].as_str().ok_or("relay_error")?.to_owned();
    Ok(Redeemed { bridge_id, token, device_id })
}
