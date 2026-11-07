//! C ABI for the shells (`include/obs_blade_bridge.h`). JSON in and out
//! keeps the ABI to four functions that never change shape.

use std::ffi::{CStr, CString, c_char, c_void};
use std::path::PathBuf;
use std::sync::Arc;

use serde_json::Value;

use crate::api::Bridge;
use crate::shared::{Config, Kind};

pub type ObbEventCallback = extern "C" fn(json: *const c_char, user: *mut c_void);

pub struct ObbBridge(Bridge);

struct UserPtr(*mut c_void);
// The shell owns `user` and promises it stays valid and thread-safe until
// obb_stop returns (documented in the header).
unsafe impl Send for UserPtr {}
unsafe impl Sync for UserPtr {}

fn config_from(json: &Value) -> Option<Config> {
    let kind = match json["kind"].as_str()? {
        "plugin" => Kind::Plugin,
        "standalone" => Kind::Standalone,
        _ => return None,
    };
    let mut cfg = Config::new(kind);
    if let Some(name) = json["name"].as_str().filter(|n| !n.trim().is_empty()) {
        cfg.name = name.trim().to_owned();
    }
    if let Some(url) = json["relay_url"].as_str() {
        cfg.relay_url = url.to_owned();
    }
    if let Some(path) = json["state_path"].as_str() {
        cfg.state_path = PathBuf::from(path);
    }
    if let Some(path) = json["obs_ws_config"].as_str() {
        cfg.obs_ws_config = Some(PathBuf::from(path));
    }
    Some(cfg)
}

/// # Safety
/// `config_json` must be a valid NUL-terminated UTF-8 string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn obb_start(
    config_json: *const c_char,
    callback: ObbEventCallback,
    user: *mut c_void,
) -> *mut ObbBridge {
    if config_json.is_null() {
        return std::ptr::null_mut();
    }
    let text = unsafe { CStr::from_ptr(config_json) }.to_string_lossy();
    let Some(cfg) = serde_json::from_str::<Value>(&text).ok().as_ref().and_then(config_from) else {
        return std::ptr::null_mut();
    };
    let user = Arc::new(UserPtr(user));
    let sink = Arc::new(move |event: Value| {
        if let Ok(text) = CString::new(event.to_string()) {
            callback(text.as_ptr(), user.0);
        }
    });
    match Bridge::start(cfg, sink) {
        Ok(bridge) => Box::into_raw(Box::new(ObbBridge(bridge))),
        Err(_) => std::ptr::null_mut(),
    }
}

/// # Safety
/// `bridge` from obb_start and not yet stopped; `command_json` NUL-terminated.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn obb_command(bridge: *mut ObbBridge, command_json: *const c_char) -> bool {
    if bridge.is_null() || command_json.is_null() {
        return false;
    }
    let text = unsafe { CStr::from_ptr(command_json) }.to_string_lossy();
    let Ok(command) = serde_json::from_str::<Value>(&text) else { return false };
    unsafe { &*bridge }.0.command(&command)
}

/// # Safety
/// `bridge` from obb_start; invalid afterwards. No callback runs after return.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn obb_stop(bridge: *mut ObbBridge, obs_exit: bool) {
    if bridge.is_null() {
        return;
    }
    let bridge = unsafe { Box::from_raw(bridge) };
    bridge.0.stop(obs_exit);
}

#[unsafe(no_mangle)]
pub extern "C" fn obb_version() -> *const c_char {
    concat!(env!("CARGO_PKG_VERSION"), "\0").as_ptr().cast()
}
