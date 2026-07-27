# DashboardStore WebSocket handling audit

Scope: [`lib/stores/views/dashboard.dart`](../lib/stores/views/dashboard.dart)
(~1.7k lines) — where almost all OBS events, request responses, and batches
are applied to UI state. Not a proposal to split the store (still intentional
monolith); this is about **correctness, cost, and agent maintainability**.

## Architecture (what works)

```
watchOBSStream → BaseEvent | BaseResponse | BaseBatchResponse
       ↓
_handleEvent / _handleResponse / _handleBatchResponse
       ↓
MobX observables (scenes, inputs, live/record flags, …)
```

- **Typed wrappers** (`GetSceneListResponse`, `InputVolumeChangedEvent`, …) keep
  field access explicit.
- **Setters from UI** fire-and-forget; store converges via events + Gets.
- **Stats** intentionally come from a **1s RequestBatch** (Stream/Record status
  + GetStats), not from `StreamStateChanged` / `RecordStateChanged` (those
  handlers are commented — correct for v5 which dropped the old periodic
  status push).
- **Scene-collection pause** via `_handleRequestsEvents` + exception for
  `CurrentSceneCollectionChanged` matches OBS guidance to pause work during
  a collection switch.

## Event coverage matrix

| EventType (app) | Handled? | Notes |
|---|---|---|
| ReplayBuffer / Virtualcam state | Yes | Updates flags |
| Scene collection changing/changed/list | Yes | Pause flag + refresh |
| Profile changed/list | Yes | |
| CurrentSceneTransition* | Yes | List refresh / duration patch |
| StudioModeStateChanged | Yes | Only if “expose studio controls” setting |
| CurrentProgram/PreviewSceneChanged | Yes | Was over-refreshing (see fixes) |
| SceneItemCreated/Removed/Reindexed, InputNameChanged | Yes | Full `_sceneCollectionRequests` (heavy but safe for groups) |
| Input volume/mute/sync/meters | Yes | Incremental `copyWith` |
| SceneItemEnableStateChanged | Yes | Should scope to active scene |
| SourceFilterEnableStateChanged | Yes | |
| ExitStarted | Yes | Finish stats, stop timers, terminate |
| StreamStateChanged / RecordStateChanged | Commented | Owned by Stats batch — OK |
| ScenesChanged | **Fixed → `SceneListChanged`** | Was dead (wrong wire name) |
| SwitchScenes | **Removed** | v4 name; use CurrentProgramSceneChanged |
| SceneTransitionStarted | Enum only | Ignored (default) — OK unless UI needs it |

## Response / batch notes

- Get* switch covers the app’s request surface; setters have no response cases
  (by design).
- **Batch Input** correctly filters mute failures (`InvalidResourceState`) and
  pairs request UUIDs — good pattern for agents to copy.
- **Batch Stats** owns live/record lifecycle + past Hive stats — critical path.
- Single-response GetInputVolume/Mute/Sync still exist (batch is primary after
  GetInputList); UUID body lookup can throw if map miss (`!`).

## Problems found (severity)

### High — wrong or wasteful behavior

1. **`EventType.ScenesChanged` never matches** OBS `SceneListChanged` → scene
   list additions/removals outside other paths may not refresh until something
   else triggers GetSceneList.
2. **Stats polling continues during collection change** while responses are
   dropped (`_handleRequestsEvents == false`). OBS says requests during a
   collection change are undefined / crash-risk — should **cancel** the stats
   timer on Changing and **restart** on Changed.
3. **`CurrentProgramSceneChanged` / preview change** called full
   `_sceneCollectionRequests()` (scenes + inputs + special + transitions).
   Scene switch does not need that; **GetSceneItemList (for active/preview
   scene) is enough** → less WS chatter and flicker.

### Medium — correctness / UX

4. **`SceneItemEnableStateChanged`** applied by `sceneItemId` only — IDs can
   collide across scenes; should ignore events whose `sceneName` is not the
   scene currently shown.
5. **Studio mode event ignored** when expose-studio setting is false — store
   `studioMode` can go stale if user toggles studio in OBS while the setting
   is off (edge case).
6. **No `requestStatus` guard** on many Get handlers — failed responses can
   throw on missing `responseData` fields (caught by outer try/log only).

### Low — future / polish

7. **`InputVolumeMeters` (~50ms)** rebuilds the whole `allInputs`
   `ObservableList` — fine for now; if audio UI janks, patch in place or
   throttle.
8. **Commented Stream/Record event code** — keep as reference or delete once
   Stats path is documented (prefer keep short comment + link here).
9. **Store size** — extracting `_handleEvent` / `_handleResponse` /
   `_handleBatchResponse` into `part` files (same class) would help agents
   without a behavioral split. Optional later.
10. **Debounce** rapid `_sceneCollectionRequests` from item churn — optional.

## Intentional non-goals

- Full DashboardStore decomposition into multiple MobX stores.
- Implementing every official OBS event.
- Replacing Stats batch with Stream/Record events only (batch still needed for
  FPS/CPU/bytes charts).

## Remediation applied with this audit

- Rename `ScenesChanged` → `SceneListChanged`; drop unused `SwitchScenes`.
- Pause/resume stats timer around scene-collection change.
- Lighter active-scene item refresh on program/preview scene change.
- Scope scene-item enable updates to the displayed scene.
- Always update `studioMode` from the event (UI refresh still gated by setting).
- **requestStatus guards** — skip applying failed Gets; Stats/Screenshot batches
  require success; soft UUID lookups (no `!` crashes); skip failed filter lists.
- Doc index links for agents.

Still open (only if needed later): InputVolumeMeters perf, `part` handler files,
debounce on item-churn refresh.
