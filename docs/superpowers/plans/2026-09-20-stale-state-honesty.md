# Stale-State Honesty Implementation Plan

> **For agentic workers:** S-tier per AGENTS.md — the controller implements
> in-session, TDD per task, gates at the end. Steps use checkbox (`- [ ]`)
> syntax for tracking.

**Goal:** During an OBS reconnect, the dashboard honestly marks displayed
values as last known (per-pane badges), disables mutation controls, and
refuses to send mutations into the dead socket — instead of looking live
while silently losing user intent.

**Architecture:** One plain-getter predicate `DashboardStore.obsStateStale`
(= `reconnecting`; documented seam for future drivers), a guard at the
`sendMutation` chokepoint returning a new `ObsRequestAck.notSent` (no resync,
no toast), and per-pane `StaleStateBadge` + per-control `StaleGuard`
(Observer-driven `IgnorePointer` + opacity) in the On Air design system.
Spec: `docs/superpowers/specs/2026-09-20-stale-state-honesty-design.md`.

**Tech Stack:** Flutter, MobX (`Observer`), GetIt, fake-peer test harness
(`test/websocket/support/fake_obs_peer.dart`).

## Global Constraints

- Values are NEVER dimmed, hidden, or color-altered — disabled look applies
  to controls only (spec §3).
- No `@computed`/`@observable` additions — plain getter only; no
  `build_runner` regen (spec §1).
- No `lib/redesign/` code; concept port only.
- `dart format` on changed files (tall style); analyze stays at exactly the
  472-issue baseline; never run flutter processes concurrently.
- Commit per verified unit; never stage the dirty `android/` IDE files.
- Test gates: `test/websocket/` per task; full suite + analyze at wrap-up.

---

### Task 1: Predicate + not-sent ack + sendMutation guard

**Files:**
- Modify: `lib/types/classes/obs_request_ack.dart` (add `notSent` kind +
  constructor + `describe()` case)
- Modify: `lib/stores/views/dashboard.dart` (predicate near `reconnecting`
  :227; guard at top of `sendMutation` :538)
- Test: `test/websocket/command_ack_dashboard_store_test.dart` (append group)

**Interfaces:**
- Produces: `DashboardStore.obsStateStale` (`bool get`), used by Task 2's
  widgets; `ObsRequestFailureKind.notSent`, `ObsRequestAck.notSent(RequestType?)`.

- [ ] **Step 1: Failing tests** — append to
  `test/websocket/command_ack_dashboard_store_test.dart` (harness already
  provides `connect()`, `requestsOf(...)`, `waitFor(...)`, `peer`,
  `dashboardStore`):

```dart
group('stale-state guard', () {
  test('obsStateStale tracks the reconnecting flag', () {
    expect(dashboardStore.obsStateStale, isFalse);
    dashboardStore.reconnecting = true;
    expect(dashboardStore.obsStateStale, isTrue);
    dashboardStore.reconnecting = false;
    expect(dashboardStore.obsStateStale, isFalse);
  });

  test(
    'stale guard refuses mutations: nothing on the wire, notSent ack, no resync, no notice',
    () async {
      await connect();
      dashboardStore.handleStream();
      dashboardStore.reconnecting = true;

      final wireBaseline = peer.requests.length;
      final ack = await dashboardStore.sendMutation(
        RequestType.SetCurrentProgramScene,
        fields: {'sceneName': 'Nope'},
        label: 'Scene switch',
      );

      expect(ack.success, isFalse);
      expect(ack.failureKind, ObsRequestFailureKind.notSent);
      expect(peer.requests.length, wireBaseline);

      /// No resync read and no failure toast may fire for a refused send
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(requestsOf('GetSceneList'), isEmpty);
      expect(dashboardStore.commandFailureNotice, isNull);
    },
  );

  test('guard is inert while not stale', () async {
    await connect();
    dashboardStore.handleStream();

    final ack = await dashboardStore.sendMutation(
      RequestType.SetCurrentProgramScene,
      fields: {'sceneName': 'Camera'},
      label: 'Scene switch',
    );

    expect(ack.success, isTrue);
    expect(requestsOf('SetCurrentProgramScene'), isNotEmpty);
  });
});
```

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/websocket/command_ack_dashboard_store_test.dart`
Expected: FAIL — `obsStateStale` getter does not exist (compile error) or,
after stubbing, ack.success is true / wire grew.

- [ ] **Step 3: Implement**

`lib/types/classes/obs_request_ack.dart` — add the enum value:

```dart
  /// Never reached the wire: refused locally because the OBS connection is
  /// down (stale-state guard in DashboardStore.sendMutation). Not an OBS
  /// failure - no resync read, no failure surface
  notSent,
```

constructor next to `connectionLost`:

```dart
  const ObsRequestAck.notSent(RequestType? requestType)
    : this._(requestType, ObsRequestFailureKind.notSent, null, null);
```

and the `describe()` case:

```dart
      case ObsRequestFailureKind.notSent:
        return '${this.requestType} not sent - OBS connection is down';
```

`lib/stores/views/dashboard.dart` — predicate (place directly under the
`reconnecting` observable, :227):

```dart
  /// Displayed OBS values may not reflect OBS's actual state and mutations
  /// cannot be delivered - the confirmation channel (the socket) is down.
  /// Single driver today: reconnect loop active. Future drivers (collection-
  /// changing window, terminated-but-still-mounted) plug in here without
  /// touching widgets. Deliberately a plain getter, NOT @computed: reactions
  /// track the `reconnecting` read through it identically, no codegen needed
  bool get obsStateStale => this.reconnecting;
```

guard at the top of `sendMutation` (:538, before the `session` lookup):

```dart
    /// Stale-state honesty: while the confirmation channel is down the
    /// mutation could never be confirmed - refuse the send instead of
    /// losing the intent silently. No resync read, no failure surface (the
    /// controls are disabled and the reconnect burst re-reads everything)
    if (this.obsStateStale) {
      return ObsRequestAck.notSent(request);
    }
```

- [ ] **Step 4: Run GREEN**

Run: `flutter test test/websocket/command_ack_dashboard_store_test.dart`
Expected: all PASS (existing ack tests unaffected — guard only fires when
`reconnecting == true`, which no other test sets).

- [ ] **Step 5: Commit**

```bash
dart format lib/types/classes/obs_request_ack.dart lib/stores/views/dashboard.dart test/websocket/command_ack_dashboard_store_test.dart
git add lib/types/classes/obs_request_ack.dart lib/stores/views/dashboard.dart test/websocket/command_ack_dashboard_store_test.dart
git commit -m "feat(dashboard): stale-state predicate + sendMutation guard refuses sends while reconnecting"
```

---

### Task 2: StaleStateBadge + StaleGuard + pane/control wiring + toast copy

**Files:**
- Create: `lib/shared/design/stale_state_badge.dart`
- Create: `lib/shared/design/stale_guard.dart`
- Modify: `lib/shared/design/design.dart` (add 2 exports)
- Modify: `lib/stores/views/dashboard.dart` — NOTHING (uses Task 1's
  `obsStateStale`)
- Badge anchors (3): `.../scene_content/scene_items/scene_items.dart`,
  `.../scene_content/audio_inputs/audio_inputs.dart`,
  `.../dashboard_element_layout.dart` (`_buildStandalone` SceneButtons case)
- Control wraps (uniform one-liner each, listed below)
- Modify: `lib/views/dashboard/widgets/reconnect_toast.dart` (copy + drop
  debug log)

**Interfaces:**
- Consumes: `DashboardStore.obsStateStale` (Task 1).
- Produces: `StaleStateBadge` (const, no args), `StaleGuard({required Widget child})`.

- [ ] **Step 1: `StaleStateBadge`** — `lib/shared/design/stale_state_badge.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../stores/views/dashboard.dart';
import 'app_motion.dart';
import 'app_spacing.dart';
import 'app_text_colors.dart';

/// "LAST KNOWN STATE" marker for dashboard panes: shown while
/// [DashboardStore.obsStateStale] - values stay fully visible (never dimmed
/// or hidden); the badge and the disabled controls carry the honesty.
class StaleStateBadge extends StatelessWidget {
  const StaleStateBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Observer(
      builder: (_) => AnimatedSwitcher(
        duration: AppMotion.medium,
        child: GetIt.instance<DashboardStore>().obsStateStale
            ? Padding(
                key: const ValueKey('stale'),
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 14.0,
                      color: theme.extension<AppTextColors>()!.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'LAST KNOWN STATE - reconnecting to OBS',
                        style: theme.textTheme.labelSmall!.copyWith(
                          color:
                              theme.extension<AppTextColors>()!.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(key: ValueKey('fresh')),
      ),
    );
  }
}
```

- [ ] **Step 2: `StaleGuard`** — `lib/shared/design/stale_guard.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../stores/views/dashboard.dart';
import 'app_motion.dart';

/// Disables a mutation control while [DashboardStore.obsStateStale] (dead
/// transport, intent would be lost). Wrap CONTROLS only - never value
/// displays - and never a scrollable (IgnorePointer would block scrolling).
class StaleGuard extends StatelessWidget {
  final Widget child;

  const StaleGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final bool stale = GetIt.instance<DashboardStore>().obsStateStale;
        return IgnorePointer(
          ignoring: stale,
          child: AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: stale ? 0.45 : 1.0,
            child: this.child,
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Exports** — add to `lib/shared/design/design.dart`
  (alphabetical: both sort after `staggered_entrance` — `stag` < `stal`):
  `export 'stale_guard.dart';` then `export 'stale_state_badge.dart';`

- [ ] **Step 4: Badge anchors (3)**

1. `scene_items/scene_items.dart`: wrap the `NestedScrollManager(...)` child
   in the `Observer` body in a `Column(children: [const StaleStateBadge(),
   Expanded(child: <existing NestedScrollManager>)])`.
2. `audio_inputs/audio_inputs.dart`: same wrap.
3. `dashboard_element_layout.dart` `_buildStandalone`
   `DashboardElement.SceneButtons` case: insert `const StaleStateBadge(),`
   before the `Center(...)` element in the returned list, and add
   `import '../../../shared/design/stale_state_badge.dart';` (the file
   already imports `design.dart`, so the export covers it).

- [ ] **Step 5: Control wraps** — wrap each of these in `StaleGuard(...)`
  (import via `design.dart`; every site already imports it or add the
  import). Never wrap a scrollable:

1. `scene_buttons/scene_button.dart`: the button's tap target (the
   `CupertinoButton`/gesture widget returned in `build`).
2. `scene_items/scene_items.dart`: each `VisibilitySlideWrapper(...)`
   construction in the list (top-level items AND group children) — covers
   tile taps + slide actions; list scroll unaffected.
3. `audio_inputs/audio_inputs.dart`: each `VisibilitySlideWrapper(...)`
   (global AND scene inputs) — covers slider, mute, sync-offset field,
   slide actions.
4. `dashboard_element_layout.dart`: `StudioModeTransitionButton()` and both
   `Row(...)`s of the `StudioModeConfig` case (`StudioModeCheckbox`,
   `TransitionControls`).
5. `exposed_controls/exposed_controls.dart`: the four sub-control widgets
   (`StreamingControls()`, `RecordingControls()`,
   `ReplayBufferControls()`, `HotkeysControl()`) at their `DescribedBox`
   child sites. Accepted: a long hotkey list can't scroll while stale —
   the sendMutation guard is the real backstop.
6. `status_app_bar/general_actions.dart`: the four mutation buttons
   (:97-144, stream/record/pause cluster).
7. `scene_items/filter_list/filter_list.dart`: the filter visibility
   toggle + options button (:121, :158).
8. `profile_scene_collection/profile_control.dart` and
   `scene_collection_control.dart`: the picker controls (:37, :39).

- [ ] **Step 6: Toast copy** — `reconnect_toast.dart`:
  `:116` text → `'OBS connection lost - values shown are\nthe last known state\nReconnecting...'`;
  delete the `advLog('RECONNECTING!!!!! - $reconnecting')` line (:73) and
  the now-unused `general_helper.dart` import if nothing else uses it.

- [ ] **Step 7: Analyze + format**

Run: `dart format <changed files>` then `flutter analyze`
Expected: exactly `472 issues found.`

- [ ] **Step 8: Commit**

```bash
git add lib/shared/design/ lib/views/dashboard/
git commit -m "feat(dashboard): per-pane LAST KNOWN badges + control lockout while reconnecting"
```

---

### Task 3: Full gates + docs + push

**Files:**
- Modify: `docs/changelog-agent.md` (new top entry)
- Modify: `docs/session-handoff.md` (astra paragraph: wave 2 landed, pending
  dogfood)
- Modify: `.superpowers/sdd/progress.md` (ledger, local only)

- [ ] **Step 1: Full gate** (never concurrent with analyze):
  `flutter test test/chat/ test/websocket/ test/persistence/ test/pro/ test/statistics/ test/settings/ test/utils/`
  Expected: all PASS (800 + new 3).
  Then: `flutter analyze` → exactly `472 issues found.`
- [ ] **Step 2: Docs** — changelog entry (wave 2: predicate/guard/badges/
  lockout/toast; commit refs; gates) + handoff astra paragraph update
  (wave 2 landed pending dogfood; remaining: chat independence + syncOffset
  follow-up) + ledger line.
- [ ] **Step 3: Commit + push**

```bash
git add docs/changelog-agent.md docs/session-handoff.md
git commit -m "docs: stale-state honesty wave 2 - changelog + handoff"
git push origin 4.0-liquid-glass
```

- [ ] **Step 4: Dogfood handoff** — tell the user: on `4.0-liquid-glass`,
  connect to OBS, then quit OBS / kill its network mid-session → badges
  appear on Scenes/Scene Items/Audio, controls lock at 0.45 opacity, toast
  says values are last known; restart OBS → "Reconnected!" flash, badges
  fade, controls re-enable, values snap to confirmed state immediately.
  Merge decision stays with the user (work lands directly on
  `4.0-liquid-glass` per wave-1 precedent for S-tier, or on a short branch
  if they prefer — ask at Task 1 start).

## Self-review notes

- Spec coverage: §1 predicate → Task 1; §2 guard → Task 1; §3 badges + toast
  → Task 2 Steps 1/4/6; §4 control disabling → Task 2 Step 5; §5 re-enable →
  no work (derived); testing → Task 1 tests + Task 3 gates.
- The `ObsRequestFailureKind` addition is exhaustive-safe: `describe()` is
  the only `switch` over it (verified in `obs_request_ack.dart`); no other
  switch matches on it (grep `ObsRequestFailureKind\.` before committing
  Task 1 — if a switch lacks a case, the analyzer flags it).
- `commandFailureNotice` is only written via `_surfaceCommandFailure`, which
  the guard bypasses by early return — the "no toast" assert in Task 1's
  test pins this.
