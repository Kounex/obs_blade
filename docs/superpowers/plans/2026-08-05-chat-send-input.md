# Chat Send Input Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the streamer send Twitch chat messages natively from the app — input dock in the chat window, Helix `Send Chat Message`, silent `user:write:chat` scope upgrade.

**Architecture:** The window (`NativeChatWindow`) gains an optional `input` slot filled by a generic `NativeChatInput` dock (plain params). `TwitchChatStore` gains a guarded `sendChatMessage` action backed by a new injectable `TwitchMessageService` (badge-service pattern). Sent messages render via the existing EventSub echo — no optimistic insert.

**Tech Stack:** Flutter, MobX, freezed (DTO), `http` (injectable client), flutter_test. Spec: `docs/superpowers/specs/2026-08-05-chat-send-input-design.md`.

## Global Constraints

- Flutter commands run as `bash flutterw <args>` (wrapper is not directly executable).
- No new dependencies. No `DashboardStore` changes. No Hive schema changes (`TwitchAuth.scopes` is already persisted).
- Style: `this.` prefix; tokens `AppSpacing`/`AppRadius`/`AppMotion`; `Pressable`; targets ≥ `kMinInteractiveDimensionCupertino`; doc comments matching neighbors.
- Status colors via `Theme.of(context).extension<AppStatusColors>() ?? AppStatusColors.standard` (fallback required for plain-MaterialApp widget tests).
- MobX/freezed changes require build_runner regeneration — never hand-edit `.g.dart`/`.freezed.dart` files. Command: `bash flutterw pub run build_runner build --delete-conflicting-outputs`.
- Analyze gate: 0 errors and exactly the 6 pre-existing warnings (`input.dart` ×2, `translucent_sliver_app_bar.dart` ×2, `statistics.dart` ×2). Test gate: full suite green (baseline 145).
- Never stage/commit `android/.settings/org.eclipse.buildship.core.prefs`.
- Public-repo hygiene: no credentials, absolute paths, device IDs, or LAN addresses in tracked files.

---

### Task 1: Scope upgrade + `TwitchSendResult` DTO + `TwitchMessageService`

**Files:**
- Modify: `lib/utils/twitch/twitch_auth_service.dart:14` (scope const)
- Modify: `test/chat/twitch_auth_service_test.dart:26` (scope assertion)
- Create: `lib/types/classes/twitch/twitch_send_result.dart` (+ generated)
- Create: `lib/utils/twitch/twitch_message_service.dart`
- Test: `test/chat/twitch_message_service_test.dart` (new)

**Interfaces:**
- Consumes: `kTwitchHelixBase` + `TwitchAuthService.helixHeaders` + `TwitchAuthException` (`lib/utils/twitch/twitch_auth_service.dart`) — `helixHeaders` carries NO `Content-Type`, the service must add it.
- Produces:
  - `kTwitchChatScopes = ['user:read:chat', 'user:write:chat']`
  - `TwitchSendResult { String messageId, bool isSent, String? dropReason }` (freezed, snake rename)
  - `Future<TwitchSendResult> TwitchMessageService.sendChatMessage({required String accessToken, required String userId, required String message})`

- [ ] **Step 1: Update the scope assertion (failing test)**

In `test/chat/twitch_auth_service_test.dart:26`, change:

```dart
        expect(request.bodyFields['scopes'], 'user:read:chat user:write:chat');
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash flutterw test test/chat/twitch_auth_service_test.dart`
Expected: FAIL — expected `'user:read:chat user:write:chat'` but got `'user:read:chat'`.

- [ ] **Step 3: Change the scope const + verify pass**

In `lib/utils/twitch/twitch_auth_service.dart:14`:

```dart
const List<String> kTwitchChatScopes = <String>[
  'user:read:chat',
  'user:write:chat',
];
```

Run: `bash flutterw test test/chat/twitch_auth_service_test.dart`
Expected: PASS. (The fake token responses at lines 79/109/180 keep `['user:read:chat']` — they model Twitch's answer payload for the auth-flow tests, not our request.)

- [ ] **Step 4: Write the failing service tests**

Create `test/chat/twitch_message_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_message_service.dart';

void main() {
  test('posts broadcaster/sender/message and parses a sent result', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://api.twitch.tv/helix/chat/messages',
      );
      expect(request.headers['Authorization'], 'Bearer token-1');
      expect(request.headers['Client-Id'], kTwitchClientId);
      expect(request.headers['Content-Type'], 'application/json');
      expect(json.decode(request.body), {
        'broadcaster_id': 'user-1',
        'sender_id': 'user-1',
        'message': 'hello chat',
      });
      return http.Response(
        json.encode({
          'data': [
            {'message_id': 'msg-1', 'is_sent': true, 'drop_reason': null},
          ],
        }),
        200,
      );
    });

    final result = await TwitchMessageService(client: client)
        .sendChatMessage(
      accessToken: 'token-1',
      userId: 'user-1',
      message: 'hello chat',
    );

    expect(result.isSent, isTrue);
    expect(result.messageId, 'msg-1');
    expect(result.dropReason, isNull);
  });

  test('parses a dropped result with its reason', () async {
    final client = MockClient(
      (request) async => http.Response(
        json.encode({
          'data': [
            {
              'message_id': '',
              'is_sent': false,
              'drop_reason': 'automod_blocked',
            },
          ],
        }),
        200,
      ),
    );

    final result = await TwitchMessageService(client: client)
        .sendChatMessage(
      accessToken: 'token-1',
      userId: 'user-1',
      message: 'spam',
    );

    expect(result.isSent, isFalse);
    expect(result.dropReason, 'automod_blocked');
  });

  test('throws TwitchAuthException with status on non-200', () {
    final client = MockClient((request) async => http.Response('nope', 401));

    expect(
      TwitchMessageService(client: client).sendChatMessage(
        accessToken: 'token-1',
        userId: 'user-1',
        message: 'hi',
      ),
      throwsA(
        isA<TwitchAuthException>()
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });
}
```

- [ ] **Step 5: Run to verify they fail**

Run: `bash flutterw test test/chat/twitch_message_service_test.dart`
Expected: FAIL — `twitch_message_service.dart` does not exist (compile error).

- [ ] **Step 6: Implement the DTO**

Create `lib/types/classes/twitch/twitch_send_result.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'twitch_send_result.freezed.dart';
part 'twitch_send_result.g.dart';

/// Result of Helix `chat/messages` — the endpoint can accept a message but
/// drop it (`isSent == false`, e.g. AutoMod), so both halves are surfaced.
@Freezed(fromJson: true, toJson: false)
abstract class TwitchSendResult with _$TwitchSendResult {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchSendResult({
    required String messageId,
    required bool isSent,
    String? dropReason,
  }) = _TwitchSendResult;

  factory TwitchSendResult.fromJson(Map<String, Object?> json) =>
      _$TwitchSendResultFromJson(json);
}
```

- [ ] **Step 7: Implement the service**

Create `lib/utils/twitch/twitch_message_service.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_send_result.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

/// Helix `chat/messages` endpoint — sends a chat message as the
/// authenticated user into their own channel. Requires a user access token
/// with the `user:write:chat` scope (see `kTwitchChatScopes`).
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class TwitchMessageService {
  final http.Client _client;

  TwitchMessageService({http.Client? client})
      : _client = client ?? http.Client();

  Future<TwitchSendResult> sendChatMessage({
    required String accessToken,
    required String userId,
    required String message,
  }) async {
    final response = await this._client.post(
      Uri.parse('$kTwitchHelixBase/chat/messages'),
      headers: {
        ...TwitchAuthService.helixHeaders(accessToken),
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'broadcaster_id': userId,
        'sender_id': userId,
        'message': message,
      }),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Sending Twitch chat message failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List || data.isEmpty) {
      throw const TwitchAuthException(
          'Sending Twitch chat message returned no data');
    }
    return TwitchSendResult.fromJson(data.first as Map<String, Object?>);
  }
}
```

- [ ] **Step 8: Regenerate freezed code**

Run: `bash flutterw pub run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded` — `twitch_send_result.freezed.dart` + `twitch_send_result.g.dart` generated.

- [ ] **Step 9: Run the task tests**

Run: `bash flutterw test test/chat/twitch_message_service_test.dart test/chat/twitch_auth_service_test.dart`
Expected: PASS — all tests in both files.

- [ ] **Step 10: Analyze + commit**

Run: `bash flutterw analyze`
Expected: 0 errors; only the 6 known pre-existing warnings.

```bash
git add lib/utils/twitch/twitch_auth_service.dart lib/utils/twitch/twitch_message_service.dart lib/types/classes/twitch/twitch_send_result.dart lib/types/classes/twitch/twitch_send_result.freezed.dart lib/types/classes/twitch/twitch_send_result.g.dart test/chat/twitch_auth_service_test.dart test/chat/twitch_message_service_test.dart
git commit -m "feat(chat): write scope + Helix send-message service"
```

---

### Task 2: `TwitchChatStore.sendChatMessage` + `canWriteChat`

**Files:**
- Modify: `lib/stores/views/twitch_chat.dart` (imports, constructor seam, getter, 2 observables, action, drop-reason helper)
- Regenerate: `lib/stores/views/twitch_chat.g.dart`
- Modify: `test/chat/support/fake_twitch_services.dart` (add `FakeTwitchMessageService`, scope-variable fake token)
- Test: `test/chat/twitch_chat_store_test.dart` (append group)

**Interfaces:**
- Consumes: `TwitchMessageService` + `TwitchSendResult` (Task 1).
- Produces:
  - `bool TwitchChatStore.get canWriteChat` — plain getter over persisted scopes (deliberately non-reactive: scopes change only at login/logout, which flip `user`/`authState` and rebuild observers)
  - `@observable bool sendingChat`, `@observable String? sendChatError`
  - `Future<bool> TwitchChatStore.sendChatMessage(String text)` — never throws

- [ ] **Step 1: Extend the fakes**

In `test/chat/support/fake_twitch_services.dart`:

(a) Add imports at the top:

```dart
import 'package:obs_blade/types/classes/twitch/twitch_send_result.dart';
import 'package:obs_blade/utils/twitch/twitch_message_service.dart';
```

(b) Make the fake token's scopes variable — in `FakeTwitchAuthService`, add the field and use it in `pollForToken` + `refreshToken`:

```dart
  /// Scopes the returned [TwitchToken] carries (default: read-only).
  List<String> tokenScopes = const ['user:read:chat'];
```

Change the `token` static const usage: replace both `return token;` bodies with:

```dart
    return TwitchToken(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expiresIn: token.expiresIn,
      scope: this.tokenScopes,
    );
```

(c) Append the message-service fake at the end of the file:

```dart
class FakeTwitchMessageService extends TwitchMessageService {
  TwitchSendResult result = const TwitchSendResult(
    messageId: 'msg-1',
    isSent: true,
  );

  /// When set, [sendChatMessage] throws this error.
  Object? sendThrows;

  /// When set, [sendChatMessage] parks on this completer — lets a test
  /// resolve the send at a chosen moment (in-flight tests).
  Completer<TwitchSendResult>? sendGate;

  int calls = 0;
  String? lastMessage;

  @override
  Future<TwitchSendResult> sendChatMessage({
    required String accessToken,
    required String userId,
    required String message,
  }) async {
    this.calls++;
    this.lastMessage = message;
    if (this.sendThrows != null) throw this.sendThrows!;
    if (this.sendGate != null) return this.sendGate!.future;
    return this.result;
  }
}
```

- [ ] **Step 2: Write the failing store tests**

Append to `test/chat/twitch_chat_store_test.dart`, inside `main()`:

```dart
  group('sendChatMessage', () {
    late FakeTwitchMessageService messageService;

    Future<void> login({List<String>? scopes}) async {
      authService.tokenScopes =
          scopes ?? const ['user:read:chat', 'user:write:chat'];
      messageService = FakeTwitchMessageService();
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory: (_, __, ___) => eventSubService,
        badgeStoreResolver: () => badgeStore,
        messageService: messageService,
      );
      await store.startLogin();
    }

    test('canWriteChat reflects the persisted scopes', () async {
      await login(scopes: const ['user:read:chat']);
      expect(store.canWriteChat, isFalse);

      await login();
      expect(store.canWriteChat, isTrue);
    });

    test('sends trimmed text, returns true, clears state', () async {
      await login();

      expect(await store.sendChatMessage('  hello chat  '), isTrue);
      expect(messageService.lastMessage, 'hello chat');
      expect(store.sendingChat, isFalse);
      expect(store.sendChatError, isNull);
    });

    test('returns false without write scope and never calls the service',
        () async {
      await login(scopes: const ['user:read:chat']);

      expect(await store.sendChatMessage('hi'), isFalse);
      expect(messageService.calls, 0);
    });

    test('returns false for empty text and never calls the service',
        () async {
      await login();

      expect(await store.sendChatMessage('   '), isFalse);
      expect(messageService.calls, 0);
    });

    test('returns false while a send is in flight', () async {
      await login();
      messageService.sendGate = Completer<TwitchSendResult>();

      final first = store.sendChatMessage('one');
      expect(await store.sendChatMessage('two'), isFalse);
      expect(messageService.calls, 1);

      messageService.sendGate!.complete(
        const TwitchSendResult(messageId: 'msg-1', isSent: true),
      );
      expect(await first, isTrue);
      expect(store.sendingChat, isFalse);
    });

    test('dropped message maps the reason and returns false', () async {
      await login();
      messageService.result = const TwitchSendResult(
        messageId: '',
        isSent: false,
        dropReason: 'automod_blocked',
      );

      expect(await store.sendChatMessage('spam'), isFalse);
      expect(store.sendChatError, 'Message held by AutoMod');
      expect(store.sendingChat, isFalse);
    });

    test('exception maps to the generic error and returns false', () async {
      await login();
      messageService.sendThrows =
          const TwitchAuthException('nope', statusCode: 401);

      expect(await store.sendChatMessage('hi'), isFalse);
      expect(store.sendChatError, 'Could not send — try again');
      expect(store.sendingChat, isFalse);
    });
  });
```

Add the import at the top of the file:

```dart
import 'package:obs_blade/types/classes/twitch/twitch_send_result.dart';
```

(`Completer` is already available via the file's `dart:async` import; `TwitchAuthException` via its existing `twitch_auth_service.dart` import.)

- [ ] **Step 3: Run to verify they fail**

Run: `bash flutterw test test/chat/twitch_chat_store_test.dart`
Expected: FAIL — `canWriteChat`/`sendChatMessage`/`messageService:` param do not exist (compile error).

- [ ] **Step 4: Implement the store changes**

In `lib/stores/views/twitch_chat.dart`:

(a) Add imports:

```dart
import 'package:obs_blade/types/classes/twitch/twitch_send_result.dart';
import 'package:obs_blade/utils/twitch/twitch_message_service.dart';
```

(b) Constructor seam — add the field, the param, and the initializer (mirroring `_badgeStoreResolver`):

```dart
  final TwitchMessageService _messageService;
```

Add to the constructor signature (after `badgeStoreResolver`):

```dart
    TwitchMessageService? messageService,
```

and to the initializer list:

```dart
        _messageService = messageService ?? TwitchMessageService();
```

(c) After the `isLoggedIn` computed:

```dart
  /// Whether the persisted token carries the write scope. Deliberately a
  /// plain getter (not reactive): scopes change only at login/logout, and
  /// those transitions flip [user]/[authState], which rebuild observers.
  bool get canWriteChat =>
      this._authBox.get(TwitchAuth.kBoxKey)?.scopes.contains(
            'user:write:chat',
          ) ??
      false;
```

(d) After the `chatConnectedAt` observable:

```dart
  /// A send is in flight — drives the dock's disabled/spinner state and
  /// guards against concurrent sends.
  @observable
  bool sendingChat = false;

  /// Transient send failure for the dock's error line; cleared on the next
  /// attempt.
  @observable
  String? sendChatError;
```

(e) After `connectChat()` (before `_validAccessToken`), the action + helper:

```dart
  /// Send a chat message as the logged-in user into their own channel.
  /// Returns whether it was delivered — never throws; failures surface in
  /// [sendChatError]. The sent message renders via the EventSub echo.
  @action
  Future<bool> sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (this.authState != TwitchAuthState.loggedIn ||
        !this.canWriteChat ||
        trimmed.isEmpty ||
        this.sendingChat) {
      return false;
    }
    this.sendingChat = true;
    this.sendChatError = null;

    try {
      final token = await this._validAccessToken();
      final result = await this._messageService.sendChatMessage(
        accessToken: token,
        userId: this.user!.id,
        message: trimmed,
      );
      if (result.isSent) return true;
      this.sendChatError = _dropReasonText(result.dropReason);
      return false;
    } catch (e) {
      GeneralHelper.advLog('Twitch chat send failed — $e');
      this.sendChatError = 'Could not send — try again';
      return false;
    } finally {
      this.sendingChat = false;
    }
  }

  /// Human text for Helix `drop_reason` values (200-but-dropped sends).
  static String _dropReasonText(String? reason) => switch (reason) {
        'automod_blocked' || 'automod_held' => 'Message held by AutoMod',
        'duplicate' => 'Duplicate message',
        'rate_limited' => 'Sending too fast — slow down',
        null => 'Message not delivered',
        _ => 'Message not delivered ($reason)',
      };
```

- [ ] **Step 5: Regenerate MobX code**

Run: `bash flutterw pub run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded` — `twitch_chat.g.dart` regenerated with the two new observables.

- [ ] **Step 6: Run the task tests**

Run: `bash flutterw test test/chat/`
Expected: PASS — whole chat test dir, incl. the 7 new store tests.

- [ ] **Step 7: Analyze + commit**

Run: `bash flutterw analyze`
Expected: 0 errors; only the 6 known pre-existing warnings.

```bash
git add lib/stores/views/twitch_chat.dart lib/stores/views/twitch_chat.g.dart test/chat/support/fake_twitch_services.dart test/chat/twitch_chat_store_test.dart
git commit -m "feat(chat): sendChatMessage action + canWriteChat scope gate"
```

---

### Task 3: `NativeChatInput` dock + `NativeChatWindow` input slot

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart` (add `input` param + render)
- Create: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart`
- Test: `test/chat/native_chat_input_test.dart` (new), `test/chat/native_chat_window_test.dart` (append one test)

**Interfaces:**
- Consumes: `NativeChatWindow` (Task 2 of the window feature — already on `master`).
- Produces (Task 4 relies on these exact names):
  - `NativeChatWindow({ ..., Widget? input })` — renders `input` below the content, hairline-separated, when non-null
  - `class NativeChatInput extends StatefulWidget` with params: `canSend` (bool, required), `inFlight` (bool, required), `accentColor` (Color, required), `onSend` (`Future<bool> Function(String)`, required), `onRelogin` (`VoidCallback`, required), `errorText` (`String?`)

- [ ] **Step 1: Write the failing widget tests**

Create `test/chat/native_chat_input_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

NativeChatInput buildInput({
  bool canSend = true,
  bool inFlight = false,
  String? errorText,
  Future<bool> Function(String)? onSend,
  VoidCallback? onRelogin,
}) =>
    NativeChatInput(
      canSend: canSend,
      inFlight: inFlight,
      errorText: errorText,
      accentColor: Colors.purple,
      onSend: onSend ?? (_) async => true,
      onRelogin: onRelogin ?? () {},
    );

void main() {
  testWidgets('ready state renders the field; read-only the lock strip',
      (tester) async {
    await tester.pumpWidget(wrap(buildInput()));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Logged in read-only'), findsNothing);

    await tester.pumpWidget(wrap(buildInput(canSend: false)));
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Logged in read-only'), findsOneWidget);
  });

  testWidgets('read-only strip fires onRelogin', (tester) async {
    var relogin = false;
    await tester.pumpWidget(
      wrap(buildInput(canSend: false, onRelogin: () => relogin = true)),
    );

    await tester.tap(find.text('Re-login to chat'));
    expect(relogin, isTrue);
  });

  testWidgets('send submits trimmed text and clears on success',
      (tester) async {
    String? sent;
    await tester.pumpWidget(
      wrap(
        buildInput(
          onSend: (text) async {
            sent = text;
            return true;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  hello chat  ');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(sent, 'hello chat');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('failed send keeps the text', (tester) async {
    await tester.pumpWidget(
      wrap(buildInput(onSend: (_) async => false)),
    );

    await tester.enterText(find.byType(TextField), 'keep me');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'keep me',
    );
  });

  testWidgets('empty submit never calls onSend', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(buildInput(onSend: (_) async {
        calls++;
        return true;
      })),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('inFlight disables the field and the send button',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(
        buildInput(
          inFlight: true,
          onSend: (_) async {
            calls++;
            return true;
          },
        ),
      ),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).enabled,
      isFalse,
    );

    await tester.tap(find.byType(NativeChatInput));
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('error text renders above the dock', (tester) async {
    await tester.pumpWidget(wrap(buildInput(errorText: 'boom')));
    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('field is hard-capped at 500 chars', (tester) async {
    await tester.pumpWidget(wrap(buildInput()));
    expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 500);
  });
}
```

And append to `test/chat/native_chat_window_test.dart` (the file already imports `native_chat_window.dart` and `ChatType`):

```dart
  testWidgets('renders the input slot below the content when provided',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        NativeChatWindow(
          chatType: ChatType.Twitch,
          status: NativeChatConnectionStatus.live,
          input: const Text('dock'),
          child: const Center(child: Text('chat content')),
        ),
      ),
    );

    expect(find.text('chat content'), findsOneWidget);
    expect(find.text('dock'), findsOneWidget);
  });
```

- [ ] **Step 2: Run to verify they fail**

Run: `bash flutterw test test/chat/native_chat_input_test.dart test/chat/native_chat_window_test.dart`
Expected: FAIL — `native_chat_input.dart` missing, `input:` param unknown (compile errors).

- [ ] **Step 3: Add the input slot to `NativeChatWindow`**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart`:

(a) Add the param to the class (field + constructor, after `child`):

```dart
  /// Optional dock rendered below the content (input field, read-only
  /// hint) — the reserved bottom slot of the pane.
  final Widget? input;
```

```dart
    required this.child,
    this.input,
```

(b) Render it in `build`, after `Expanded(child: this.child)`:

```dart
          Expanded(child: this.child),
          if (this.input != null) ...[
            const BaseDivider(),
            this.input!,
          ],
```

(c) Extend the class doc comment's first paragraph with one sentence: `An optional [input] dock sits at the pane's bottom edge (hairline-separated).`

- [ ] **Step 4: Implement `NativeChatInput`**

Create `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../utils/styling_helper.dart';

/// Chat input dock of the native chat window: pill text field + circular
/// send button when the account may write ([canSend]), or a read-only hint
/// strip when the token predates the write scope. Generic by params — no
/// Twitch types — so a future native engine reuses it as-is.
class NativeChatInput extends StatefulWidget {
  /// Whether the account's token carries write scope
  final bool canSend;

  /// A send is in flight — field + button disabled, spinner shown
  final bool inFlight;

  /// Transient send error, shown above the dock
  final String? errorText;

  /// Brand accent (send button, hint action)
  final Color accentColor;

  /// Delivers the trimmed message; the field clears when it completes true
  final Future<bool> Function(String text) onSend;

  /// Starts the re-login flow from the read-only strip
  final VoidCallback onRelogin;

  const NativeChatInput({
    super.key,
    required this.canSend,
    required this.inFlight,
    required this.accentColor,
    required this.onSend,
    required this.onRelogin,
    this.errorText,
  });

  @override
  State<NativeChatInput> createState() => _NativeChatInputState();
}

class _NativeChatInputState extends State<NativeChatInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    this._controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (this.widget.inFlight) return;
    final String text = this._controller.text.trim();
    if (text.isEmpty) return;
    this.widget.onSend(text).then((sent) {
      if (sent && this.mounted) this._controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!this.widget.canSend) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.lock_fill,
              size: 14.0,
              color: this.widget.accentColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Logged in read-only',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Pressable(
              haptic: true,
              onTap: this.widget.onRelogin,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: kMinInteractiveDimensionCupertino,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Re-login to chat',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: this.widget.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final Color errorColor =
        (Theme.of(context).extension<AppStatusColors>() ??
                AppStatusColors.standard)
            .unreachable;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (this.widget.errorText != null) ...[
            Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 12.0,
                  color: errorColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    this.widget.errorText!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: errorColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: this._controller,
                  enabled: !this.widget.inFlight,
                  maxLength: 500,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => this._submit(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: StylingHelper.lightenDarkenColor(
                        Theme.of(context).cardColor),
                    hintText: 'Send a message…',
                    hintStyle:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                            ),

                    /// The 500-cap is enforced silently (Twitch's limit) —
                    /// no counter chrome (design decision: option A)
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.pill,
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.4),
                        width: 0.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.pill,
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.4),
                        width: 0.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.pill,
                      borderSide: BorderSide(
                        color: this.widget.accentColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pressable(
                haptic: true,
                onTap: this.widget.inFlight ? null : this._submit,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: kMinInteractiveDimensionCupertino,
                    minHeight: kMinInteractiveDimensionCupertino,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      color: this.widget.accentColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: this.widget.inFlight
                        ? (StylingHelper.isApple(context)
                            ? const CupertinoActivityIndicator(radius: 8.0)
                            : const SizedBox(
                                width: 16.0,
                                height: 16.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              ))
                        : const Icon(
                            CupertinoIcons.paperplane_fill,
                            size: 15.0,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run the task tests**

Run: `bash flutterw test test/chat/native_chat_input_test.dart test/chat/native_chat_window_test.dart`
Expected: PASS — 8 input tests + all window tests (incl. the new slot test).

- [ ] **Step 6: Analyze + commit**

Run: `bash flutterw analyze`
Expected: 0 errors; only the 6 known pre-existing warnings.

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart test/chat/native_chat_input_test.dart test/chat/native_chat_window_test.dart
git commit -m "feat(chat): input dock widget + window input slot"
```

---

### Task 4: Wire the dock into `stream_chat.dart`

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart` (native branch: add `input:` + import)

**Interfaces:**
- Consumes: `NativeChatInput` (Task 3); `TwitchChatStore.canWriteChat` / `sendingChat` / `sendChatError` / `sendChatMessage` (Task 2).
- Produces: the shipped feature — no new interfaces.

- [ ] **Step 1: Wire the branch**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart`:

(a) Add the import (with the other stream_chat relative imports):

```dart
import 'native_chat_input.dart';
```

(b) In the native branch's `NativeChatWindow(...)` (the one built inside the `Observer`), add the `input` argument directly after `child:` — noting the child currently ends the argument list, so restructure the tail to:

```dart
                      child: loggedIn
                          ? const NativeTwitchChatView()
                          : StaggeredEntrance(
                              child: _ChatEmptyState(
                                chatType: chatType,
                                nativeConnectPrompt: true,
                              ),
                            ),
                      input: loggedIn
                          ? NativeChatInput(
                              canSend: twitchStore.canWriteChat,
                              inFlight: twitchStore.sendingChat,
                              errorText: twitchStore.sendChatError,
                              accentColor: chatType.brandColor ??
                                  Theme.of(context).colorScheme.secondary,
                              onSend: twitchStore.sendChatMessage,
                              onRelogin: () => startTwitchLogin(context),
                            )
                          : null,
                    );
```

`canWriteChat`, `sendingChat`, and `sendChatError` are all read inside the `Observer` builder, so the dock rebuilds on login state, scope availability, and send progress.

- [ ] **Step 2: Full suite + analyze**

Run: `bash flutterw test`
Expected: PASS — full suite green (baseline 145 + 3 service + 7 store + 8 input + 1 window slot = 164).

Run: `bash flutterw analyze`
Expected: 0 errors; only the 6 known pre-existing warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart
git commit -m "feat(chat): dock the input in the native chat window"
```

---

### Task 5: Dogfood + handoff docs

**Files:**
- Modify: `docs/changelog-agent.md`, `docs/session-handoff.md`, `.superpowers/sdd/progress.md` (ledger — untracked)

**Interfaces:**
- Consumes: Tasks 1-4 on `master`.

- [ ] **Step 1: Manual dogfood pass**

Run the app on the workstation sim (per `docs/local-obs-e2e.md`) with the native Twitch engine selected and a **fresh login** (so the token carries write scope):

- Dock renders at the pane bottom: pill field + circular send; tap, type, keyboard send → message appears in your own Twitch chat (verify on twitch.tv too); the echo renders it in the app with emotes parsed.
- Send button shows the spinner in flight; field clears on success.
- Error path: send while offline (airplane mode) → inline error line, text kept; re-enable, resend works.
- Read-only path: install/login with a pre-upgrade build's stored session (or temporarily flip `kTwitchChatScopes` back) → dock shows the lock strip; tap "Re-login to chat" → device flow → dock becomes the field.
- 500-char cap: paste a long text — capped, no counter chrome.
- Tablet mode: dock inside the Chat card, keyboard focus doesn't fight the pane clip.
- WebView engine: unchanged.

- [ ] **Step 2: Update docs**

- `docs/changelog-agent.md` — new entry: send input (scope upgrade, service, store action, dock, drop-reason surfacing, EventSub echo), tests, dogfood result.
- `docs/session-handoff.md` — native chat now reads AND writes; next chat items: availability/entitlement gate, 7TV/BTTV, replies/announce as future send polish.
- `.superpowers/sdd/progress.md` — ledger lines per task.

- [ ] **Step 3: Commit + report**

```bash
git add docs/changelog-agent.md docs/session-handoff.md
git commit -m "docs: chat send input shipped — handoff + changelog"
```

Report dogfood findings to the user (their explicit dogfood step — wait for their pass/fail before calling the feature done).
