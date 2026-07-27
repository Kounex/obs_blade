# OBS WebSocket architecture (agent reference)

**No code changes implied by this doc** — it describes how OBS Blade talks to
OBS Studio today so agents can extend it without rediscovering the design.

Upstream protocol: [obsproject/obs-websocket](https://github.com/obsproject/obs-websocket)
(generated protocol docs under `docs/generated/protocol.md` in that repo).

OBS Blade targets **OBS WebSocket protocol 5.x** (`rpcVersion: 1`), which ships
built into OBS Studio **28+**. Older OBS needs the plugin installed manually
(see root `README.md`).

## What this app controls

OBS (Open Broadcaster Software) runs on the streaming PC: scenes, sources
(desktop/window capture, etc.), audio inputs, transitions, stream/record
outputs. The phone/tablet app is a remote companion over the LAN (or domain)
via the WebSocket OBS exposes — not Twitch/YouTube APIs for OBS itself (chat
widgets are separate).

Author intent (manual codebase): implement **only the subset of the official
API the app needs**, but do so **as type-safely as practical** — enums for
request/event/op names, typed wrappers for payloads, freezed models for nested
JSON objects.

## Mental model (layers)

```
UI widgets (lib/views/dashboard/…)
    │  call NetworkHelper.makeRequest / makeBatchRequest
    │  read DashboardStore observables via GetIt
    ▼
DashboardStore (lib/stores/views/dashboard.dart)  ← large; intentional monolith
    │  initialRequests, event/response/batch switches, timers
    ▼
NetworkStore (lib/stores/shared/network.dart)
    │  Session + auth handshake; watchOBSStream() → Message
    ▼
NetworkHelper (lib/utils/network_helper.dart)
    │  WebSocket connect, encode Request / RequestBatch, UUID lookup maps
    ▼
OBS WebSocket (JSON: { op, d })
```

**Typed protocol surface** lives under `lib/types/`:

| Layer | Role |
|---|---|
| `enums/web_socket_codes/` | Wire integers: `WebSocketOpCode`, close codes, `RequestStatus`, batch execution |
| `enums/request_type.dart` | Every **request name** the app can send (matches protocol `requestType` string = enum `.name`) |
| `enums/event_type.dart` | Every **event name** the app knows (matched via `.name` to `eventType`) |
| `enums/request_batch_type.dart` | App-level batch recipes (not an OBS type) |
| `classes/stream/responses/` | Typed **Get\*** response wrappers (`extends BaseResponse`) |
| `classes/stream/events/` | Typed event wrappers (`extends BaseEvent`) |
| `classes/stream/batch_responses/` | Helpers over `BaseBatchResponse` |
| `classes/api/` | Nested freezed DTOs (`Scene`, `SceneItem`, `Input`, `Filter`, …) |
| `interfaces/message.dart` | Shared `jsonRAW` / `json` for Event + Response + Batch |

There is **no central factory** that maps `RequestType → ResponseClass`.
Consumers (almost always `DashboardStore`) do:

```dart
case RequestType.GetSceneList:
  final r = GetSceneListResponse(response.jsonRAW);
  // use getters / freezed lists
```

Same pattern for events: `SomeEvent(event.jsonRAW)`.

## Wire envelope (protocol 5)

Every message:

```json
{ "op": <WebSocketOpCode int>, "d": { … } }
```

Relevant ops (`WebSocketOpCode`):

| Op | Id | Direction | App handling |
|---|---|---|---|
| Hello | 0 | OBS → app | Auth salt/challenge; then Identify |
| Identify | 1 | app → OBS | `AuthenticationHelper.identify` |
| Identified | 2 | OBS → app | Completes connect as success |
| Event | 5 | OBS → app | `BaseEvent` |
| Request | 6 | app → OBS | `NetworkHelper.makeRequest` |
| RequestResponse | 7 | OBS → app | `BaseResponse` |
| RequestBatch | 8 | app → OBS | `NetworkHelper.makeBatchRequest` |
| RequestBatchResponse | 9 | OBS → app | `BaseBatchResponse` |

`NetworkStore.watchOBSStream()` only yields Event / RequestResponse /
RequestBatchResponse. Hello/Identified are handled only during the initial
auth subscription.

### Identify payload (as implemented)

`AuthenticationHelper.identify` sends:

- `rpcVersion: 1` (or Hello’s offered version when negotiated)
- `authentication` **only if** Hello included an auth challenge/salt
- `eventSubscriptions: EventSubscription.appDefault` (all categories +
  `InputVolumeMeters`)

See also [`websocket-connect-audit.md`](websocket-connect-audit.md) for
handshake hardening and failure mapping.


## Connection lifecycle

1. **Discover / enter host** — Home UI; optional WLAN IP scan via
   `NetworkHelper.getAvailableOBSIPs` (isolate + parallel `Socket.connect` on
   `/24`; non-`255.255.255.0` masks flagged). Domains use a short WebSocket probe.
2. **`NetworkStore.setOBSWebSocket(Connection)`** — opens `IOWebSocketChannel`
   via `NetworkHelper.websocketUri` (`ws://` for LAN; scheme may be baked into
   domain `host`), broadcast stream, Hello → Identify → Identified (or close
   code / staged timeout → `ConnectionAttemptResult`).
3. Success (`DontClose`) → `handleStream()` on NetworkStore (only reacts to
   `ExitStarted` today) and navigation to Dashboard.
4. **Dashboard** `init()` → `handleStream()` + `initialRequests()` + reconnect
   timer + 1s stats batch timer.
5. Disconnect / OBS quit → finish stream/record stats, `obsTerminated`, back Home.
6. Lost socket (`closeCode != null`) → `_checkOBSConnection` retries (5× or
   unlimited setting) with `reconnect: true`.

`Session` = socket + broadcast stream + `Connection` (host/port/pw/ssid/…).

Typo to know when grepping: `connectionClodeCode` (not “Code”).

## Sending requests

```dart
NetworkHelper.makeRequest(channel, RequestType.X, { …fields });
```

Encoded as:

```json
{
  "op": 6,
  "d": {
    "requestType": "<RequestType.name>",
    "requestId": "<uuid>",
    "requestData": { … }
  }
}
```

**Important v5 detail:** many Get responses no longer echo the input name you
asked about. For Get requests **with fields**, the helper stores
`requestId → fields` in `_requestBodyByUUID` and
`getRequestBodyForUUID` pops it when handling the response (e.g. merge volume
onto the right `Input`).

Setters (`Set*`, `Toggle*`, …) usually have **no** dedicated response class —
UI fires and forgets; UI state updates from events and/or later Gets/batches.

### Batches (app concept)

OBS supports `RequestBatch`. The app groups common multi-gets into
`RequestBatchType`:

| Batch | Contained requests | `lookup` (keep per-item request bodies) |
|---|---|---|
| `Input` | GetInputVolume, GetInputMute, GetInputAudioSyncOffset | yes |
| `Stats` | GetStreamStatus, GetRecordStatus, GetStats | no |
| `Screenshot` | SaveSourceScreenshot, GetSourceScreenshot | no |
| `FilterList` | GetSourceFilterList (N sources) | yes |
| `FilterDefaultSettings` | GetSourceFilterDefaultSettings | yes |

Default execution: `SerialRealtime`. Batch UUID may map to the list of
`RequestBatchObject`s when `lookup` is true so responses can be paired with
`sourceName` / `inputName`.

`BaseBatchResponse.batchRequestType` is inferred by checking that **every**
request type in a `RequestBatchType` appears at least once among results —
works for current recipes; fragile if two batch kinds share the same type set.

Typed helpers: `StatsBatchResponse`, `InputsBatchResponse`,
`FilterListBatchResponse`, etc.

## Receiving messages

```dart
abstract class Message {
  late Map<String, dynamic> jsonRAW; // full {op,d}
  late Map<String, dynamic> json;    // eventData / responseData only
}
```

- `BaseEvent`: `json = d.eventData`; `eventType` via `EventType.values` where
  `.name == d.eventType` (unknown → `null`, logged as NOT HANDLED).
- `BaseResponse`: `json = d.responseData`; `requestType`, `status`, `uuid`,
  `error`.
- `BaseBatchResponse`: list of `BaseResponse.d(...)` from `d.results`.

Typed subclasses only add **getters** over `json` (and sometimes nest freezed
`fromJson`). Example:

```dart
class GetSceneListResponse extends BaseResponse {
  String get currentProgramSceneName => json['currentProgramSceneName'];
  Iterable<Scene> get scenes =>
      (json['scenes'] as List).map((s) => Scene.fromJson(s));
}
```

Freezed API models (`lib/types/classes/api/`) are for **objects inside**
responseData, plus app-only fields (e.g. `SceneItem.displayGroup`,
`Input.inputMuted` defaults).

## Request inventory (what exists in code)

`RequestType` documents parameters in comments. Rough split:

**Getters with response classes** under `classes/stream/responses/`  
(GetVersion, GetSceneList, GetInputList, GetInputVolume/Mute,
GetSpecialInputs, GetSceneTransitionList, GetCurrentSceneTransition,
GetSourceScreenshot, SaveSourceScreenshot, GetRecordDirectory,
GetRecordStatus, GetStreamStatus, GetStudioModeEnabled,
GetSceneCollectionList, GetProfileList, GetReplayBufferStatus,
GetSceneItemList, GetGroupSceneItemList, GetInputDefaultSettings,
GetStats, GetVirtualCamStatus, GetHotkeyList, GetInputAudioSyncOffset,
GetSourceFilterList, GetSourceFilterDefaultSettings).

**Setters / toggles (no response class)**  
SetCurrentProgramScene, SetCurrentPreviewScene, SetInputVolume/Mute,
SetSceneItemEnabled, ToggleStream/Record/RecordPause/ReplayBuffer/VirtualCam,
PlayPauseMedia, SetCurrentSceneTransition(+Duration), SetStudioModeEnabled,
TransitionToProgram, SetCurrentSceneCollection/Profile, SaveReplayBuffer,
TriggerHotkeyByName, SetInputAudioSyncOffset, SetSourceFilterEnabled/Settings.

Not every official obs-websocket request exists — **by design**. Add only when
a feature needs it (enum + optional response class + dashboard/UI wiring).

## Event inventory

`EventType` names must **exactly** match protocol `eventType` strings (Dart
enum `.name`). Typed files under `classes/stream/events/`.

**Actively used in `DashboardStore._handleEvent` today** (non-exhaustive but
practical): ReplayBuffer/VirtualCam state, scene collection changing/changed +
list, profile changed/list, transition changed/duration, studio mode,
program/preview scene, scene item create/remove/reindex/enable, input
name/volume/mute/meters/sync, filter enable, ExitStarted.

**Stream/Record state events exist as classes** (`StreamStateChanged`,
`RecordStateChanged`) but the corresponding switch cases in the dashboard are
**commented out** — live/recording flags and stats come from the **1s Stats
batch** instead (v5 no longer pushes the old periodic status event the v4 app
relied on).

### Legacy / mismatch pitfalls (read before “fixing” events)

Some enum names or event **classes** still look like WebSocket **4.x**:

| In app | Likely protocol 5 name / note |
|---|---|
| Legacy event *classes* (`SwitchTransitionEvent`, `TransitionBeginEvent`) | kebab-case JSON keys; unused by dashboard |
| `studio_mode_switched.dart` filename | Class is correctly `StudioModeStateChangedEvent` |

`EventType.SceneListChanged` matches the protocol (renamed from the old
`ScenesChanged` miss). Stream/Record UI state is driven by the Stats batch,
not `StreamStateChanged` / `RecordStateChanged` — see
[`dashboard-store-websocket-audit.md`](dashboard-store-websocket-audit.md).


When adding an event: **name the enum exactly like the protocol**, add a
typed class with **camelCase v5 field names**, handle in dashboard (or a future
split store).

## DashboardStore (consumer hub)

Path: `lib/stores/views/dashboard.dart` (~1.7k lines). Author note: **could be
split later; do not refactor casually** — it is the live control plane for
500k+ users’ sessions.

Responsibilities lumped together:

- Observables for scenes, scene items, inputs, transitions, studio mode,
  preview bytes, hotkeys, live/record/replay/vcam flags, past stats hooks
- `initialRequests` / `_sceneCollectionRequests` fan-out
- Single `watchOBSStream` listener → `_handleEvent` / `_handleResponse` /
  `_handleBatchResponse`
- Pause handling during `CurrentSceneCollectionChanging` via
  `_handleRequestsEvents` (still allows collection-changed)
- Preview screenshot polling, connection watchdog, stats batch + past
  stream/record Hive persistence
- Filter default merge logic (`DefaultFilter`, filter setting overlays)

UI generally:

- **Reads** store via `GetIt.instance<DashboardStore>()` + MobX `Observer`
- **Writes** to OBS via `NetworkHelper.makeRequest` directly from widgets
  (volume sliders, scene buttons, toggles) — store then converges via events /
  follow-up Gets

Dashboard is registered as a **lazy singleton** and **reset** when entering the
dashboard view so each session starts clean.

## NetworkStore vs DashboardStore

| | NetworkStore | DashboardStore |
|---|---|---|
| Owns socket | yes (`Session`) | uses GetIt NetworkStore |
| Auth | yes | no |
| Parses Message | yields stream | handles almost all domain logic |
| ExitStarted | closes session | finishes stats / timers |

Both listen to the broadcast socket stream independently after connect.

## Autodiscovery & errors

- `NotInWLANException` / `NoNetworkException` — scan preconditions
- Close codes: `WebSocketCloseCode` (4000-range OBS codes + internal
  `DontClose` / `UnknownReason`)
- Request failures: `BaseResponse.status` / `RequestStatus` identifiers

## How to extend (checklist for agents)

1. Confirm the request/event in upstream protocol docs (name + fields).
2. Add `RequestType` / `EventType` value — **`.name` must match wire string**.
3. For Gets: add `GetFooResponse extends BaseResponse` with getters; nest
   freezed models if the payload has objects/arrays of objects.
4. For events: add `FooEvent extends BaseEvent`.
5. Wire send sites (widget and/or store) and handle in dashboard switches (or
   extract carefully later).
6. If multiple Gets need one round-trip, consider a new `RequestBatchType`
   (+ `lookup` if request body must be recovered).
7. Prefer updating UI from events or existing batches over new polling where
   possible; stats already poll at 1s by necessity.
8. Do **not** renumber Hive `TypeIDs` while touching this layer (orthogonal but
   high blast radius) — see `docs/persistence-risk.md`.

## Related files (quick index)

| File | Why |
|---|---|
| `lib/utils/network_helper.dart` | Connect, scan, request/batch encode, UUID body maps |
| `lib/utils/authentication_helper.dart` | Identify + auth hash |
| `lib/stores/shared/network.dart` | Session, handshake, `watchOBSStream` |
| `lib/stores/views/dashboard.dart` | Domain handling |
| `lib/types/enums/request_type.dart` | Documented request catalog |
| `lib/types/enums/event_type.dart` | Event catalog |
| `lib/views/dashboard/services/record_stream.dart` | Toggle stream/record UX |
| Root `README.md` | User-facing OBS prep / stores |

## Out of scope here

- Hive persistence / upgrade (see other `docs/` entries)
- Chat (Twitch/YouTube/Owncast WebViews) — not OBS WebSocket
- Purchases / themes / intro

Personal author notes may be appended later; prefer updating **this** doc when
protocol behavior or intentional gaps change.
