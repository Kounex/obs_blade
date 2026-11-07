//! Lighter screenshots on relay sessions.
//!
//! The app's preview loop asks for `GetSourceScreenshot` with only
//! `imageWidth` (its screen width) and `imageCompressionQuality: -1`.
//! obs-websocket derives the missing dimension from the source's aspect
//! ratio, but when **both** are given it renders exactly that size and
//! stretches (`TakeSourceScreenshot` in `RequestHandler_Sources.cpp`; its
//! doc comment says "scale to inner", the code doesn't). So the rewrite
//! never adds a dimension: it lowers the ones the request has, both by the
//! same factor. The format is left alone (the app parses the returned data
//! URI); only JPEG gets a lower quality.

use serde_json::{Map, Value};

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct PreviewCap {
    /// Longest edge in pixels; 0 = no cap.
    pub max_edge: u32,
    /// JPEG quality 1-100 for requests asking for "default" (-1) or more.
    pub jpeg_quality: i32,
    /// Width / height of OBS's base canvas, when known: bounds the long
    /// edge of width-only requests on portrait canvases.
    pub canvas_aspect: Option<f64>,
}

impl Default for PreviewCap {
    fn default() -> Self {
        Self { max_edge: 640, jpeg_quality: 60, canvas_aspect: None }
    }
}

const SCREENSHOT: &str = "GetSourceScreenshot";
const MIN_EDGE: f64 = 8.0; // obs-websocket's lower bound

/// Returns the rewritten frame, or `None` when nothing changed.
pub fn rewrite_request(frame: &str, cap: PreviewCap) -> Option<String> {
    if cap.max_edge == 0 || !frame.contains(SCREENSHOT) {
        return None;
    }
    let mut message: Value = serde_json::from_str(frame).ok()?;
    let op = message.get("op")?.as_u64()?;
    let data = message.get_mut("d")?.as_object_mut()?;
    let changed = match op {
        6 => rewrite_one(data, cap),
        8 => {
            let mut any = false;
            if let Some(Value::Array(requests)) = data.get_mut("requests") {
                for request in requests.iter_mut() {
                    if let Some(request) = request.as_object_mut() {
                        any |= rewrite_one(request, cap);
                    }
                }
            }
            any
        }
        _ => false,
    };
    changed.then(|| message.to_string())
}

fn rewrite_one(request: &mut Map<String, Value>, cap: PreviewCap) -> bool {
    if request.get("requestType").and_then(Value::as_str) != Some(SCREENSHOT) {
        return false;
    }
    let Some(data) = request.get_mut("requestData").and_then(Value::as_object_mut) else {
        return false;
    };
    let edge = f64::from(cap.max_edge).max(MIN_EDGE);
    // Aspect of what OBS will render when only one side is given.
    let aspect = cap.canvas_aspect.filter(|a| a.is_finite() && *a > 0.0).unwrap_or(16.0 / 9.0);
    let width_limit = if aspect < 1.0 { edge * aspect } else { edge };
    let height_limit = if aspect > 1.0 { edge / aspect } else { edge };
    let width = data.get("imageWidth").and_then(Value::as_f64);
    let height = data.get("imageHeight").and_then(Value::as_f64);
    let mut changed = false;
    let mut set = |data: &mut Map<String, Value>, key: &str, value: f64| {
        data.insert(key.into(), Value::from(value.round().max(MIN_EDGE) as u64));
        changed = true;
    };
    match (width, height) {
        (Some(w), Some(h)) => {
            let longest = w.max(h);
            if longest > edge {
                let factor = edge / longest;
                set(data, "imageWidth", w * factor);
                set(data, "imageHeight", h * factor);
            }
        }
        (Some(w), None) if w > width_limit => set(data, "imageWidth", width_limit),
        (None, Some(h)) if h > height_limit => set(data, "imageHeight", height_limit),
        (None, None) => set(data, "imageWidth", width_limit),
        _ => {}
    }
    let jpeg = data
        .get("imageFormat")
        .and_then(Value::as_str)
        .is_some_and(|f| f.eq_ignore_ascii_case("jpg") || f.eq_ignore_ascii_case("jpeg"));
    if jpeg {
        let quality = data.get("imageCompressionQuality").and_then(Value::as_i64).unwrap_or(-1);
        let target = i64::from(cap.jpeg_quality.clamp(1, 100));
        if quality == -1 || quality > target {
            data.insert("imageCompressionQuality".into(), Value::from(target));
            changed = true;
        }
    }
    changed
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn data(frame: &str) -> Value {
        serde_json::from_str::<Value>(frame).unwrap()["d"]["requestData"].clone()
    }

    fn app_request(width: u64) -> String {
        // What DashboardStore._sendPreviewImageRequest sends.
        json!({"op": 6, "d": {"requestType": "GetSourceScreenshot", "requestId": "r1",
            "requestData": {"sourceName": "Scene", "imageFormat": "jpg", "imageWidth": width,
                            "imageCompressionQuality": -1}}})
        .to_string()
    }

    #[test]
    fn app_preview_request_keeps_width_only() {
        let cap = PreviewCap { canvas_aspect: Some(1920.0 / 1080.0), ..PreviewCap::default() };
        let out = rewrite_request(&app_request(1179), cap).unwrap();
        // No imageHeight added: OBS would stretch to exactly W x H.
        assert_eq!(
            data(&out),
            json!({"sourceName": "Scene", "imageFormat": "jpg", "imageWidth": 640, "imageCompressionQuality": 60})
        );
        assert_eq!(serde_json::from_str::<Value>(&out).unwrap()["d"]["requestId"], "r1");
    }

    #[test]
    fn portrait_canvas_bounds_the_long_edge() {
        let cap = PreviewCap { canvas_aspect: Some(1080.0 / 1920.0), ..PreviewCap::default() };
        let out = rewrite_request(&app_request(1179), cap).unwrap();
        assert_eq!(data(&out)["imageWidth"], 360); // height becomes 640
    }

    #[test]
    fn both_sides_scale_together() {
        let frame = json!({"op": 6, "d": {"requestType": "GetSourceScreenshot",
            "requestData": {"imageFormat": "png", "imageWidth": 1920, "imageHeight": 1080}}})
        .to_string();
        let out = rewrite_request(&frame, PreviewCap::default()).unwrap();
        assert_eq!(data(&out), json!({"imageFormat": "png", "imageWidth": 640, "imageHeight": 360}));
    }

    #[test]
    fn small_and_png_requests_keep_their_size_and_quality() {
        let frame = json!({"op": 6, "d": {"requestType": "GetSourceScreenshot",
            "requestData": {"imageFormat": "png", "imageWidth": 200, "imageHeight": 100}}})
        .to_string();
        assert_eq!(rewrite_request(&frame, PreviewCap::default()), None);
    }

    #[test]
    fn batch_requests_are_rewritten_too() {
        let frame = json!({"op": 8, "d": {"requestId": "b", "requests": [
            {"requestType": "GetStats"},
            {"requestType": "GetSourceScreenshot", "requestData": {"imageFormat": "jpeg", "imageCompressionQuality": 90}}
        ]}})
        .to_string();
        let out: Value = serde_json::from_str(&rewrite_request(&frame, PreviewCap::default()).unwrap()).unwrap();
        assert_eq!(out["d"]["requests"][0], json!({"requestType": "GetStats"}));
        assert_eq!(
            out["d"]["requests"][1]["requestData"],
            json!({"imageFormat": "jpeg", "imageCompressionQuality": 60, "imageWidth": 640})
        );
    }

    #[test]
    fn other_traffic_is_untouched() {
        assert_eq!(rewrite_request(r#"{"op":6,"d":{"requestType":"GetStats"}}"#, PreviewCap::default()), None);
        assert_eq!(rewrite_request("not json GetSourceScreenshot", PreviewCap::default()), None);
        let off = PreviewCap { max_edge: 0, ..PreviewCap::default() };
        let frame = r#"{"op":6,"d":{"requestType":"GetSourceScreenshot","requestData":{}}}"#;
        assert_eq!(rewrite_request(frame, off), None);
    }
}
