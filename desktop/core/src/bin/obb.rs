//! Headless bridge host: runs the core, prints events as JSON lines and
//! takes commands as JSON lines on stdin (`{"cmd":"pair","code":"..."}`).
//! For development and end-to-end tests; also usable as a headless bridge.
//!
//! obb [--kind standalone|plugin] [--relay URL] [--state PATH]
//!     [--obs-config PATH] [--name NAME] [--obs-running true|false]

use std::io::BufRead;
use std::sync::Arc;

use obb::{Bridge, Config, Kind};
use serde_json::{Value, json};

fn main() {
    let mut args = std::env::args().skip(1);
    let mut cfg = Config::new(Kind::Standalone);
    let mut running = None;
    while let Some(arg) = args.next() {
        let mut value = || args.next().unwrap_or_else(|| usage(&arg));
        match arg.as_str() {
            "--kind" => {
                cfg.kind = match value().as_str() {
                    "plugin" => Kind::Plugin,
                    "standalone" => Kind::Standalone,
                    other => usage(other),
                }
            }
            "--relay" => cfg.relay_url = value(),
            "--state" => cfg.state_path = value().into(),
            "--obs-config" => cfg.obs_ws_config = Some(value().into()),
            "--name" => cfg.name = value(),
            "--obs-running" => running = Some(value() == "true"),
            _ => usage(&arg),
        }
    }
    let bridge = Bridge::start(cfg, Arc::new(|event: Value| println!("{event}")))
        .expect("bridge runtime");
    if let Some(value) = running {
        bridge.command(&json!({"cmd": "obs_running", "value": value}));
    }
    for line in std::io::stdin().lock().lines() {
        let Ok(line) = line else { break };
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        match serde_json::from_str::<Value>(line) {
            Ok(command) if bridge.command(&command) => {}
            _ => eprintln!("unknown command: {line}"),
        }
    }
    bridge.stop(false);
}

fn usage(arg: &str) -> ! {
    eprintln!("bad argument {arg}\nobb [--kind standalone|plugin] [--relay URL] [--state PATH] [--obs-config PATH] [--name NAME] [--obs-running true|false]");
    std::process::exit(2)
}
