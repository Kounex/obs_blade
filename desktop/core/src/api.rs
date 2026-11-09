//! The bridge as the shells use it: start, send commands, stop.
//!
//! Commands (JSON, `{"cmd": ...}`):
//! - `pair {code, app_key}` - redeem a code with the phone's end-to-end
//!   key (the plugin's vendor request; the standalone also gets codes as a
//!   CustomEvent itself). The ack with this bridge's key goes back as the
//!   `obs-blade-pair-ack` CustomEvent either way; `state.bridge_key` has
//!   it too (for the vendor request's answer)
//! - `set_enabled {value}`, `set_preview {max_edge, jpeg_quality}`,
//!   `set_obs_override {port|null, password|null}`
//! - `remove_device {id}`, `refresh_devices`, `unpair`
//! - `obs_running {value}` - the shell's knowledge of the OBS process
//! - `open_plugin_panel` - standalone, deferred: the plugin shows its panel
//!   in OBS
//!
//! Events (JSON to the sink, from bridge threads - marshal to your UI
//! thread): `state {...}`, `pair_result {ok, bridge_id, device_id | reason}`,
//! `start_obs {device}` (standalone).

use std::sync::Arc;
use std::time::Duration;

use serde_json::{Value, json};

use crate::shared::{Config, Shared, Sink};

pub struct Bridge {
    shared: Arc<Shared>,
    runtime: Option<tokio::runtime::Runtime>,
    tasks: Vec<tokio::task::JoinHandle<()>>,
}

impl Bridge {
    pub fn start(cfg: Config, sink: Sink) -> std::io::Result<Self> {
        let _ = rustls::crypto::ring::default_provider().install_default();
        let runtime = tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .thread_name("obs-blade-bridge")
            .enable_all()
            .build()?;
        let shared = Shared::new(cfg, sink);
        // Made up front: the panel / vendor answer shows the key at once.
        shared.e2e_keypair();
        let tasks = {
            let _guard = runtime.enter();
            vec![
                tokio::spawn(crate::relay::run(shared.clone())),
                tokio::spawn(crate::monitor::run(shared.clone())),
            ]
        };
        shared.emit_state();
        Ok(Self { shared, runtime: Some(runtime), tasks })
    }

    /// Returns false for an unknown or malformed command.
    pub fn command(&self, command: &Value) -> bool {
        let shared = &self.shared;
        let Some(name) = command["cmd"].as_str() else { return false };
        match name {
            "pair" => {
                let Some(code) = command["code"].as_str() else { return false };
                let app_key = command["app_key"].as_str().unwrap_or_default();
                let _guard = self.runtime.as_ref().map(|r| r.enter());
                crate::pairing::pair(shared.clone(), code.to_owned(), app_key.to_owned());
            }
            "set_enabled" => {
                let Some(value) = command["value"].as_bool() else { return false };
                shared.update(|s| s.enabled = value);
            }
            "set_preview" => {
                let edge = command["max_edge"].as_u64().map(|v| v.min(4096) as u32);
                let quality = command["jpeg_quality"].as_i64().map(|v| v.clamp(1, 100) as i32);
                shared.update(|s| {
                    if let Some(edge) = edge {
                        s.preview_max_edge = edge;
                    }
                    if let Some(quality) = quality {
                        s.preview_jpeg_quality = quality;
                    }
                });
            }
            "set_obs_override" => {
                let port = command["port"].as_u64().and_then(|p| u16::try_from(p).ok());
                let password = command["password"].as_str().map(str::to_owned);
                shared.update(|s| {
                    s.obs_port = port;
                    s.obs_password = password;
                });
            }
            "remove_device" => {
                let Some(id) = command["id"].as_str() else { return false };
                let _ = shared.control_tx.send(json!({"type": "remove_device", "id": id}));
            }
            "refresh_devices" => {
                let _ = shared.control_tx.send(json!({"type": "devices"}));
            }
            "unpair" => {
                let _ = shared.control_tx.send(json!({"type": "unpair"}));
                // Offline: forget locally anyway; the relay purges idle devices.
                let shared = shared.clone();
                if let Some(runtime) = self.runtime.as_ref() {
                    runtime.spawn(async move {
                        tokio::time::sleep(Duration::from_secs(2)).await;
                        shared.update(|s| {
                            s.bridge_token = None;
                            s.bridge_id = None;
                            s.app_keys.clear();
                        });
                        shared.set_devices(Vec::new());
                    });
                }
            }
            "open_plugin_panel" => {
                let _ = shared.obs_outbox.send(crate::monitor::open_plugin_panel_request());
            }
            "obs_running" => {
                let value = command["value"].as_bool();
                if shared.obs_running.send_replace(value) != value {
                    shared.wake.notify_waiters();
                }
            }
            _ => return false,
        }
        true
    }

    /// `obs_exit`: OBS is closing cleanly (plugin) - the relay tells the
    /// phone "OBS was closed" instead of "PC offline".
    pub fn stop(mut self, obs_exit: bool) {
        self.shared.stop.send_replace(Some(obs_exit));
        if let Some(runtime) = self.runtime.take() {
            let tasks = std::mem::take(&mut self.tasks);
            runtime.block_on(async {
                let _ = tokio::time::timeout(Duration::from_secs(2), futures_util::future::join_all(tasks)).await;
            });
            runtime.shutdown_timeout(Duration::from_secs(1));
        }
    }
}

impl Drop for Bridge {
    fn drop(&mut self) {
        if let Some(runtime) = self.runtime.take() {
            self.shared.stop.send_replace(Some(false));
            runtime.shutdown_timeout(Duration::from_secs(1));
        }
    }
}
