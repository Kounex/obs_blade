# Chat Engine Switch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the dashboard chat control section around a persisted, manual WebView ↔ Native chat-engine switch so native Twitch controls (login/logout, account) stop mixing with the classic WebView username controls.

**Architecture:** A new persisted `ChatEngine` enum (Hive typeId 14) + `SettingsKeys.SelectedChatEngine` (default `webView`) drives two things: the username bar's right column (engine switch + mode-specific controls) and the chat slot's renderer (native view / connect prompt / legacy WebView stack). A single top-level seam, `nativeChatAvailableFor(ChatType)`, gates every engine read so the future entitlement/monetization gate has exactly one call site to extend.

**Tech Stack:** Flutter (Dart), MobX + GetIt, Hive CE (codegen via build_runner), flutter_test.

**Spec:** `docs/superpowers/specs/2026-08-04-chat-engine-switch-design.md` (approved).

## Global Constraints

Every task implicitly includes these:

- **typeId discipline:** `ChatEngine` gets Hive **typeId 14** (`TwitchAuth = 13` is the current max). Never renumber existing IDs.
- **Adapter registration is manual:** add `Hive.registerAdapter(ChatEngineAdapter())` in `lib/main.dart` `_initializeHive()` (enum section) and a guarded registration in `test/persistence/support/hive_test_harness.dart`. Never **hand-edit** the generated `lib/hive_registrar.g.dart` — it is checked into version control, regenerates via build_runner to include `ChatEngineAdapter()`, and that regenerated version is committed as-is.
- **Default is `webView`:** existing installs see zero behavioral change. Every read uses `defaultValue: ChatEngine.webView` (missing key falls back at read time, same as `ChatType`).
- **All engine visibility/reads go through `nativeChatAvailableFor(ChatType)`** in `lib/models/enums/chat_engine.dart`.
- **No `DashboardStore` changes. No new dependencies. EventSub lifecycle untouched** (stays connected while logged in regardless of engine).
- **Style:** match the codebase — `this.` prefix on instance members, design tokens (`AppSpacing`, `AppRadius`, `AppMotion`), `Pressable` for tappables, relative imports where neighboring files use them.
- **Toolchain:** Flutter/Dart binaries at `~/.dotfiles/flutter/sdk/bin/` (workstation clone). Codegen: `~/.dotfiles/flutter/sdk/bin/dart run build_runner build --delete-conflicting-outputs`.
- **Quality gates:** full `flutter test` green; `flutter analyze` = 0 errors and only the 6 pre-existing warnings (`input.dart` ×2, `translucent_sliver_app_bar.dart` ×2, `statistics.dart` ×2).
- **Commit per task** with `git add <specific files>` (never `-A`). **Do NOT push** — push happens at wrap-up/handoff.
- **Hive-in-widget-test rules** (proven patterns in `test/chat/twitch_chat_integration_test.dart`):
  - Hive writes in test setup go through `await tester.runAsync(() async { ... })` — the test body's FakeAsync zone never completes real I/O.
  - After a tap-driven Hive write (e.g. tapping the engine switch), assert the in-memory value immediately (Hive applies puts to its in-memory keystore synchronously) and finish the UI assertions, then **close Hive from inside the test's FakeAsync zone** using the dance copied from the 'connect button starts the login' integration test: `var closed = false; unawaited(harness.close().then((_) => closed = true));` then loop `await tester.pump();` + `await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));` up to 10× until `closed`, `await tester.pump(); expect(closed, isTrue);`. When the test involved a store/login flow, unmount + `await tester.runAsync(() => store.dispose());` first. tearDown's `harness.close()` is then a no-op. Draining with runAsync/pump windows alone does NOT work: hive_ce write-queue Completers dispatch only through the zone they were created in, so a real-zone `harness.close()` hangs forever (verified empirically in Task 2 — even 8 drain rounds leave it stuck).
  - Tests that run the real login flow (token persist + auth-box watcher starts) must unmount the chat UI, dispose the store via `runAsync`, and close Hive from inside the zone (copy the dance from the existing 'connect button starts the login' test).
  - Never `pumpAndSettle` while a spinner is animating (device-code dialog, native view connecting state).

## File Map

| File | Change | Responsibility |
|---|---|---|
| `lib/models/enums/chat_engine.dart` | Create (T1) | `ChatEngine` enum (typeId 14) + `text` extension + `nativeChatAvailableFor` seam |
| `lib/models/type_ids.dart` | Modify (T1) | Append `ChatEngine = 14` |
| `lib/types/enums/settings_keys.dart` | Modify (T1) | `SelectedChatEngine` entry + `'selected-chat-engine'` map value |
| `lib/main.dart` | Modify (T1) | Import + manual adapter registration |
| `test/persistence/support/hive_test_harness.dart` | Modify (T1) | Guarded adapter registration for tests |
| `test/chat/chat_engine_test.dart` | Create (T1) | Enum/availability unit tests + persistence round-trip |
| `.../chat_username_bar.dart/chat_engine_switch.dart` | Create (T2) | `CupertinoSlidingSegmentedControl<ChatEngine>` toggle |
| `test/chat/chat_engine_switch_test.dart` | Create (T2) | Switch widget tests |
| `.../chat_username_bar.dart/twitch_account_control.dart` | Create (T3) | Native-mode account chip / connect pill / disconnect dialog |
| `.../chat_username_bar.dart/chat_username_bar.dart` | Modify (T4) | Two-column restructure around the engine switch |
| `.../chat_username_bar.dart/username_action_row.dart` | Modify (T4) | Back to pure WebView add/edit/delete (chip removed) |
| `.../stream_chat/stream_chat.dart` | Modify (T5) | Engine-aware slot branch + split empty states |
| `test/chat/twitch_chat_integration_test.dart` | Modify (T3–T5) | Control/bar/slot tests per engine |
| `docs/changelog-agent.md`, `docs/session-handoff.md`, `AGENTS.md` | Modify (T6) | Docs hygiene |

(`.../chat_username_bar.dart/` is literally a directory named `chat_username_bar.dart` under `lib/views/dashboard/widgets/obs_widgets/stream_chat/` — yes, really.)

---

### Task 1: ChatEngine enum + persistence plumbing

**Files:**
- Create: `lib/models/enums/chat_engine.dart`
- Modify: `lib/models/type_ids.dart` (append one line)
- Modify: `lib/types/enums/settings_keys.dart` (two spots)
- Modify: `lib/main.dart` (import + adapter registration)
- Modify: `test/persistence/support/hive_test_harness.dart` (import + guarded registration)
- Test: `test/chat/chat_engine_test.dart`

**Interfaces:**
- Consumes: existing patterns — `lib/models/enums/chat_type.dart` (`@HiveType` enum + `text` extension), `TypeIDs`, `SettingsKeys`, `HiveTestHarness`.
- Produces (later tasks rely on these exact names):
  - `enum ChatEngine { webView, native }` with `String get text` (`'WebView'` / `'Native'`)
  - `bool nativeChatAvailableFor(ChatType chatType)` (top-level, in `chat_engine.dart`)
  - `SettingsKeys.SelectedChatEngine` (`.name` == `'selected-chat-engine'`)
  - `TypeIDs.ChatEngine == 14`

- [ ] **Step 1: Write the failing test**

Create `test/chat/chat_engine_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  group('ChatEngine', () {
    test('has a label per engine', () {
      expect(ChatEngine.webView.text, 'WebView');
      expect(ChatEngine.native.text, 'Native');
    });

    test('native engine is available for Twitch only', () {
      expect(nativeChatAvailableFor(ChatType.Twitch), isTrue);
      expect(nativeChatAvailableFor(ChatType.YouTube), isFalse);
      expect(nativeChatAvailableFor(ChatType.Owncast), isFalse);
    });
  });

  group('SelectedChatEngine persistence', () {
    late Directory tempDir;
    late HiveTestHarness harness;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('chat_engine_test');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await Hive.openBox(HiveKeys.Settings.name);
    });

    tearDown(() async {
      await harness.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('missing key falls back to the WebView default at read time', () {
      expect(
        Hive.box(HiveKeys.Settings.name).get(
              SettingsKeys.SelectedChatEngine.name,
              defaultValue: ChatEngine.webView,
            ),
        ChatEngine.webView,
      );
    });

    test('round-trips through the Settings box and survives a cold open',
        () async {
      final settings = Hive.box(HiveKeys.Settings.name);
      await settings.put(
          SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
      expect(settings.get(SettingsKeys.SelectedChatEngine.name),
          ChatEngine.native);

      await harness.reopenFromDisk();

      expect(
        Hive.box(HiveKeys.Settings.name)
            .get(SettingsKeys.SelectedChatEngine.name),
        ChatEngine.native,
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/chat_engine_test.dart`
Expected: FAIL — compile error `Target of URI doesn't exist: 'package:obs_blade/models/enums/chat_engine.dart'`.

- [ ] **Step 3: Create the enum + plumbing**

Create `lib/models/enums/chat_engine.dart`:

```dart
import 'package:hive_ce/hive.dart';

import '../type_ids.dart';
import 'chat_type.dart';

part 'chat_engine.g.dart';

/// Which implementation renders the stream chat: the classic WebView embed
/// or a native client. A native engine exists only for Twitch today - see
/// [nativeChatAvailableFor].
@HiveType(typeId: TypeIDs.ChatEngine)
enum ChatEngine {
  @HiveField(0)
  webView,

  @HiveField(1)
  native,
}

extension ChatEngineFunctions on ChatEngine {
  String get text => const {
        ChatEngine.webView: 'WebView',
        ChatEngine.native: 'Native',
      }[this]!;
}

/// The single seam deciding whether a native chat engine exists for
/// [chatType]. The engine switch's visibility and every engine read go
/// through here, so the future entitlement gate (and the auto-switch on
/// login it brings) has exactly one call site to extend.
bool nativeChatAvailableFor(ChatType chatType) => chatType == ChatType.Twitch;
```

Modify `lib/models/type_ids.dart` — change:

```dart
  static const int TwitchAuth = 13;
}
```

to:

```dart
  static const int TwitchAuth = 13;
  static const int ChatEngine = 14;
}
```

Modify `lib/types/enums/settings_keys.dart` — change:

```dart
  /// [ChatType]: enum which can be peristed with Hive as well
  SelectedChatType,
```

to:

```dart
  /// [ChatType]: enum which can be peristed with Hive as well
  SelectedChatType,

  /// [ChatEngine]: enum which can be peristed with Hive as well
  SelectedChatEngine,
```

and change:

```dart
        SettingsKeys.SelectedChatType: 'selected-chat-type',
```

to:

```dart
        SettingsKeys.SelectedChatType: 'selected-chat-type',
        SettingsKeys.SelectedChatEngine: 'selected-chat-engine',
```

Modify `lib/main.dart` — after the existing line `import 'models/enums/chat_type.dart';` add:

```dart
import 'models/enums/chat_engine.dart';
```

and in `_initializeHive()`, change:

```dart
  /// Enums which can also be persisted as part of the models
  Hive.registerAdapter(ChatTypeAdapter());
```

to:

```dart
  /// Enums which can also be persisted as part of the models
  Hive.registerAdapter(ChatTypeAdapter());
  Hive.registerAdapter(ChatEngineAdapter());
```

Modify `test/persistence/support/hive_test_harness.dart` — before the existing line `import 'package:obs_blade/models/enums/chat_type.dart';` add:

```dart
import 'package:obs_blade/models/enums/chat_engine.dart';
```

and in `registerAllAdapters()`, change:

```dart
    if (!Hive.isAdapterRegistered(TypeIDs.ChatType)) {
      Hive.registerAdapter<ChatType>(ChatTypeAdapter());
    }
```

to:

```dart
    if (!Hive.isAdapterRegistered(TypeIDs.ChatType)) {
      Hive.registerAdapter<ChatType>(ChatTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.ChatEngine)) {
      Hive.registerAdapter<ChatEngine>(ChatEngineAdapter());
    }
```

- [ ] **Step 4: Generate the Hive adapter**

Run: `~/.dotfiles/flutter/sdk/bin/dart run build_runner build --delete-conflicting-outputs`
Expected: ends with `Succeeded after ...`; `lib/models/enums/chat_engine.g.dart` now exists and contains `class ChatEngineAdapter extends TypeAdapter<ChatEngine>`. `lib/hive_registrar.g.dart` also regenerates (adds the `chat_engine.dart` import + `registerAdapter(ChatEngineAdapter());` in both extensions) — expected, commit it as-is.

- [ ] **Step 5: Run the test to verify it passes**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/chat_engine_test.dart`
Expected: `+4: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/models/enums/chat_engine.dart lib/models/enums/chat_engine.g.dart lib/models/type_ids.dart lib/types/enums/settings_keys.dart lib/main.dart lib/hive_registrar.g.dart test/persistence/support/hive_test_harness.dart test/chat/chat_engine_test.dart
git commit -m "feat(chat): add ChatEngine enum + SelectedChatEngine setting (typeId 14)"
```

---

### Task 2: ChatEngineSwitch widget

**Files:**
- Create: `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_engine_switch.dart`
- Test: `test/chat/chat_engine_switch_test.dart`

**Interfaces:**
- Consumes: `ChatEngine`, `nativeChatAvailableFor`, `SettingsKeys.SelectedChatEngine` (Task 1); established segmented-control pattern (`lib/views/home/widgets/connect_box/switcher_card.dart` — full-width `CupertinoSlidingSegmentedControl`, no thumb/background overrides).
- Produces: `ChatEngineSwitch({required Box settingsBox, required ChatType chatType})` — renders `SizedBox.shrink()` when `!nativeChatAvailableFor(chatType)`; writes `SettingsKeys.SelectedChatEngine` on segment tap. Used by Task 4.

- [ ] **Step 1: Write the failing tests**

Create `test/chat/chat_engine_switch_test.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_engine_switch.dart';

import '../persistence/support/hive_test_harness.dart';

/// Fixed-width host: the switch sizes `double.infinity` inside the bar's
/// right column, so it needs a bounded width in isolation
Widget wrap(Widget child) => MaterialApp(
      theme: ThemeData(cupertinoOverrideTheme: const CupertinoThemeData()),
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(0.8)),
        child: Scaffold(
          body: Center(child: SizedBox(width: 280.0, child: child)),
        ),
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_engine_switch');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('renders nothing for platforms without a native engine',
      (tester) async {
    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.YouTube)));
    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsNothing);

    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Owncast)));
    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsNothing);
  });

  testWidgets('Twitch shows both segments', (tester) async {
    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Twitch)));

    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsOneWidget);
    expect(find.text('WebView'), findsOneWidget);
    expect(find.text('Native'), findsOneWidget);
  });

  testWidgets('tapping a segment persists the engine', (tester) async {
    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Twitch)));

    await tester.tap(find.text('Native'));
    await tester.pump();
    expect(settingsBox().get(SettingsKeys.SelectedChatEngine.name),
        ChatEngine.native);

    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Twitch)));
    await tester.tap(find.text('WebView'));
    await tester.pump();
    expect(settingsBox().get(SettingsKeys.SelectedChatEngine.name),
        ChatEngine.webView);

    /// The taps ran their Hive writes in the test's FakeAsync zone, and
    /// the Completers Hive created for its write queue only dispatch
    /// their listeners through the zone they were created in - a
    /// real-zone harness.close() in tearDown would await one of them
    /// forever (proven: even 8 pump/runAsync drain rounds leave it
    /// stuck). So close Hive from inside the zone instead: each pump
    /// drains the zone's queue, each runAsync is a real-time window for
    /// the next file op of the close (handles close sequentially - hence
    /// several rounds). tearDown's harness.close() is then a no-op.
    /// Same dance as the 'connect button starts the login' integration
    /// test.
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/chat_engine_switch_test.dart`
Expected: FAIL — compile error `Target of URI doesn't exist: '.../chat_engine_switch.dart'`.

- [ ] **Step 3: Implement the switch**

Create `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_engine_switch.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/enums/chat_engine.dart';
import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../types/enums/settings_keys.dart';

/// Manual WebView <-> Native engine toggle for the stream chat. Renders
/// nothing for platforms without a native engine
/// ([nativeChatAvailableFor]); writes [SettingsKeys.SelectedChatEngine]
/// straight to the Settings box - the surrounding HiveBuilder in
/// `chat_username_bar.dart` rebuilds on the change.
class ChatEngineSwitch extends StatelessWidget {
  final Box settingsBox;
  final ChatType chatType;

  const ChatEngineSwitch({
    super.key,
    required this.settingsBox,
    required this.chatType,
  });

  @override
  Widget build(BuildContext context) {
    if (!nativeChatAvailableFor(this.chatType)) {
      return const SizedBox.shrink();
    }

    final ChatEngine engine = this.settingsBox.get(
          SettingsKeys.SelectedChatEngine.name,
          defaultValue: ChatEngine.webView,
        );

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<ChatEngine>(
        groupValue: engine,
        children: const {
          ChatEngine.webView: Text('WebView'),
          ChatEngine.native: Text('Native'),
        },
        onValueChanged: (selected) {
          if (selected != null) {
            this
                .settingsBox
                .put(SettingsKeys.SelectedChatEngine.name, selected);
          }
        },
      ),
    );
  }
}
```

(The labels intentionally mirror `ChatEngine.text` — Task 1's unit test pins those strings, so drift between the two fails fast.)

- [ ] **Step 4: Run the tests to verify they pass**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/chat_engine_switch_test.dart`
Expected: `+3: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_engine_switch.dart test/chat/chat_engine_switch_test.dart
git commit -m "feat(chat): add ChatEngineSwitch segmented control"
```

---

### Task 3: TwitchAccountControl (native-mode account chip / connect pill)

**Files:**
- Create: `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/twitch_account_control.dart`
- Test: `test/chat/twitch_chat_integration_test.dart` (append two tests, add imports)

**Interfaces:**
- Consumes: `TwitchChatStore` (`isLoggedIn`, `user?.displayName ?? user?.login`, `logout()`), `startTwitchLogin(BuildContext)` from `../twitch_device_code_dialog.dart`, `ConfirmationDialog` (`package:obs_blade/shared/dialogs/confirmation.dart`, pops itself on OK), `ModalHandler.showBaseDialog`, `Pressable`/`AppSpacing`/`AppRadius` from design, `ChatTypeBrand.brandColor` from `../chat_type_brand.dart`, `StylingHelper.lightenDarkenColor`.
- Produces: `const TwitchAccountControl()` — Observer rendering the connected-account chip (tap → disconnect confirmation) when logged in, or a "Connect Twitch" pill (tap → `startTwitchLogin`) when logged out. Used by Task 4's bar; the pill's visual style is shared with the native connect empty state (Task 5).

**Intentional copy change (flag for review):** the disconnect dialog body loses the sentence "The classic WebView chat will be used instead." — in native mode logging out lands on the native connect prompt, not the WebView. New body: `'Connected as <name>. You will be logged out of your Twitch account.'`

- [ ] **Step 1: Add the failing tests**

In `test/chat/twitch_chat_integration_test.dart`, add this import after the existing `chat_username_bar.dart` import:

```dart
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/twitch_account_control.dart';
```

Append these two tests inside `main()`, after the existing 'username bar shows the connected account and offers disconnect' test:

```dart
  testWidgets(
      'native account control offers connect while logged out and starts login on tap',
      (tester) async {
    await tester.pumpWidget(wrap(const TwitchAccountControl()));
    await tester.pumpAndSettle();

    expect(find.text('Connect Twitch'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsNothing);

    await tester.tap(find.text('Connect Twitch'));
    await tester.pump();
    expect(find.byType(TwitchDeviceCodeDialog), findsOneWidget);

    /// Same teardown dance as the slot login test above: the tap-driven
    /// login chain persists the token (Hive write in this FakeAsync zone)
    /// and starts the store's auth-box watcher — unmount, dispose and
    /// close Hive from inside the zone or harness.close() hangs.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.dispose());
    await tester.pump();

    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  });

  testWidgets(
      'native account control shows the connected account and disconnects on confirm',
      (tester) async {
    store.authState = TwitchAuthState.loggedIn;
    store.user = FakeTwitchAuthService.user;

    await tester.pumpWidget(wrap(const TwitchAccountControl()));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsOneWidget);
    expect(find.text('Kounex'), findsOneWidget);

    await tester.tap(find.text('Kounex'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Twitch?'), findsOneWidget);

    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Twitch?'), findsNothing);

    /// logout() awaits the chat disconnect, the TwitchAuth box delete and
    /// the (faked) revoke — real I/O window, then the zone resumes the
    /// continuations
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(store.authState, TwitchAuthState.loggedOut);

    /// The tap-driven box delete ran in the test's FakeAsync zone and
    /// Hive's write-queue Completers only dispatch through the zone they
    /// were created in - a real-zone harness.close() in tearDown would
    /// hang. Same close-inside-the-zone dance as the login test above.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.dispose());
    await tester.pump();

    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_chat_integration_test.dart`
Expected: FAIL — compile error `Target of URI doesn't exist: '.../twitch_account_control.dart'`.

- [ ] **Step 3: Implement the control**

Create `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/twitch_account_control.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../chat_type_brand.dart';
import '../twitch_device_code_dialog.dart';

/// Native-mode Twitch account control for the username bar: the connected
/// account chip (tap -> disconnect confirmation) while logged in, or a
/// "Connect Twitch" pill while logged out. Only visible while the native
/// engine is selected - the WebView engine shows the classic username
/// actions instead.
class TwitchAccountControl extends StatelessWidget {
  const TwitchAccountControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<TwitchChatStore>();
        final displayName = store.user?.displayName ?? store.user?.login;

        return Align(
          alignment: Alignment.centerRight,
          child: store.isLoggedIn
              ? _AccountChip(displayName: displayName)
              : const _ConnectPill(),
        );
      },
    );
  }
}

/// The connected account, styled like the bar's other control containers
/// and reading as tappable (checkmark + display name). Tapping opens the
/// disconnect confirmation.
class _AccountChip extends StatelessWidget {
  final String? displayName;

  const _AccountChip({this.displayName});

  @override
  Widget build(BuildContext context) {
    final enabledColor =
        Theme.of(context).cupertinoOverrideTheme!.primaryColor;

    return Tooltip(
      message:
          'Connected as ${this.displayName ?? 'Twitch'} — tap to disconnect',
      child: Pressable(
        haptic: true,
        onTap: () => ModalHandler.showBaseDialog(
          context: context,
          dialogWidget: ConfirmationDialog(
            title: 'Disconnect Twitch?',
            body:
                'Connected as ${this.displayName ?? 'your Twitch account'}. You will be logged out of your Twitch account.',
            okText: 'Disconnect',
            isYesDestructive: true,
            onOk: (_) => GetIt.instance<TwitchChatStore>().logout(),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color:
                StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              width: 0.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 18.0,
                color: enabledColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96.0),
                child: Text(
                  this.displayName ?? 'Twitch',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: enabledColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same visual style as the "Connect Twitch" pill in the native connect
/// empty state (`stream_chat.dart`)
class _ConnectPill extends StatelessWidget {
  const _ConnectPill();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: true,
      onTap: () => startTwitchLogin(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: ChatType.Twitch.brandColor ??
              Theme.of(context).colorScheme.secondary,
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          'Connect Twitch',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_chat_integration_test.dart`
Expected: all tests pass (`+8: All tests passed!`).

Note: the pre-existing bar tests ('username bar shows the Twitch account action…', 'username bar shows the connected account…') still pass at this point because `username_action_row.dart` is untouched so far — Task 4 rewrites them.

- [ ] **Step 5: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/twitch_account_control.dart test/chat/twitch_chat_integration_test.dart
git commit -m "feat(chat): add TwitchAccountControl for the native engine mode"
```

---

### Task 4: Username bar restructure + UsernameActionRow cleanup

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart` (full rewrite)
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/username_action_row.dart` (remove chip/Observer + `_UsernameAction.label`)
- Test: `test/chat/twitch_chat_integration_test.dart` (rewrite two bar tests, add one; add imports)

**Interfaces:**
- Consumes: `ChatEngineSwitch` (T2), `TwitchAccountControl` (T3), `ChatEngine`/`nativeChatAvailableFor`/`SettingsKeys.SelectedChatEngine` (T1), existing `ChatTypeDropdown`, `UsernameDropdown`, `UsernameActionRow`.
- Produces: bar contract used by Task 5's tests —
  - `nativeMode == nativeChatAvailableFor(chatType) && engine == ChatEngine.native`
  - Left column: `ChatTypeDropdown` always; `UsernameDropdown` only when `!nativeMode`.
  - Right column: `ChatEngineSwitch` only when `nativeChatAvailableFor(chatType)`; below it `TwitchAccountControl` (nativeMode) or `UsernameActionRow` (WebView mode).
  - `UsernameActionRow` keeps its public signature `UsernameActionRow({required this.settingsBox})` — pure add/edit/delete, no Twitch branch.

- [ ] **Step 1: Rewrite/extend the bar tests (failing)**

In `test/chat/twitch_chat_integration_test.dart`, add these imports (after the ones added in Task 3):

```dart
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/username_action_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/username_dropdown.dart';
```

**Replace** the test `'username bar shows the Twitch account action only for Twitch'` (the one asserting `CupertinoIcons.link`) with:

```dart
  testWidgets(
      'username bar shows the engine switch and connect pill only for Twitch in native mode',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });

    await tester.pumpWidget(wrap(const ChatUsernameBar()));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsOneWidget);
    expect(find.text('Connect Twitch'), findsOneWidget);

    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.YouTube);
    });
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsNothing);
    expect(find.text('Connect Twitch'), findsNothing);
  });
```

**Replace** the test `'username bar shows the connected account and offers disconnect'` with:

```dart
  testWidgets(
      'username bar shows the connected account in native mode and offers disconnect',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });
    store.authState = TwitchAuthState.loggedIn;
    store.user = FakeTwitchAuthService.user;

    await tester.pumpWidget(wrap(const ChatUsernameBar()));
    await tester.pumpAndSettle();

    /// Account chip instead of a bare status icon — reads as tappable
    expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsOneWidget);
    expect(find.text('Kounex'), findsOneWidget);

    await tester.tap(find.text('Kounex'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Twitch?'), findsOneWidget);
  });
```

**Add** this test after them:

```dart
  testWidgets('switching engines swaps the bar controls and persists the key',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.TwitchUsernames.name, <String>['someuser']);
      await settingsBox()
          .put(SettingsKeys.SelectedTwitchUsername.name, 'someuser');
    });

    await tester.pumpWidget(wrap(const ChatUsernameBar()));
    await tester.pumpAndSettle();

    /// WebView engine by default: username controls, no account control,
    /// and no persisted key yet
    expect(find.byType(UsernameDropdown), findsOneWidget);
    expect(find.byType(UsernameActionRow), findsOneWidget);
    expect(find.byType(TwitchAccountControl), findsNothing);
    expect(settingsBox().get(SettingsKeys.SelectedChatEngine.name), isNull);

    await tester.tap(find.text('Native'));
    await tester.pump();

    /// Hive applies puts to its in-memory keystore synchronously; the box
    /// watch event reaches the HiveBuilder through the zone's microtasks,
    /// so pumps alone drive the rebuild (no real I/O window needed)
    expect(settingsBox().get(SettingsKeys.SelectedChatEngine.name),
        ChatEngine.native);

    await tester.pumpAndSettle();

    expect(find.byType(UsernameDropdown), findsNothing);
    expect(find.byType(UsernameActionRow), findsNothing);
    expect(find.byType(TwitchAccountControl), findsOneWidget);

    /// Close Hive from inside the test's FakeAsync zone (zone-bound write
    /// Completers hang a real-zone close) - same dance as the login test,
    /// minus the store dispose: no login flow ran here
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_chat_integration_test.dart`
Expected: FAIL — the rewritten bar tests fail (no `CupertinoSlidingSegmentedControl` in the current bar; `UsernameActionRow` still contains the chip, so the 'only for Twitch' expectations break).

- [ ] **Step 3: Rewrite the bar**

Replace the entire content of `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart` with:

```dart
import 'package:flutter/material.dart';

import '../../../../../../models/enums/chat_engine.dart';
import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import 'chat_engine_switch.dart';
import 'chat_type_dropdown.dart';
import 'twitch_account_control.dart';
import 'username_action_row.dart';
import 'username_dropdown.dart';

/// Chat control section. The platform dropdown is the single major
/// control; everything else hangs off the selected chat engine
/// ([SettingsKeys.SelectedChatEngine]):
///
/// WebView mode (default): username dropdown + add/edit/delete actions -
/// the classic behavior, unchanged.
///
/// Native mode (Twitch only, see [nativeChatAvailableFor]): the engine
/// switch plus the account control (login/logout, connected account) -
/// never the username controls.
class ChatUsernameBar extends StatelessWidget {
  const ChatUsernameBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.SelectedChatType,
        SettingsKeys.SelectedChatEngine,
        SettingsKeys.TwitchUsernames,
        SettingsKeys.SelectedTwitchUsername,
        SettingsKeys.YouTubeUsernames,
        SettingsKeys.SelectedYouTubeUsername,
        SettingsKeys.OwncastUsernames,
        SettingsKeys.SelectedOwncastUsername,
      ],
      builder: (context, settingsBox, child) {
        final ChatType chatType = settingsBox.get(
          SettingsKeys.SelectedChatType.name,
          defaultValue: ChatType.Twitch,
        );
        final ChatEngine engine = settingsBox.get(
          SettingsKeys.SelectedChatEngine.name,
          defaultValue: ChatEngine.webView,
        );
        final bool nativeMode =
            nativeChatAvailableFor(chatType) && engine == ChatEngine.native;

        return Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 256.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChatTypeDropdown(settingsBox: settingsBox),
                      if (!nativeMode) ...[
                        const SizedBox(height: AppSpacing.xs),
                        UsernameDropdown(
                          settingsBox: settingsBox,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (nativeChatAvailableFor(chatType)) ...[
                      ChatEngineSwitch(
                        settingsBox: settingsBox,
                        chatType: chatType,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    if (nativeMode)
                      const TwitchAccountControl()
                    else
                      UsernameActionRow(
                        settingsBox: settingsBox,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Clean up UsernameActionRow (remove the chip)**

Replace the entire content of `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/username_action_row.dart` with:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/dialogs/add_edit_owncast_username.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/dialogs/add_edit_youtube_username.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import 'delete_username_dialog.dart';
import 'dialogs/add_edit_twitch_username.dart';

/// WebView-mode username actions (add / edit / delete) for the selected
/// chat platform. The Twitch account chip used to live here - it moved to
/// `twitch_account_control.dart`, which owns the native engine mode.
class UsernameActionRow extends StatelessWidget {
  final Box settingsBox;

  const UsernameActionRow({super.key, required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    ChatType chatType = this.settingsBox.get(
          SettingsKeys.SelectedChatType.name,
          defaultValue: ChatType.Twitch,
        );
    String? selectedChatUsername = switch (chatType) {
      ChatType.Twitch =>
        this.settingsBox.get(SettingsKeys.SelectedTwitchUsername.name),
      ChatType.YouTube =>
        this.settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name),
      ChatType.Owncast =>
        this.settingsBox.get(SettingsKeys.SelectedOwncastUsername.name),
    };

    return Container(
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _UsernameAction(
            icon: CupertinoIcons.person_add,
            tooltip: 'Add',
            onPressed: () => ModalHandler.showBaseDialog(
              context: context,
              dialogWidget: switch (chatType) {
                ChatType.Twitch =>
                  AddEditTwitchUsernameDialog(settingsBox: this.settingsBox),
                ChatType.YouTube =>
                  AddEditYouTubeUsernameDialog(settingsBox: this.settingsBox),
                ChatType.Owncast =>
                  AddEditOwncastUsernameDialog(settingsBox: this.settingsBox),
              },
            ),
          ),
          const SizedBox(
            height: 20.0,
            child: VerticalDivider(width: 1.0, thickness: 0.0),
          ),
          _UsernameAction(
            icon: CupertinoIcons.pencil,
            tooltip: 'Edit',
            onPressed: selectedChatUsername != null
                ? () => ModalHandler.showBaseDialog(
                      context: context,
                      dialogWidget: switch (chatType) {
                        ChatType.Twitch => AddEditTwitchUsernameDialog(
                            settingsBox: this.settingsBox,
                            username: selectedChatUsername,
                          ),
                        ChatType.YouTube => AddEditYouTubeUsernameDialog(
                            settingsBox: this.settingsBox,
                            username: selectedChatUsername,
                          ),
                        ChatType.Owncast => AddEditOwncastUsernameDialog(
                            settingsBox: this.settingsBox,
                            username: selectedChatUsername,
                          ),
                      },
                    )
                : null,
          ),
          const SizedBox(
            height: 20.0,
            child: VerticalDivider(width: 1.0, thickness: 0.0),
          ),
          _UsernameAction(
            icon: CupertinoIcons.trash,
            tooltip: 'Delete',
            isDestructive: selectedChatUsername != null,
            onPressed: selectedChatUsername != null
                ? () => ModalHandler.showBaseDialog(
                      context: context,
                      dialogWidget: DeleteUsernameDialog(
                        settingsBox: settingsBox,
                        username: selectedChatUsername,
                      ),
                    )
                : null,
          ),
        ],
      ),
    );
  }
}

/// One segment of the username action control - icon button with [Pressable]
/// feedback; keeps the enabled / destructive color semantics of the old
/// text buttons.
class _UsernameAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDestructive;

  final void Function()? onPressed;

  const _UsernameAction({
    required this.icon,
    required this.tooltip,
    this.isDestructive = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabledColor = this.isDestructive
        ? CupertinoColors.destructiveRed
        : Theme.of(context).cupertinoOverrideTheme!.primaryColor;

    return Tooltip(
      message: this.tooltip,
      child: Pressable(
        onTap: this.onPressed,
        haptic: this.onPressed != null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Icon(
            this.icon,
            size: 18.0,
            color: this.onPressed != null
                ? enabledColor
                : Theme.of(context).disabledColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_chat_integration_test.dart`
Expected: all tests pass (`+9: All tests passed!`).

Also run the switch tests to catch regressions:
Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/chat_engine_switch_test.dart`
Expected: `+3: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/username_action_row.dart test/chat/twitch_chat_integration_test.dart
git commit -m "feat(chat): restructure username bar around the engine switch"
```

---

### Task 5: Engine-aware chat slot + split empty states

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart`
- Test: `test/chat/twitch_chat_integration_test.dart` (update three slot tests, add two)

**Interfaces:**
- Consumes: `ChatEngine`/`nativeChatAvailableFor`/`SettingsKeys.SelectedChatEngine` (T1); bar contract (T4) is unaffected.
- Produces: slot rendering rules —
  - `nativeEngine == nativeChatAvailableFor(chatType) && settingsBox.get(SelectedChatEngine, defaultValue: webView) == ChatEngine.native`
  - `nativeEngine && isLoggedIn` → `NativeTwitchChatView`
  - `nativeEngine && !isLoggedIn` → `_ChatEmptyState(chatType: ChatType.Twitch, nativeConnectPrompt: true)`
  - `!nativeEngine` → legacy WebView stack regardless of login state; its empty state is the username prompt only (no connect pill)
  - `_syncWebController` only runs when `!nativeEngine` (no WebView warm-up while native owns the slot)
  - `_ChatEmptyState` gains `final bool nativeConnectPrompt` (default `false`)

- [ ] **Step 1: Update/add the slot tests (failing)**

In `test/chat/twitch_chat_integration_test.dart`:

**Update** the test `'slot shows the native view for Twitch when logged in'` — its `runAsync` block becomes:

```dart
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });
```

(the rest of the test stays as-is — login still lands on the native view, now explicitly via the native engine.)

**Replace** the test `'slot keeps the empty state + connect button when logged out'` with:

```dart
  testWidgets(
      'slot shows the native connect prompt when logged out in native mode',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    expect(find.byType(NativeTwitchChatView), findsNothing);
    expect(
      find.text('Connect your Twitch account to see your chat natively.'),
      findsOneWidget,
    );

    /// Two "Connect Twitch" affordances by design in this tree: the
    /// username bar's account-control pill (Task 4) and the slot prompt's
    /// pill - both call startTwitchLogin
    expect(find.text('Connect Twitch'), findsNWidgets(2));
  });
```

**Update** the test `'connect button starts the login and the dialog auto-closes'` — its `runAsync` block becomes:

```dart
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });
```

and its tap line becomes:

```dart
    /// `.last` = the slot prompt's pill (the username bar's account-control
    /// pill comes first in tree order; both invoke the same
    /// startTwitchLogin, so the tested flow is identical)
    await tester.tap(find.text('Connect Twitch').last);
```

(With the engine set to native, the pill moves to the native connect prompt — and the Task 4 bar renders its own "Connect Twitch" pill in this tree, hence the disambiguation. The rest of the test — login, auto-close, teardown dance — is unchanged.)

**Add** these two tests after them:

```dart
  testWidgets(
      'slot keeps the legacy WebView path when logged in but the engine is WebView',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
    });
    store.authState = TwitchAuthState.loggedIn;
    store.chatConnection = TwitchChatConnectionState.live;

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    /// Being logged in no longer takes over the slot by itself — the
    /// WebView engine keeps the legacy path (here: its empty state, since
    /// no username is selected and a real WebView can't mount in tests)
    expect(find.byType(NativeTwitchChatView), findsNothing);
    expect(
      find.text('No Twitch username selected, so no one\'s chat can be displayed.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'native engine with a selected username still shows the connect prompt when logged out',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
      await settingsBox()
          .put(SettingsKeys.TwitchUsernames.name, <String>['someuser']);
      await settingsBox()
          .put(SettingsKeys.SelectedTwitchUsername.name, 'someuser');
    });

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    /// The native branch wins before the legacy stack - no WebView gets
    /// built for the selected username while logged out
    expect(find.byType(NativeTwitchChatView), findsNothing);
    expect(
      find.text('Connect your Twitch account to see your chat natively.'),
      findsOneWidget,
    );
    expect(
      find.text('No Twitch username selected, so no one\'s chat can be displayed.'),
      findsNothing,
    );
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_chat_integration_test.dart`
Expected: FAIL — the two new tests fail (logged-in currently takes over the slot; the connect prompt copy doesn't exist), and the replaced connect-prompt test fails (current copy is the username prompt + pill without `nativeConnectPrompt`). The connect-button test may already pass at RED (the legacy empty-state pill it taps still exists pre-change) — it guards the login flow, not the new behavior.

- [ ] **Step 3: Implement the engine-aware slot**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart`:

**3a.** Add the import after `import '../../../../../models/enums/chat_type.dart';`:

```dart
import '../../../../../models/enums/chat_engine.dart';
```

**3b.** Add the engine key to the `HiveBuilder` rebuildKeys — change:

```dart
            rebuildKeys: const [
              SettingsKeys.SelectedChatType,
              SettingsKeys.SelectedTwitchUsername,
```

to:

```dart
            rebuildKeys: const [
              SettingsKeys.SelectedChatType,
              SettingsKeys.SelectedChatEngine,
              SettingsKeys.SelectedTwitchUsername,
```

**3c.** Replace the slot branch — change:

```dart
              final chatActive = anyChatActive(chatType, settingsBox);
              if (chatActive) {
                _syncWebController(_urlForChatType(chatType, settingsBox));
              }

              /// Native Twitch chat takes over the slot once logged in;
              /// logged-out Twitch / YouTube / Owncast keep the WebView path
              if (chatType == ChatType.Twitch) {
                return Observer(
                  builder: (_) {
                    if (GetIt.instance<TwitchChatStore>().isLoggedIn) {
                      return const NativeTwitchChatView();
                    }
                    return this._buildLegacyChatStack(
                      context,
                      settingsBox,
                      chatType,
                      chatActive,
                      dashboardStore,
                    );
                  },
                );
              }

              return this._buildLegacyChatStack(
                  context, settingsBox, chatType, chatActive, dashboardStore);
```

to:

```dart
              final chatActive = anyChatActive(chatType, settingsBox);

              /// A native engine exists only where
              /// [nativeChatAvailableFor] says so (Twitch today)
              final nativeEngine = nativeChatAvailableFor(chatType) &&
                  settingsBox.get(
                        SettingsKeys.SelectedChatEngine.name,
                        defaultValue: ChatEngine.webView,
                      ) ==
                      ChatEngine.native;

              /// No WebView warm-up while the native engine owns the slot
              if (chatActive && !nativeEngine) {
                _syncWebController(_urlForChatType(chatType, settingsBox));
              }

              /// Native Twitch chat takes over the slot when the native
              /// engine is selected and the user is logged in; logged out
              /// it shows the connect prompt instead. The WebView engine
              /// keeps the legacy path regardless of the login state.
              if (nativeEngine) {
                return Observer(
                  builder: (_) {
                    if (GetIt.instance<TwitchChatStore>().isLoggedIn) {
                      return const NativeTwitchChatView();
                    }
                    return StaggeredEntrance(
                      child: _ChatEmptyState(
                        chatType: chatType,
                        nativeConnectPrompt: true,
                      ),
                    );
                  },
                );
              }

              return this._buildLegacyChatStack(
                  context, settingsBox, chatType, chatActive, dashboardStore);
```

**3d.** Split the empty state — replace the whole `_ChatEmptyState` class:

```dart
/// Shown while no username is selected for the active platform - or, with
/// [nativeConnectPrompt], while the native Twitch engine is selected but
/// no account is connected (then the "Connect Twitch" pill lives here -
/// it belongs to native mode exclusively)
class _ChatEmptyState extends StatelessWidget {
  final ChatType chatType;
  final bool nativeConnectPrompt;

  const _ChatEmptyState({
    required this.chatType,
    this.nativeConnectPrompt = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color brandColor = this.chatType.brandColor ??
        Theme.of(context).colorScheme.secondary;

    /// Top-aligned (instead of centered in the fixed-height chat viewport)
    /// so the state sits inside the actually visible area of the dashboard
    /// scroll view
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.xl,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChatBrandIcon(chatType: this.chatType, color: brandColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${this.chatType.text} Chat',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              this.nativeConnectPrompt
                  ? 'Connect your Twitch account to see your chat natively.'
                  : 'No ${this.chatType.text} username selected, so no one\'s chat can be displayed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (this.nativeConnectPrompt) ...[
              const SizedBox(height: AppSpacing.lg),
              Pressable(
                haptic: true,
                onTap: () => startTwitchLogin(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: brandColor,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    'Connect Twitch',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

Notes for the implementer:
- The old `Observer` around the pill is gone on purpose: the connect prompt is only built by the native branch, which already sits inside an `Observer` — a completed login flips `isLoggedIn` and swaps the whole branch to `NativeTwitchChatView`.
- The WebView empty state loses the "Connect Twitch" pill entirely (it was the WebView/native mixing point); the legacy stack's `StaggeredEntrance(child: _ChatEmptyState(chatType: chatType))` call site is unchanged.
- All existing imports in `stream_chat.dart` stay needed (`Observer`, `GetIt`, `startTwitchLogin`, `Pressable`, `StaggeredEntrance` all remain in use).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_chat_integration_test.dart`
Expected: all tests pass (`+11: All tests passed!`).

- [ ] **Step 5: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart test/chat/twitch_chat_integration_test.dart
git commit -m "feat(chat): engine-aware chat slot + split empty states"
```

---

### Task 6: Full verification + docs

**Files:**
- Modify: `docs/changelog-agent.md` (new entry)
- Modify: `docs/session-handoff.md` (current-state update)
- Modify: `AGENTS.md` (chat line refresh)

**Interfaces:**
- Consumes: everything from T1–T5.

- [ ] **Step 1: Full test suite**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test`
Expected: all tests pass — around `+108: All tests passed!` (96 pre-existing + 4 chat_engine + 3 switch + 2 account control + 1 bar swap + 2 slot; the exact total may shift if the suite changed since this plan was written — green is the gate, not the number).

- [ ] **Step 2: Analyze**

Run: `~/.dotfiles/flutter/sdk/bin/flutter analyze`
Expected: 0 errors; only the 6 pre-existing warnings (`input.dart` ×2, `translucent_sliver_app_bar.dart` ×2, `statistics.dart` ×2). Any new warning in touched files must be fixed before continuing.

- [ ] **Step 3: Changelog entry**

Read `docs/changelog-agent.md`, follow its existing entry format, and add a new entry dated 2026-08-04 with this content:

> **Chat engine switch (control-section redesign)** — spec `docs/superpowers/specs/2026-08-04-chat-engine-switch-design.md`, plan `docs/superpowers/plans/2026-08-04-chat-engine-switch.md`.
> - Persisted `ChatEngine` enum (`webView`/`native`, Hive typeId 14) + `SettingsKeys.SelectedChatEngine`; default WebView, so existing installs are unchanged.
> - `nativeChatAvailableFor(ChatType)` seam in `lib/models/enums/chat_engine.dart` — the future availability/entitlement gate for native chat plugs in there.
> - Username bar restructured: platform dropdown owns the left column (username dropdown only in WebView mode); right column = `ChatEngineSwitch` (Twitch only) + mode actions (`UsernameActionRow` for WebView — account chip removed; `TwitchAccountControl` for native — chip + disconnect dialog when logged in, "Connect Twitch" pill when logged out).
> - Slot: native view iff Twitch + native engine + logged in; native + logged out → connect empty state (pill relocated there); WebView engine → legacy stack regardless of login, empty state back to the username prompt only.
> - Disconnect dialog copy no longer claims the WebView takes over after logout.

- [ ] **Step 4: Handoff doc**

Read `docs/session-handoff.md` and update its current-state / next-steps so a fresh agent learns: the chat control section is now organized around the manual WebView↔Native engine switch (`SelectedChatEngine`, default WebView; seam `nativeChatAvailableFor`); native Twitch chat Phase 1 + engine switch are both on `master`; next chat items are the availability/entitlement gate for native chat (plugs into the seam, brings auto-switch-on-login), badges/role toggles, chat container UI (prelude to send input), 7TV/BTTV, and the open post-logout WebView-fallback-blank verification. Keep the doc's existing structure and length discipline — adjust only the affected sections.

- [ ] **Step 5: AGENTS.md refresh**

In `AGENTS.md`, change the quick-map row:

```markdown
| Stream chat (WebView) | `lib/views/dashboard/widgets/obs_widgets/stream_chat/` |
```

to:

```markdown
| Stream chat (WebView + native Twitch) | `lib/views/dashboard/widgets/obs_widgets/stream_chat/` |
```

and change the Chat paragraph:

```markdown
**Chat:** WebView embeds today; Phase 0 hardened (parse + lifecycle). Next is
native Twitch (needs Dev Console credentials) — see chat audit + handoff.
```

to:

```markdown
**Chat:** Twitch has a native engine (device-code login + EventSub chat,
read-only) next to the WebView embeds; a manual WebView↔Native switch lives in
the chat bar (`SelectedChatEngine`, default WebView; availability seam:
`nativeChatAvailableFor` in `lib/models/enums/chat_engine.dart`). Next:
availability gate, badges — see chat audit + handoff.
```

(If the paragraph drifted since this plan was written, apply the same content update to whatever the current Chat paragraph says.)

- [ ] **Step 6: Commit**

```bash
git add docs/changelog-agent.md docs/session-handoff.md AGENTS.md
git commit -m "docs: chat engine switch changelog, handoff + AGENTS.md refresh"
```

---

## Post-plan notes (not implementation steps)

- **Do not push** during execution — push happens at wrap-up (`git push origin master`), together with the spec commit and the plan commit.
- Manual dogfood checklist for the user after execution (simulator): switch visible only on Twitch; engine persists across restart; native + logged out → connect prompt + pill in both bar and slot; disconnect → native connect prompt; WebView mode unchanged incl. add/edit/delete usernames; YouTube/Owncast bars unchanged.
- Known open item (unchanged by this work, still on the verification list): post-logout WebView-fallback-blank check (`_syncWebController` early-return).
