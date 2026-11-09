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

/// The folder a portable OBS keeps its `config` in, from its executable
/// (frontend/OBSApp.cpp: `CONFIG_PATH` = `BASE_PATH "/config"`, relative
/// to `bin/64bit` on Windows (`../..`) and to `bin` on Linux builds with
/// `ENABLE_PORTABLE_CONFIG` (`..`); macOS has no portable mode).
pub fn install_base(exe: &Path, windows: bool) -> Option<PathBuf> {
    let bin = exe.parent()?;
    let base = if windows { bin.parent()?.parent()? } else { bin.parent()? };
    Some(base.to_path_buf())
}

/// OBS's config root inside a portable install
pub fn portable_root(base: &Path) -> PathBuf {
    base.join("config").join("obs-studio")
}

/// Portable mode by marker file (frontend/obs-main.cpp); `--portable` on
/// the command line leaves none
pub fn has_portable_marker(base: &Path) -> bool {
    ["portable_mode", "obs_portable_mode", "portable_mode.txt", "obs_portable_mode.txt"]
        .iter()
        .any(|name| base.join(name).exists())
}

/// The config file to use: `explicit` (the plugin passes the exact path,
/// portable installs included); else, with the OBS executable the shell
/// saw running, its portable config when the install is marked portable;
/// else the most recently written one of the known roots (a machine can
/// have both a native and a Flatpak OBS, an install started with
/// `--portable` has no marker).
pub fn find(explicit: Option<&Path>, exe: Option<&Path>) -> Option<(PathBuf, WsConfig)> {
    find_in(explicit, exe, cfg!(windows), config_roots())
}

fn find_in(explicit: Option<&Path>, exe: Option<&Path>, windows: bool, mut roots: Vec<PathBuf>) -> Option<(PathBuf, WsConfig)> {
    if let Some(path) = explicit {
        let text = std::fs::read_to_string(path).ok()?;
        return Some((path.to_path_buf(), parse(&text)));
    }
    if let Some(base) = exe.and_then(|exe| install_base(exe, windows)) {
        let file = ws_config_file(&portable_root(&base));
        if has_portable_marker(&base)
            && let Ok(text) = std::fs::read_to_string(&file)
        {
            return Some((file, parse(&text)));
        }
        roots.push(portable_root(&base));
    }
    let mut best: Option<(SystemTime, PathBuf)> = None;
    for root in roots {
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

    fn scratch(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("obb-obs-config-{}-{name}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        dir
    }

    fn write_config(root: &Path, port: u16) -> PathBuf {
        let file = ws_config_file(root);
        std::fs::create_dir_all(file.parent().unwrap()).unwrap();
        std::fs::write(&file, format!(r#"{{"server_enabled":true,"server_port":{port}}}"#)).unwrap();
        file
    }

    #[test]
    fn install_base_from_the_running_executable() {
        let exe = Path::new("/d/OBS/bin/64bit/obs64.exe");
        assert_eq!(install_base(exe, true), Some(PathBuf::from("/d/OBS")));
        assert_eq!(install_base(Path::new("/opt/obs/bin/obs"), false), Some(PathBuf::from("/opt/obs")));
    }

    #[test]
    fn a_marked_portable_install_wins_over_the_user_config() {
        let dir = scratch("marker");
        let user_root = dir.join("appdata/obs-studio");
        let base = dir.join("OBS-portable");
        let portable = write_config(&portable_root(&base), 4466);
        // The user config is newer - the marker still decides
        std::thread::sleep(std::time::Duration::from_millis(20));
        write_config(&user_root, 4455);
        std::fs::write(base.join("portable_mode.txt"), "").unwrap();
        let exe = base.join("bin/64bit/obs64.exe");
        let (file, config) = find_in(None, Some(&exe), true, vec![user_root.clone()]).unwrap();
        assert_eq!((file, config.port), (portable, 4466));
    }

    #[test]
    fn without_a_marker_the_portable_config_competes_by_age() {
        let dir = scratch("age");
        let user_root = dir.join("appdata/obs-studio");
        let base = dir.join("OBS-portable");
        write_config(&user_root, 4455);
        std::thread::sleep(std::time::Duration::from_millis(20));
        let portable = write_config(&portable_root(&base), 4466);
        let exe = base.join("bin/64bit/obs64.exe");
        let (file, _) = find_in(None, Some(&exe), true, vec![user_root.clone()]).unwrap();
        assert_eq!(file, portable);
        // Nothing anywhere: not found (the shell shows that)
        assert!(find_in(None, None, true, vec![dir.join("none")]).is_none());
    }
}
