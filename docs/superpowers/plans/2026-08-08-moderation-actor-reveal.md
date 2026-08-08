# Deleting-Moderator Reveal (`channel.moderate` v2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the `channel.moderate` v2 EventSub subscription so tapping a
mod-deleted chat message reveals who deleted it (`<mod> deleted
<chatter>'s message`), gated on the 8-scope `moderator:read:*` bundle.

**Architecture:** One new best-effort subscription on the existing EventSub
session; `delete` actions enrich the store's existing
`_deletedMessageActors` map (order-tolerant with `message_delete`). No new
state systems, no persistence, no UI changes (reveal already shipped,
dormant). Spec: `docs/superpowers/specs/2026-08-08-moderation-actor-reveal-design.md`.

**Tech Stack:** Flutter/Dart, MobX, freezed/json_serializable, Twitch
EventSub WebSocket.

## Global Constraints

- Flutter SDK on this machine: `~/.dotfiles/flutter/sdk/bin/flutter`
  (headless NAS clone: `~/flutter/bin/flutter`). `./flutterw` has no SDK here.
- freezed codegen: `~/.dotfiles/flutter/sdk/bin/dart run build_runner build
  --delete-conflicting-outputs --build-filter='<path>.*.dart'`.
- Gates before final commit: `flutter test` all green (currently 250);
  `flutter analyze` = 0 errors + exactly the 6 pre-existing warnings.
- Commit per task, small logically-scoped commits. Do NOT push.
- Fixture payloads must mirror Twitch's real shapes (source: twitch-rs
  `moderate.rs` v2) — never invent fields.

---

### Task 1: `ChannelModerateEvent` DTO + fixtures

**Files:**
- Create: `lib/types/classes/twitch/eventsub/channel_moderate_event.dart`
- Create: `test/chat/fixtures/twitch/channel_moderate_delete.json`
- Create: `test/chat/fixtures/twitch/channel_moderate_timeout.json`
- Test: `test/chat/twitch_lifecycle_dto_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `ChannelModerateEvent({required String action, required String
  moderatorUserName, ModerateDeleteAction? delete})` with
  `ChannelModerateEvent.fromJson(Map<String, Object?>)`;
  `ModerateDeleteAction({required String messageId, String? userName})`.

- [ ] **Step 1: Write the two fixtures (real twitch-rs v2 envelope shapes)**

`test/chat/fixtures/twitch/channel_moderate_delete.json`:

```json
{
  "broadcaster_user_id": "129546453",
  "broadcaster_user_login": "nerixyz",
  "broadcaster_user_name": "nerixyz",
  "source_broadcaster_user_id": null,
  "source_broadcaster_user_login": null,
  "source_broadcaster_user_name": null,
  "moderator_user_id": "424596340",
  "moderator_user_login": "quotrok",
  "moderator_user_name": "quotrok",
  "action": "delete",
  "followers": null,
  "slow": null,
  "vip": null,
  "unvip": null,
  "mod": null,
  "unmod": null,
  "ban": null,
  "unban": null,
  "timeout": null,
  "untimeout": null,
  "raid": null,
  "unraid": null,
  "delete": {
    "user_id": "141981764",
    "user_login": "twitchdev",
    "user_name": "TwitchDev",
    "message_id": "ab24e0b0-2260-4bac-94e4-05eedd4ecd0e",
    "message_body": "that was rude Kappa"
  },
  "automod_terms": null,
  "unban_request": null,
  "warn": null,
  "shared_chat_ban": null,
  "shared_chat_unban": null,
  "shared_chat_timeout": null,
  "shared_chat_untimeout": null,
  "shared_chat_delete": null
}
```

`test/chat/fixtures/twitch/channel_moderate_timeout.json` — same envelope,
`action: "timeout"`, `delete: null`, `timeout` filled:

```json
{
  "broadcaster_user_id": "129546453",
  "broadcaster_user_login": "nerixyz",
  "broadcaster_user_name": "nerixyz",
  "source_broadcaster_user_id": null,
  "source_broadcaster_user_login": null,
  "source_broadcaster_user_name": null,
  "moderator_user_id": "424596340",
  "moderator_user_login": "quotrok",
  "moderator_user_name": "quotrok",
  "action": "timeout",
  "followers": null,
  "slow": null,
  "vip": null,
  "unvip": null,
  "mod": null,
  "unmod": null,
  "ban": null,
  "unban": null,
  "timeout": {
    "user_id": "141981764",
    "user_login": "twitchdev",
    "user_name": "TwitchDev",
    "reason": "test Kappa",
    "expires_at": "2024-11-27T18:12:43.640505703Z"
  },
  "untimeout": null,
  "raid": null,
  "unraid": null,
  "delete": null,
  "automod_terms": null,
  "unban_request": null,
  "warn": null,
  "shared_chat_ban": null,
  "shared_chat_unban": null,
  "shared_chat_timeout": null,
  "shared_chat_untimeout": null,
  "shared_chat_delete": null
}
```

- [ ] **Step 2: Write the failing tests**

Append to `test/chat/twitch_lifecycle_dto_test.dart` — import line at the
top (after the existing chat_lifecycle_events import):

```dart
import 'package:obs_blade/types/classes/twitch/eventsub/channel_moderate_event.dart';
```

and a new group inside `main()` after the existing `group(...)` block:

```dart
  group('channel.moderate v2 DTO', () {
    test('delete action parses the real payload shape', () {
      final event =
          ChannelModerateEvent.fromJson(fixture('channel_moderate_delete'));
      expect(event.action, 'delete');
      expect(event.moderatorUserName, 'quotrok');
      expect(event.delete?.messageId, 'ab24e0b0-2260-4bac-94e4-05eedd4ecd0e');
      expect(event.delete?.userName, 'TwitchDev');
    });

    test('a non-delete action yields no delete payload', () {
      final event =
          ChannelModerateEvent.fromJson(fixture('channel_moderate_timeout'));
      expect(event.action, 'timeout');
      expect(event.moderatorUserName, 'quotrok');
      expect(event.delete, isNull);
    });

    test('delete without message_id throws', () {
      expect(
        () => ChannelModerateEvent.fromJson(const {
          'action': 'delete',
          'moderator_user_name': 'quotrok',
          'delete': <String, Object?>{},
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_lifecycle_dto_test.dart`
Expected: FAIL — `ChannelModerateEvent` undefined (import not found).

- [ ] **Step 4: Write the DTO**

Create `lib/types/classes/twitch/eventsub/channel_moderate_event.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_moderate_event.freezed.dart';
part 'channel_moderate_event.g.dart';

/// `channel.moderate` v2 event — a moderator performed an action in the
/// channel. Only the `delete` action is modeled (tombstone actor reveal);
/// every other action parses-then-ignores. The real payload is a flat
/// envelope: an `action` discriminator plus every action field present,
/// all but the active one null (see the fixtures, which mirror the
/// twitch-rs v2 shape).
@Freezed(fromJson: true, toJson: false)
abstract class ChannelModerateEvent with _$ChannelModerateEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChannelModerateEvent({
    required String action,
    required String moderatorUserName,
    ModerateDeleteAction? delete,
  }) = _ChannelModerateEvent;

  factory ChannelModerateEvent.fromJson(Map<String, Object?> json) =>
      _$ChannelModerateEventFromJson(json);
}

/// The `delete` action payload — [messageId] keys the tombstone;
/// [userName] is the chatter (the row already renders their name).
@Freezed(fromJson: true, toJson: false)
abstract class ModerateDeleteAction with _$ModerateDeleteAction {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ModerateDeleteAction({
    required String messageId,
    String? userName,
  }) = _ModerateDeleteAction;

  factory ModerateDeleteAction.fromJson(Map<String, Object?> json) =>
      _$ModerateDeleteActionFromJson(json);
}
```

Then codegen:

```bash
~/.dotfiles/flutter/sdk/bin/dart run build_runner build --delete-conflicting-outputs \
  --build-filter='lib/types/classes/twitch/eventsub/channel_moderate_event.*.dart'
```

Expected: `Built with build_runner ... wrote 3 outputs` (creates
`channel_moderate_event.freezed.dart` + `channel_moderate_event.g.dart`).

- [ ] **Step 5: Run the tests to verify they pass**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_lifecycle_dto_test.dart`
Expected: PASS (8 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/types/classes/twitch/eventsub/channel_moderate_event.dart \
  lib/types/classes/twitch/eventsub/channel_moderate_event.freezed.dart \
  lib/types/classes/twitch/eventsub/channel_moderate_event.g.dart \
  test/chat/fixtures/twitch/channel_moderate_delete.json \
  test/chat/fixtures/twitch/channel_moderate_timeout.json \
  test/chat/twitch_lifecycle_dto_test.dart
git commit -m "feat(chat): channel.moderate v2 DTO — tolerant delete-action model"
```

---

### Task 2: EventSub service — `includeModeration` + moderate dispatch

**Files:**
- Modify: `lib/utils/twitch/twitch_eventsub_service.dart`
- Test: `test/chat/twitch_eventsub_service_test.dart`

**Interfaces:**
- Consumes: `ChannelModerateEvent` / `ModerateDeleteAction` (Task 1);
  fixtures `channel_moderate_delete.json` / `channel_moderate_timeout.json`.
- Produces: `TwitchEventSubService.connect({required String accessToken,
  required String userId, bool includeModeration = false})`; optional
  constructor callback `onModerationDelete` of type `void Function(String
  messageId, String moderatorName)?`.

- [ ] **Step 1: Write the failing tests**

In `test/chat/twitch_eventsub_service_test.dart`:

a) Add a record list next to the other captures (after
`late List<ChatClearEvent> clears;`):

```dart
  late List<(String, String)> moderationDeletes;
```

and initialize it in `setUp` (after `clears = [];`):

```dart
    moderationDeletes = [];
```

b) Add a helper after `lifecycleServiceWith`:

```dart
  TwitchEventSubService moderationServiceWith(MockClient client) =>
      TwitchEventSubService(
        onChatMessage: messages.add,
        onMessageDelete: deletes.add,
        onClearUserMessages: purges.add,
        onChatClear: clears.add,
        onModerationDelete: (messageId, actor) =>
            moderationDeletes.add((messageId, actor)),
        onStateChanged: states.add,
        onRevoked: revocations.add,
        client: client,
        channelFactory: (uri) {
          final channel = FakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
        sleep: (_) async {},
      );
```

c) Add the tests (append after the
`'a failing lifecycle POST degrades tombstones, not chat'` test):

```dart
  test('includeModeration appends a v2 channel.moderate subscription',
      () async {
    final bodies = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      bodies.add(json.decode(request.body) as Map<String, dynamic>);
      return http.Response(
        json.encode({
          'data': [
            {'id': 'sub-${bodies.length}'}
          ],
        }),
        202,
      );
    });

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', includeModeration: true);
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(bodies.map((body) => body['type']), [
      'channel.chat.message',
      'channel.chat.message_delete',
      'channel.chat.clear_user_messages',
      'channel.chat.clear',
      'channel.moderate',
    ]);
    for (final body in bodies.sublist(0, 4)) {
      expect(body['version'], '1');
      expect(body['condition'],
          {'broadcaster_user_id': 'user-1', 'user_id': 'user-1'});
    }
    expect(bodies[4]['version'], '2');
    expect(bodies[4]['condition'],
        {'broadcaster_user_id': 'user-1', 'moderator_user_id': 'user-1'});
  });

  test('moderate delete dispatches; other actions are ignored', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = moderationServiceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', includeModeration: true);
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    String moderateNotification(Map<String, Object?> event) => json.encode({
          'metadata': {
            'message_id': 'mod-1',
            'message_type': 'notification',
            'message_timestamp': '2026-08-08T10:00:00.000Z',
            'subscription_type': 'channel.moderate',
            'subscription_version': '2',
          },
          'payload': {
            'subscription': {'type': 'channel.moderate'},
            'event': event,
          },
        });

    final timeoutEvent = json.decode(File(
            'test/chat/fixtures/twitch/channel_moderate_timeout.json')
        .readAsStringSync()) as Map<String, Object?>;
    final deleteEvent = json.decode(File(
            'test/chat/fixtures/twitch/channel_moderate_delete.json')
        .readAsStringSync()) as Map<String, Object?>;

    channels.single.incoming.add(moderateNotification(timeoutEvent));
    channels.single.incoming.add(moderateNotification(deleteEvent));
    await pumpEventQueue();

    expect(moderationDeletes, [
      ('ab24e0b0-2260-4bac-94e4-05eedd4ecd0e', 'quotrok'),
    ]);
  });

  test('a failing moderate POST degrades the reveal, not chat', () async {
    var posts = 0;
    final client = MockClient((request) async {
      posts++;
      if (posts == 5) return http.Response('Forbidden', 403);
      return http.Response(
          json.encode({
            'data': [
              {'id': 'sub-$posts'}
            ],
          }),
          202);
    });

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', includeModeration: true);
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(posts, 5);
    expect(revocations, isEmpty);
    expect(states, contains(TwitchEventSubState.connected));
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_eventsub_service_test.dart`
Expected: FAIL to compile — no `includeModeration` parameter, no
`onModerationDelete` parameter.

- [ ] **Step 3: Implement the service changes**

In `lib/utils/twitch/twitch_eventsub_service.dart`:

a) Add the import (after the chat_lifecycle_events import):

```dart
import 'package:obs_blade/types/classes/twitch/eventsub/channel_moderate_event.dart';
```

b) Add the moderate type constant after `_kMessageType`:

```dart
  /// `channel.moderate` v2 — optional best-effort fifth type, created only
  /// when [connect] passes `includeModeration` (the token must carry the
  /// full moderator:read bundle; condition uses `moderator_user_id`).
  static const String _kModerateType = 'channel.moderate';
```

c) Add the callback field after `onChatClear`:

```dart
  /// `channel.moderate` delete actions — (messageId, moderator display
  /// name). Optional; a null callback skips parsing for this type.
  final void Function(String messageId, String moderatorName)?
      onModerationDelete;
```

and the constructor parameter after `this.onChatClear,`:

```dart
    this.onModerationDelete,
```

d) Add the flag field next to `_accessToken`/`_userId`:

```dart
  bool _includeModeration = false;
```

e) Extend `connect` — replace the whole method:

```dart
  Future<void> connect({
    required String accessToken,
    required String userId,
    bool includeModeration = false,
  }) async {
    this._accessToken = accessToken;
    this._userId = userId;
    this._includeModeration = includeModeration;
    this._disposed = false;
    this._reconnectAttempts = 0;
    this._openSocket(Uri.parse(_wsUrl));
  }
```

f) Add the dispatch case in `_handleNotification`, after the
`'channel.chat.clear'` case:

```dart
        case 'channel.moderate':
          final callback = this.onModerationDelete;
          if (callback != null) {
            final event = ChannelModerateEvent.fromJson(
              envelope.payload['event'] as Map<String, Object?>,
            );
            final delete = event.delete;
            if (event.action == 'delete' && delete != null) {
              callback(delete.messageId, event.moderatorUserName);
            }
          }
```

g) Replace the body of `_createSubscriptions`'s loop header and POST body
so the type list and condition are per-type. Replace:

```dart
    final created = <String>[];
    for (final type in _kSubscriptionTypes) {
      final mandatory = type == _kMessageType;
```

with:

```dart
    final types = <String>[
      ..._kSubscriptionTypes,
      if (this._includeModeration) _kModerateType,
    ];
    final created = <String>[];
    for (final type in types) {
      final mandatory = type == _kMessageType;
      final isModerate = type == _kModerateType;
```

and replace:

```dart
          body: json.encode({
            'type': type,
            'version': '1',
            'condition': {'broadcaster_user_id': userId, 'user_id': userId},
            'transport': {'method': 'websocket', 'session_id': sessionId},
          }),
```

with:

```dart
          body: json.encode({
            'type': type,
            'version': isModerate ? '2' : '1',
            'condition': isModerate
                ? {
                    'broadcaster_user_id': userId,
                    'moderator_user_id': userId,
                  }
                : {'broadcaster_user_id': userId, 'user_id': userId},
            'transport': {'method': 'websocket', 'session_id': sessionId},
          }),
```

Also update the class doc comment's second sentence. Replace:

```
/// Dedicated EventSub WebSocket session for chat messages + moderation
/// lifecycle events (`message_delete`, `clear_user_messages`, `clear`).
```

with:

```
/// Dedicated EventSub WebSocket session for chat messages + moderation
/// lifecycle events (`message_delete`, `clear_user_messages`, `clear`,
/// optionally `channel.moderate` v2 for the deleting-mod reveal).
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_eventsub_service_test.dart`
Expected: PASS — all existing tests (default `includeModeration: false`
keeps 4 subscriptions) plus the 3 new ones.

- [ ] **Step 5: Commit**

```bash
git add lib/utils/twitch/twitch_eventsub_service.dart \
  test/chat/twitch_eventsub_service_test.dart
git commit -m "feat(chat): optional channel.moderate v2 subscription + delete dispatch"
```

---

### Task 3: Auth — the `moderator:read:*` scope bundle

**Files:**
- Modify: `lib/utils/twitch/twitch_auth_service.dart:13-20`
- Test: `test/chat/twitch_auth_service_test.dart:26-27`

**Interfaces:**
- Consumes: nothing.
- Produces: `const List<String> kTwitchModerationScopes` (8 entries) —
  consumed by the store gate (Task 4); `kTwitchChatScopes` now includes it.

- [ ] **Step 1: Update the failing test first**

In `test/chat/twitch_auth_service_test.dart`, replace:

```dart
        expect(request.bodyFields['scopes'],
            'user:read:chat user:write:chat user:read:emotes');
```

with:

```dart
        expect(request.bodyFields['scopes'],
            'user:read:chat user:write:chat user:read:emotes '
            'moderator:read:blocked_terms moderator:read:chat_settings '
            'moderator:read:unban_requests moderator:read:banned_users '
            'moderator:read:chat_messages moderator:read:warnings '
            'moderator:read:moderators moderator:read:vips');
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_auth_service_test.dart`
Expected: FAIL — scopes string mismatch (still the old 3 scopes).

- [ ] **Step 3: Add the bundle to the scopes**

In `lib/utils/twitch/twitch_auth_service.dart`, replace:

```dart
/// Chat scopes requested in the device flow — read incoming chat, send
/// messages as the authenticated user, and list the emotes they can use
/// (emote picker).
const List<String> kTwitchChatScopes = <String>[
  'user:read:chat',
  'user:write:chat',
  'user:read:emotes',
];
```

with:

```dart
/// Moderation read bundle required by the `channel.moderate` v2
/// subscription (Twitch demands ALL of them — read variants only, no
/// moderation powers). Gates `TwitchChatStore.canReadModeration`.
const List<String> kTwitchModerationScopes = <String>[
  'moderator:read:blocked_terms',
  'moderator:read:chat_settings',
  'moderator:read:unban_requests',
  'moderator:read:banned_users',
  'moderator:read:chat_messages',
  'moderator:read:warnings',
  'moderator:read:moderators',
  'moderator:read:vips',
];

/// Chat scopes requested in the device flow — read incoming chat, send
/// messages as the authenticated user, list the emotes they can use
/// (emote picker), and read their own channel's moderation actions
/// (deleting-mod reveal on native chat tombstones).
const List<String> kTwitchChatScopes = <String>[
  'user:read:chat',
  'user:write:chat',
  'user:read:emotes',
  ...kTwitchModerationScopes,
];
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_auth_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/utils/twitch/twitch_auth_service.dart \
  test/chat/twitch_auth_service_test.dart
git commit -m "feat(chat): request the moderator:read bundle at login (channel.moderate v2)"
```

---

### Task 4: Store — scope gate, `applyModerationDelete`, factory wiring

**Files:**
- Modify: `lib/stores/views/twitch_chat.dart` (getter near
  `canReadEmotes` ~:193; factory typedefs :51-58 + ctor ~:74-83; default
  factory ~:88-97; `connectChat` :346-357; new action next to
  `applyMessageDelete` :573-582; `_deletedMessageActors` comment :156-160)
- Modify: `test/chat/support/fake_twitch_services.dart:104-129`
- Test: `test/chat/twitch_chat_store_test.dart`
- Mechanically update factory arity (6 → 7 params) in:
  `test/chat/twitch_chat_integration_test.dart:55`,
  `test/chat/native_twitch_chat_view_test.dart:94`,
  `test/chat/twitch_chat_store_test.dart:59,455,512,646,702,886`

**Interfaces:**
- Consumes: `kTwitchModerationScopes` (Task 3); service `connect(
  includeModeration:)` + `onModerationDelete` callback (Task 2).
- Produces: `TwitchChatStore.canReadModeration` (`bool` getter);
  `TwitchChatStore.applyModerationDelete(String messageId, String
  actorName)`; factory signature gains a 5th-of-7 positional callback
  `void Function(String messageId, String actorName) onModerationDelete`
  (after `onChatClear`, before `onStateChanged`).

- [ ] **Step 1: Write the failing store tests**

In `test/chat/twitch_chat_store_test.dart`, append inside the
`group('lifecycle', ...)` (before its closing `});`):

```dart
    test('a moderate delete tombstones with the actor and bumps the version',
        () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      final version = store.lifecycleVersion;

      store.applyModerationDelete('m1', 'Cool_Mod');

      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
      expect(store.lifecycleVersion, version + 1);
    });

    test('message_delete first, moderate later — actor lands with a bump',
        () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyMessageDelete(
          const ChatMessageDeleteEvent(messageId: 'm1', targetUserId: 'u1'));
      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), isNull);
      final version = store.lifecycleVersion;

      store.applyModerationDelete('m1', 'Cool_Mod');

      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
      expect(store.lifecycleVersion, version + 1);
    });

    test('moderate first, message_delete later — idempotent single tombstone',
        () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyModerationDelete('m1', 'Cool_Mod');
      final version = store.lifecycleVersion;

      store.applyMessageDelete(
          const ChatMessageDeleteEvent(messageId: 'm1', targetUserId: 'u1'));

      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
      expect(store.lifecycleVersion, version);
    });

    test('a moderate delete for an unknown id is a no-op', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      final version = store.lifecycleVersion;

      store.applyModerationDelete('nope', 'Cool_Mod');

      expect(store.isMessageDeleted('nope'), isFalse);
      expect(store.lifecycleVersion, version);
    });
```

- [ ] **Step 2: Write the failing gate + wiring tests**

a) In the `group('lifecycle wiring', ...)` — extend
`loginWithCapturedCallbacks` and add a capture. Replace:

```dart
    late void Function(ChatMessageDeleteEvent) emitDelete;
    late void Function(ChatClearUserMessagesEvent) emitPurge;
    late void Function(ChatClearEvent) emitClear;
```

with:

```dart
    late void Function(ChatMessageDeleteEvent) emitDelete;
    late void Function(ChatClearUserMessagesEvent) emitPurge;
    late void Function(ChatClearEvent) emitClear;
    late void Function(String, String) emitModerationDelete;
```

and replace the factory in `loginWithCapturedCallbacks`:

```dart
        eventSubFactory: (onChatMessage, onMessageDelete,
            onClearUserMessages, onChatClear, onStateChanged, onRevoked) {
          emitDelete = onMessageDelete;
          emitPurge = onClearUserMessages;
          emitClear = onChatClear;
          return eventSubService;
        },
```

with:

```dart
        eventSubFactory: (onChatMessage, onMessageDelete,
            onClearUserMessages, onChatClear, onModerationDelete,
            onStateChanged, onRevoked) {
          emitDelete = onMessageDelete;
          emitPurge = onClearUserMessages;
          emitClear = onChatClear;
          emitModerationDelete = onModerationDelete;
          return eventSubService;
        },
```

Then append inside the same group:

```dart
    test('the moderate callback drives the actor reveal', () async {
      await loginWithCapturedCallbacks();
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));

      emitModerationDelete('m1', 'Cool_Mod');

      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
    });
```

b) Append a new group after `group('lifecycle wiring', ...)` (before the
final `}` of `main()`):

```dart
  group('moderation scope gate', () {
    test('connectChat passes includeModeration: false without the bundle',
        () async {
      authService.tokenScopes = const [
        'user:read:chat',
        'user:write:chat',
        'user:read:emotes',
      ];
      await store.startLogin();

      expect(eventSubService.lastIncludeModeration, isFalse);
    });

    test('connectChat passes includeModeration: true with the full bundle',
        () async {
      authService.tokenScopes = kTwitchModerationScopes;
      await store.startLogin();

      expect(eventSubService.lastIncludeModeration, isTrue);
    });
  });
```

- [ ] **Step 3: Run the store tests to verify they fail**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/twitch_chat_store_test.dart`
Expected: FAIL to compile — `applyModerationDelete` undefined, factory
arity mismatch, `lastIncludeModeration` undefined.

- [ ] **Step 4: Update the fake service**

In `test/chat/support/fake_twitch_services.dart`, replace the
`FakeTwitchEventSubService` class body (fields + connect override):

```dart
class FakeTwitchEventSubService extends TwitchEventSubService {
  bool connectCalled = false;
  String? lastAccessToken;
  bool? lastIncludeModeration;
  bool disposeCalled = false;

  FakeTwitchEventSubService()
      : super(
          onChatMessage: (_) {},
          onStateChanged: (_) {},
          onRevoked: (_) {},
        );

  @override
  Future<void> connect({
    required String accessToken,
    required String userId,
    bool includeModeration = false,
  }) async {
    this.connectCalled = true;
    this.lastAccessToken = accessToken;
    this.lastIncludeModeration = includeModeration;
  }

  @override
  Future<void> dispose() async {
    this.disposeCalled = true;
  }
}
```

- [ ] **Step 5: Implement the store changes**

In `lib/stores/views/twitch_chat.dart`:

a) Update the `_deletedMessageActors` doc comment (it currently says
Twitch never sends the actor). Replace:

```dart
  /// Display name of the moderator who deleted a message, keyed by
  /// messageId — plain Map, same [lifecycleVersion] reactivity story as
  /// [_deletedMessageIds]. Twitch's `message_delete` payload does not
  /// currently include the deleting moderator (kept forward-compatible on
  /// the DTO), so entries only ever appear if Twitch adds the field;
  /// purge and /clear ids are always absent here.
```

with:

```dart
  /// Display name of the moderator who deleted a message, keyed by
  /// messageId — plain Map, same [lifecycleVersion] reactivity story as
  /// [_deletedMessageIds]. The actor arrives via `channel.moderate` delete
  /// actions (only when the token carries the moderation scope bundle);
  /// purge and /clear ids never have one.
```

b) Add the gate getter after `canReadEmotes`:

```dart
  /// Whether the persisted token carries the full moderation read bundle
  /// (`channel.moderate` v2 → deleting-mod reveal). Same deliberately
  /// plain (non-reactive) pattern as [canReadEmotes].
  bool get canReadModeration {
    final scopes = this._authBox.get(TwitchAuth.kBoxKey)?.scopes;
    return scopes != null && kTwitchModerationScopes.every(scopes.contains);
  }
```

c) Extend the factory typedef. Replace (field declaration):

```dart
  final TwitchEventSubService Function(
    void Function(ChatMessageEvent) onChatMessage,
    void Function(ChatMessageDeleteEvent) onMessageDelete,
    void Function(ChatClearUserMessagesEvent) onClearUserMessages,
    void Function(ChatClearEvent) onChatClear,
    void Function(TwitchEventSubState) onStateChanged,
    void Function(String) onRevoked,
  ) _eventSubFactory;
```

with:

```dart
  final TwitchEventSubService Function(
    void Function(ChatMessageEvent) onChatMessage,
    void Function(ChatMessageDeleteEvent) onMessageDelete,
    void Function(ChatClearUserMessagesEvent) onClearUserMessages,
    void Function(ChatClearEvent) onChatClear,
    void Function(String messageId, String actorName) onModerationDelete,
    void Function(TwitchEventSubState) onStateChanged,
    void Function(String) onRevoked,
  ) _eventSubFactory;
```

and apply the same insertion (`void Function(String messageId, String
actorName),` after the `ChatClearEvent` line) to the constructor
parameter typedef below it.

d) Extend the default factory. Replace:

```dart
        _eventSubFactory = eventSubFactory ??
            ((onChatMessage, onMessageDelete, onClearUserMessages, onChatClear,
                    onStateChanged, onRevoked) =>
                TwitchEventSubService(
                  onChatMessage: onChatMessage,
                  onMessageDelete: onMessageDelete,
                  onClearUserMessages: onClearUserMessages,
                  onChatClear: onChatClear,
                  onStateChanged: onStateChanged,
                  onRevoked: onRevoked,
                )),
```

with:

```dart
        _eventSubFactory = eventSubFactory ??
            ((onChatMessage, onMessageDelete, onClearUserMessages, onChatClear,
                    onModerationDelete, onStateChanged, onRevoked) =>
                TwitchEventSubService(
                  onChatMessage: onChatMessage,
                  onMessageDelete: onMessageDelete,
                  onClearUserMessages: onClearUserMessages,
                  onChatClear: onChatClear,
                  onModerationDelete: onModerationDelete,
                  onStateChanged: onStateChanged,
                  onRevoked: onRevoked,
                )),
```

e) Wire the callback + gate in `connectChat`. Replace:

```dart
      this._eventSub = this._eventSubFactory(
        this._appendMessage,
        (event) => this.applyMessageDelete(event),
        (event) => this.applyClearUserMessages(event.targetUserId),
        (_) => this.applyChatClear(),
        this._onEventSubState,
        this._onEventSubRevoked,
      );
      await this._eventSub!.connect(
        accessToken: token,
        userId: this.user!.id,
      );
```

with:

```dart
      this._eventSub = this._eventSubFactory(
        this._appendMessage,
        (event) => this.applyMessageDelete(event),
        (event) => this.applyClearUserMessages(event.targetUserId),
        (_) => this.applyChatClear(),
        (messageId, actor) => this.applyModerationDelete(messageId, actor),
        this._onEventSubState,
        this._onEventSubRevoked,
      );
      await this._eventSub!.connect(
        accessToken: token,
        userId: this.user!.id,
        includeModeration: this.canReadModeration,
      );
```

f) Add the action after `applyMessageDelete`:

```dart
  /// `channel.moderate` delete — tombstone + actor in one event (a
  /// superset of `message_delete`). Both orderings converge: the version
  /// bumps on any real change, so a `message_delete`-first tombstone gains
  /// its actor (and tap target) when this lands; a moderate-first
  /// tombstone makes the later `message_delete` a no-op.
  @action
  void applyModerationDelete(String messageId, String actorName) {
    final visible =
        this.messages.any((message) => message.messageId == messageId);
    if (!visible) return;
    final tombstoned = this._deletedMessageIds.add(messageId);
    final actorNew = this._deletedMessageActors[messageId] != actorName;
    if (actorNew) this._deletedMessageActors[messageId] = actorName;
    if (tombstoned || actorNew) this.lifecycleVersion++;
  }
```

g) Add the `kTwitchModerationScopes` import — the auth service is already
imported (`package:obs_blade/utils/twitch/twitch_auth_service.dart`), no
new import needed.

- [ ] **Step 6: Update the remaining factory call sites (mechanical)**

Every test factory literal gains a 7th parameter (the new callback sits
between `onChatClear` and `onStateChanged`):

- `test/chat/twitch_chat_store_test.dart:59,512,646,702` —
  `(_, __, ___, ____, _____, ______) => eventSubService` →
  `(_, __, ___, ____, _____, ______, _______) => eventSubService`
- `test/chat/twitch_chat_store_test.dart:455` —
  `(_, __, ___, ____, onStateChanged, onRevoked)` →
  `(_, __, ___, ____, ______, onStateChanged, onRevoked)`
- `test/chat/twitch_chat_integration_test.dart:55` and
  `test/chat/native_twitch_chat_view_test.dart:94` — same 6→7 underscore
  insertion as above.

- [ ] **Step 7: Run the chat tests to verify they pass**

Run: `~/.dotfiles/flutter/sdk/bin/flutter test test/chat/`
Expected: PASS (all 219+ prior tests plus the 7 new ones).

- [ ] **Step 8: Commit**

```bash
git add lib/stores/views/twitch_chat.dart \
  test/chat/support/fake_twitch_services.dart \
  test/chat/twitch_chat_store_test.dart \
  test/chat/twitch_chat_integration_test.dart \
  test/chat/native_twitch_chat_view_test.dart
git commit -m "feat(chat): store scope gate + moderation delete merge — actor reveal wired"
```

---

### Task 5: Comment/doc sync + full gates

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart:28-31`
- Modify: `AGENTS.md` (chat paragraph)
- Modify: `docs/changelog-agent.md` (new top entry)
- Modify: `docs/session-handoff.md` ("Deleted content + actor reveal" bullet)

**Interfaces:**
- Consumes: Tasks 1-4.
- Produces: nothing code-facing.

- [ ] **Step 1: Fix the row's `deletedActor` comment (behavior changed)**

In `twitch_chat_message_row.dart`, replace:

```dart
  /// Display name of the moderator who deleted this message — Twitch's
  /// `message_delete` payload does not currently include the actor, so
  /// this is null in practice (purge//clear ids always are). Non-null
  /// together with [isDeleted] makes the row tappable ([onDeletedTap]).
```

with:

```dart
  /// Display name of the moderator who deleted this message — arrives via
  /// `channel.moderate` when the token carries the moderation scope
  /// bundle; null for pre-upgrade tokens and always for purge//clear ids.
  /// Non-null together with [isDeleted] makes the row tappable
  /// ([onDeletedTap]).
```

- [ ] **Step 2: Update `AGENTS.md`**

Replace (in the Chat paragraph):

```
tombstones (dimmed content + ` —Deleted` marker) + `/clear` banner,
best-effort subs — Twitch's `message_delete` payload carries no deleting
mod, so actor reveal stays dormant unless `channel.moderate` is ever
added) and scrolled-up chat shows a
```

with:

```
tombstones (dimmed content + ` —Deleted` marker) + `/clear` banner,
best-effort subs; a `channel.moderate` v2 sub (gated on the
`kTwitchModerationScopes` 8-scope bundle, pre-upgrade tokens skip it)
supplies the deleting mod for the tap reveal) and scrolled-up chat shows a
```

- [ ] **Step 3: Changelog entry**

Prepend to `docs/changelog-agent.md` (after the intro line):

```markdown
## 2026-08-08 — Native chat: deleting-mod reveal live (channel.moderate v2)

- The tap-to-reveal on deleted messages now works end to end: the EventSub
  session creates a best-effort `channel.moderate` v2 subscription
  (condition `moderator_user_id` = self) whose `delete` actions carry the
  acting moderator — the piece `channel.chat.message_delete` lacks.
- Login now requests the 8-scope `moderator:read:*` bundle Twitch demands
  (`kTwitchModerationScopes`); pre-upgrade tokens skip the subscription
  (`canReadModeration` gate) and keep plain tombstones until re-login.
- Store merge is order-tolerant with `message_delete` (either event may
  land first; the version bumps when the actor arrives). The moderate
  event also tombstones on its own — a failed `message_delete` POST no
  longer loses single deletes.
- New `ChannelModerateEvent` DTO is tolerant (only `delete` modeled,
  fixtures mirror the real twitch-rs v2 envelope). Tests: DTO 3, service
  3, store 6 + gate 2. Gates: full suite green, analyze 0 errors + 6
  pre-existing warnings.
```

- [ ] **Step 4: Handoff update**

In `docs/session-handoff.md`, replace the whole "Deleted content + actor
reveal" bullet with:

```markdown
  - Deleted content + actor reveal (08-07/08-08): deleted rows keep
    content dimmed (alpha 0.5) + italic ` —Deleted` marker; tap →
    `<mod> deleted <chatter>'s message`. The actor arrives via a
    best-effort `channel.moderate` v2 sub gated on the 8-scope
    `moderator:read:*` bundle (pre-upgrade tokens: plain tombstones).
    **DOGFOOD OPEN — needs a fresh login first** (consent screen shows
    the bundle; sanity-check it reads acceptably):
    - Re-login → delete a message from twitch.tv mod tools → dimmed +
      marker → tap → reveal line with the acting mod; tap again collapses.
    - Delete as a *different* mod account → reveal shows that mod.
    - Time out a user / `/clear` → content + marker, no tap reveal.
    - Deleted message with emotes → emotes render dimmed.
```

- [ ] **Step 5: Full gates**

```bash
~/.dotfiles/flutter/sdk/bin/flutter test
~/.dotfiles/flutter/sdk/bin/flutter analyze
```

Expected: all tests pass; `0 errors` + exactly the 6 pre-existing
warnings (input.dart ×2, statistics.dart ×2, translucent_sliver_app_bar.dart ×2).

- [ ] **Step 6: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart \
  AGENTS.md docs/changelog-agent.md docs/session-handoff.md
git commit -m "docs: deleting-mod reveal live via channel.moderate v2 — sync comments + dogfood"
```

---

## Self-review notes (already applied)

- Spec coverage: auth scopes (T3), store gate (T4b), service sub +
  dispatch (T2), DTO + fixtures (T1), store merge (T4f), error/degrade
  handling (T2 test 3 + best-effort policy), tests (all tasks), docs (T5).
- Type consistency: `onModerationDelete` is `void Function(String
  messageId, String moderatorName)` on the service; the store factory
  names it `actorName` — same type, position 5 of 7 everywhere.
- `includeModeration` defaults to `false`, so all pre-existing service
  tests keep passing unchanged.
- No pending-actor map: the moderate event is a tombstone superset, both
  orderings converge idempotently (tested in T4 Step 1).
