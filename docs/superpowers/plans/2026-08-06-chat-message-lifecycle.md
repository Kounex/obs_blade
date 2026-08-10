# Chat Message Lifecycle (deletions + pause indicator) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tombstone deleted messages in native Twitch chat (single delete, timeout/ban purge, `/clear` + banner) and make the scroll-up pause state an explicit chip.

**Architecture:** The EventSub service subscribes to four types (message + three lifecycle types, same `user:read:chat` scope/condition); lifecycle events become store-owned plain containers (`_deletedMessageIds`, `systemNotices`) with a `lifecycleVersion` rebuild counter; the row gets an `isDeleted` tombstone branch; the window merges messages+notices by arrival sequence and restyles its pill into a two-state pause/unread chip.

**Tech Stack:** Flutter, MobX, freezed (fromJson only), GetIt, Hive CE (settings only — no schema changes), flutter_test.

**Spec:** `docs/superpowers/specs/2026-08-06-chat-message-lifecycle-design.md`

## Global Constraints

- Copy, verbatim: tombstone `<message deleted>` (italic, dimmed; username +
  badges kept); `/clear` banner `Chat was cleared by a moderator` (centered
  divider row); chip `New messages ↓` (unread, accent) / `Paused ↓` (idle,
  dim).
- `channel.chat.message` subscription stays **mandatory** (POST failure →
  `onRevoked`, today's semantics). The three lifecycle types are
  **best-effort**: POST failure → `advLog` + degrade (no tombstones this
  session), never block chat, never `onRevoked`. Lifecycle **revocations**
  are logged, never surfaced.
- No new Twitch scopes (all three lifecycle types ride `user:read:chat`);
  no auth-flow changes.
- **No persistence changes:** no Hive boxes/TypeIDs/adapters. All lifecycle
  state is in-memory session state, wiped on logout/session reset.
- `/clear` on an empty chat is a full no-op (no tombstones, no banner).
- Matching keys: single delete by `messageId`; user purge by
  `chatterUserId == targetUserId`. All three store actions are idempotent
  and ignore events for unknown/evicted ids.
- Reactivity pattern: lifecycle containers are **plain** (not Observable*)
  because rows render inside the window's HiveBuilder (untracked by the
  outer Observer); a public `@observable int lifecycleVersion` is the
  rebuild trigger — the established `catalogVersion` pattern.
- Flutter commands: `bash flutterw …`.
  Gates per task: focused tests green; full suite green before commit;
  analyze 0 errors + exactly 6 pre-existing warnings (no new ones).
  Info-level lints are tolerated (the `(_, __, …)` factory idiom adds some
  `unnecessary_underscores` infos — accepted class).
- Commit per task (`git add`/`git commit` only — **never push**).
- Codegen after Tasks 1 and 2:
  `bash flutterw pub run build_runner build --delete-conflicting-outputs`

---

### Task 1: Lifecycle DTOs + ChatSystemNotice + fixtures

**Files:**
- Create: `lib/types/classes/twitch/eventsub/chat_lifecycle_events.dart`
- Create: `lib/types/classes/twitch/chat_system_notice.dart`
- Create: `test/chat/fixtures/twitch/channel_chat_message_delete.json`
- Create: `test/chat/fixtures/twitch/channel_chat_clear_user_messages.json`
- Create: `test/chat/fixtures/twitch/channel_chat_clear.json`
- Test: `test/chat/twitch_lifecycle_dto_test.dart`

**Interfaces:**
- Consumes: nothing (first task).
- Produces:
  - `ChatMessageDeleteEvent({required String messageId, required String targetUserId})` + `.fromJson`
  - `ChatClearUserMessagesEvent({required String targetUserId})` + `.fromJson`
  - `ChatClearEvent({required String broadcasterUserId})` + `.fromJson`
  - `enum ChatSystemNoticeKind { chatCleared }`
  - `ChatSystemNotice({required int afterSeq, required ChatSystemNoticeKind kind})` — plain class, no codegen.

- [x] **Step 1: Write the failing test**

Create `test/chat/twitch_lifecycle_dto_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';

Map<String, Object?> fixture(String name) =>
    json.decode(File('test/chat/fixtures/twitch/$name.json').readAsStringSync())
        as Map<String, Object?>;

void main() {
  group('lifecycle event DTOs', () {
    test('message_delete parses the documented example payload', () {
      final event = ChatMessageDeleteEvent.fromJson(
          fixture('channel_chat_message_delete'));
      expect(event.messageId, 'e860a7a5-58d3-4959-9c5f-0f4dc9b5b0a2');
      expect(event.targetUserId, '7734');
    });

    test('clear_user_messages parses the documented example payload', () {
      final event = ChatClearUserMessagesEvent.fromJson(
          fixture('channel_chat_clear_user_messages'));
      expect(event.targetUserId, '7734');
    });

    test('clear parses the documented example payload', () {
      final event = ChatClearEvent.fromJson(fixture('channel_chat_clear'));
      expect(event.broadcasterUserId, '1337');
    });

    test('message_delete without message_id throws', () {
      expect(
        () => ChatMessageDeleteEvent.fromJson(const {'target_user_id': '1'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('clear_user_messages without target_user_id throws', () {
      expect(
        () => ChatClearUserMessagesEvent.fromJson(const {}),
        throwsA(isA<TypeError>()),
      );
    });

    test('clear without broadcaster_user_id throws', () {
      expect(
        () => ChatClearEvent.fromJson(const {}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
```

- [x] **Step 2: Write the fixtures**

`test/chat/fixtures/twitch/channel_chat_message_delete.json` (Twitch docs
example shape for `channel.chat.message_delete`):

```json
{
  "broadcaster_user_id": "1337",
  "broadcaster_user_name": "Cool_User",
  "broadcaster_user_login": "cool_user",
  "target_user_id": "7734",
  "target_user_name": "Uncool_viewer",
  "target_user_login": "uncool_viewer",
  "message_id": "e860a7a5-58d3-4959-9c5f-0f4dc9b5b0a2"
}
```

`test/chat/fixtures/twitch/channel_chat_clear_user_messages.json` (verbatim
from the Twitch docs example):

```json
{
  "broadcaster_user_id": "1337",
  "broadcaster_user_name": "Cool_User",
  "broadcaster_user_login": "cool_user",
  "target_user_id": "7734",
  "target_user_name": "Uncool_viewer",
  "target_user_login": "uncool_viewer"
}
```

`test/chat/fixtures/twitch/channel_chat_clear.json` (verbatim from the
Twitch docs example):

```json
{
  "broadcaster_user_id": "1337",
  "broadcaster_user_name": "Cool_User",
  "broadcaster_user_login": "cool_user"
}
```

- [x] **Step 3: Run the test to verify it fails**

Run: `bash flutterw test test/chat/twitch_lifecycle_dto_test.dart`
Expected: FAIL — compile error, `chat_lifecycle_events.dart` does not exist.

- [x] **Step 4: Write the DTOs**

Create `lib/types/classes/twitch/eventsub/chat_lifecycle_events.dart`
(mirrors `channel_chat_message.dart`'s freezed-3 form exactly):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_lifecycle_events.freezed.dart';
part 'chat_lifecycle_events.g.dart';

/// `channel.chat.message_delete` event — a moderator removed one message.
/// Display fields in the payload are deliberately not modeled (nothing
/// consumes them).
@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageDeleteEvent with _$ChatMessageDeleteEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatMessageDeleteEvent({
    required String messageId,
    required String targetUserId,
  }) = _ChatMessageDeleteEvent;

  factory ChatMessageDeleteEvent.fromJson(Map<String, Object?> json) =>
      _$ChatMessageDeleteEventFromJson(json);
}

/// `channel.chat.clear_user_messages` event — a moderator/bot cleared all
/// messages from a specific user (timeout/ban purge).
@Freezed(fromJson: true, toJson: false)
abstract class ChatClearUserMessagesEvent with _$ChatClearUserMessagesEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatClearUserMessagesEvent({
    required String targetUserId,
  }) = _ChatClearUserMessagesEvent;

  factory ChatClearUserMessagesEvent.fromJson(Map<String, Object?> json) =>
      _$ChatClearUserMessagesEventFromJson(json);
}

/// `channel.chat.clear` event — a moderator/bot cleared the whole chat
/// room. The payload carries only broadcaster ids.
@Freezed(fromJson: true, toJson: false)
abstract class ChatClearEvent with _$ChatClearEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatClearEvent({
    required String broadcasterUserId,
  }) = _ChatClearEvent;

  factory ChatClearEvent.fromJson(Map<String, Object?> json) =>
      _$ChatClearEventFromJson(json);
}
```

Create `lib/types/classes/twitch/chat_system_notice.dart`:

```dart
/// Kind of system banner merged into the native chat scroll. One kind so
/// far: the whole chat was cleared by a moderator (`/clear`).
enum ChatSystemNoticeKind { chatCleared }

/// System banner in the native chat scroll — NOT a wire DTO (no JSON).
/// Merged into the message list by arrival sequence: the notice sorts
/// after every message whose seq is <= [afterSeq].
class ChatSystemNotice {
  /// Arrival seq of the last message this notice sorts after.
  final int afterSeq;
  final ChatSystemNoticeKind kind;

  const ChatSystemNotice({required this.afterSeq, required this.kind});
}
```

- [x] **Step 5: Codegen + run the test to verify it passes**

```bash
bash flutterw pub run build_runner build --delete-conflicting-outputs
bash flutterw test test/chat/twitch_lifecycle_dto_test.dart
```

Expected: PASS (6/6).

- [x] **Step 6: Commit**

```bash
git add lib/types/classes/twitch/eventsub/chat_lifecycle_events.dart \
  lib/types/classes/twitch/eventsub/chat_lifecycle_events.freezed.dart \
  lib/types/classes/twitch/eventsub/chat_lifecycle_events.g.dart \
  lib/types/classes/twitch/chat_system_notice.dart \
  test/chat/fixtures/twitch/channel_chat_message_delete.json \
  test/chat/fixtures/twitch/channel_chat_clear_user_messages.json \
  test/chat/fixtures/twitch/channel_chat_clear.json \
  test/chat/twitch_lifecycle_dto_test.dart
git commit -m "feat(chat): lifecycle event DTOs + ChatSystemNotice"
```

---

### Task 2: Store lifecycle state + actions + merge

**Files:**
- Modify: `lib/stores/views/twitch_chat.dart`
- Test: `test/chat/twitch_chat_store_test.dart`

**Interfaces:**
- Consumes: Task 1's DTOs/`ChatSystemNotice` (import only — actions take
  primitives).
- Produces (Task 4 wires them; Task 6 renders them):
  - `@observable int lifecycleVersion`
  - `List<ChatSystemNotice> systemNotices` (plain)
  - `bool isMessageDeleted(String messageId)` (plain read)
  - `List<Object> messagesWithNotices()` — entries are `ChatMessageEvent` or
    `ChatSystemNotice`, arrival order
  - `@action void applyMessageDelete(String messageId)`
  - `@action void applyClearUserMessages(String targetUserId)`
  - `@action void applyChatClear()`

- [x] **Step 1: Write the failing tests**

In `test/chat/twitch_chat_store_test.dart`, add this top-level helper above
`void main()`:

```dart
ChatMessageEvent chatMessage(String id, String chatterId) => ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: chatterId,
      chatterUserLogin: 'user$chatterId',
      chatterUserName: 'User$chatterId',
      messageId: id,
      message: ChatMessageText(
        text: 'text $id',
        fragments: [ChatMessageFragment(type: 'text', text: 'text $id')],
      ),
    );
```

Add the import for the notice type at the top of the file (alphabetical —
`chat_system_notice.dart` sorts before the `eventsub/` imports):

```dart
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
```

Add a new group at the end of `main()`:

```dart
  group('lifecycle', () {
    test('deleting a visible message tombstones it and bumps the version', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      final version = store.lifecycleVersion;

      store.applyMessageDelete('m1');

      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.lifecycleVersion, version + 1);
    });

    test('deleting an unknown id is a no-op', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      final version = store.lifecycleVersion;

      store.applyMessageDelete('nope');

      expect(store.isMessageDeleted('nope'), isFalse);
      expect(store.lifecycleVersion, version);
    });

    test('user purge tombstones only that user and is idempotent', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u2'));
      store.appendChatMessageForTest(chatMessage('m3', 'u2'));

      store.applyClearUserMessages('u2');

      expect(store.isMessageDeleted('m1'), isFalse);
      expect(store.isMessageDeleted('m2'), isTrue);
      expect(store.isMessageDeleted('m3'), isTrue);
      final version = store.lifecycleVersion;

      store.applyClearUserMessages('u2');
      expect(store.lifecycleVersion, version);
    });

    test('chat clear tombstones everything and banners between old and new', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u2'));

      store.applyChatClear();

      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.isMessageDeleted('m2'), isTrue);
      expect(store.systemNotices.single.kind, ChatSystemNoticeKind.chatCleared);

      store.appendChatMessageForTest(chatMessage('m3', 'u1'));
      final items = store.messagesWithNotices();
      expect(items, hasLength(4));
      expect(items[0], isA<ChatMessageEvent>());
      expect(items[1], isA<ChatMessageEvent>());
      expect(items[2], isA<ChatSystemNotice>());
      expect(items[3], isA<ChatMessageEvent>());
    });

    test('chat clear on an empty chat is a full no-op', () {
      final version = store.lifecycleVersion;

      store.applyChatClear();

      expect(store.systemNotices, isEmpty);
      expect(store.lifecycleVersion, version);
    });

    test('two clears keep banner order in the merged list', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyChatClear();
      store.appendChatMessageForTest(chatMessage('m2', 'u1'));
      store.applyChatClear();

      // runtimeType is the freezed _ChatMessageEvent, so assert with isA.
      final items = store.messagesWithNotices();
      expect(items, hasLength(4));
      expect(items[0], isA<ChatMessageEvent>());
      expect(items[1], isA<ChatSystemNotice>());
      expect(items[2], isA<ChatMessageEvent>());
      expect(items[3], isA<ChatSystemNotice>());
    });

    test('cap eviction prunes the tombstone set', () {
      // kMaxMessages lives on the private _TwitchChatStore — statics don't
      // cross the mixin-application alias, so the cap is literal here (same
      // as the 'message buffer' group above).
      for (var i = 0; i < 500; i++) {
        store.appendChatMessageForTest(chatMessage('m$i', 'u1'));
      }
      store.applyMessageDelete('m0');
      expect(store.isMessageDeleted('m0'), isTrue);

      store.appendChatMessageForTest(chatMessage('m500', 'u1'));

      expect(store.messages, hasLength(500));
      expect(store.isMessageDeleted('m0'), isFalse);
    });

    test('logout clears tombstones, notices and the arrival counter', () async {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyChatClear();
      expect(store.systemNotices, isNotEmpty);

      await store.logout();

      expect(store.isMessageDeleted('m1'), isFalse);
      expect(store.systemNotices, isEmpty);

      /// Arrival seq restarted — the merged list has no stale notices.
      store.appendChatMessageForTest(chatMessage('m2', 'u1'));
      expect(store.messagesWithNotices(), hasLength(1));
    });
  });
```

- [x] **Step 2: Run the tests to verify they fail**

Run: `bash flutterw test test/chat/twitch_chat_store_test.dart`
Expected: FAIL — compile errors (`lifecycleVersion`, `isMessageDeleted`, …
do not exist).

- [x] **Step 3: Implement the store changes**

In `lib/stores/views/twitch_chat.dart`:

a) Add the import (next to the other `types/classes/twitch/` imports):

```dart
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
```

b) Add the fields right after the `messages` declaration
   (`final ObservableList<ChatMessageEvent> messages = …`, ~line 135):

```dart
  /// Ids of visible messages tombstoned by moderation (delete / timeout /
  /// ban / /clear) — plain Set, pruned with the 500-cap. UI reactivity
  /// rides [lifecycleVersion]: rows build inside the window's HiveBuilder
  /// (untracked by the outer Observer), so the version read is the only
  /// rebuild trigger — same pattern as the emote catalogs.
  final Set<String> _deletedMessageIds = <String>{};

  /// System banners merged into the scroll by arrival sequence — plain
  /// List, same [lifecycleVersion] reactivity story as [_deletedMessageIds].
  final List<ChatSystemNotice> systemNotices = <ChatSystemNotice>[];

  /// Bumped on every lifecycle mutation (tombstone / banner) — the
  /// window's tracked rebuild signal for the two plain containers above.
  @observable
  int lifecycleVersion = 0;

  /// Monotonic arrival counter — a message at index i has arrival seq
  /// [_arrivalSeq] - messages.length + i + 1 (front eviction shifts
  /// indices, not seqs). Reset on logout/session wipe.
  int _arrivalSeq = 0;
```

c) In `_appendMessage` (~line 477), count arrivals and prune the tombstone
   set on eviction:

```dart
  @action
  void _appendMessage(ChatMessageEvent event) {
    this.messages.add(event);
    this._arrivalSeq++;
    while (this.messages.length > kMaxMessages) {
      this._deletedMessageIds.remove(this.messages.first.messageId);
      this.messages.removeAt(0);
    }
  }
```

d) Add the API block right after `appendChatMessageForTest` (~line 488):

```dart
  /// Whether [messageId] is tombstoned — plain read (reactivity rides
  /// [lifecycleVersion]).
  bool isMessageDeleted(String messageId) =>
      this._deletedMessageIds.contains(messageId);

  /// Visible messages + system notices in arrival order — the window's
  /// single render source. A notice sorts after every message with
  /// seq <= afterSeq; front eviction drops old seqs naturally.
  List<Object> messagesWithNotices() {
    if (this.systemNotices.isEmpty) return List.of(this.messages);
    final base = this._arrivalSeq - this.messages.length + 1;
    final merged = <Object>[];
    var noticeIndex = 0;
    for (var i = 0; i < this.messages.length; i++) {
      final seq = base + i;
      while (noticeIndex < this.systemNotices.length &&
          this.systemNotices[noticeIndex].afterSeq < seq) {
        merged.add(this.systemNotices[noticeIndex]);
        noticeIndex++;
      }
      merged.add(this.messages[i]);
    }
    while (noticeIndex < this.systemNotices.length) {
      merged.add(this.systemNotices[noticeIndex]);
      noticeIndex++;
    }
    return merged;
  }

  /// Moderation lifecycle — all idempotent; events for unknown/evicted
  /// ids are no-ops. [lifecycleVersion] bumps only on real mutations.
  @action
  void applyMessageDelete(String messageId) {
    final visible =
        this.messages.any((message) => message.messageId == messageId);
    if (visible && this._deletedMessageIds.add(messageId)) {
      this.lifecycleVersion++;
    }
  }

  @action
  void applyClearUserMessages(String targetUserId) {
    var changed = false;
    for (final message in this.messages) {
      if (message.chatterUserId == targetUserId &&
          this._deletedMessageIds.add(message.messageId)) {
        changed = true;
      }
    }
    if (changed) this.lifecycleVersion++;
  }

  /// `/clear` on an empty chat is a full no-op — nothing was deleted, so
  /// nothing is marked (and the window's empty-states stay correct).
  @action
  void applyChatClear() {
    if (this.messages.isEmpty) return;
    for (final message in this.messages) {
      this._deletedMessageIds.add(message.messageId);
    }
    this.systemNotices.add(
      ChatSystemNotice(
        afterSeq: this._arrivalSeq,
        kind: ChatSystemNoticeKind.chatCleared,
      ),
    );
    this.lifecycleVersion++;
  }

  /// Lifecycle wipe shared by logout and external session resets.
  void _clearLifecycle() {
    this._deletedMessageIds.clear();
    this.systemNotices.clear();
    this._arrivalSeq = 0;
  }
```

e) Wire the wipe into both clear sites. In `logout()` the line
   `this.messages.clear();` (~line 271) becomes:

```dart
      this.messages.clear();
      this._clearLifecycle();
```

   In `_resetToLoggedOut()` (~line 538) inside the `runInAction`:

```dart
    runInAction(() {
      this.messages.clear();
      this._clearLifecycle();
      this.user = null;
      this.authState = TwitchAuthState.loggedOut;
    });
```

- [x] **Step 4: Codegen + run the tests to verify they pass**

```bash
bash flutterw pub run build_runner build --delete-conflicting-outputs
bash flutterw test test/chat/twitch_chat_store_test.dart
```

Expected: PASS (all existing + 8 new). Then the full suite once:

```bash
bash flutterw test
```

Expected: all PASS.

- [x] **Step 5: Commit**

```bash
git add lib/stores/views/twitch_chat.dart lib/stores/views/twitch_chat.g.dart test/chat/twitch_chat_store_test.dart
git commit -m "feat(chat): store lifecycle state — tombstone set, notices, merge, actions"
```

---

### Task 3: EventSub service — four subscriptions + dispatch + revocation split

**Files:**
- Modify: `lib/utils/twitch/twitch_eventsub_service.dart`
- Test: `test/chat/twitch_eventsub_service_test.dart`

**Interfaces:**
- Consumes: Task 1's DTOs.
- Produces (Task 4 wires):
  - New optional constructor params: `void Function(ChatMessageDeleteEvent)? onMessageDelete`, `void Function(ChatClearUserMessagesEvent)? onClearUserMessages`, `void Function(ChatClearEvent)? onChatClear` — all nullable, all default null (existing constructions keep compiling).
  - `_subscriptionId` (single) becomes `_subscriptionIds` (list) — private, no consumer change.
  - Behavior: 4 sequential subscription POSTs on a fresh session (message first = mandatory; lifecycle = best-effort); notification dispatch routes all four types; revocations of lifecycle types are logged, not forwarded.

- [x] **Step 1: Update the existing tests + write the failing new tests**

In `test/chat/twitch_eventsub_service_test.dart`:

a) Add to the `late` declarations at the top of `main()`:

```dart
  late List<ChatMessageDeleteEvent> deletes;
  late List<ChatClearUserMessagesEvent> purges;
  late List<ChatClearEvent> clears;
```

   and to `setUp`:

```dart
    deletes = [];
    purges = [];
    clears = [];
```

   plus the import:

```dart
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
```

b) Add a second builder next to `serviceWith`:

```dart
  TwitchEventSubService lifecycleServiceWith(MockClient client) =>
      TwitchEventSubService(
        onChatMessage: messages.add,
        onMessageDelete: deletes.add,
        onClearUserMessages: purges.add,
        onChatClear: clears.add,
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

c) Replace the test `'welcome triggers a subscription with the session id'`
   with:

```dart
  test('welcome subscribes to message + lifecycle types with the session id',
      () async {
    final bodies = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer token-1');
      expect(request.headers['Client-Id'], kTwitchClientId);
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
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(states, contains(TwitchEventSubState.connected));
    expect(bodies.map((body) => body['type']), [
      'channel.chat.message',
      'channel.chat.message_delete',
      'channel.chat.clear_user_messages',
      'channel.chat.clear',
    ]);
    for (final body in bodies) {
      expect(body['version'], '1');
      expect(body['condition'], {
        'broadcaster_user_id': 'user-1',
        'user_id': 'user-1',
      });
      expect(body['transport'], {
        'method': 'websocket',
        'session_id': 'session-1',
      });
    }
  });
```

d) In `'session_reconnect opens a new socket at the reconnect url without
   resubscribing'`, the two `expect(subscriptionPosts, 1);` become
   `expect(subscriptionPosts, 4);`.

e) Replace the test `'dispose deletes the subscription best-effort'` with:

```dart
  test('dispose deletes every created subscription best-effort', () async {
    final deletedUrls = <String>[];
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'DELETE') {
        deletedUrls.add(request.url.toString());
        return http.Response('', 204);
      }
      posts++;
      return http.Response(
          json.encode({
            'data': [
              {'id': 'sub-$posts'}
            ],
          }),
          202);
    });

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    await service.dispose();
    expect(deletedUrls, [
      'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-1',
      'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-2',
      'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-3',
      'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-4',
    ]);
  });
```

f) Add the new tests at the end of `main()`:

```dart
  test('lifecycle notifications dispatch to their callbacks', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = lifecycleServiceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    String lifecycleNotification(String type, Map<String, Object?> event) =>
        json.encode({
          'metadata': {
            'message_id': 'n-$type',
            'message_type': 'notification',
            'message_timestamp': '2026-08-06T10:00:00.000Z',
            'subscription_type': type,
            'subscription_version': '1',
          },
          'payload': {
            'subscription': {'type': type},
            'event': event,
          },
        });

    channels.single.incoming
        .add(lifecycleNotification('channel.chat.message_delete', {
      'broadcaster_user_id': 'b1',
      'target_user_id': 'u2',
      'message_id': 'm-9',
    }));
    channels.single.incoming
        .add(lifecycleNotification('channel.chat.clear_user_messages', {
      'broadcaster_user_id': 'b1',
      'target_user_id': 'u2',
    }));
    channels.single.incoming.add(lifecycleNotification('channel.chat.clear', {
      'broadcaster_user_id': 'b1',
    }));
    await pumpEventQueue();

    expect(deletes.single.messageId, 'm-9');
    expect(deletes.single.targetUserId, 'u2');
    expect(purges.single.targetUserId, 'u2');
    expect(clears.single.broadcasterUserId, 'b1');
    expect(messages, isEmpty);
  });

  test('a failing lifecycle POST degrades tombstones, not chat', () async {
    var posts = 0;
    final client = MockClient((request) async {
      posts++;
      if (posts == 2) return http.Response('Forbidden', 403);
      return http.Response(
          json.encode({
            'data': [
              {'id': 'sub-$posts'}
            ],
          }),
          202);
    });

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(posts, 4);
    expect(revocations, isEmpty);
    expect(states, contains(TwitchEventSubState.connected));
  });

  test('a lifecycle revocation is logged, not surfaced', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();
    channels.single.incoming.add(json.encode({
      'metadata': {
        'message_id': 'v1',
        'message_type': 'revocation',
        'message_timestamp': '2026-08-06T10:00:00.000Z',
        'subscription_type': 'channel.chat.clear',
        'subscription_version': '1',
      },
      'payload': {
        'subscription': {
          'type': 'channel.chat.clear',
          'status': 'authorization_revoked',
        },
      },
    }));
    await pumpEventQueue();

    expect(revocations, isEmpty);
  });
```

   (The existing `'revocation is forwarded with its status'` test keeps
   passing: its payload carries no `type`, and the no-type case keeps the
   message-revocation semantics. The `'subscription POST throwing routes to
   onRevoked'` test also stands — the message POST is first and mandatory.)

- [x] **Step 2: Run the tests to verify the new/changed ones fail**

Run: `bash flutterw test test/chat/twitch_eventsub_service_test.dart`
Expected: FAIL — compile errors (`onMessageDelete` etc. don't exist) and/or
behavioral failures (only 1 POST, single dispose DELETE).

- [x] **Step 3: Implement the service changes**

In `lib/utils/twitch/twitch_eventsub_service.dart`:

a) Add the import:

```dart
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
```

b) Replace the class doc + add the subscription-type constants (after the
   existing `_maxBackoff` constant):

```dart
/// Subscription types created on a fresh session, in POST order.
/// `channel.chat.message` is mandatory — a failure routes to [onRevoked].
/// The three lifecycle types are best-effort: failures are logged and
/// degrade tombstones, never chat.
static const List<String> _kSubscriptionTypes = <String>[
  'channel.chat.message',
  'channel.chat.message_delete',
  'channel.chat.clear_user_messages',
  'channel.chat.clear',
];
static const String _kMessageType = 'channel.chat.message';
```

   Also update the class doc comment from ``Dedicated EventSub WebSocket
   session for `channel.chat.message`.`` to:

```dart
/// Dedicated EventSub WebSocket session for chat messages + moderation
/// lifecycle events (`message_delete`, `clear_user_messages`, `clear`).
/// Completely separate from the OBS WebSocket — owns its socket, keepalive
/// watchdog and reconnect backoff. [channelFactory] and [sleep] are
/// injectable for tests.
```

c) Add the new callbacks after `onChatMessage`:

```dart
  /// Lifecycle callbacks — optional; a null callback skips parsing for
  /// that type (tests / non-lifecycle consumers).
  final void Function(ChatMessageDeleteEvent event)? onMessageDelete;
  final void Function(ChatClearUserMessagesEvent event)?
      onClearUserMessages;
  final void Function(ChatClearEvent event)? onChatClear;
```

   and to the constructor signature:

```dart
  TwitchEventSubService({
    required this.onChatMessage,
    this.onMessageDelete,
    this.onClearUserMessages,
    this.onChatClear,
    required this.onStateChanged,
    required this.onRevoked,
    http.Client? client,
    WebSocketChannel Function(Uri)? channelFactory,
    Future<void> Function(Duration)? sleep,
  })  : _client = client ?? http.Client(),
        _channelFactory = channelFactory ?? WebSocketChannel.connect,
        _sleep = sleep ?? Future.delayed;
```

d) Replace `String? _subscriptionId;` with:

```dart
  /// Ids created on the current session (message + whichever lifecycle
  /// subscriptions succeeded) — resume check + best-effort cleanup.
  List<String> _subscriptionIds = <String>[];
```

e) In `_handleWelcome`, the resumed check + subscribe call become:

```dart
    final resumed =
        sessionId == this._sessionId && this._subscriptionIds.isNotEmpty;
    this._sessionId = sessionId;
    this._reconnectAttempts = 0;
    this.onStateChanged(TwitchEventSubState.connected);

    /// A socket opened from `session_reconnect`'s reconnect_url resumes the
    /// session with subscriptions intact — only subscribe on fresh sessions.
    if (!resumed) {
      await this._createSubscriptions();
    }
```

f) Replace the whole `_handleNotification` method with:

```dart
  void _handleNotification(EventSubEnvelope envelope) {
    final type = envelope.metadata.subscriptionType;
    try {
      switch (type) {
        case 'channel.chat.message':
          this.onChatMessage(
            ChatMessageEvent.fromJson(
              envelope.payload['event'] as Map<String, Object?>,
            ),
          );
        case 'channel.chat.message_delete':
          final callback = this.onMessageDelete;
          if (callback != null) {
            callback(
              ChatMessageDeleteEvent.fromJson(
                envelope.payload['event'] as Map<String, Object?>,
              ),
            );
          }
        case 'channel.chat.clear_user_messages':
          final callback = this.onClearUserMessages;
          if (callback != null) {
            callback(
              ChatClearUserMessagesEvent.fromJson(
                envelope.payload['event'] as Map<String, Object?>,
              ),
            );
          }
        case 'channel.chat.clear':
          final callback = this.onChatClear;
          if (callback != null) {
            callback(
              ChatClearEvent.fromJson(
                envelope.payload['event'] as Map<String, Object?>,
              ),
            );
          }
      }
    } catch (e) {
      GeneralHelper.advLog('Twitch EventSub: could not parse $type event — $e');
    }
  }
```

   (Unknown types fall through the switch silently — today's early-return
   behavior for unhandled types.)

g) Replace the whole `_handleRevocation` method with:

```dart
  void _handleRevocation(Map<String, Object?> payload) {
    final subscription = payload['subscription'] as Map<String, dynamic>;
    final type = subscription['type'] as String?;
    if (type == null || type == _kMessageType) {
      /// A missing type is treated as the message subscription — the only
      /// one whose loss kills chat.
      this.onRevoked(subscription['status'] as String? ?? 'revoked');
    } else {
      GeneralHelper.advLog(
        'Twitch EventSub: lifecycle subscription $type revoked '
        '(${subscription['status']}) — tombstones degraded this session',
      );
    }
  }
```

h) Replace the whole `_createSubscription` method with:

```dart
  Future<void> _createSubscriptions() async {
    final token = this._accessToken;
    final userId = this._userId;
    final sessionId = this._sessionId;
    if (token == null || userId == null || sessionId == null) return;

    final created = <String>[];
    for (final type in _kSubscriptionTypes) {
      final mandatory = type == _kMessageType;

      /// The socket-level failure path (DNS/socket/timeout) must not
      /// escape this unawaited future — surface it like a failed
      /// subscription.
      try {
        final response = await this._client.post(
          Uri.parse(_subscriptionsUrl),
          headers: {
            ...TwitchAuthService.helixHeaders(token),
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'type': type,
            'version': '1',
            'condition': {'broadcaster_user_id': userId, 'user_id': userId},
            'transport': {'method': 'websocket', 'session_id': sessionId},
          }),
        );

        if (response.statusCode == 202) {
          final data =
              (json.decode(response.body) as Map<String, dynamic>)['data'];
          final id = (data as List).first['id'] as String?;
          if (id != null) created.add(id);
        } else if (mandatory) {
          this.onRevoked('subscription_failed:${response.statusCode}');
          return;
        } else {
          GeneralHelper.advLog(
            'Twitch EventSub: lifecycle subscription $type failed '
            '(${response.statusCode}) — tombstones degraded this session',
          );
        }
      } catch (e) {
        if (mandatory) {
          GeneralHelper.advLog(
              'Twitch EventSub: subscription POST failed — $e');
          this.onRevoked('subscription_failed:$e');
          return;
        }
        GeneralHelper.advLog(
          'Twitch EventSub: lifecycle subscription $type failed — $e',
        );
      }
    }
    this._subscriptionIds = created;
  }
```

i) Replace the `dispose` method's subscription cleanup with:

```dart
  /// Tear down the session. Deleting the subscriptions is best effort —
  /// Twitch drops them anyway once the session times out.
  Future<void> dispose() async {
    this._disposed = true;
    this._closeSocket();

    final subscriptionIds = List<String>.of(this._subscriptionIds);
    final token = this._accessToken;
    this._subscriptionIds = <String>[];
    if (token != null) {
      for (final id in subscriptionIds) {
        try {
          await this._client.delete(
            Uri.parse('$_subscriptionsUrl?id=$id'),
            headers: TwitchAuthService.helixHeaders(token),
          );
        } catch (_) {
          // best effort
        }
      }
    }
  }
```

- [x] **Step 4: Run the tests to verify they pass**

```bash
bash flutterw test test/chat/twitch_eventsub_service_test.dart
bash flutterw test
```

Expected: service suite PASS (7 existing-updated + 3 new), full suite PASS
(the new constructor params are optional, so nothing else breaks).

- [x] **Step 5: Commit**

```bash
git add lib/utils/twitch/twitch_eventsub_service.dart test/chat/twitch_eventsub_service_test.dart
git commit -m "feat(chat): EventSub lifecycle subscriptions + dispatch + revocation split"
```

---

### Task 4: Store ↔ service wiring

**Files:**
- Modify: `lib/stores/views/twitch_chat.dart`
- Test: `test/chat/twitch_chat_store_test.dart`
- Modify (mechanical, suite stays green): `test/chat/native_twitch_chat_view_test.dart`, `test/chat/twitch_chat_integration_test.dart`

**Interfaces:**
- Consumes: Task 2's actions, Task 3's optional callbacks.
- Produces: the live path — EventSub lifecycle notifications drive the
  store's tombstone/banner actions.

- [x] **Step 1: Write the failing wiring test**

In `test/chat/twitch_chat_store_test.dart`, add the import:

```dart
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
```

Add a new group at the end of `main()`:

```dart
  group('lifecycle wiring', () {
    late void Function(ChatMessageDeleteEvent) emitDelete;
    late void Function(ChatClearUserMessagesEvent) emitPurge;
    late void Function(ChatClearEvent) emitClear;

    /// A fresh store whose factory captures the lifecycle callbacks the
    /// store hands to its EventSub service (chatConnectedAt-group pattern).
    Future<void> loginWithCapturedCallbacks() async {
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory: (onChatMessage, onMessageDelete,
            onClearUserMessages, onChatClear, onStateChanged, onRevoked) {
          emitDelete = onMessageDelete;
          emitPurge = onClearUserMessages;
          emitClear = onChatClear;
          return eventSubService;
        },
        badgeStoreResolver: () => badgeStore,
      );
      await store.startLogin();
    }

    test('EventSub lifecycle callbacks drive the store actions', () async {
      await loginWithCapturedCallbacks();
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u2'));

      emitDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1'));
      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.isMessageDeleted('m2'), isFalse);

      emitPurge(const ChatClearUserMessagesEvent(targetUserId: 'u2'));
      expect(store.isMessageDeleted('m2'), isTrue);

      emitClear(const ChatClearEvent(broadcasterUserId: 'b1'));
      expect(store.systemNotices, hasLength(1));
    });
  });
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash flutterw test test/chat/twitch_chat_store_test.dart`
Expected: FAIL — compile error (the factory closure has 6 params, the
store's typedef has 3).

- [x] **Step 3: Extend the factory signature + wire the construction site**

In `lib/stores/views/twitch_chat.dart`:

a) Add the import:

```dart
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
```

b) The `_eventSubFactory` field type (~line 49) becomes:

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

c) The constructor param type (~line 69) becomes:

```dart
    TwitchEventSubService Function(
      void Function(ChatMessageEvent),
      void Function(ChatMessageDeleteEvent),
      void Function(ChatClearUserMessagesEvent),
      void Function(ChatClearEvent),
      void Function(TwitchEventSubState),
      void Function(String),
    )? eventSubFactory,
```

d) The default closure (~line 79) becomes:

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

e) The construction site in `connectChat` (~line 306) becomes:

```dart
      this._eventSub = this._eventSubFactory(
        this._appendMessage,
        (event) => this.applyMessageDelete(event.messageId),
        (event) => this.applyClearUserMessages(event.targetUserId),
        (_) => this.applyChatClear(),
        this._onEventSubState,
        this._onEventSubRevoked,
      );
```

- [x] **Step 4: Update the remaining factory call sites (mechanical)**

All `(_, __, ___) =>` discards become `(_, __, ___, ____, _____, ______) =>`
(adds info-level `unnecessary_underscores` lints — accepted idiom class):

- `test/chat/twitch_chat_store_test.dart` — setUp (`eventSubFactory: (_, __, ___) => eventSubService`), the `sendChatMessage` group's `login`, and the two other discard sites (~lines 45, 497, 631, 687).
- `test/chat/twitch_chat_store_test.dart` — the `chatConnectedAt` group's `loginWithCapturedCallbacks` factory becomes:

```dart
        eventSubFactory:
            (_, __, ___, ____, onStateChanged, onRevoked) {
          emitState = onStateChanged;
          emitRevoked = onRevoked;
          return eventSubService;
        },
```

- `test/chat/native_twitch_chat_view_test.dart` — setUp's `eventSubFactory: (_, __, ___) => FakeTwitchEventSubService(),`.
- `test/chat/twitch_chat_integration_test.dart` — the `eventSubFactory: (_, __, ___) => FakeTwitchEventSubService(),` site.

- [x] **Step 5: Run the tests to verify they pass**

```bash
bash flutterw test test/chat/
bash flutterw test
bash flutterw analyze
```

Expected: all PASS; analyze 0 errors + exactly 6 pre-existing warnings.

- [x] **Step 6: Commit**

```bash
git add lib/stores/views/twitch_chat.dart test/chat/twitch_chat_store_test.dart test/chat/native_twitch_chat_view_test.dart test/chat/twitch_chat_integration_test.dart
git commit -m "feat(chat): wire EventSub lifecycle events into the store"
```

---

### Task 5: Row tombstone branch

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`
- Test: `test/chat/native_twitch_chat_view_test.dart` (existing `TwitchChatMessageRow` group)

**Interfaces:**
- Consumes: nothing from earlier tasks (plain bool param).
- Produces: `TwitchChatMessageRow({required event, required settingsBox, bool isDeleted = false})` — Task 6 passes `isDeleted`.

- [x] **Step 1: Write the failing test**

In `test/chat/native_twitch_chat_view_test.dart`, add to the
`TwitchChatMessageRow` group:

```dart
    testWidgets('a deleted message keeps the author, tombstones the body',
        (tester) async {
      final event = ChatMessageEvent(
        broadcasterUserId: 'b1',
        chatterUserId: '1',
        chatterUserLogin: 'emoter',
        chatterUserName: 'Emoter',
        messageId: '1',
        message: ChatMessageText(
          text: 'Hello Kappa',
          fragments: [
            ChatMessageFragment(type: 'text', text: 'Hello '),
            ChatMessageFragment(
              type: 'emote',
              text: 'Kappa',
              emote: ChatFragmentEmote(id: '25'),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: event,
          settingsBox: Hive.box(HiveKeys.Settings.name),
          isDeleted: true,
        )),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));

      /// Emote parsing is skipped — no inline image spans.
      expect(richText.text.toPlainText(), 'Emoter: <message deleted>');
      expect(collectWidgetSpans(richText.text), isEmpty);
    });
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash flutterw test test/chat/native_twitch_chat_view_test.dart`
Expected: FAIL — compile error (`isDeleted` isn't a parameter).

- [x] **Step 3: Implement the tombstone branch**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`:

a) Add the field + constructor param:

```dart
  /// Moderation tombstone — username/badges stay, the body collapses to
  /// `<message deleted>` (set by the window from the store's lifecycle
  /// state).
  final bool isDeleted;

  const TwitchChatMessageRow({
    super.key,
    required this.event,
    required this.settingsBox,
    this.isDeleted = false,
  });
```

b) In `_richText`, replace the tail of the span list (`const TextSpan(text: ': '), ...this._messageSpans(),`) with:

```dart
            const TextSpan(text: ': '),
            if (this.isDeleted)
              TextSpan(
                text: '<message deleted>',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              )
            else
              ...this._messageSpans(),
```

- [x] **Step 4: Run the tests to verify they pass**

```bash
bash flutterw test test/chat/native_twitch_chat_view_test.dart
bash flutterw test
```

Expected: PASS (existing rows unchanged — `isDeleted` defaults false).

- [x] **Step 5: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart test/chat/native_twitch_chat_view_test.dart
git commit -m "feat(chat): tombstone branch in the native message row"
```

---

### Task 6: Window — merged list + pause chip

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart`
- Test: `test/chat/native_twitch_chat_view_test.dart` (existing `NativeTwitchChatView` group)

**Interfaces:**
- Consumes: Task 2's `lifecycleVersion`/`systemNotices`/`isMessageDeleted`/`messagesWithNotices`, Task 5's `isDeleted`.
- Produces: the shipped UX — tombstones + banner in the scroll, two-state pause chip.

- [x] **Step 1: Write the failing tests**

In `test/chat/native_twitch_chat_view_test.dart`, add to the
`NativeTwitchChatView` group:

```dart
    testWidgets('/clear tombstones the rows and banners between old and new',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.appendChatMessageForTest(textEvent('1', 'Viewer32', 'Hi chat'));
      store.appendChatMessageForTest(textEvent('2', 'Emoter', 'Hello Kappa'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();

      store.applyChatClear();
      await tester.pump();

      expect(find.text('Chat was cleared by a moderator'), findsOneWidget);
      final texts = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((richText) => richText.text.toPlainText());
      expect(
        texts,
        containsAll(<String>[
          'Viewer32: <message deleted>',
          'Emoter: <message deleted>',
        ]),
      );

      /// The banner sorts after the cleared rows, before newer ones.
      store.appendChatMessageForTest(textEvent('3', 'Viewer32', 'fresh'));
      await tester.pump();
      final bannerY = tester
          .getTopLeft(find.text('Chat was cleared by a moderator'))
          .dy;
      final freshY = tester
          .getTopLeft(find.textContaining('fresh', findRichText: true))
          .dy;
      expect(bannerY, lessThan(freshY));
    });

    testWidgets('scrolling up shows the paused chip; tapping it resumes',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      for (var i = 0; i < 50; i++) {
        store.appendChatMessageForTest(textEvent('$i', 'V$i', 'message $i'));
      }

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();
      expect(find.text('Paused ↓'), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pump();
      expect(find.text('Paused ↓'), findsOneWidget);
      expect(find.text('New messages ↓'), findsNothing);

      await tester.tap(find.text('Paused ↓'));
      await tester.pumpAndSettle();
      expect(find.text('Paused ↓'), findsNothing);
    });

    testWidgets('a new message while paused flips the chip to the unread pill',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      for (var i = 0; i < 50; i++) {
        store.appendChatMessageForTest(textEvent('$i', 'V$i', 'message $i'));
      }

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pump();
      expect(find.text('Paused ↓'), findsOneWidget);

      store.appendChatMessageForTest(textEvent('50', 'Late', 'new one'));
      await tester.pump();
      await tester.pump();
      expect(find.text('New messages ↓'), findsOneWidget);
      expect(find.text('Paused ↓'), findsNothing);
    });
```

- [x] **Step 2: Run the tests to verify they fail**

Run: `bash flutterw test test/chat/native_twitch_chat_view_test.dart`
Expected: FAIL — no banner text, no `Paused ↓` chip.

- [x] **Step 3: Implement the window changes**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart`:

a) Add the imports (both — the itemBuilder in (d) switches on `ChatSystemNotice`
   and casts to `ChatMessageEvent`, and Dart imports aren't transitive):

```dart
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
```

b) In the Observer builder, right after the existing
   `// ignore: unused_local_variable` `emoteCatalogVersion` read, add the
   lifecycle twin + compute the merged items:

```dart
        /// Tracked so lifecycle changes (tombstones, /clear banner)
        /// rebuild the list — the merge/membership reads below are
        /// non-reactive plain data, so this version read is their only
        /// rebuild trigger (same pattern as the emote pop-in above).
        // ignore: unused_local_variable
        final lifecycleVersion = this._store.lifecycleVersion;
```

c) Replace the new-frame bookkeeping block (`if (this._pinnedToBottom) { …
   } else if (messageCount != this._lastRenderedCount) { … }
   this._lastRenderedCount = messageCount;`) with:

```dart
        final items = this._store.messagesWithNotices();

        /// New-frame bookkeeping: jump to the newest message while pinned,
        /// flag the unread pill otherwise (post-frame — not during build).
        /// Tombstones don't change the count (no unread flag); a /clear
        /// banner does (it counts as new activity).
        if (this._pinnedToBottom) {
          this._unreadWhileScrolledUp = false;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (this._scrollController.hasClients) {
              this._scrollController.jumpTo(
                  this._scrollController.position.maxScrollExtent);
            }
          });
        } else if (items.length != this._lastRenderedCount) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (this.mounted) {
              setState(() => this._unreadWhileScrolledUp = true);
            }
          });
        }
        this._lastRenderedCount = items.length;
```

d) In the `ListView.builder`, replace `itemCount: messageCount,` with
   `itemCount: items.length,` and replace the `itemBuilder` with:

```dart
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is ChatSystemNotice) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Text(
                              'Chat was cleared by a moderator',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                    );
                  }
                  final event = item as ChatMessageEvent;
                  return TwitchChatMessageRow(
                    event: event,
                    settingsBox: settingsBox,
                    isDeleted: this._store.isMessageDeleted(event.messageId),
                  );
                },
```

e) Replace the whole `if (this._unreadWhileScrolledUp) Positioned(…)` pill
   block with the two-state chip:

```dart
              if (!this._pinnedToBottom)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.sm,
                  child: Center(
                    child: Pressable(
                      haptic: true,
                      onTap: () {
                        setState(() {
                          this._pinnedToBottom = true;
                          this._unreadWhileScrolledUp = false;
                        });
                        this._scrollToBottom();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: this._unreadWhileScrolledUp
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          this._unreadWhileScrolledUp
                              ? 'New messages ↓'
                              : 'Paused ↓',
                          style: this._unreadWhileScrolledUp
                              ? Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white)
                              : Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ),
```

- [x] **Step 4: Run the tests to verify they pass**

```bash
bash flutterw test test/chat/native_twitch_chat_view_test.dart
bash flutterw test
bash flutterw analyze
```

Expected: PASS everywhere; analyze 0 errors + exactly 6 pre-existing
warnings.

- [x] **Step 5: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart test/chat/native_twitch_chat_view_test.dart
git commit -m "feat(chat): merged lifecycle list + two-state pause chip"
```

---

### Task 7: Gates + docs

**Files:**
- Modify: `docs/changelog-agent.md` (new dated entry at the top, matching the dated `## 2026-08-06` heading style)
- Modify: `docs/session-handoff.md` (current-state bullet; keep the baton style)
- Modify: `AGENTS.md` (chat paragraph)

- [x] **Step 1: Run the full gates**

```bash
bash flutterw test test/chat/ test/websocket/ test/persistence/
bash flutterw analyze
```

Expected: all tests PASS; analyze 0 errors (6 pre-existing warnings, none new).

- [x] **Step 2: Changelog entry**

Add a dated entry to the top of `docs/changelog-agent.md`:

```markdown
## 2026-08-06 — Native chat: message lifecycle (deletions + pause)

- `TwitchEventSubService` subscribes to four types now — `channel.chat.message`
  (mandatory, unchanged semantics) plus `message_delete`,
  `clear_user_messages`, `clear` (best-effort: POST failures/revocations
  degrade tombstones, never chat; same `user:read:chat` scope, no auth
  change).
- `TwitchChatStore` lifecycle state: plain tombstone id-set + system
  notices merged by arrival sequence (`lifecycleVersion` rebuild counter,
  `catalogVersion` pattern); pruned with the 500-cap; wiped on logout.
- Deleted messages tombstone in place (`<message deleted>`, username +
  badges kept) — single delete, timeout/ban purge, and `/clear` (which also
  inserts a "Chat was cleared by a moderator" banner). `/clear` on an empty
  chat is a no-op.
- Pause chip: scrolled-up chat now shows an explicit "Paused ↓" chip; new
  messages flip it to the existing "New messages ↓" pill; tap resumes.
- Tests: DTO (6), store lifecycle (8), service (3 new + 3 updated), wiring
  (1), row (1), window (3). Gates: chat + websocket + persistence suites
  green, analyze 0 errors (6 pre-existing warnings, none new).
```

- [x] **Step 3: Handoff update**

In `docs/session-handoff.md` (baton style — short bullets, no narrative),
add a new bullet next to the emote-picker one:

- **Message lifecycle on `master`** (2026-08-06) — native chat tombstones
  deleted messages (delete / timeout-ban purge / `/clear` + banner) and
  shows a "Paused ↓" chip when scrolled up. Spec
  `docs/superpowers/specs/2026-08-06-chat-message-lifecycle-design.md` +
  plan `docs/superpowers/plans/2026-08-06-chat-message-lifecycle.md`.
  **Maintainer dogfood pending:**
  - Delete a message from twitch.tv mod tools → tombstone in OBS Blade
    (username stays).
  - Time out a chatty user → all their visible messages tombstone.
  - `/clear` → everything tombstones + banner; new messages flow after it;
    `/clear` on an empty chat does nothing.
  - Scroll up → "Paused ↓"; new message → flips to "New messages ↓"; tap →
    resume at bottom.
  - Degrade path: chat works with no tombstones if the lifecycle
    subscriptions fail (log lines only).
  - WebView engine, YouTube/Owncast, tablet unchanged.

- [x] **Step 4: AGENTS.md chat paragraph**

In `AGENTS.md`'s Chat paragraph, append one clause to the shipped
description — e.g. "message lifecycle rides the same session
(`message_delete`/`clear_user_messages`/`clear` → tombstones + `/clear`
banner, best-effort subs) and scrolled-up chat shows a pause chip".

- [x] **Step 5: Commit**

```bash
git add docs/changelog-agent.md docs/session-handoff.md AGENTS.md
git commit -m "docs: chat message lifecycle shipped — changelog, handoff, AGENTS.md"
```
