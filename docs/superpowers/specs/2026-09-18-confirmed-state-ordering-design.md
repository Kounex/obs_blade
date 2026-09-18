# Confirmed-state ordering port (astra phase 3, wave 1) — design

Date: 2026-09-18 · Status: ratified (design approved in brainstorm) · Branch target: `4.0-liquid-glass`

## Context

Astra's `lib/redesign/obs/` prototype proved an ordering guarantee master
lacks: **a read response must never overwrite state that a newer event already
set** ("events beat stale reads"). Master (post command-ack wave) still applies
whatever arrives last, so a slow `Get*` response can regress a value that a
newer event already carried (e.g. scene A → tap scene B → event applies B →
in-flight `GetSceneList` response sent before the change arrives and re-applies
A).

Ratified in brainstorm (2026-09-18):

- **UX stays optimistic.** Taps/sliders update instantly as today; this wave
  adds ordering, not pending indicators. Failure self-healing (re-read on
  rejection/timeout) already landed with the command-ack layer and is
  unchanged.
- **Hybrid architecture.** The ordering machinery is a new pure, dependency-
  free component; `DashboardStore`/`NetworkHelper` integrate it in place. No
  parallel projection, no astra controllers.
- **Domain scope:** scenes (program/preview/studio mode), scene-item
  visibility, audio volume/mute — one verified commit per domain.

Explicitly **not** in this wave: pending/busy indicators, per-row freshness
flags, STALE/RECONNECTING surfaces (later stale-state-honesty port), acks
assigning state (they still never do), any change to slider tick behavior
(fire-and-forget, acked `onChangeEnd` — unchanged).

## The component: `EventOrdering`

New file `lib/utils/event_read_ordering.dart` — pure Dart, no Flutter/MobX/
app imports, fully synchronous:

```dart
/// Ordering journal: a value event always beats a read that was sent before
/// the event arrived. Integrate at the send seam (capture) and the apply
/// seam (shouldApplyRead).
class EventOrdering {
  /// Tag captured immediately before a read request is sent.
  ({int epoch, int seq}) capture();

  /// A value event for [key] arrived. Call when the event is applied.
  void noteEvent(Object key);

  /// At read-apply time: true when no event for [key] arrived after [tag]
  /// was captured AND [tag] belongs to the current epoch. False = keep the
  /// event value already in state; drop the read value.
  bool shouldApplyRead(Object key, ({int epoch, int seq}) tag);

  /// Invalidate everything in flight (reconnect, scene-collection change,
  /// scene list/name change). Old tags never apply again.
  void newEpoch();
}
```

Semantics (astra's, adapted — astra equivalents in parentheses):

- One monotonic sequence per instance; `noteEvent` records `++seq` for the
  key (astra: per-field revisions for scenes, one global sequence with
  per-target journals for sources/audio — unified here).
- `capture()` returns `(epoch, seq)` at send time. Astra's subtlest rule is
  preserved: the tag is captured **per individual read send**, never per
  logical refresh batch — a group child read sent later must capture its own,
  later tag (astra `obs_source_controller.dart` pins this; its test "a group
  snapshot supersedes events received before its own read" is adapted).
- `shouldApplyRead(key, tag)` is true iff `tag.epoch == currentEpoch` and no
  `noteEvent(key)` sequence exceeds `tag.seq`. Because master's event handlers
  apply event values immediately, dropping the stale read value is equivalent
  to astra's "apply journaled event value" — the event value is already in
  state.
- `newEpoch()` bumps the epoch and clears the journal; all in-flight tags
  die with the old epoch (astra: `_epoch` on collection change/disconnect).

DashboardStore holds three instances: `_sceneOrdering` (keys: a private
`_SceneField { program, preview, studioMode }` enum), `_sceneItemOrdering`
(keys: `(String sceneName, int sceneItemId)` records), `_audioOrdering`
(keys: `(String inputName, _AudioField { volume, mute })` records).

## Integration seams (all in `lib/stores/views/dashboard.dart`)

### Events — note at apply

In `_handleEvent` (:1009), alongside each existing direct apply:

- `CurrentProgramSceneChanged` (:1125) → `_sceneOrdering.noteEvent(program)`
- `CurrentPreviewSceneChanged` (:1132) → `noteEvent(preview)`
- `StudioModeStateChanged` (:1108) → `noteEvent(studioMode)`
- `SceneItemEnableStateChanged` (:1219) →
  `_sceneItemOrdering.noteEvent((sceneName, sceneItemId))`
- `InputVolumeChanged` (:1162) → `_audioOrdering.noteEvent((inputName, volume))`
- `InputMuteStateChanged` (:1203) → `noteEvent((inputName, mute))`
- `SceneListChanged` (:1086),
  `CurrentSceneCollectionChanging` (:1040) / `Changed` (:1046) →
  `_sceneOrdering.newEpoch(); _sceneItemOrdering.newEpoch();`
- `SceneNameChanged` renames invalidate name-keyed item journals →
  `_sceneItemOrdering.newEpoch()` (**verify during implementation whether
  `_handleEvent` handles `SceneNameChanged` today; add the case if absent**)
- `InputNameChanged` → `_audioOrdering.newEpoch()` (audio keys are input
  names; same verify-or-add note). `InputCreated`/`InputRemoved` already
  trigger input-list re-reads; no journal action (keys arrive with the
  re-read)

### Reads — capture at send, gate at apply

Each send captures its tag into a **FIFO queue per read target** (the socket
delivers responses in send order; each response pops the tag of its send).
Astra guards superseded reads with a last-load-wins counter because its
controllers never run concurrent reads of the same target; DashboardStore can
(init burst + failure re-read + event re-read may overlap), so a single
mutable tag field would let an earlier stale response pop a later send's tag
and apply wrongly. Queues are wiped by `newEpoch()`. Accepted corner: a
response arriving after its ack timeout (10 s) *and* after a newer same-target
send would pop the wrong tag — vanishingly rare on the supported LAN path and
self-correcting via the next event/read; documented, not handled.

- **Scenes:** one `_sceneListTags` queue, enqueued at every `GetSceneList`
  send site (initial connect burst, `_resyncAfterFailedMutation`,
  event-triggered re-reads). In the `GetSceneList` case of `_handleResponse`
  (:1298): pop the tag, then apply `currentProgramSceneName` /
  `currentPreviewSceneName` / `studioModeEnabled` each gated on
  `shouldApplyRead(field, tag)` **per field** (a preview event must not block
  the program field). Empty queue (response to a pre-feature send) = apply
  ungated, today's behavior.
- **Scene items:** `_sceneItemTags[sceneName]` queues, enqueued per send of
  `GetSceneItemList` (:1341 chain, `_requestDisplayedSceneItems` :373) and
  per `GetGroupSceneItemList` send (:1389). At apply (:1379 ff.): pop that
  scene's tag; per item, gate `sceneItemEnabled` on
  `shouldApplyRead((scene, id), tag)`.
- **Audio:** `_inputBatchTags` queue for the `Input` batch (:1448) and
  per-`(inputName, field)` queues for the single `GetInputVolume` /
  `GetInputMute` re-reads (the ack layer's `_resyncAfterFailedMutation`). At
  apply (batch handler in `_handleBatchResponse` :1676 and the
  single-response cases): per input per field, gate on
  `shouldApplyRead((input, field), tag)`.

### Epoch — reset on reconnect

New session / reconnect success → `newEpoch()` on all three instances (the
post-connect init burst re-reads everything anyway). Seam: wherever
DashboardStore reacts to a fresh `activeSession` (same place the ack wave
hooked the init burst).

## Edge cases (design decisions, not open questions)

- **Own-echo events:** our own `Set*` produces a value event (e.g.
  `InputVolumeChanged` echo). It journals + applies as any event — harmless:
  the value equals what we optimistically set, and any read sent before the
  echo is correctly treated as stale.
- **Slider drags:** ticks are fire-and-forget and echo events apply as today
  (no behavior change); the acked `onChangeEnd` commit's failure re-read is
  covered by the audio gates above.
- **Multiple in-flight `GetSceneItemList`** for different scenes (group
  expansion while switching): tags are keyed per scene, no cross-talk.
- **Rename while a read is in flight:** `SceneNameChanged` bumps the item
  epoch, so a response keyed by the old name never applies into the renamed
  scene.
- **Empty scenes / no inputs:** orthogonal to the empty-batch fix (empty
  batches never reach the wire since `9d6619b2`); no interaction.

## Testing

- **`test/utils/event_read_ordering_test.dart`** (new home candidate —
  component is in `lib/utils/`): pure unit tests adapting astra's pinned
  cases — event mid-read wins per key; a read sent *after* an event
  supersedes it; epoch invalidates in-flight tags; per-key independence;
  `newEpoch` clears journals.
- **Fake-peer integration** (`test/websocket/`, existing `FakeObsPeer` with
  `ackDelay` + `event()`), one per domain: delay the read response, fire the
  value event mid-flight, then answer the read with the stale value; assert
  the store keeps the event value. Companion test per domain: without the
  mid-flight event the read applies normally (no over-blocking).
- Gates per AGENTS.md: `test/utils/` + `test/websocket/` during the wave;
  full suite + analyze (472 baseline) before wrap-up.

## Wave structure (commit per verified unit)

1. `EventOrdering` component + pure tests.
2. Scenes domain integration + fake-peer ordering tests.
3. Scene-item visibility domain + tests.
4. Audio volume/mute domain + tests.
5. Epoch resets (reconnect, collection change, list/name changes) + tests.
6. Full gates, changelog + handoff, push; dogfood note for the user (real
  OBS: rapid scene switching while events fly, slider drags during active
  metering).

## Risks

- **Missed event handler** → stale read beats an unjournaled event. Mitigation:
  enumerate all six value events + the structural events in the reviewer
  checklist; the per-domain integration tests each prove their event path.
- **Over-blocking** (journal too aggressive → reads never apply): each domain
  ships the companion "no event → read applies" test.
- **`_handleEvent` is async and event dispatch for collection change is
  throttled** (:593); epoch calls must land synchronously with the existing
  applies — verify in review that `noteEvent`/`newEpoch` are placed before
  any await in those cases.
