# Canvases — shipped state

Moved from `AGENTS.md` (2026-10 docs restructure). Protocol facts live in
[`docs/obs-protocol-gotchas.md`](obs-protocol-gotchas.md).

**Canvases (OBS 32.1+ / obs-websocket 5.7):** `CanvasViewStore` (per
dashboard view, next to `DashboardStore`) is a **view-only** switch to a
non-main canvas (e.g. Aitum Vertical): canvas picker above the scene
buttons (only with >1 canvas, `ExposeCanvasSwitcher` default on), then
scene buttons / preview / scene items of that canvas. All its reads go
through `NetworkHelper.makeScopedRequest` (ack carries `responseData`;
`DashboardStore._handleResponse` skips scoped responses) and are keyed by
UUID. Core OBS has no live scene for non-main canvases - picking a scene
only selects what the app shows. **Aitum Vertical** (vendor
`aitum-vertical-canvas`, `lib/types/classes/api/aitum_vertical.dart`):
detected per connection (`version` vendor call → `aitumSupport`), drives
only the canvas named `Aitum Vertical` (requests target it by
width/height) - live scene switch (by name) + its stream / record /
backtrack / virtual camera (+ record pause, chapter) in
`CanvasOutputControls`, state from `VendorEvent`s. **Twitch Dual
Format** sends a canvas through the *main* stream (profile
`Stream1/EnableMultitrackVideo` + `MultitrackExtraCanvas`, read into
`dualFormatCanvasUuid`). The app bar's `ExtraCanvasOnAirPill` shows
either. Canvases can be any size - labels say "vertical" only for
portrait (`ObsCanvas.outputLabel`). Without it
everything stays view-only and gated taps explain why
(`aitumBlockedReason`). Canvas groups expand (children addressed by the
group's name), hidden scenes / items are stored per canvas
(`HiddenScene` / `HiddenSceneItem.canvasName`, null = main). Streaming
mode always shows main.
