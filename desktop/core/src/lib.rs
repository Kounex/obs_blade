//! OBS Blade Remote bridge core, shared by the OBS plugin and the
//! standalone app. Design: docs/superpowers/specs/2026-11-07-remote-relay-design.md,
//! relay protocol: tool/remote_relay/README.md.

pub mod api;
pub mod auth;
pub mod ffi;
pub mod monitor;
pub mod obs_config;
pub mod obs_link;
pub mod pairing;
pub mod relay;
pub mod rewrite;
pub mod session;
pub mod shared;
pub mod state;
pub mod wire;

pub use api::Bridge;
pub use shared::{Config, Kind};
