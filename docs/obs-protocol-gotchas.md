# OBS protocol gotchas

Facts about obs-websocket, OBS and plugins that are **not obvious from the
protocol docs** and cost a debugging round each. Read before building an
OBS-facing feature; add every new one you find (with the source location
that proves it).

The rule behind this file: **the docs say what a request is for, the
source says what it does.** Before relying on a request or event, read its
handler - `obsproject/obs-websocket` `src/requesthandler/`, `src/eventhandler/`,
`src/utils/`; OBS frontend code in `obsproject/obs-studio` `frontend/`.
A shallow clone into the scratchpad is enough (`git clone --depth 1`, or
`--filter=blob:none --sparse` + `sparse-checkout set <dirs>` for
obs-studio). Test fakes (`test/websocket/support/fake_obs_peer.dart`) must
behave like that source, not like our assumptions - note the source
location in a comment where the fake models a non-obvious behavior.

## Canvases (OBS 32.1+, obs-websocket 5.7)

- **Lookups by name are canvas-scoped.** `Request::AcquireSource` resolves
  `sceneName` / `sourceName` inside the canvas given by `canvasUuid`, the
  main canvas when absent (`src/requesthandler/rpc/Request.cpp`). A scene
  or group of another canvas addressed by name *without* `canvasUuid`
  fails - or silently hits a same-named main one. Prefer UUIDs; when only
  a name exists (groups), send `canvasUuid` along.
- **Names repeat across canvases.** Scene, group and source names are only
  unique within a canvas. Key app state by UUID (`sceneUuid`,
  `sourceUuid`, `canvasUuid`); events carry UUIDs (`sceneUuid` on scene
  item events) - match on them.
- **No event for a canvas' resolution change.** Only `CanvasCreated` /
  `CanvasRemoved` / `CanvasNameChanged` exist. A plugin can change a
  canvas' size at runtime (Aitum's dock) - re-read `GetCanvasList`
  periodically while it matters, and on any hint (an Aitum event with a
  different `width` / `height`).
- **`GetCanvasList` includes plugin-internal canvases.** Filter
  `canvasFlags.EPHEMERAL` (OBS' own settings do the same).
- **Core has no live scene for non-main canvases** ("Canvases do not have
  any concept of a program or preview scene"). Live switching only exists
  through a plugin's vendor requests (Aitum Vertical).
- **Scene created / removed events are main-canvas only;** enable / lock
  item events fire for every canvas.
- **OBS has no UI to create canvases** (checked 2026-10-01) - plugins do
  (`obs_frontend_add_canvas`). In practice: Aitum Vertical only.

## Enhanced Broadcasting / Twitch Dual Format

- The main stream can send **one** extra canvas: profile `Stream1` /
  `EnableMultitrackVideo` + `MultitrackExtraCanvas` (canvas UUID) - read
  via `GetProfileParameter` (values are strings: `"true"`).
- OBS only builds the multitrack output when the service offers it
  (`multitrack_video_configuration_url` in the service settings, e.g.
  Twitch) or for `rtmp_custom` (`frontend/utility/BasicOutputHandler.cpp`).
- Settings changes send **no event** - re-read on profile switch and
  stream start.

## Aitum Vertical (vendor `aitum-vertical-canvas`)

- Source: `Aitum/obs-vertical-canvas`, `vertical-canvas.cpp`
  (`vendor_request_*`, `SendVendorEvent`).
- Requests pick their canvas by `width` / `height` (0 = any) - stale
  dimensions make them miss. `switch_scene` ignores the size (switches
  every dock).
- Every handler answers `success: true|false` - treat anything else as
  failure. A missing vendor is an OBS rejection of `CallVendorRequest`.
- **Known bug:** on a fresh install without a stored canvas the vendor
  isn't registered until OBS restarts.
- `status` reports streaming / recording / backtrack / virtual camera -
  **not** a recording pause, and there are no pause events. A refused
  pause / resume while recording means it already is that way.
- `update_stream_key` / `update_stream_server` only overwrite an in-memory
  setting at an output index that can't be listed, and answer success even
  for an invalid index - not usable from the app.
- Its canvas is always named `Aitum Vertical`, whatever the resolution
  (portrait, 4:5, landscape up to 4K) - never assume "vertical" from the
  name.

## General

- Responses of scoped requests (`NetworkHelper.makeScopedRequest`) never
  reach `DashboardStore` - use them for anything that must not touch
  program state.
- `availableRequests` (GetVersion) is never cleared across reconnects -
  reactions that should re-fire per session must also track the session.
- obs-websocket v5 status fields differ from v4 (`outputActive`, not
  `isReplayBufferActive`; `imageCompressionQuality`, not
  `compressionQuality`) - check every DTO key against the generated
  `docs/generated/protocol.md`.

## Platform event APIs (activity feed)

Not OBS, but the same kind of trap - verified 2026-10-02, details in
`superpowers/specs/2026-10-02-activity-feed-design.md`:

- Twitch EventSub: a second subscription with the same type + condition
  is a 409. The own channel's `channel.chat.notification` sub may only
  exist while ANOTHER channel is viewed - delete it before switching
  back. `channel.hype_train.*` v1 is deprecated (use v2), `channel.follow`
  is v2 with a moderator condition.
- Twitch `shared_chat_*` notices come from other channels of a shared
  chat - never count them as the own channel's subs / raids.
- Kick webhooks: one URL per app; app tokens can subscribe any channel
  (no user scope). The public key at `api.kick.com/public/v1/public-key`
  is NOT the one printed in KickDevDocs - fetch it. Failing deliveries
  for a day unsubscribes the app from that event.
- kounex.com runs Cloudflare Bot Fight Mode: anything a server must call
  (webhooks) can't live there - use obs-blade.com.
- Helix `streams` pages 20 by default (`first=100`), and its
  `started_at` is when the stream started - use it, not "when the app
  noticed".
- A grouped scene item's `SceneItemEnableStateChanged` /
  `SceneItemLockStateChanged` carry the **group's** name / uuid as
  `sceneName` / `sceneUuid` (a group is a scene; the event names the
  item's own `obs_scene_t`, `EventHandler_SceneItems.cpp`), and
  `SetSceneItemEnabled` / `SetSceneItemLocked` take the group as
  `sceneName` (`OBS_WEBSOCKET_SCENE_FILTER_SCENE_OR_GROUP`). Item ids are
  unique per scene only - a group child can share its id with a
  top-level item of the scene that holds the group.
