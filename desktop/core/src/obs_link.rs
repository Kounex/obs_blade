//! Local websocket connections to OBS.

use std::time::Duration;

use futures_util::StreamExt;
use serde_json::Value;
use tokio::net::TcpStream;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::tungstenite::http::HeaderValue;
use tokio_tungstenite::tungstenite::{Error as WsError, Message};
use tokio_tungstenite::{MaybeTlsStream, WebSocketStream, connect_async};

use crate::obs_config::WsConfig;

pub type LocalWs = WebSocketStream<MaybeTlsStream<TcpStream>>;

pub const CONNECT_TIMEOUT: Duration = Duration::from_secs(5);

#[derive(Debug, PartialEq, Eq)]
pub enum ConnectError {
    /// Nothing listens on the port: OBS closed, or its server is off.
    Refused,
    Other(String),
}

pub async fn connect(port: u16) -> Result<LocalWs, ConnectError> {
    let mut request = format!("ws://127.0.0.1:{port}")
        .into_client_request()
        .map_err(|e| ConnectError::Other(e.to_string()))?;
    request
        .headers_mut()
        .insert("Sec-WebSocket-Protocol", HeaderValue::from_static("obswebsocket.json"));
    match tokio::time::timeout(CONNECT_TIMEOUT, connect_async(request)).await {
        Err(_) => Err(ConnectError::Other("timeout".into())),
        Ok(Err(WsError::Io(e))) if e.kind() == std::io::ErrorKind::ConnectionRefused => {
            Err(ConnectError::Refused)
        }
        Ok(Err(e)) => Err(ConnectError::Other(e.to_string())),
        Ok(Ok((ws, _))) => Ok(ws),
    }
}

/// The next text frame (skipping pings), or None when the socket ends.
pub async fn next_text(ws: &mut LocalWs) -> Option<String> {
    while let Some(message) = ws.next().await {
        match message {
            Ok(Message::Text(text)) => return Some(text.to_string()),
            Ok(Message::Close(_)) | Err(_) => return None,
            Ok(_) => {}
        }
    }
    None
}

/// OBS's Hello with `authentication` removed, plus (challenge, salt) when
/// OBS asked for auth.
pub fn split_hello(text: &str) -> Option<(Value, Option<(String, String)>)> {
    let mut hello: Value = serde_json::from_str(text).ok()?;
    if hello.get("op")?.as_u64()? != 0 {
        return None;
    }
    let data = hello.get_mut("d")?.as_object_mut()?;
    let auth = data.remove("authentication").and_then(|a| {
        Some((a.get("challenge")?.as_str()?.to_owned(), a.get("salt")?.as_str()?.to_owned()))
    });
    Some((hello, auth))
}

/// The Identify OBS gets: the phone's, with the bridge's authentication.
pub fn identify_with_auth(
    text: &str,
    auth: Option<&(String, String)>,
    config: &WsConfig,
) -> Option<String> {
    let mut message: Value = serde_json::from_str(text).ok()?;
    if message.get("op")?.as_u64()? != 1 {
        return None;
    }
    let data = message.get_mut("d")?.as_object_mut()?;
    match auth {
        Some((challenge, salt)) => {
            data.insert(
                "authentication".into(),
                Value::from(crate::auth::auth_string(&config.password, salt, challenge)),
            );
        }
        None => {
            data.remove("authentication");
        }
    }
    Some(message.to_string())
}

pub fn op_of(text: &str) -> Option<u64> {
    // Cheap check before a full parse: every OBS frame starts with "op"
    // somewhere near the front; parse only frames that might be Identify.
    let value: Value = serde_json::from_str(text).ok()?;
    value.get("op")?.as_u64()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn hello_loses_its_challenge() {
        let text = json!({"op": 0, "d": {"obsWebSocketVersion": "5.7.6", "rpcVersion": 1,
            "authentication": {"challenge": "c", "salt": "s"}}})
        .to_string();
        let (hello, auth) = split_hello(&text).unwrap();
        assert_eq!(hello, json!({"op": 0, "d": {"obsWebSocketVersion": "5.7.6", "rpcVersion": 1}}));
        assert_eq!(auth, Some(("c".into(), "s".into())));
        assert_eq!(split_hello(r#"{"op":2,"d":{}}"#), None);
    }

    #[test]
    fn identify_gets_the_bridge_auth_or_none() {
        let config = WsConfig { password: "pw".into(), ..WsConfig::default() };
        let phone = r#"{"op":1,"d":{"rpcVersion":1,"eventSubscriptions":66559}}"#;
        let auth = ("c".to_owned(), "s".to_owned());
        let out: Value = serde_json::from_str(&identify_with_auth(phone, Some(&auth), &config).unwrap()).unwrap();
        assert_eq!(out["d"]["authentication"], crate::auth::auth_string("pw", "s", "c"));
        assert_eq!(out["d"]["eventSubscriptions"], 66559);
        // A phone that sent its own (stale) auth to a password-less OBS.
        let stale = r#"{"op":1,"d":{"rpcVersion":1,"authentication":"x"}}"#;
        let out: Value = serde_json::from_str(&identify_with_auth(stale, None, &config).unwrap()).unwrap();
        assert!(out["d"].get("authentication").is_none());
    }
}
