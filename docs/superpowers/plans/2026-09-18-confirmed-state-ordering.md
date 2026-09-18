# Confirmed-State Ordering (Astra Phase 3 Wave 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Guarantee "events beat stale reads" in the dashboard: a `Get*` response must never overwrite state that a newer OBS event already set — for scenes (program/preview/studio mode), scene-item visibility, and audio volume/mute.

**Architecture:** New pure component `EventOrdering` (`lib/utils/event_read_ordering.dart`, zero app deps) holding a monotonic sequence + epoch + per-key event journal. `DashboardStore` integrates in place: FIFO tag queues per read target (captured at send, popped at apply), `noteEvent` at each value-event apply, `newEpoch` on structural changes and session attach. Optimistic writes, slider ticks, and the command-ack policy are unchanged.

**Spec:** `docs/superpowers/specs/2026-09-18-confirmed-state-ordering-design.md` (ratified). Reference mechanism: `origin/redesign-astra:lib/redesign/obs/` (do not port its files — adapt its semantics).

**Tech Stack:** Dart/Flutter, MobX (fields added are non-observable → no `.g.dart` regeneration), GetIt, fake-peer test seam `test/websocket/support/fake_obs_peer.dart`.

## Global Constraints

- Work on new branch `confirmed-state-ordering` off `4.0-liquid-glass` (`git checkout -b confirmed-state-ordering 4.0-liquid-glass`), pushed with `-u`; merge back only after user dogfood.
- Commit per task, after its tests pass. `dart format` every changed file (tall style) before committing.
- `flutter analyze` must stay at the documented **472-issue baseline** (17 errors, all in `tool/youtube_spike` unfetched protos — expected).
- Never run `flutter test` concurrently with other flutter processes.
- Never port `lib/redesign/` code or astra docs.
- Line numbers below reference `4.0-liquid-glass` @ `f1b74c80` — trust code anchors over numbers; numbers drift as tasks land.
- DashboardStore is an intentional monolith — integrate in place, do not split it.
- The store's dispatch try/catch (`handleStream`, `dashboard.dart:602`) only covers synchronous throws; `_handleBatchResponse` is async — async throws surface as unhandled test errors. Use that to detect RED.

---

### Task 1: `EventOrdering` component + pure tests

**Files:**
- Create: `lib/utils/event_read_ordering.dart`
- Test: `test/utils/event_read_ordering_test.dart`

**Interfaces:**
- Produces (all later tasks rely on these exact signatures):
  - `class EventOrdering<K>` with `({int epoch, int seq}) capture()`, `void noteEvent(K key)`, `bool shouldApplyRead(K key, ({int epoch, int seq}) tag)`, `void newEpoch()`.

- [ ] **Step 1: Write the failing tests**

`test/utils/event_read_ordering_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/event_read_ordering.dart';

void main() {
  late EventOrdering<String> ordering;

  setUp(() => ordering = EventOrdering<String>());

  test('read applies when no event arrived for the key', () {
    final tag = ordering.capture();
    expect(ordering.shouldApplyRead('program', tag), isTrue);
  });

  test('event captured after send beats the read (per key)', () {
    final tag = ordering.capture();
    ordering.noteEvent('program');
    expect(ordering.shouldApplyRead('program', tag), isFalse);
    // a different key is unaffected (per-key independence)
    expect(ordering.shouldApplyRead('preview', tag), isTrue);
  });

  test('a read sent AFTER the event supersedes it', () {
    ordering.noteEvent('program');
    final tag = ordering.capture();
    expect(ordering.shouldApplyRead('program', tag), isTrue);
  });

  test('two events: only sequences after capture block', () {
    ordering.noteEvent('program'); // seq 1
    final tag = ordering.capture(); // captures 1
    expect(ordering.shouldApplyRead('program', tag), isTrue);
    ordering.noteEvent('program'); // seq 2
    expect(ordering.shouldApplyRead('program', tag), isFalse);
  });

  test('newEpoch invalidates in-flight tags and clears journals', () {
    final tag = ordering.capture();
    ordering.newEpoch();
    expect(ordering.shouldApplyRead('program', tag), isFalse);
    // a fresh capture in the new epoch applies again
    final tag2 = ordering.capture();
    expect(ordering.shouldApplyRead('program', tag2), isTrue);
  });

  test('tags from an old epoch stay invalid even after new events', () {
    final tag = ordering.capture();
    ordering.newEpoch();
    ordering.noteEvent('program');
    expect(ordering.shouldApplyRead('program', tag), isFalse);
  });
}
```

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/utils/event_read_ordering_test.dart`
Expected: FAIL — `event_read_ordering.dart` doesn't exist.

- [ ] **Step 3: Implement the component**

`lib/utils/event_read_ordering.dart`:

```dart
/// Ordering journal for OBS state: a value event always beats a read that
/// was sent before the event arrived ("events beat stale reads").
///
/// Integrate at two seams: [capture] immediately before a read request is
/// sent, and [shouldApplyRead] when its response is applied. Value events
/// call [noteEvent] when applied. [newEpoch] invalidates everything in
/// flight (reconnect, scene-collection change, renames).
///
/// Pure and synchronous on purpose — no Flutter / MobX / app imports.
class EventOrdering<K> {
  int _seq = 0;
  int _epoch = 0;

  /// Key -> sequence of the latest event seen for it
  final Map<K, int> _latestEventSeq = {};

  /// Tag captured immediately before a read request is sent
  ({int epoch, int seq}) capture() => (epoch: _epoch, seq: _seq);

  /// A value event for [key] arrived (call when the event is applied)
  void noteEvent(K key) => _latestEventSeq[key] = ++_seq;

  /// At read-apply time: true when [tag] belongs to the current epoch and
  /// no event for [key] arrived after [tag] was captured. False = an event
  /// beat this read; keep the event value already in state.
  bool shouldApplyRead(K key, ({int epoch, int seq}) tag) =>
      tag.epoch == _epoch && (_latestEventSeq[key] ?? 0) <= tag.seq;

  /// Invalidate every in-flight tag and all journaled events
  void newEpoch() {
    _epoch++;
    _latestEventSeq.clear();
  }
}
```

- [ ] **Step 4: Run to verify GREEN**

Run: `flutter test test/utils/event_read_ordering_test.dart`
Expected: 6/6 PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/utils/event_read_ordering.dart test/utils/event_read_ordering_test.dart
flutter analyze | tail -1   # must stay: 472 issues found
git add lib/utils/event_read_ordering.dart test/utils/event_read_ordering_test.dart
git commit -m "feat(utils): EventOrdering - events-beat-stale-reads journal (astra phase 3 wave 1)"
```

---

### Task 2: Scenes domain (program / preview / studio mode)

**Files:**
- Modify: `lib/stores/views/dashboard.dart` (fields ~:280, `initialRequests` :287, `_sceneCollectionRequests` :337, `_resyncAfterFailedMutation` :446-451/497-501, `_handleEvent` cases :1086/:1108/:1125/:1132, `_handleResponse` cases :1326/:1493)
- Test: `test/websocket/state_ordering_test.dart` (new)

**Interfaces:**
- Consumes: `EventOrdering` from Task 1; `FakeObsPeer` (`peer.responseData`, `peer.rejections`, `peer.ackDelay`, `peer.event()`, `peer.droppedRequestTypes`); test harness pattern from `test/websocket/command_ack_dashboard_store_test.dart` (Hive init, `connect()`, `waitFor`, `requestsOf`).
- Produces: DashboardStore private members later tasks reuse the pattern of:
  - `typedef _ReadTag = ({int epoch, int seq});`
  - `_sceneOrdering` (`EventOrdering<_SceneField>`), `_SceneField { program, preview, studioMode }`
  - `_sendGetSceneList()`, `_sendGetStudioModeEnabled()` wrappers

- [ ] **Step 1: Write the failing integration tests**

`test/websocket/state_ordering_test.dart` — copy the setUp/tearDown/connect/waitFor/requestsOf harness verbatim from `command_ack_dashboard_store_test.dart` (Hive temp dir, `FakeObsPeer.start()`, register NetworkStore+DashboardStore in GetIt). Tests:

```dart
test('scene event during in-flight GetSceneList beats the stale read', () async {
  peer.responseData['GetSceneList'] = {
    'scenes': [
      {'sceneName': 'Camera', 'sceneIndex': 0},
      {'sceneName': 'Break', 'sceneIndex': 1},
    ],
    'currentProgramSceneName': 'Camera',
    'currentPreviewSceneName': 'Camera',
  };
  peer.droppedRequestTypes.add('GetSceneItemList'); // keep the chain quiet
  await connect();
  dashboardStore.handleStream();

  // drive a GetSceneList re-read via the ack layer's failure path
  peer.rejections['SetCurrentProgramScene'] =
      RequestStatus.InvalidResourceType.identifier;
  peer.ackDelay = const Duration(milliseconds: 300);
  final ackFuture = dashboardStore.sendMutation(
    RequestType.SetCurrentProgramScene,
    fields: {'sceneName': 'Nope'},
    label: 'Scene switch',
  );
  await waitFor(() => requestsOf('GetSceneList').isNotEmpty,
      'GetSceneList re-read in flight');

  // event arrives AFTER the read was sent, carrying newer state
  peer.event('CurrentProgramSceneChanged', {'sceneName': 'Break'});
  await ackFuture; // mutation rejected; re-read resolves with stale data

  await waitFor(() => dashboardStore.activeSceneName == 'Break',
      'event value survives the stale read');
  await Future<void>.delayed(const Duration(milliseconds: 400));
  expect(dashboardStore.activeSceneName, 'Break'); // never regressed
});
```

Companion (no over-blocking): same setup WITHOUT the mid-flight event → after the re-read, `activeSceneName` is the response's `'Camera'` (read applies normally).

Third test (per-field independence): same in-flight setup, but fire `peer.event('CurrentPreviewSceneChanged', {'sceneName': 'Break'})` — program field of the stale read still applies (`activeSceneName` → `'Camera'`), preview does not regress (`studioModePreviewSceneName` stays `'Break'`).

Note for RED: without the ordering gate the first test ends with `activeSceneName == 'Camera'` (stale read wins) — that IS the bug demonstrated.

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/websocket/state_ordering_test.dart`
Expected: first and third tests FAIL (stale read wins / preview not independent), companion passes.

- [ ] **Step 3: Integrate the scenes journal into DashboardStore**

In `dashboard.dart`, near the other privates (~:281):

```dart
enum _SceneField { program, preview, studioMode }

// place inside DashboardStore with the other fields:
final EventOrdering<_SceneField> _sceneOrdering = EventOrdering();
final Queue<({int epoch, int seq})> _sceneListTags = Queue();
final Queue<({int epoch, int seq})> _studioModeTags = Queue();
```

Imports to add: `dart:collection` (Queue), `package:obs_blade/utils/event_read_ordering.dart`.

Send wrappers (new methods, replace ALL listed send sites):

```dart
void _sendGetSceneList() {
  _sceneListTags.add(_sceneOrdering.capture());
  NetworkHelper.makeRequest(
    GetIt.instance<NetworkStore>().activeSession!.socket,
    RequestType.GetSceneList,
  );
}

void _sendGetStudioModeEnabled() {
  _studioModeTags.add(_sceneOrdering.capture());
  NetworkHelper.makeRequest(
    GetIt.instance<NetworkStore>().activeSession!.socket,
    RequestType.GetStudioModeEnabled,
  );
}
```

Replace these existing sends with the wrappers (anchor by content):
- `_sceneCollectionRequests` (:337): `RequestType.GetSceneList` → `_sendGetSceneList();`
- `_resyncAfterFailedMutation` (:450): → `_sendGetSceneList();`
- `_resyncAfterFailedMutation` `SetStudioModeEnabled` case (:498-501): → `_sendGetStudioModeEnabled();`
- `_handleEvent` `SceneListChanged` (:1087-1090): → `_sendGetSceneList();`
- `_handleEvent` `StudioModeStateChanged` (:1119-1122): → `_sendGetSceneList();`
- `_handleResponse` `GetStudioModeEnabled` (:1503-1506): → `_sendGetSceneList();`
- `initialRequests` (:305-307): `GetStudioModeEnabled` → `_sendGetStudioModeEnabled();`

noteEvent at event apply (inside `_handleEvent`):
- `CurrentProgramSceneChanged` (:1125): before `this.activeSceneName = ...` add `_sceneOrdering.noteEvent(_SceneField.program);`
- `CurrentPreviewSceneChanged` (:1132): before the assignment add `_sceneOrdering.noteEvent(_SceneField.preview);`
- `StudioModeStateChanged` (:1108): before `this.studioMode = ...` add `_sceneOrdering.noteEvent(_SceneField.studioMode);`

Gate the applies (in `_handleResponse`):

`GetSceneList` case (:1326) — pop + per-field gate:

```dart
final tag =
    _sceneListTags.isEmpty ? null : _sceneListTags.removeFirst();
if (tag == null ||
    _sceneOrdering.shouldApplyRead(_SceneField.program, tag)) {
  this.activeSceneName = getSceneListResponse.currentProgramSceneName;
}
if (tag == null ||
    _sceneOrdering.shouldApplyRead(_SceneField.preview, tag)) {
  this.studioModePreviewSceneName =
      getSceneListResponse.currentPreviewSceneName;
}
this.scenes = ObservableList.of([...getSceneListResponse.scenes]
  ..sort((a, b) => b.sceneIndex - a.sceneIndex));
// ...chained GetSceneItemList send stays as-is (reads current state)
```

(Empty queue = response to an untracked send → apply, today's behavior.)

`GetStudioModeEnabled` case (:1493) — pop `_studioModeTags`, gate `this.studioMode = getStudioModeEnabledResponse.studioModeEnabled;` the same way (the conditional `_sendGetSceneList()` below it is unaffected).

- [ ] **Step 4: Run to verify GREEN**

Run: `flutter test test/websocket/state_ordering_test.dart test/websocket/command_ack_dashboard_store_test.dart test/websocket/command_ack_test.dart`
Expected: all PASS (the existing suites prove no regression of the ack policy).

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/stores/views/dashboard.dart test/websocket/state_ordering_test.dart
flutter analyze | tail -1   # 472 baseline
git add lib/stores/views/dashboard.dart test/websocket/state_ordering_test.dart
git commit -m "feat(dashboard): scenes domain - events beat stale GetSceneList/GetStudioModeEnabled reads"
```

---

### Task 3: Scene-item visibility domain

**Files:**
- Modify: `lib/stores/views/dashboard.dart` (`_requestDisplayedSceneItems` :369, `GetSceneList`→`GetSceneItemList` chain :1339, group loop :1387-1395, `SceneItemEnableStateChanged` :1219, `GetSceneItemList` apply :1375, `GetGroupSceneItemList` apply :1398)
- Test: `test/websocket/state_ordering_test.dart` (append)

**Interfaces:**
- Consumes: Task 1 component; Task 2 harness/pattern.
- Produces: `_sceneItemOrdering` (`EventOrdering<(String, int)>`), `_sceneItemListTags` / `_groupSceneItemListTags` (`Map<String, Queue<_ReadTag>>`), `_sendGetSceneItemList(String sceneName)`, `_sendGetGroupSceneItemList(String sourceName)`.

- [ ] **Step 1: Failing tests**

Setup: `GetSceneList` responseData with one scene `Camera`; `GetSceneItemList` responseData:

```dart
{
  'sceneItems': [
    {'sceneItemId': 7, 'sceneItemIndex': 0, 'sceneItemEnabled': true,
     'sourceName': 't1', 'isGroup': false},
  ],
}
```

Also `peer.droppedRequestTypes.add('GetSourceFilterList')` and set `NetworkHelper.requestAckTimeout = const Duration(milliseconds: 300)` in the test (with `addTearDown` resetting it to 10s) — the filter batch following a non-empty item list must not leave a pending ack hanging at teardown. (If the FilterList batch response proves to parse cleanly against the default empty responseData, dropping is optional; decide by running it once both ways, keep the quieter one.)

Test A (event beats stale read): after connect+handleStream and the initial item apply, set `peer.ackDelay = 300ms`, then fire `peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'})` (re-triggers `_requestDisplayedSceneItems`); `waitFor` the new `GetSceneItemList` request; then fire `peer.event('SceneItemEnableStateChanged', {'sceneName': 'Camera', 'sceneItemId': 7, 'sceneItemEnabled': false})`; let the stale read (enabled: true) arrive. Assert `dashboardStore.currentSceneItems.single.sceneItemEnabled` stays `false` after settling.

Test B (companion): no mid-flight event → the re-read applies `enabled: true` normally.

- [ ] **Step 2: Run to verify RED** — Test A ends with `true` pre-fix.

- [ ] **Step 3: Implement**

Fields:

```dart
final EventOrdering<(String, int)> _sceneItemOrdering = EventOrdering();
final Map<String, Queue<({int epoch, int seq})>> _sceneItemListTags = {};
final Map<String, Queue<({int epoch, int seq})>> _groupSceneItemListTags = {};
```

Wrappers:

```dart
void _sendGetSceneItemList(String sceneName) {
  (_sceneItemListTags[sceneName] ??= Queue())
      .add(_sceneItemOrdering.capture());
  NetworkHelper.makeRequest(
    GetIt.instance<NetworkStore>().activeSession!.socket,
    RequestType.GetSceneItemList,
    {'sceneName': sceneName},
  );
}

void _sendGetGroupSceneItemList(String sourceName) {
  (_groupSceneItemListTags[sourceName] ??= Queue())
      .add(_sceneItemOrdering.capture());
  NetworkHelper.makeRequest(
    GetIt.instance<NetworkStore>().activeSession!.socket,
    RequestType.GetGroupSceneItemList,
    {'sceneName': sourceName},
  );
}
```

Replace: `_requestDisplayedSceneItems` (:369-378) body → `_sendGetSceneItemList(sceneName);`; the `GetSceneList`-chained send (:1339-1352) → `_sendGetSceneItemList(<same conditional name expression>);`; the group loop (:1389-1393) → `_sendGetGroupSceneItemList(sceneItem.sourceName);` (check `sourceName` nullability at the anchor — the existing code passes it directly; keep identical behavior).

Event: in `SceneItemEnableStateChanged` (:1219), AFTER the `_displayedSceneName` guard (:1224) and before the list rebuild: `_sceneItemOrdering.noteEvent((sceneItemEnableStateChangedEvent.sceneName, sceneItemEnableStateChangedEvent.sceneItemId));`

Gate `GetSceneItemList` apply (:1375): the response carries no scene name — resolve it from the request body (existing pattern at :1402): `final sceneName = NetworkHelper.getRequestBodyForUUID(response.uuid)?['sceneName'] as String?;` then pop `_sceneItemListTags[sceneName]`. When building the new `currentSceneItems`, per item:

```dart
SceneItem applyItem(SceneItem item) {
  if (sceneName == null || tag == null) return item;
  final id = item.sceneItemId;
  if (id == null) return item;
  if (_sceneItemOrdering.shouldApplyRead((sceneName, id), tag)) return item;
  // an event beat this read - keep the event value already in state
  for (final current in this.currentSceneItems) {
    if (current.sceneItemId == id) {
      return item.copyWith(sceneItemEnabled: current.sceneItemEnabled);
    }
  }
  return item;
}
```

Apply via `getSceneItemListResponse.sceneItems.map(applyItem).toList()` before the existing sort. The `fetchSceneItemsFilters()` + group loop afterwards stay unchanged.

Gate `GetGroupSceneItemList` apply (:1398 ff.) the same way, keyed by the request body's `sceneName` (the group), popping `_groupSceneItemListTags[...]`. (Read the rest of that case first — it merges children into the group item; gate only the `sceneItemEnabled` field per child.)

- [ ] **Step 4: Run to verify GREEN**

Run: `flutter test test/websocket/state_ordering_test.dart`
Expected: all PASS.

- [ ] **Step 5: Format, analyze, commit** — same trio as Task 2; message `"feat(dashboard): scene-item visibility - events beat stale item-list reads"`.

---

### Task 4: Audio volume/mute domain

**Files:**
- Modify: `lib/stores/views/dashboard.dart` (`InputVolumeChanged` :1162, `InputMuteStateChanged` :1203, `GetInputList` batch send :1448, `GetInputVolume` apply :1569, `GetInputMute` apply :1592, Input batch apply :1841-~1940, `_resyncAfterFailedMutation` :455-470)
- Test: `test/websocket/state_ordering_test.dart` (append)

**Interfaces:**
- Consumes: Task 1 component; harness.
- Produces: `_audioOrdering` (`EventOrdering<(String, _AudioField)>`), `_AudioField { volume, mute }`, `_inputBatchTags` (Queue), `_inputReadTags` (`Map<(String, _AudioField), Queue<_ReadTag>>`), `_sendGetInputVolume(String inputName)`, `_sendGetInputMute(String inputName)`.

- [ ] **Step 1: Failing tests**

Setup: `GetInputList` responseData `{'inputs': [{'inputName': 'Mic'}]}` (the batch follows automatically); default batch answers volume/mute from `peer.responseData['GetInputVolume'] = {'inputVolumeMul': 0.5, 'inputVolumeDb': -9.0}` and `peer.responseData['GetInputMute'] = {'inputMuted': false}`. Also `GetSceneList` minimal (one scene) + drop `GetSceneItemList` to keep the scene chain quiet.

Test A (event beats stale re-read): after settle, `peer.rejections['SetInputVolume'] = RequestStatus.GenericError.identifier;` `peer.ackDelay = 300ms`; `dashboardStore.sendMutation(RequestType.SetInputVolume, fields: {'inputName': 'Mic', 'inputVolumeMul': 0.8}, label: 'Volume')`; `waitFor` the single `GetInputVolume` re-read request; fire `peer.event('InputVolumeChanged', {'inputName': 'Mic', 'inputVolumeMul': 0.9, 'inputVolumeDb': -0.9})`; stale read answers 0.5. Assert the `Mic` input's `inputVolumeMul` stays `0.9`.

Test B (companion, no over-blocking): establish a changed value first — fire `peer.event('InputVolumeChanged', {'inputName': 'Mic', 'inputVolumeMul': 0.9, 'inputVolumeDb': -0.9})` with NO read in flight and let it apply (assert `0.9`). Then the rejected `SetInputVolume` mutation → re-read → no event during it → the read applies normally and the input returns to the response value `0.5`. (The naive variant — assert `0.5` right after rejection — is vacuous because the batch already applied `0.5`; the event-then-read sequence is what makes "reads still apply" observable.)

Test C (mute path): same shape with `SetInputMute` rejected, `GetInputMute` re-read (`inputMuted: false`), mid-flight `InputMuteStateChanged` `{'inputName': 'Mic', 'inputMuted': true}` → stays `true`.

- [ ] **Step 2: Run to verify RED** — A and C regress to the stale values pre-fix.

- [ ] **Step 3: Implement**

Fields + wrappers:

```dart
enum _AudioField { volume, mute }

final EventOrdering<(String, _AudioField)> _audioOrdering = EventOrdering();
final Queue<({int epoch, int seq})> _inputBatchTags = Queue();
final Map<(String, _AudioField), Queue<({int epoch, int seq})>>
    _inputReadTags = {};

void _sendGetInputVolume(String inputName) {
  (_inputReadTags[(inputName, _AudioField.volume)] ??= Queue())
      .add(_audioOrdering.capture());
  NetworkHelper.makeRequest(
    GetIt.instance<NetworkStore>().activeSession!.socket,
    RequestType.GetInputVolume,
    {'inputName': inputName},
  );
}

void _sendGetInputMute(String inputName) {
  (_inputReadTags[(inputName, _AudioField.mute)] ??= Queue())
      .add(_audioOrdering.capture());
  NetworkHelper.makeRequest(
    GetIt.instance<NetworkStore>().activeSession!.socket,
    RequestType.GetInputMute,
    {'inputName': inputName},
  );
}
```

Replace the `_resyncAfterFailedMutation` sends (:455-470) with the wrappers. In the `GetInputList` handler, enqueue before the batch send (:1448): `_inputBatchTags.add(_audioOrdering.capture());`

Events: `InputVolumeChanged` (:1162) → `_audioOrdering.noteEvent((inputVolumeChangedEvent.inputName, _AudioField.volume));` before the rebuild. `InputMuteStateChanged` (:1203) → same with `_AudioField.mute`.

Gates:
- `GetInputVolume` apply (:1569): after resolving `requestData['inputName']`, pop `_inputReadTags[(name, _AudioField.volume)]`; skip the `copyWith` for that input when `tag != null && !shouldApplyRead(...)`.
- `GetInputMute` apply (:1592): same with `_AudioField.mute`.
- Input batch apply (:1841 ff.): pop `_inputBatchTags` once; in the final `.map` over inputs, when building the merged input, keep `tempInput.inputVolumeMul/inputVolumeDb` (current = event value) if the volume read is blocked, and `tempInput.inputMuted` if the mute read is blocked. SyncOffset is **not** gated (out of scope — see plan end).

- [ ] **Step 4: Run GREEN** — `flutter test test/websocket/state_ordering_test.dart` all PASS.

- [ ] **Step 5: Format, analyze, commit** — message `"feat(dashboard): audio volume/mute - events beat stale input reads"`.

---

### Task 5: Epoch resets (reconnect, collection change, renames)

**Files:**
- Modify: `lib/stores/views/dashboard.dart` (`initialRequests` :287, `SceneListChanged` :1086, `CurrentSceneCollectionChanging` :1040, `CurrentSceneCollectionChanged` :1046, `InputNameChanged` :1156; ADD a `SceneNameChanged` case — none exists today, verified at `f1b74c80`)
- Test: `test/websocket/state_ordering_test.dart` (append)

**Interfaces:** consumes all previous.

- [ ] **Step 1: Failing tests**

Test A (structural event invalidates an in-flight scene read): connect with two scenes; drive a `GetSceneList` re-read via rejected mutation with `ackDelay`; while in flight fire `peer.event('SceneListChanged', {'scenes': [...]})` — the event handler ALSO sends a fresh tracked `GetSceneList`. Record every `activeSceneName` value in an `autorun` from before the re-read. Then swap `peer.responseData['GetSceneList']['currentProgramSceneName']` to `'Break'` (the map is read at ack time, so the second response carries it) and let both responses arrive. Assert: the stale first response's value (`'Camera'`) never lands *after* the SceneListChanged event (no transient regression in the recording), and the final state is `'Break'`. Without the epoch reset, response#1 pops its tag and — no program event being journaled — applies `'Camera'` transiently: that's the RED.

Test B (rename invalidates item journal): with the Task-3 item setup, send a `GetSceneItemList` re-read (program event), then fire `peer.event('SceneNameChanged', {'oldSceneName': 'Camera', 'newSceneName': 'Cam'})` before the response arrives → the stale item read must not apply (assert the event-set `enabled` value survives; combine with a `SceneItemEnableStateChanged` before the rename if a concrete differing value is needed).

Test C (session re-attach resets epochs): connect; capture an in-flight `GetSceneList`; call `dashboardStore.initialRequests()` directly (this is the re-attach burst seam — it now resets epochs); the stale response must not apply its program value.

- [ ] **Step 2: Run to verify RED** — A/B/C fail pre-fix (stale values apply).

- [ ] **Step 3: Implement**

- Top of `initialRequests()` (:287): `_sceneOrdering.newEpoch(); _sceneItemOrdering.newEpoch(); _audioOrdering.newEpoch();` and clear all tag queues (`_sceneListTags.clear(); _studioModeTags.clear(); _sceneItemListTags.clear(); _groupSceneItemListTags.clear(); _inputBatchTags.clear(); _inputReadTags.clear();`). (Task 1–4 members must all exist by now; move the clears into a small `_resetOrdering()` private method called from `initialRequests`.)
- `SceneListChanged` (:1086): before `_sendGetSceneList();` add `_sceneOrdering.newEpoch(); _sceneItemOrdering.newEpoch();` and clear the scene/item queues.
- New case in `_handleEvent` (next to `SceneListChanged`):

```dart
case EventType.SceneNameChanged:
  /// A rename invalidates name-keyed journals (items, audio) and the
  /// scene list holds a stale name until re-read
  _sceneItemOrdering.newEpoch();
  _audioOrdering.newEpoch();
  _sendGetSceneList();
  break;
```

(Verify `EventType.SceneNameChanged` exists in `lib/types/enums/event_type.dart`; if the typed event class exists under `lib/types/classes/stream/events/`, no parsing is needed here — the re-read covers state.)
- `InputNameChanged` (:1156): add `_audioOrdering.newEpoch();` before `_sceneCollectionRequests();`.
- `CurrentSceneCollectionChanging` (:1040) and `CurrentSceneCollectionChanged` (:1046): `_resetOrdering();` in both (all three journals + queues).

- [ ] **Step 4: Run GREEN** — `flutter test test/websocket/` all PASS.

- [ ] **Step 5: Format, analyze, commit** — message `"feat(dashboard): ordering epochs - reconnect, collection change, renames invalidate in-flight reads"`.

---

### Task 6: Wrap-up gates + docs + push

- [ ] **Step 1: Full gate (sequential, never concurrent)**

```bash
flutter test test/chat/ test/websocket/ test/persistence/ test/pro/ test/statistics/ test/settings/ test/utils/
flutter analyze   # must print: 472 issues found
```

- [ ] **Step 2: Docs**

Append a `## 2026-09-XX` entry to `docs/changelog-agent.md` (wave summary, per-domain commits, test counts, the accepted late-after-timeout corner, the deliberately-un gated syncOffset note). Update the astra paragraph in `docs/session-handoff.md`: confirmed-state ordering landed on branch `confirmed-state-ordering`, pending user dogfood; remaining astra ports: chat independence + stale-state honesty. Add the spec/plan to the handoff Doc map table.

- [ ] **Step 3: Commit docs, push branch**

```bash
git push -u origin confirmed-state-ordering
```

- [ ] **Step 4: Dogfood handoff message to the user** — real-OBS feel checks: rapid scene switching while OBS events fly, scene-item visibility toggles, slider drags (incl. during active metering), studio-mode toggling; no stale regressions expected; merge only on user OK.

## Deliberately out of scope (flagged, not silently skipped)

- `InputAudioSyncOffset` has the identical event/read race shape (`InputAudioSyncOffsetChanged` :1241 + batch/single reads) — NOT gated in this wave per the ratified spec (volume/mute only). Follow-up candidate.
- `GetSceneList`'s scene list itself is ungated (no event carries list data; `SceneListChanged` triggers re-reads) — intentional.
- STALE/RECONNECTING surfaces, pending indicators, per-row freshness — later stale-state-honesty port.
- `lib/redesign/` — never ported.
