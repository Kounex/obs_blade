//! Redeems a pairing code at the relay (`POST /v1/pairings/redeem`).

use std::sync::Arc;
use std::time::Duration;

use serde_json::{Value, json};

use crate::shared::Shared;

/// Runs in the background; the outcome arrives as a `pair_result` event.
pub fn pair(shared: Arc<Shared>, code: String) {
    if !shared.first_sight_of(&code) {
        return;
    }
    shared.log("info", "redeeming a pairing code");
    tokio::spawn(async move {
        let request_shared = shared.clone();
        let outcome = tokio::task::spawn_blocking(move || redeem(&request_shared, &code))
            .await
            .unwrap_or_else(|_| Err("internal".into()));
        match outcome {
            Ok((bridge_id, token)) => {
                shared.update(|stored| {
                    stored.bridge_id = Some(bridge_id.clone());
                    if let Some(token) = token {
                        stored.bridge_token = Some(token);
                    }
                    stored.enabled = true;
                });
                shared.emit(json!({"type": "pair_result", "ok": true, "bridge_id": bridge_id}));
            }
            Err(reason) => {
                shared.log("warn", format!("pairing refused: {reason}"));
                if reason == "unknown_bridge" {
                    // Our token was revoked: forget it, the next code pairs fresh.
                    shared.update(|stored| {
                        stored.bridge_token = None;
                        stored.bridge_id = None;
                    });
                }
                shared.emit(json!({"type": "pair_result", "ok": false, "reason": reason}));
            }
        }
    });
}

fn redeem(shared: &Shared, code: &str) -> Result<(String, Option<String>), String> {
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
    Ok((bridge_id, token))
}
