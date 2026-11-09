//! The bridge's stored identity and settings. One file per OS user,
//! shared by the plugin and the standalone so both act as the same paired
//! bridge (the relay lets the newer connection win).

use std::io::Write;
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default)]
pub struct Stored {
    pub bridge_id: Option<String>,
    pub bridge_token: Option<String>,
    /// Remote access on/off (the panel's switch).
    pub enabled: bool,
    pub preview_max_edge: u32,
    pub preview_jpeg_quality: i32,
    /// Manual override when OBS runs with --websocket_port/--websocket_password.
    pub obs_port: Option<u16>,
    pub obs_password: Option<String>,
    /// Standalone: the OBS executable last seen running (portable installs:
    /// its config folder, starting it, its crash marks)
    pub obs_exe: Option<String>,
    /// This bridge's X25519 static key pair (base64), for end-to-end
    /// encryption (`e2e.rs`). Made once; the phones pin the public key.
    pub e2e_private: Option<String>,
    pub e2e_public: Option<String>,
    /// The phones paired with this bridge: only their static keys open a
    /// session. Exchanged through OBS when pairing, never via the relay.
    pub app_keys: Vec<AppKey>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AppKey {
    /// The relay's device id (assigned at redeem): removing the device
    /// there removes its key here
    pub device_id: String,
    /// base64 X25519 public key
    pub key: String,
    /// Unix seconds: a key stays while the app hasn't collected the
    /// pairing yet (the relay's device list doesn't have it then)
    pub added_at: u64,
}

impl Default for Stored {
    fn default() -> Self {
        Self {
            bridge_id: None,
            bridge_token: None,
            enabled: true,
            preview_max_edge: 640,
            preview_jpeg_quality: 60,
            obs_port: None,
            obs_password: None,
            obs_exe: None,
            e2e_private: None,
            e2e_public: None,
            app_keys: Vec::new(),
        }
    }
}

impl Stored {
    pub fn paired(&self) -> bool {
        self.bridge_token.as_deref().is_some_and(|t| !t.is_empty())
    }
}

pub fn default_path() -> PathBuf {
    dirs::config_dir()
        .unwrap_or_else(std::env::temp_dir)
        .join("obs-blade-remote")
        .join("bridge.json")
}

pub fn load(path: &Path) -> Stored {
    std::fs::read_to_string(path)
        .ok()
        .and_then(|text| serde_json::from_str(&text).ok())
        .unwrap_or_default()
}

/// Written atomically (temp file + rename), readable by the user only:
/// the bridge token is a credential.
pub fn save(path: &Path, stored: &Stored) -> std::io::Result<()> {
    if let Some(dir) = path.parent() {
        std::fs::create_dir_all(dir)?;
    }
    let tmp = path.with_extension("json.tmp");
    {
        let mut options = std::fs::OpenOptions::new();
        options.write(true).create(true).truncate(true);
        #[cfg(unix)]
        {
            use std::os::unix::fs::OpenOptionsExt;
            options.mode(0o600);
        }
        let mut file = options.open(&tmp)?;
        file.write_all(serde_json::to_string_pretty(stored)?.as_bytes())?;
        file.sync_all()?;
    }
    std::fs::rename(&tmp, path)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn save_and_load_round_trip_with_private_mode() {
        let dir = std::env::temp_dir().join(format!("obb-state-{}", std::process::id()));
        let path = dir.join("bridge.json");
        let stored = Stored { bridge_token: Some("t".into()), obs_port: Some(4460), ..Stored::default() };
        save(&path, &stored).unwrap();
        assert_eq!(load(&path), stored);
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            assert_eq!(std::fs::metadata(&path).unwrap().permissions().mode() & 0o777, 0o600);
        }
        std::fs::remove_dir_all(dir).unwrap();
    }

    #[test]
    fn missing_or_partial_file_gives_defaults() {
        assert_eq!(load(Path::new("/nonexistent/obb.json")), Stored::default());
        let partial: Stored = serde_json::from_str(r#"{"enabled": false}"#).unwrap();
        assert!(!partial.enabled);
        assert_eq!(partial.preview_max_edge, 640);
    }
}
