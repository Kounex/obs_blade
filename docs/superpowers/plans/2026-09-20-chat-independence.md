# Chat Independence (Dedicated Chat Tab) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make stream chat usable with or without an OBS session by giving it a dedicated Chat tab, without touching the dashboard chat pane.

**Architecture:** Add `Tabs.Chat` (Home · Chat · Statistics · Settings) with a `ChatView` root that reuses the existing `StreamChat` widget verbatim, minus two new constructor seams: `scrollArbitration` (skip the dashboard-only WebView pointer hack + its `DashboardStore` lookup) and `proRoute` (host-provided paywall route for the Pro upsell). Spec: `docs/superpowers/specs/2026-09-20-chat-independence-design.md`.

**Tech Stack:** Flutter, MobX, GetIt, Hive CE. No new dependencies.

## Global Constraints

- Branch `4.0-liquid-glass`. Commit per verified unit; `git add` only the files named in each commit step — the working tree has dirty `android/` IDE files that must never be staged.
- `flutter analyze` must end at exactly the **472-issue baseline** (no new issues).
- `dart format` (tall style) on every changed/new Dart file.
- Never run `flutter test` concurrently with analyze or other Flutter processes.
- No agent-side simulator verification — the user dogfoods.
- Test gotcha (real): Hive writes inside a `testWidgets` fake-async zone hang the suite at shutdown. Do box writes via `await tester.runAsync(() => box.put(...))` (the `revokePro` pattern in `test/chat/chat_engine_switch_test.dart`), never bare `await box.put(...)` inside the test body.
- `DashboardStore` stays a monolith; chat stores (`TwitchChatStore`/`YouTubeChatStore`) are not touched.
- Task order differs from the spec's commit list (seams before scaffold) because `ChatView` only compiles once the seams exist.

---

### Task 1: `StreamChat` standalone seams

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart` (constructor ~:80-94, `build` :237-238, `_buildLegacyChatStack` :503-565, `_ChatProUpsell` :680-766)
- Test: `test/chat/stream_chat_seams_test.dart` (create)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `StreamChat({bool scrollArbitration = true, String? proRoute})`. `scrollArbitration: false` ⇒ no `DashboardStore` lookup, WebView rendered without the pointer `Listener`. `proRoute` null ⇒ upsell pushes `HomeTabRoutingKeys.Pro.route` (today's behavior).

- [ ] **Step 1: Write the failing tests**

Create `test/chat/stream_chat_seams_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData(
    cupertinoOverrideTheme: const CupertinoThemeData(),
    extensions: const [AppStatusColors.standard, AppTextColors.standard],
  ),
  home: Scaffold(body: child),
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late ProStore proStore;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('stream_chat_seams');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await settingsBox().put(SettingsKeys.BoughtPro.name, true);
    await settingsBox().put(SettingsKeys.ProColdStartRestoreDone.name, true);

    proStore = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();
    GetIt.instance.registerSingleton<ProStore>(proStore);
  });

  tearDown(() async {
    proStore.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'standalone mode renders chat without any OBS stores registered',
    (tester) async {
      await tester.pumpWidget(wrap(const StreamChat(scrollArbitration: false)));
      await tester.pump();

      /// Empty state = no username selected: the whole surface rendered
      /// with no DashboardStore/NetworkStore in GetIt
      expect(find.text('Twitch Chat'), findsOneWidget);
      expect(
        find.textContaining('No Twitch username selected'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'default mode still consults DashboardStore (dashboard behavior '
    'unchanged)',
    (tester) async {
      await tester.pumpWidget(wrap(const StreamChat()));
      await tester.pump();

      /// DashboardStore is not registered in this harness, so the
      /// default (dashboard) path must still look it up and fail here
      final exception = tester.takeException();
      expect(exception, isNotNull);
      expect(exception.toString(), contains('DashboardStore'));
    },
  );

  testWidgets('upsell pill pushes the host-provided pro route', (
    tester,
  ) async {
    await tester.runAsync(
      () => settingsBox().put(SettingsKeys.BoughtPro.name, false),
    );
    await tester.runAsync(
      () => settingsBox().put(
        SettingsKeys.SelectedChatEngine.name,
        ChatEngine.native,
      ),
    );

    String? pushed;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(),
          extensions: const [AppStatusColors.standard, AppTextColors.standard],
        ),
        home: const Scaffold(
          body: StreamChat(scrollArbitration: false, proRoute: '/test/pro'),
        ),
        onGenerateRoute: (settings) {
          pushed = settings.name;
          return CupertinoPageRoute(
            builder: (_) => const Scaffold(body: Text('PRO STUB')),
          );
        },
      ),
    );
    await tester.pump();

    expect(find.text('Explore Pro'), findsOneWidget);
    await tester.tap(find.text('Explore Pro'));
    await tester.pump();

    expect(pushed, '/test/pro');
    expect(find.text('PRO STUB'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail/characterize**

Run: `flutter test test/chat/stream_chat_seams_test.dart`
Expected: compile error — `StreamChat` has no `scrollArbitration`/`proRoute` parameters yet. (Test 2 is a characterization guard: it is green before and after, pinning that the default path is unchanged.)

- [ ] **Step 3: Add the seams to `StreamChat`**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart`:

(a) Constructor — replace the field block and constructor:

```dart
class StreamChat extends StatefulWidget {
  final bool usernameRowPadding;
  final bool usernameRowExpandable;
  final bool usernameRowBeneath;

  /// WebView scroll arbitration with the surrounding dashboard scroll view
  /// (the pointer band + `DashboardStore.setPointerOnChat` in
  /// [_buildLegacyChatStack]). Standalone hosts without a parent scroll
  /// view (the Chat tab) pass false: the WebView then owns its touches
  /// directly and no [DashboardStore] is looked up.
  final bool scrollArbitration;

  /// Route the locked-Pro upsell pill pushes. Null = the Home tab's
  /// paywall route (the dashboard context); other tab hosts pass their own
  /// paywall route so the push resolves on their navigator.
  final String? proRoute;

  const StreamChat({
    super.key,
    this.usernameRowPadding = false,
    this.usernameRowExpandable = false,
    this.usernameRowBeneath = false,
    this.scrollArbitration = true,
    this.proRoute,
  });
```

(b) `build` — make the store lookup conditional (line ~238):

```dart
    DashboardStore? dashboardStore = this.widget.scrollArbitration
        ? GetIt.instance<DashboardStore>()
        : null;
```

(c) `_buildLegacyChatStack` — change the last parameter to `DashboardStore? dashboardStore` and replace the `Listener(...)` child inside the `if (chatActive && _webController != null)` spread with a conditional:

```dart
        if (chatActive && _webController != null) ...[
          if (this.widget.scrollArbitration)

            /// Scroll arbitration with the dashboard scroll view (see
            /// [scrollArbitration]) - the WebView can consume the scroll
            /// only inside the pointer band
            Listener(
              onPointerDown: (onPointerDown) => dashboardStore!
                  .setPointerOnChat(
                    onPointerDown.localPosition.dy > 150.0 &&
                        onPointerDown.localPosition.dy < 450.0,
                  ),
              onPointerUp: (_) => dashboardStore!.setPointerOnChat(false),
              onPointerCancel: (_) => dashboardStore!.setPointerOnChat(false),
              child: WebViewWidget(
                key: Key(
                  chatType.toString() +
                      settingsBox
                          .get(SettingsKeys.SelectedTwitchUsername.name)
                          .toString() +
                      settingsBox
                          .get(SettingsKeys.SelectedYouTubeUsername.name)
                          .toString() +
                      settingsBox
                          .get(SettingsKeys.SelectedOwncastUsername.name)
                          .toString(),
                ),
                controller: _webController!,
              ),
            )
          else

            /// Standalone host (no parent scroll view): the WebView owns
            /// its touches directly
            WebViewWidget(
              key: Key(
                chatType.toString() +
                    settingsBox
                        .get(SettingsKeys.SelectedTwitchUsername.name)
                        .toString() +
                    settingsBox
                        .get(SettingsKeys.SelectedYouTubeUsername.name)
                        .toString() +
                    settingsBox
                        .get(SettingsKeys.SelectedOwncastUsername.name)
                        .toString(),
              ),
              controller: _webController!,
            ),

          /// ... AnimatedOpacity loading surface stays exactly as it is ...
```

(d) Upsell route — at the `_ChatProUpsell` call site (in `build`):

```dart
                      child: _ChatProUpsell(
                        chatType: chatType,
                        proRoute: this.widget.proRoute ??
                            HomeTabRoutingKeys.Pro.route,
                      ),
```

and in `_ChatProUpsell` add the field, update the constructor and the tap:

```dart
class _ChatProUpsell extends StatelessWidget {
  final ChatType chatType;

  /// Paywall route on the host tab's navigator
  final String proRoute;

  const _ChatProUpsell({required this.chatType, required this.proRoute});
```

```dart
            Pressable(
              haptic: true,
              onTap: () => Navigator.of(context).pushNamed(this.proRoute),
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/chat/stream_chat_seams_test.dart`
Expected: 3 tests PASS.

- [ ] **Step 5: Format, analyze spot-check, commit**

```bash
dart format lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart test/chat/stream_chat_seams_test.dart
flutter analyze 2>&1 | tail -3   # must stay at the 472 baseline
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart test/chat/stream_chat_seams_test.dart
git commit -m "feat(chat): StreamChat standalone seams - scrollArbitration + proRoute"
```

---

### Task 2: Chat tab scaffold + `ChatView`

**Files:**
- Modify: `lib/utils/routing_helper.dart` (`Tabs` enum :43, `TabsFunctions` maps :50-66, new `ChatTabRoutingKeys` after :78, `chatTabRoutes` in `RoutingHelper`, new import)
- Create: `lib/views/chat/chat_view.dart`
- Test: `test/chat/chat_tab_view_test.dart` (create)

**Interfaces:**
- Consumes: `StreamChat({scrollArbitration, proRoute})` from Task 1.
- Produces: `Tabs.Chat`; `ChatTabRoutingKeys { Landing('/tabs/chat'), Pro('/tabs/chat/pro') }`; `RoutingHelper.chatTabRoutes`; `ChatView` (tab root). `lib/tab_base.dart` iterates `Tabs.values` — no changes needed there.

- [ ] **Step 1: Write the failing tests**

Create `test/chat/chat_tab_view_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:obs_blade/views/chat/chat_view.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData(
    cupertinoOverrideTheme: const CupertinoThemeData(),
    extensions: const [AppStatusColors.standard, AppTextColors.standard],
  ),
  home: child,
);

void main() {
  test('chat tab routing is wired (enum, name, icon, routes)', () {
    expect(Tabs.Chat.name, 'Chat');
    expect(Tabs.Chat.icon, CupertinoIcons.chat_bubble_2_fill);
    expect(Tabs.Chat.routes, same(RoutingHelper.chatTabRoutes));
    expect(ChatTabRoutingKeys.Landing.route, '/tabs/chat');
    expect(ChatTabRoutingKeys.Pro.route, '/tabs/chat/pro');
    expect(
      RoutingHelper.chatTabRoutes.keys,
      containsAll(['/tabs/chat', '/tabs/chat/pro']),
    );
  });

  group('ChatView', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late ProStore proStore;

    Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('chat_tab_view');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await Hive.openBox(HiveKeys.Settings.name);
      await settingsBox().put(SettingsKeys.BoughtPro.name, true);
      await settingsBox().put(SettingsKeys.ProColdStartRestoreDone.name, true);

      proStore = ProStore(
        service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
      )..init();
      GetIt.instance.registerSingleton<ProStore>(proStore);
    });

    tearDown(() async {
      proStore.dispose();
      await GetIt.instance.reset();
      await harness.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('renders chat standalone (no OBS stores registered)', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const ChatView()));
      await tester.pump();

      /// Nav bar title + the no-config empty state: chat is usable before
      /// any OBS session exists
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Twitch Chat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('upsell resolves on the chat tab navigator', (tester) async {
      await tester.runAsync(
        () => settingsBox().put(SettingsKeys.BoughtPro.name, false),
      );
      await tester.runAsync(
        () => settingsBox().put(
          SettingsKeys.SelectedChatEngine.name,
          ChatEngine.native,
        ),
      );

      String? pushed;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            cupertinoOverrideTheme: const CupertinoThemeData(),
            extensions: const [
              AppStatusColors.standard,
              AppTextColors.standard,
            ],
          ),
          initialRoute: ChatTabRoutingKeys.Landing.route,
          onGenerateRoute: (settings) {
            if (settings.name == ChatTabRoutingKeys.Landing.route) {
              return CupertinoPageRoute(
                builder: (_) => const ChatView(),
                settings: settings,
              );
            }
            pushed = settings.name;
            return CupertinoPageRoute(
              builder: (_) => const Scaffold(body: Text('PRO STUB')),
              settings: settings,
            );
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Explore Pro'));
      await tester.pump();

      expect(pushed, ChatTabRoutingKeys.Pro.route);
      expect(find.text('PRO STUB'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/chat/chat_tab_view_test.dart`
Expected: compile error — `Tabs.Chat`, `ChatTabRoutingKeys`, `chatTabRoutes`, `ChatView` do not exist.

- [ ] **Step 3: Implement the tab scaffold + `ChatView`**

(a) `lib/utils/routing_helper.dart` — add the import at the top:

```dart
import '../views/chat/chat_view.dart';
```

(b) Same file — `Tabs` enum:

```dart
enum Tabs { Home, Chat, Statistics, Settings }
```

(c) Same file — `TabsFunctions` extension maps:

```dart
  String get name => const {
    Tabs.Home: 'Home',
    Tabs.Chat: 'Chat',
    Tabs.Statistics: 'Statistics',
    Tabs.Settings: 'Settings',
  }[this]!;

  IconData get icon => const {
    Tabs.Home: CupertinoIcons.house_alt,
    Tabs.Chat: CupertinoIcons.chat_bubble_2_fill,
    Tabs.Statistics: CupertinoIcons.chart_bar_alt_fill,
    Tabs.Settings: CupertinoIcons.settings,
  }[this]!;

  Map<String, Widget Function(BuildContext)> get routes => {
    Tabs.Home: RoutingHelper.homeTabRoutes,
    Tabs.Chat: RoutingHelper.chatTabRoutes,
    Tabs.Statistics: RoutingHelper.statisticsTabRoutes,
    Tabs.Settings: RoutingHelper.settingsTabRoutes,
  }[this]!;
```

(d) Same file — new routing keys after `HomeTabRoutingKeys`:

```dart
/// Routing keys for the chat tab
enum ChatTabRoutingKeys implements RoutingKeys {
  Landing,
  Pro;

  @override
  String get route =>
      '${AppRoutingKeys.Tabs.route}/chat${{ChatTabRoutingKeys.Landing: '', ChatTabRoutingKeys.Pro: '/pro'}[this]!}';
}
```

(e) Same file — in `RoutingHelper`, next to `homeTabRoutes`:

```dart
  static Map<String, Widget Function(BuildContext)> chatTabRoutes = {
    ChatTabRoutingKeys.Landing.route: (_) => const ChatView(),
    ChatTabRoutingKeys.Pro.route: (_) => const ProPaywallView(),
  };
```

(f) Create `lib/views/chat/chat_view.dart`:

```dart
import 'package:flutter/material.dart';

import '../../shared/general/base/constrained_box.dart';
import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../utils/routing_helper.dart';
import '../dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';

/// Chat tab root: the standalone home for stream chat - usable with or
/// without an OBS session (chat state lives in the global settings box and
/// the GetIt chat stores; the stores connect on login restore / channel
/// select regardless of any surface). The dashboard chat pane is untouched
/// and remains the live co-display surface.
class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        title: 'Chat',
        customBody: Padding(
          padding: EdgeInsets.only(
            /// The tab scaffold extends bodies behind the translucent tab
            /// bar (extendBody) - same bottom clearance CustomSliverList
            /// gives the sliver-based tab views, so the chat input rests
            /// above the bar
            bottom:
                2 * kBottomNavigationBarHeight +
                MediaQuery.paddingOf(context).bottom / 2,
          ),
          child: Center(
            child: BaseConstrainedBox(
              child: StreamChat(
                usernameRowPadding: true,
                scrollArbitration: false,
                proRoute: ChatTabRoutingKeys.Pro.route,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Note: `lib/tab_base.dart` builds tabs from `Tabs.values` — the new tab's navigator, hero controller and scroll controller are automatic. No edit there.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/chat/chat_tab_view_test.dart test/chat/stream_chat_seams_test.dart`
Expected: all tests PASS (3 + 3).

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/utils/routing_helper.dart lib/views/chat/chat_view.dart test/chat/chat_tab_view_test.dart
flutter analyze 2>&1 | tail -3   # must stay at the 472 baseline
git add lib/utils/routing_helper.dart lib/views/chat/chat_view.dart test/chat/chat_tab_view_test.dart
git commit -m "feat(chat): dedicated Chat tab - standalone chat surface reachable without an OBS session"
```

---

### Task 3: Full gates + docs

**Files:**
- Modify: `docs/changelog-agent.md` (new dated entry at the top of the log section)
- Modify: `docs/session-handoff.md` (astra paragraph: chat-independence status)

**Interfaces:**
- Consumes: Tasks 1–2 landed.
- Produces: release notes trail + current-state handoff.

- [ ] **Step 1: Full chat suite**

Run: `flutter test test/chat/`
Expected: the whole directory green (new + pre-existing tests; the two new files included).

- [ ] **Step 2: Analyze gate**

Run: `flutter analyze`
Expected: exactly the 472-issue baseline, no new issues.

- [ ] **Step 3: Changelog entry**

Add a dated entry to `docs/changelog-agent.md` (match the existing entry style), covering: dedicated Chat tab (Home · Chat · Statistics · Settings) making chat usable without an OBS session; `StreamChat` `scrollArbitration`/`proRoute` seams; dashboard pane untouched; tests + gates. Mention the ratified follow-ups: conversation-owned drafts wave, optional live-session strip (astra focus-swap translation).

- [ ] **Step 4: Handoff update**

In `docs/session-handoff.md`, update the astra paragraph: replace the "Chat independence still needs the user to run the astra labs …" line with the landed state (tab shipped on `4.0-liquid-glass`; pending user dogfood: pre-connect chat reachability, Dashboard↔Chat tab switching state preservation, tablet 640 column) and keep the follow-up pointers (drafts wave, session-strip option).

- [ ] **Step 5: Commit + push**

```bash
git add docs/changelog-agent.md docs/session-handoff.md
git commit -m "docs: chat-independence tab - changelog + handoff"
git push origin 4.0-liquid-glass
```

---

## Self-Review Notes

- **Spec coverage:** tab scaffold (Task 2 a–e), `ChatView` incl. clearance + `BaseConstrainedBox` (Task 2 f), both seams (Task 3 of Task 1), all four spec tests (Task 1 file: independence/guard/upsell seam; Task 2 file: routing wired, ChatView render, chat-navigator upsell), gates + docs (Task 3). Non-goals untouched: no store changes, no dashboard pane change, no drafts, no strip.
- **Type consistency:** `scrollArbitration` (bool, default true) and `proRoute` (`String?`) are spelled identically in the seams, the view, and every test. `ChatTabRoutingKeys` routes: `/tabs/chat`, `/tabs/chat/pro` — asserted in tests.
- **Known test-limit:** no test pumps the active WebView path (webview_flutter has no test platform) — the arbitration seam is pinned at the build level (no `DashboardStore` lookup in standalone mode) rather than at the `Listener` level. Dogfood covers the touch behavior.
