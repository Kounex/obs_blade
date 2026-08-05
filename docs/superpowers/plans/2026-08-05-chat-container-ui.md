# Native Chat Window Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the native chat engine a real window — inset pane, always-tappable connection status row, and a connection sheet (account/uptime, diagnostics, actions) — wired into the dashboard chat slot.

**Architecture:** A generic `NativeChatWindow` wrapper widget (plain params, no Twitch types) renders the pane chrome; `stream_chat.dart` maps `TwitchChatStore` state onto it and wraps both native states (message view, connect prompt). The only store change is a `chatConnectedAt` timestamp feeding the sheet's uptime line.

**Tech Stack:** Flutter, MobX (`TwitchChatStore`), GetIt, Hive CE (untouched), flutter_test. Spec: `docs/superpowers/specs/2026-08-05-chat-container-ui-design.md`.

## Global Constraints

- Flutter commands run as `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw <args>` (wrapper is not directly executable).
- No new dependencies. No `DashboardStore` changes. No Hive schema changes.
- Style: `this.` prefix for members; design tokens `AppSpacing`/`AppRadius`/`AppMotion`; `Pressable` (not `GestureDetector`/`InkWell`); touch targets ≥ `kMinInteractiveDimensionCupertino`; doc comments matching neighboring files.
- Status colors come from `Theme.of(context).extension<AppStatusColors>() ?? AppStatusColors.standard` — the `?? standard` fallback is required because widget tests run a plain `MaterialApp` without the extension registered.
- Visual idiom for pane/rows (match the chat bar controls exactly): `StylingHelper.lightenDarkenColor(Theme.of(context).cardColor)` fill, `BorderRadius.circular(AppRadius.md)`, `Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4), width: 0.0)`.
- Analyze gate: 0 errors and exactly the 6 pre-existing warnings (`input.dart` ×2, `translucent_sliver_app_bar.dart` ×2, `statistics.dart` ×2). Test gate: full suite green (baseline 133).
- Never stage/commit `android/.settings/org.eclipse.buildship.core.prefs` (unrelated dirty file — leave it alone).
- Public-repo hygiene: no credentials, absolute paths, device IDs, or LAN addresses in tracked files.

---

### Task 1: `chatConnectedAt` in `TwitchChatStore`

**Files:**
- Modify: `lib/stores/views/twitch_chat.dart` (observable at ~line 100; `_onEventSubState` ~331-348; `_onEventSubRevoked` ~350-362; `connectChat` catches ~265-282; `_disconnectChat` ~383-390)
- Regenerate: `lib/stores/views/twitch_chat.g.dart` (build_runner)
- Test: `test/chat/twitch_chat_store_test.dart` (append a new group)

**Interfaces:**
- Consumes: existing `TwitchEventSubState` (`package:obs_blade/utils/twitch/twitch_eventsub_service.dart`) with values `connected | connecting | reconnecting | disconnected`; test seams `eventSubFactory` (captures the store's real callbacks) and `FakeTwitchAuthService` (`test/chat/support/fake_twitch_services.dart`).
- Produces: `@observable DateTime? TwitchChatStore.chatConnectedAt` — set when the session goes `live`, `null` when disconnected/failed. Task 3 reads it.

- [ ] **Step 1: Write the failing tests**

Append to `test/chat/twitch_chat_store_test.dart`, inside `main()` after the existing groups, plus add the import at the top of the file:

```dart
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';
```

```dart
  group('chatConnectedAt', () {
    late void Function(TwitchEventSubState) emitState;
    late void Function(String) emitRevoked;

    /// A fresh store whose factory captures the callbacks the store hands
    /// to its EventSub service, so the test can drive state/revocation.
    Future<void> loginWithCapturedCallbacks() async {
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory: (onChatMessage, onStateChanged, onRevoked) {
          emitState = onStateChanged;
          emitRevoked = onRevoked;
          return eventSubService;
        },
        badgeStoreResolver: () => badgeStore,
      );
      await store.startLogin();
    }

    test('stamped on live, kept on repeated live, re-stamped after reconnect',
        () async {
      await loginWithCapturedCallbacks();
      expect(store.chatConnectedAt, isNull);

      emitState(TwitchEventSubState.connected);
      final first = store.chatConnectedAt;
      expect(first, isNotNull);

      emitState(TwitchEventSubState.connected);
      expect(store.chatConnectedAt, same(first));

      emitState(TwitchEventSubState.reconnecting);
      emitState(TwitchEventSubState.connected);
      expect(store.chatConnectedAt, isNot(same(first)));
    });

    test('cleared on disconnect', () async {
      await loginWithCapturedCallbacks();
      emitState(TwitchEventSubState.connected);
      expect(store.chatConnectedAt, isNotNull);

      emitState(TwitchEventSubState.disconnected);
      expect(store.chatConnectedAt, isNull);
    });

    test('cleared on subscription failure', () async {
      await loginWithCapturedCallbacks();
      emitState(TwitchEventSubState.connected);
      expect(store.chatConnectedAt, isNotNull);

      emitRevoked('subscription_failed:500');
      expect(store.chatConnection, TwitchChatConnectionState.failed);
      expect(store.chatConnectedAt, isNull);
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/twitch_chat_store_test.dart`
Expected: FAIL — `chatConnectedAt` getter does not exist (compile error).

- [ ] **Step 3: Add the observable + transitions**

In `lib/stores/views/twitch_chat.dart`:

(a) After the `chatError` observable (~line 100):

```dart
  @observable
  String? chatError;

  /// When the current chat session went live — drives the connection
  /// sheet's uptime line. In-memory only.
  @observable
  DateTime? chatConnectedAt;
```

(b) `_onEventSubState` — stamp on the transition into `live`, clear on `disconnected`:

```dart
  void _onEventSubState(TwitchEventSubState state) {
    runInAction(() {
      switch (state) {
        case TwitchEventSubState.connected:
          if (this.chatConnection != TwitchChatConnectionState.live) {
            this.chatConnectedAt = DateTime.now();
          }
          this.chatConnection = TwitchChatConnectionState.live;
          break;
        case TwitchEventSubState.connecting:
          this.chatConnection = TwitchChatConnectionState.connecting;
          break;
        case TwitchEventSubState.reconnecting:
          this.chatConnection = TwitchChatConnectionState.reconnecting;
          break;
        case TwitchEventSubState.disconnected:
          this.chatConnection = TwitchChatConnectionState.disconnected;
          this.chatConnectedAt = null;
          break;
      }
    });
  }
```

(c) `_onEventSubRevoked` — clear in the non-auth (failure) branch:

```dart
    } else {
      runInAction(() {
        this.chatConnection = TwitchChatConnectionState.failed;
        this.chatError = 'Twitch chat subscription failed ($reason)';
        this.chatConnectedAt = null;
      });
    }
```

(d) `connectChat` — clear in **both** failure branches (the non-definitive `TwitchAuthException` branch and the generic `catch`):

```dart
      } else {
        GeneralHelper.advLog('Twitch chat connect failed — $e');
        this.chatConnection = TwitchChatConnectionState.failed;
        this.chatError = 'Could not connect to Twitch chat';
        this.chatConnectedAt = null;
      }
    } catch (e) {
      GeneralHelper.advLog('Twitch chat connect failed — $e');
      this.chatConnection = TwitchChatConnectionState.failed;
      this.chatError = 'Could not connect to Twitch chat';
      this.chatConnectedAt = null;
    }
```

(e) `_disconnectChat` — clear alongside the state reset:

```dart
    runInAction(() {
      this.chatConnection = TwitchChatConnectionState.disconnected;
      this.chatConnectedAt = null;
    });
```

- [ ] **Step 4: Regenerate MobX code**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw pub run build_runner build --delete-conflicting-outputs`
Expected: finishes with `Succeeded` — `lib/stores/views/twitch_chat.g.dart` regenerated with `chatConnectedAt`.

- [ ] **Step 5: Run the task tests**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/twitch_chat_store_test.dart`
Expected: PASS — all tests incl. the 3 new ones.

- [ ] **Step 6: Analyze**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw analyze`
Expected: 0 errors; only the 6 known pre-existing warnings.

- [ ] **Step 7: Commit**

```bash
git add lib/stores/views/twitch_chat.dart lib/stores/views/twitch_chat.g.dart test/chat/twitch_chat_store_test.dart
git commit -m "feat(chat): chatConnectedAt session timestamp in TwitchChatStore"
```

---

### Task 2: `NativeChatWindow` widget + connection sheet

**Files:**
- Create: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart`
- Test: `test/chat/native_chat_window_test.dart` (new)

**Interfaces:**
- Consumes: nothing from Task 1 (independent). Uses `ChatType` (`lib/models/enums/chat_type.dart`: `.text`, `.icon`, `.brandColor`), `ModalHandler.showBaseBottomSheet` (`lib/utils/modal_handler.dart`), `BaseDivider` (`lib/shared/general/base/divider.dart`), tokens/`Pressable`/`AppStatusColors` via `package:obs_blade/shared/design/design.dart`.
- Produces (Task 3 relies on these exact names):
  - `enum NativeChatConnectionStatus { offline, connecting, live, reconnecting, failed }`
  - `String formatChatUptime(Duration uptime)` — `m:ss` under an hour, `h:mm:ss` beyond
  - `class NativeChatWindow extends StatelessWidget` with params: `chatType` (ChatType, required), `status` (NativeChatConnectionStatus, required), `child` (Widget, required), `statusDetail`/`accountLabel` (`String?`), `connectedAt` (`DateTime?`), `onRetry`/`onLogout`/`onConnect` (`VoidCallback?`)

- [ ] **Step 1: Write the failing widget tests**

Create `test/chat/native_chat_window_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

NativeChatWindow buildWindow({
  NativeChatConnectionStatus status = NativeChatConnectionStatus.live,
  String? statusDetail,
  String? accountLabel,
  DateTime? connectedAt,
  VoidCallback? onRetry,
  VoidCallback? onLogout,
  VoidCallback? onConnect,
}) =>
    NativeChatWindow(
      chatType: ChatType.Twitch,
      status: status,
      statusDetail: statusDetail,
      accountLabel: accountLabel,
      connectedAt: connectedAt,
      onRetry: onRetry,
      onLogout: onLogout,
      onConnect: onConnect,
      child: const Center(child: Text('chat content')),
    );

void main() {
  testWidgets('renders platform label, child and per-status labels',
      (tester) async {
    for (final (status, label) in [
      (NativeChatConnectionStatus.offline, 'offline'),
      (NativeChatConnectionStatus.connecting, 'connecting…'),
      (NativeChatConnectionStatus.live, 'connected'),
      (NativeChatConnectionStatus.reconnecting, 'reconnecting…'),
      (NativeChatConnectionStatus.failed, 'failed'),
    ]) {
      await tester.pumpWidget(wrap(buildWindow(status: status)));
      expect(find.text('Twitch'), findsOneWidget);
      expect(find.text(label), findsOneWidget);
      expect(find.text('chat content'), findsOneWidget);
    }
  });

  testWidgets('live: tapping the status row shows account and uptime',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        buildWindow(
          status: NativeChatConnectionStatus.live,
          accountLabel: 'Kounex',
          connectedAt: DateTime.now().subtract(const Duration(seconds: 90)),
        ),
      ),
    );

    await tester.tap(find.text('connected'));
    await tester.pumpAndSettle();

    expect(find.text('Twitch chat'), findsOneWidget);
    expect(find.text('Connected as Kounex'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'Connected for \d+:\d{2}')),
      findsOneWidget,
    );
  });

  testWidgets('failed: sheet shows the error and fires retry + logout',
      (tester) async {
    var retried = false;
    var loggedOut = false;
    await tester.pumpWidget(
      wrap(
        buildWindow(
          status: NativeChatConnectionStatus.failed,
          statusDetail: 'Could not connect to Twitch chat',
          onRetry: () => retried = true,
          onLogout: () => loggedOut = true,
        ),
      ),
    );

    await tester.tap(find.text('failed'));
    await tester.pumpAndSettle();
    expect(find.text('Could not connect to Twitch chat'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(retried, isTrue);

    await tester.tap(find.text('failed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(loggedOut, isTrue);
  });

  testWidgets('offline: sheet fires connect', (tester) async {
    var connected = false;
    await tester.pumpWidget(
      wrap(
        buildWindow(
          status: NativeChatConnectionStatus.offline,
          onConnect: () => connected = true,
        ),
      ),
    );

    await tester.tap(find.text('offline'));
    await tester.pumpAndSettle();

    expect(find.text('Connect Twitch'), findsOneWidget);
    await tester.tap(find.text('Connect Twitch'));
    await tester.pumpAndSettle();
    expect(connected, isTrue);
  });

  group('formatChatUptime', () {
    test('m:ss under an hour', () {
      expect(formatChatUptime(Duration.zero), '0:00');
      expect(formatChatUptime(const Duration(seconds: 5)), '0:05');
      expect(
        formatChatUptime(const Duration(minutes: 1, seconds: 5)),
        '1:05',
      );
      expect(
        formatChatUptime(const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
    });

    test('h:mm:ss beyond an hour', () {
      expect(formatChatUptime(const Duration(hours: 1)), '1:00:00');
      expect(
        formatChatUptime(
          const Duration(hours: 1, minutes: 2, seconds: 5),
        ),
        '1:02:05',
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/native_chat_window_test.dart`
Expected: FAIL — `native_chat_window.dart` does not exist (compile error).

- [ ] **Step 3: Implement the window**

Create `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/divider.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/styling_helper.dart';

/// Platform-agnostic connection state of a native chat engine, rendered by
/// [NativeChatWindow]'s status row. Each native engine maps its own store
/// state onto this (the Twitch mapping lives in `stream_chat.dart`).
enum NativeChatConnectionStatus {
  /// No account connected / engine not running
  offline,
  connecting,
  live,
  reconnecting,
  failed,
}

/// Compact uptime for the connection sheet: `m:ss` under an hour,
/// `h:mm:ss` beyond.
String formatChatUptime(Duration uptime) {
  final String minutes =
      uptime.inMinutes.remainder(60).toString().padLeft(2, '0');
  final String seconds =
      uptime.inSeconds.remainder(60).toString().padLeft(2, '0');
  return uptime.inHours > 0
      ? '${uptime.inHours}:$minutes:$seconds'
      : '${uptime.inMinutes}:$seconds';
}

/// Window chrome for the native chat engines: an inset pane (same visual
/// idiom as the chat bar's control containers) wrapping the engine's
/// content, with a slim status row on top. The row shows platform +
/// connection state and is always tappable — it opens a connection sheet
/// (account + uptime when healthy, diagnostics + actions when degraded,
/// connect action when offline).
///
/// Deliberately generic: everything Twitch-specific arrives as plain
/// params, so a future native engine (e.g. YouTube) reuses the window with
/// its own branding and state mapping.
class NativeChatWindow extends StatelessWidget {
  final ChatType chatType;
  final NativeChatConnectionStatus status;

  /// Engine's last error, shown in the sheet for degraded states
  final String? statusDetail;

  /// Connected account's display name, when logged in
  final String? accountLabel;

  /// When the current session went live — feeds the sheet's uptime line
  final DateTime? connectedAt;

  /// Sheet actions; a null callback hides the action
  final VoidCallback? onRetry;
  final VoidCallback? onLogout;
  final VoidCallback? onConnect;

  /// The engine's content (message view or connect prompt)
  final Widget child;

  const NativeChatWindow({
    super.key,
    required this.chatType,
    required this.status,
    required this.child,
    this.statusDetail,
    this.accountLabel,
    this.connectedAt,
    this.onRetry,
    this.onLogout,
    this.onConnect,
  });

  (String, Color) _statusMeta(BuildContext context) {
    final AppStatusColors statusColors =
        Theme.of(context).extension<AppStatusColors>() ??
            AppStatusColors.standard;
    final Color muted =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    return switch (this.status) {
      NativeChatConnectionStatus.live => ('connected', statusColors.live),
      NativeChatConnectionStatus.connecting =>
        ('connecting…', statusColors.warning),
      NativeChatConnectionStatus.reconnecting =>
        ('reconnecting…', statusColors.warning),
      NativeChatConnectionStatus.failed =>
        ('failed', statusColors.unreachable),
      NativeChatConnectionStatus.offline => ('offline', muted),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (String statusLabel, Color statusColor) = this._statusMeta(context);
    final Color brandColor = this.chatType.brandColor ??
        Theme.of(context).colorScheme.secondary;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: Column(
        children: [
          Pressable(
            haptic: true,
            onTap: () => ModalHandler.showBaseBottomSheet(
              context: context,
              barrierDismissible: true,
              builder: (context) => _NativeChatConnectionSheet(
                chatType: this.chatType,
                status: this.status,
                statusLabel: statusLabel,
                statusColor: statusColor,
                statusDetail: this.statusDetail,
                accountLabel: this.accountLabel,
                connectedAt: this.connectedAt,
                onRetry: this.onRetry,
                onLogout: this.onLogout,
                onConnect: this.onConnect,
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimensionCupertino,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(this.chatType.icon, size: 14.0, color: brandColor),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    this.chatType.text,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    statusLabel,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: statusColor),
                  ),
                ],
              ),
            ),
          ),
          const BaseDivider(),
          Expanded(child: this.child),
        ],
      ),
    );
  }
}

/// Connection sheet of [NativeChatWindow]: account + uptime when healthy,
/// diagnostics + retry/logout when degraded, connect action when offline.
/// Actions pop the sheet and delegate to the call site's callbacks
/// (confirmation dialogs etc. live there, not here).
class _NativeChatConnectionSheet extends StatelessWidget {
  final ChatType chatType;
  final NativeChatConnectionStatus status;
  final String statusLabel;
  final Color statusColor;
  final String? statusDetail;
  final String? accountLabel;
  final DateTime? connectedAt;
  final VoidCallback? onRetry;
  final VoidCallback? onLogout;
  final VoidCallback? onConnect;

  const _NativeChatConnectionSheet({
    required this.chatType,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    this.statusDetail,
    this.accountLabel,
    this.connectedAt,
    this.onRetry,
    this.onLogout,
    this.onConnect,
  });

  void _popThen(BuildContext context, VoidCallback? action) {
    Navigator.of(context).pop();
    action?.call();
  }

  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool destructive = false,
  }) {
    final Color color = destructive
        ? (Theme.of(context).extension<AppStatusColors>() ??
                AppStatusColors.standard)
            .unreachable
        : Theme.of(context).textTheme.bodyMedium?.color ??
            CupertinoColors.label;
    return Pressable(
      haptic: true,
      onTap: onTap == null ? null : () => this._popThen(context, onTap),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: kMinInteractiveDimensionCupertino,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
          children: [
            Icon(icon, size: 18.0, color: color),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool degraded =
        this.status == NativeChatConnectionStatus.connecting ||
            this.status == NativeChatConnectionStatus.reconnecting ||
            this.status == NativeChatConnectionStatus.failed;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${this.chatType.text} chat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: this.statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                this.statusLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: this.statusColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (this.status == NativeChatConnectionStatus.live) ...[
            Text(
              'Connected as ${this.accountLabel ?? this.chatType.text}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (this.connectedAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Connected for ${formatChatUptime(DateTime.now().difference(this.connectedAt!))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
          if (degraded) ...[
            if (this.statusDetail != null) ...[
              Text(
                this.statusDetail!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            this._actionRow(
              context,
              icon: CupertinoIcons.arrow_clockwise,
              label: 'Retry',
              onTap: this.onRetry,
            ),
            const SizedBox(height: AppSpacing.xs),
            this._actionRow(
              context,
              icon: CupertinoIcons.square_arrow_right,
              label: 'Log out',
              destructive: true,
              onTap: this.onLogout,
            ),
          ],
          if (this.status == NativeChatConnectionStatus.offline) ...[
            Text(
              'Not connected — connect your ${this.chatType.text} account to see chat natively.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            this._actionRow(
              context,
              icon: CupertinoIcons.link,
              label: 'Connect ${this.chatType.text}',
              onTap: this.onConnect,
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the task tests**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/native_chat_window_test.dart`
Expected: PASS — 4 widget tests + 2 unit tests.

- [ ] **Step 5: Analyze**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw analyze`
Expected: 0 errors; only the 6 known pre-existing warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart test/chat/native_chat_window_test.dart
git commit -m "feat(chat): native chat window — pane, status row, connection sheet"
```

---

### Task 3: Wire the window into `stream_chat.dart`

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart` (native branch ~lines 230-244; imports; new top-level mapping function)
- Test: `test/chat/chat_window_mapping_test.dart` (new)

**Interfaces:**
- Consumes: `NativeChatWindow` / `NativeChatConnectionStatus` (Task 2); `TwitchChatStore.chatConnectedAt` (Task 1); `ConfirmationDialog` (`lib/shared/dialogs/confirmation.dart`: `title`, `body`, `okText`, `isYesDestructive`, `onOk(void Function(bool))` — self-dismisses on OK); `startTwitchLogin(context)` (already imported via `twitch_device_code_dialog.dart`).
- Produces: top-level `NativeChatConnectionStatus twitchChatWindowStatus(TwitchChatConnectionState state, bool isLoggedIn)` in `stream_chat.dart`.

- [ ] **Step 1: Write the failing mapping tests**

Create `test/chat/chat_window_mapping_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';

void main() {
  test('twitchChatWindowStatus maps every connection state when logged in',
      () {
    expect(
      twitchChatWindowStatus(TwitchChatConnectionState.live, true),
      NativeChatConnectionStatus.live,
    );
    expect(
      twitchChatWindowStatus(TwitchChatConnectionState.connecting, true),
      NativeChatConnectionStatus.connecting,
    );
    expect(
      twitchChatWindowStatus(TwitchChatConnectionState.reconnecting, true),
      NativeChatConnectionStatus.reconnecting,
    );
    expect(
      twitchChatWindowStatus(TwitchChatConnectionState.failed, true),
      NativeChatConnectionStatus.failed,
    );
    expect(
      twitchChatWindowStatus(TwitchChatConnectionState.disconnected, true),
      NativeChatConnectionStatus.offline,
    );
  });

  test('logged out always maps to offline', () {
    for (final state in TwitchChatConnectionState.values) {
      expect(
        twitchChatWindowStatus(state, false),
        NativeChatConnectionStatus.offline,
      );
    }
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/chat_window_mapping_test.dart`
Expected: FAIL — `twitchChatWindowStatus` is not defined (compile error).

- [ ] **Step 3: Add the mapping + wrap the native branch**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart`:

(a) Add imports at the top (with the other shared imports):

```dart
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../utils/modal_handler.dart';
import 'native_chat_window.dart';
```

(b) Add the top-level mapping function (directly above `class StreamChat`):

```dart
/// Maps the Twitch store's connection state (+ login) onto the chat
/// window's platform-agnostic status.
NativeChatConnectionStatus twitchChatWindowStatus(
  TwitchChatConnectionState state,
  bool isLoggedIn,
) {
  if (!isLoggedIn) return NativeChatConnectionStatus.offline;
  return switch (state) {
    TwitchChatConnectionState.live => NativeChatConnectionStatus.live,
    TwitchChatConnectionState.connecting =>
      NativeChatConnectionStatus.connecting,
    TwitchChatConnectionState.reconnecting =>
      NativeChatConnectionStatus.reconnecting,
    TwitchChatConnectionState.failed => NativeChatConnectionStatus.failed,
    TwitchChatConnectionState.disconnected =>
      NativeChatConnectionStatus.offline,
  };
}
```

(c) Replace the native branch (`if (nativeEngine) { return Observer(...); }`, currently lines 230-244) with:

```dart
              /// Native Twitch chat takes over the slot when the native
              /// engine is selected, wrapped in the chat window (pane +
              /// status row + connection sheet). Logged out, the content is
              /// the connect prompt. The WebView engine keeps the legacy
              /// path regardless of the login state.
              if (nativeEngine) {
                return Observer(
                  builder: (_) {
                    final twitchStore = GetIt.instance<TwitchChatStore>();
                    final loggedIn = twitchStore.isLoggedIn;
                    final displayName = twitchStore.user?.displayName ??
                        twitchStore.user?.login;

                    return NativeChatWindow(
                      chatType: chatType,
                      status: twitchChatWindowStatus(
                        twitchStore.chatConnection,
                        loggedIn,
                      ),
                      statusDetail: twitchStore.chatError,
                      accountLabel: displayName,
                      connectedAt: twitchStore.chatConnectedAt,
                      onRetry: twitchStore.connectChat,
                      onConnect: () => startTwitchLogin(context),
                      onLogout: () => ModalHandler.showBaseDialog(
                        context: context,
                        dialogWidget: ConfirmationDialog(
                          title: 'Disconnect Twitch?',
                          body:
                              'Connected as ${displayName ?? 'your Twitch account'}. You will be logged out of your Twitch account.',
                          okText: 'Disconnect',
                          isYesDestructive: true,
                          onOk: (_) => twitchStore.logout(),
                        ),
                      ),
                      child: loggedIn
                          ? const NativeTwitchChatView()
                          : StaggeredEntrance(
                              child: _ChatEmptyState(
                                chatType: chatType,
                                nativeConnectPrompt: true,
                              ),
                            ),
                    );
                  },
                );
              }
```

Note: the `Observer` builder reads `isLoggedIn`, `chatConnection`, `chatError`, `user`, and `chatConnectedAt` — all observables, so the window rebuilds on every state change. The WebView/legacy branch stays byte-identical.

- [ ] **Step 4: Run the mapping tests + the full suite**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test`
Expected: PASS — full suite green (baseline 133 + ~12 new from this feature).

- [ ] **Step 5: Analyze**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw analyze`
Expected: 0 errors; only the 6 known pre-existing warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart test/chat/chat_window_mapping_test.dart
git commit -m "feat(chat): wrap native engine in the chat window"
```

---

### Task 4: Dogfood + handoff docs

**Files:**
- Modify: `docs/changelog-agent.md`, `docs/session-handoff.md`, `.superpowers/sdd/progress.md` (ledger — untracked)

**Interfaces:**
- Consumes: Tasks 1-3 merged on `master`.

- [ ] **Step 1: Manual dogfood pass**

Run the app on the maintainer workstation sim (`tool/obs_local/obs_test_env.sh start` → `flutter run -d <sim-id>` per `docs/local-obs-e2e.md`, OBS ws password from local OBS config) and verify, with the native Twitch engine selected:

- Mobile Chat+Stats tab: chat sits in the new pane; status row shows `Twitch` + `● connected`.
- Tap the status row while healthy: sheet shows account + `Connected for m:ss`.
- Airplane-mode / OBS-offline blip: row flips to `reconnecting…` (amber), recovers to `connected`; `chatConnectedAt` resets (uptime restarts).
- Failed state (e.g. revoke the token in Twitch settings, then retry): sheet shows error + Retry + Log out; Log out asks for confirmation and returns to the connect prompt inside the pane.
- Force Tablet Mode: window nests inside the `Chat` BaseCard without a duplicated "Chat" label.
- WebView engine: unchanged, no pane.

- [ ] **Step 2: Update docs**

- `docs/changelog-agent.md` — new entry: chat window (pane, status row, connection sheet, `chatConnectedAt`), tests added, dogfood result.
- `docs/session-handoff.md` — move the native-chat track state forward: container UI done; next = chat input phase (dock reserved) or availability gate, per priority.
- `.superpowers/sdd/progress.md` — ledger line per task (BASE→HEAD, review verdicts).

- [ ] **Step 3: Commit + report**

```bash
git add docs/changelog-agent.md docs/session-handoff.md
git commit -m "docs: chat window shipped — handoff + changelog"
```

Report dogfood findings to the user (this is their explicit dogfood step — wait for their pass/fail before calling the feature done).
