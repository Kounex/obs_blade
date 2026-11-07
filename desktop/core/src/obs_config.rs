//! obs-websocket's own settings, read from OBS's config directory so the
//! bridge needs no password entry.
//!
//! Source: obs-websocket `src/Config.cpp` - the file is
//! `<OBS config>/plugin_config/obs-websocket/config.json` with the keys
//! below; defaults from `src/Config.h` (server off, port 4455, auth on).
//! OBS started with `--websocket_port` / `--websocket_password` overrides
//! the file; the settings' manual override covers that case.

use std::path::{Path, PathBuf};
use std::time::SystemTime;

use serde_json::Value;

pub const DEFAULT_PORT: u16 = 4455;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WsConfig {
    pub enabled: bool,
    pub port: u16,
    pub auth_required: bool,
    pub password: String,
}

impl Default for WsConfig {
    fn default() -> Self {
        Self { enabled: false, port: DEFAULT_PORT, auth_required: true, password: String::new() }
    }
}

/// OBS config roots on this machine, most common first.
pub fn config_roots() -> Vec<PathBuf> {
    let mut roots = Vec::new();
    // Windows %APPDATA%, macOS ~/Library/Application Support, Linux ~/.config
    if let Some(dir) = dirs::config_dir() {
        roots.push(dir.join("obs-studio"));
    }
    #[cfg(target_os = "linux")]
    if let Some(home) = dirs::home_dir() {
        roots.push(home.join(".var/app/com.obsproject.Studio/config/obs-studio"));
    }
    roots
}

pub fn ws_config_file(root: &Path) -> PathBuf {
    root.join("plugin_config").join("obs-websocket").join("config.json")
}

pub fn parse(text: &str) -> WsConfig {
    let mut config = WsConfig::default();
    let Ok(Value::Object(map)) = serde_json::from_str::<Value>(text) else {
        return config;
    };
    if let Some(Value::Bool(v)) = map.get("server_enabled") {
        config.enabled = *v;
    }
    if let Some(port) = map.get("server_port").and_then(Value::as_u64)
        && let Ok(port) = u16::try_from(port)
        && port > 0
    {
        config.port = port;
    }
    if let Some(Value::Bool(v)) = map.get("auth_required") {
        config.auth_required = *v;
    }
    if let Some(Value::String(v)) = map.get("server_password") {
        config.password = v.clone();
    }
    config
}

/// The config file to use: `explicit` (the plugin passes the exact path,
/// portable installs included), else the most recently written one of
/// the known roots (a machine can have both a native and a Flatpak OBS).
pub fn find(explicit: Option<&Path>) -> Option<(PathBuf, WsConfig)> {
    if let Some(path) = explicit {
        let text = std::fs::read_to_string(path).ok()?;
        return Some((path.to_path_buf(), parse(&text)));
    }
    let mut best: Option<(SystemTime, PathBuf)> = None;
    for root in config_roots() {
        let file = ws_config_file(&root);
        if let Ok(meta) = std::fs::metadata(&file) {
            let modified = meta.modified().unwrap_or(SystemTime::UNIX_EPOCH);
            if best.as_ref().is_none_or(|(t, _)| modified > *t) {
                best = Some((modified, file));
            }
        }
    }
    let (_, file) = best?;
    let text = std::fs::read_to_string(&file).ok()?;
    Some((file, parse(&text)))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_obs_websocket_config() {
        let c = parse(
            r#"{"alerts_enabled":false,"auth_required":true,"first_load":false,
                "server_enabled":true,"server_password":"s3cr3t","server_port":4466}"#,
        );
        assert_eq!(
            c,
            WsConfig { enabled: true, port: 4466, auth_required: true, password: "s3cr3t".into() }
        );
    }

    #[test]
    fn missing_or_odd_values_fall_back_to_obs_defaults() {
        assert_eq!(parse("{}"), WsConfig::default());
        assert_eq!(parse("not json"), WsConfig::default());
        let c = parse(r#"{"server_port":70000,"server_enabled":"yes"}"#);
        assert_eq!((c.port, c.enabled), (DEFAULT_PORT, false));
    }
}
