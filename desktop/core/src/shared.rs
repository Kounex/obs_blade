//! State shared by the bridge's tasks and the shell (plugin / standalone).

use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use serde_json::{Value, json};
use tokio::sync::{Notify, mpsc, watch};

use crate::obs_config::{self, WsConfig};
use crate::rewrite::PreviewCap;
use crate::state::{self, Stored};

pub const DEFAULT_RELAY: &str = "https://relay.obs-blade.com";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    Plugin,
    Standalone,
}

impl Kind {
    pub fn as_str(self) -> &'static str {
        match self {
            Kind::Plugin => "plugin",
            Kind::Standalone => "standalone",
        }
    }
}

#[derive(Debug, Clone)]
pub struct Config {
    pub kind: Kind,
    /// Shown in the app ("GAMING-PC"); the shell passes a nice name.
    pub name: String,
    pub relay_url: String,
    pub state_path: PathBuf,
    /// Exact obs-websocket config.json (the plugin knows it, portable
    /// installs included); otherwise the known locations are searched.
    pub obs_ws_config: Option<PathBuf>,
    pub version: String,
}

impl Config {
    pub fn new(kind: Kind) -> Self {
        Self {
            kind,
            name: machine_name(),
            relay_url: DEFAULT_RELAY.into(),
            state_path: state::default_path(),
            obs_ws_config: None,
            version: env!("CARGO_PKG_VERSION").into(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum RelayState {
    Disabled,
    Unpaired,
    /// Standalone while the plugin in OBS holds the link.
    Deferred,
    Connecting,
    Online,
    Offline(String),
    UpdateRequired(String),
}

impl RelayState {
    fn label(&self) -> &'static str {
        match self {
            RelayState::Disabled => "disabled",
            RelayState::Unpaired => "unpaired",
            RelayState::Deferred => "deferred",
            RelayState::Connecting => "connecting",
            RelayState::Online => "online",
            RelayState::Offline(_) => "offline",
            RelayState::UpdateRequired(_) => "update_required",
        }
    }
}

pub type Sink = Arc<dyn Fn(Value) + Send + Sync>;

pub struct Shared {
    pub cfg: Config,
    stored: Mutex<Stored>,
    pub devices: Mutex<Vec<Value>>,
    pub relay_state: Mutex<RelayState>,
    pub obs_state: watch::Sender<String>,
    pub obs_running: watch::Sender<Option<bool>>,
    pub plugin_present: watch::Sender<bool>,
    pub status: watch::Sender<Option<Value>>,
    /// Stored settings / pairing changed.
    pub wake: Notify,
    /// Some(obs_exit) once the shell stops the bridge.
    pub stop: watch::Sender<Option<bool>>,
    pub control_tx: mpsc::UnboundedSender<Value>,
    pub control_rx: Mutex<Option<mpsc::UnboundedReceiver<Value>>>,
    sink: Sink,
    last_emitted: Mutex<String>,
    /// Codes already redeemed or in flight: the app re-sends its code
    /// until the pairing is collected (a CustomEvent can be missed).
    recent_codes: Mutex<Vec<String>>,
    /// OBS base canvas width / height (GetVideoSettings), for the preview cap.
    pub canvas_aspect: Mutex<Option<f64>>,
}

impl Shared {
    pub fn new(cfg: Config, sink: Sink) -> Arc<Self> {
        let stored = state::load(&cfg.state_path);
        let (control_tx, control_rx) = mpsc::unbounded_channel();
        Arc::new(Self {
            cfg,
            stored: Mutex::new(stored),
            devices: Mutex::new(Vec::new()),
            relay_state: Mutex::new(RelayState::Connecting),
            obs_state: watch::Sender::new(String::new()),
            obs_running: watch::Sender::new(None),
            plugin_present: watch::Sender::new(false),
            status: watch::Sender::new(None),
            wake: Notify::new(),
            stop: watch::Sender::new(None),
            control_tx,
            control_rx: Mutex::new(Some(control_rx)),
            sink,
            last_emitted: Mutex::new(String::new()),
            recent_codes: Mutex::new(Vec::new()),
            canvas_aspect: Mutex::new(None),
        })
    }

    pub fn stored(&self) -> Stored {
        self.stored.lock().unwrap().clone()
    }

    /// Re-read from disk: the plugin and the standalone share the file.
    pub fn reload(&self) -> Stored {
        let fresh = state::load(&self.cfg.state_path);
        *self.stored.lock().unwrap() = fresh.clone();
        fresh
    }

    pub fn update(&self, change: impl FnOnce(&mut Stored)) {
        let snapshot = {
            let mut stored = self.stored.lock().unwrap();
            change(&mut stored);
            stored.clone()
        };
        if let Err(error) = state::save(&self.cfg.state_path, &snapshot) {
            self.log("error", format!("saving bridge state failed: {error}"));
        }
        self.wake.notify_waiters();
        self.emit_state();
    }

    pub fn ws_config(&self) -> WsConfig {
        let stored = self.stored();
        let mut ws = obs_config::find(self.cfg.obs_ws_config.as_deref())
            .map(|(_, c)| c)
            .unwrap_or_default();
        if let Some(port) = stored.obs_port {
            ws.port = port;
            ws.enabled = true;
        }
        if let Some(password) = stored.obs_password {
            ws.auth_required = !password.is_empty();
            ws.password = password;
        }
        ws
    }

    pub fn preview_cap(&self) -> PreviewCap {
        let stored = self.stored();
        PreviewCap {
            max_edge: stored.preview_max_edge,
            jpeg_quality: stored.preview_jpeg_quality,
            canvas_aspect: *self.canvas_aspect.lock().unwrap(),
        }
    }

    pub fn set_relay_state(&self, state: RelayState) {
        *self.relay_state.lock().unwrap() = state;
        self.emit_state();
    }

    pub fn set_obs_state(&self, state: &str) {
        self.obs_state.send_if_modified(|current| {
            if current == state {
                return false;
            }
            *current = state.to_owned();
            true
        });
        self.emit_state();
    }

    pub fn set_devices(&self, devices: Vec<Value>) {
        *self.devices.lock().unwrap() = devices;
        self.emit_state();
    }

    pub fn emit(&self, event: Value) {
        (self.sink)(event);
    }

    /// Diagnostics for the shell's log (the plugin writes them to OBS's log).
    pub fn log(&self, level: &str, message: impl Into<String>) {
        self.emit(json!({"type": "log", "level": level, "message": message.into()}));
    }

    /// Full state for the panel; sent only when it changed.
    pub fn emit_state(&self) {
        let stored = self.stored();
        let relay = self.relay_state.lock().unwrap().clone();
        let detail = match &relay {
            RelayState::Offline(reason) => Some(reason.clone()),
            RelayState::UpdateRequired(min) => Some(min.clone()),
            _ => None,
        };
        let event = json!({
            "type": "state",
            "kind": self.cfg.kind.as_str(),
            "relay": relay.label(),
            "detail": detail,
            "obs": *self.obs_state.borrow(),
            "paired": stored.paired(),
            "bridge_id": stored.bridge_id,
            "enabled": stored.enabled,
            "devices": *self.devices.lock().unwrap(),
            "preview_max_edge": stored.preview_max_edge,
            "preview_jpeg_quality": stored.preview_jpeg_quality,
            "obs_port": stored.obs_port,
            "obs_password_set": stored.obs_password.is_some(),
            "name": self.cfg.name,
            "version": self.cfg.version,
        });
        let text = event.to_string();
        {
            let mut last = self.last_emitted.lock().unwrap();
            if *last == text {
                return;
            }
            *last = text;
        }
        self.emit(event);
    }

    /// False when this code was seen already (a repeat from the app).
    pub fn first_sight_of(&self, code: &str) -> bool {
        let code: String = code.chars().filter(char::is_ascii_alphanumeric).collect::<String>().to_ascii_uppercase();
        let mut recent = self.recent_codes.lock().unwrap();
        if recent.contains(&code) {
            return false;
        }
        if recent.len() >= 16 {
            recent.remove(0);
        }
        recent.push(code);
        true
    }

    pub fn relay_http(&self) -> String {
        self.cfg.relay_url.trim_end_matches('/').to_owned()
    }

    pub fn relay_ws(&self) -> String {
        let base = self.relay_http();
        let ws = if let Some(rest) = base.strip_prefix("https://") {
            format!("wss://{rest}")
        } else if let Some(rest) = base.strip_prefix("http://") {
            format!("ws://{rest}")
        } else {
            base
        };
        format!("{ws}/v1/bridge")
    }

    pub fn stopping(&self) -> bool {
        self.stop.borrow().is_some()
    }
}

/// The PC's name as people know it.
pub fn machine_name() -> String {
    #[cfg(target_os = "windows")]
    if let Ok(name) = std::env::var("COMPUTERNAME") {
        return name;
    }
    #[cfg(target_os = "macos")]
    if let Some(name) = command_output("scutil", &["--get", "ComputerName"]) {
        return name;
    }
    #[cfg(target_os = "linux")]
    if let Ok(name) = std::fs::read_to_string("/etc/hostname") {
        let name = name.trim();
        if !name.is_empty() {
            return name.to_owned();
        }
    }
    command_output("hostname", &[])
        .map(|n| n.split('.').next().unwrap_or(&n).to_owned())
        .unwrap_or_else(|| "OBS PC".into())
}

fn command_output(program: &str, args: &[&str]) -> Option<String> {
    let output = std::process::Command::new(program).args(args).output().ok()?;
    let text = String::from_utf8(output.stdout).ok()?;
    let text = text.trim();
    (output.status.success() && !text.is_empty()).then(|| text.to_owned())
}
