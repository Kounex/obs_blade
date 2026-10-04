# Deleted Message Content + Actor Reveal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render deleted chat messages as dimmed original content + an italic ` —Deleted` marker (Twitch mod view), with a tap-to-expand reveal of which moderator deleted a message.

**Architecture:** One new DTO field (`userName` = deleting moderator) flows EventSub service → store (`_deletedMessageActors` map next to the tombstone set) → window (per-message expansion set) → row (dimmed-content branch + reveal line). No new state systems, scopes, settings, or persistence.

**Tech Stack:** Flutter, MobX, freezed (fromJson only), GetIt, Hive CE (settings only — no schema changes), flutter_test.

**Spec:** `docs/superpowers/specs/2026-08-07-deleted-message-content-design.md`

## Global Constraints

- Copy, verbatim: marker ` —Deleted` (space + U+2014 em-dash + `Deleted`,
  no space after the dash); reveal line
  `<actor> deleted <chatter>'s message` (no trailing content repeat).
- Styling, verbatim: content text = `bodySmall.color.withValues(alpha: 0.5)`,
  non-italic; emote images wrapped in `Opacity(opacity: 0.5)`; marker =
  italic, plain `bodySmall.color`; username + badges untouched.
- The DTO gains **only** `userName` — `targetUserName` is deliberately not
  modeled (the reveal takes the chatter's name from the message's own
  `chatterUserName`; the visibility guard guarantees the message is present).
- Purge (`clear_user_messages`) and `/clear` payloads carry **no actor** —
  those tombstoned messages get content + marker but **no tap target**
  (`deletedMessageActor` returns null).
- The Wave B lifecycle posture is unchanged: actions idempotent,
  unknown/evicted ids no-op, `lifecycleVersion` bumps only on real
  mutations, plain containers (never Observable*), no persistence changes,
  no new Twitch scopes.
- No settings toggle / hide path — the native chat viewer is the
  broadcaster by construction (spec § Context).
- Flutter commands: `bash flutterw …`.
  Gates per task: focused tests green; full suite green before commit;
  analyze 0 errors + exactly 6 pre-existing warnings (no new ones).
  Info-level lints are tolerated.
- Repo formatting convention: do NOT run `dart format` (this SDK's tall
  style churns committed regions); hand-match the repo's short style.
- Commit per task (`git add`/`git commit` only — **never push**).
- Codegen after the Task 1 DTO change:
  `bash flutterw pub run build_runner build --delete-conflicting-outputs`

---

### Task 1: DTO `userName` + store actor map + wiring signature

**Files:**
- Modify: `lib/types/classes/twitch/eventsub/chat_lifecycle_events.dart`
- Modify: `test/chat/fixtures/twitch/channel_chat_message_delete.json`
- Test: `test/chat/twitch_lifecycle_dto_test.dart`
- Modify: `lib/stores/views/twitch_chat.dart`
- Test: `test/chat/twitch_chat_store_test.dart`

**Interfaces:**
- Consumes: nothing new (Wave B pipeline is live).
- Produces:
  - `ChatMessageDeleteEvent({required messageId, required targetUserId, required userName})` — `userName` is the deleting moderator's display name.
  - `String? deletedMessageActor(String messageId)` on `TwitchChatStore` — actor display name, null for purge/`/clear`/unknown ids. Plain read; reactivity rides `lifecycleVersion`.
  - `void applyMessageDelete(ChatMessageDeleteEvent event)` — replaces the String-typed action (records tombstone + actor in the same idempotent pass).

- [x] **Step 1: Extend the fixture and write the failing DTO assertion**

`test/chat/fixtures/twitch/channel_chat_message_delete.json` becomes (adds
the `user_*` actor fields the real payload carries, per Twitch docs):

```json
{
  "broadcaster_user_id": "1337",
  "broadcaster_user_name": "Cool_User",
  "broadcaster_user_login": "cool_user",
  "user_id": "9001",
  "user_name": "Cool_Mod",
  "user_login": "cool_mod",
  "target_user_id": "7734",
  "target_user_name": "Uncool_viewer",
  "target_user_login": "uncool_viewer",
  "message_id": "e860a7a5-58d3-4959-9c5f-0f4dc9b5b0a2"
}
```

In `test/chat/twitch_lifecycle_dto_test.dart`, add one assertion to the
existing 'message_delete parses the documented example payload' test:

```dart
      expect(event.userName, 'Cool_Mod');
```

- [x] **Step 2: Run the DTO test to verify it fails**

Run: `bash flutterw test test/chat/twitch_lifecycle_dto_test.dart`
Expected: FAIL — compile error, `userName` isn't a getter on `ChatMessageDeleteEvent`.

- [x] **Step 3: Add `userName` to the DTO and regenerate**

In `lib/types/classes/twitch/eventsub/chat_lifecycle_events.dart`, replace
the `ChatMessageDeleteEvent` doc comment + factory with:

```dart
/// `channel.chat.message_delete` event — a moderator removed one message.
/// [userName] is the deleting moderator's display name (the row's reveal
/// line consumes it); other display fields are deliberately not modeled.
@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageDeleteEvent with _$ChatMessageDeleteEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatMessageDeleteEvent({
    required String messageId,
    required String targetUserId,
    required String userName,
  }) = _ChatMessageDeleteEvent;

  factory ChatMessageDeleteEvent.fromJson(Map<String, Object?> json) =>
      _$ChatMessageDeleteEventFromJson(json);
}
```

(The other two DTOs are untouched.) Then codegen:

Run: `bash flutterw pub run build_runner build --delete-conflicting-outputs`

Then: `bash flutterw test test/chat/twitch_lifecycle_dto_test.dart`
Expected: PASS (6/6).

- [x] **Step 4: Write the failing store tests (update 3 call sites + add actor coverage)**

In `test/chat/twitch_chat_store_test.dart`, `group('lifecycle')`:

a) In 'deleting a visible message tombstones it and bumps the version',
replace `store.applyMessageDelete('m1');` with:

```dart
      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1', userName: 'Cool_Mod'));
```

b) In 'deleting an unknown id is a no-op', replace
`store.applyMessageDelete('nope');` with:

```dart
      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'nope', targetUserId: 'u1', userName: 'Cool_Mod'));
```

c) In 'cap eviction prunes the tombstone set', replace
`store.applyMessageDelete('m0');` with:

```dart
      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm0', targetUserId: 'u1', userName: 'Cool_Mod'));
```

and extend that test's assertions — after
`expect(store.isMessageDeleted('m0'), isTrue);` add:

```dart
      expect(store.deletedMessageActor('m0'), 'Cool_Mod');
```

and at the end, after `expect(store.isMessageDeleted('m0'), isFalse);` add:

```dart
      expect(store.deletedMessageActor('m0'), isNull);
```

d) In 'logout clears tombstones, notices and the arrival counter', replace
the setup — `store.appendChatMessageForTest(chatMessage('m1', 'u1'));`
followed by `store.applyChatClear();` — with (delete BEFORE clear, so the
actor is genuinely recorded and the post-logout `isNull` proves the wipe):

```dart
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1', userName: 'Cool_Mod'));
      store.applyChatClear();
      expect(store.systemNotices, isNotEmpty);
      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
```

and after `expect(store.isMessageDeleted('m1'), isFalse);` add:

```dart
      expect(store.deletedMessageActor('m1'), isNull);
```

e) Add one new test at the end of the `lifecycle` group (before its
closing brace):

```dart
    test('deleting records the actor; purge and /clear record none', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u2'));
      store.appendChatMessageForTest(chatMessage('m3', 'u3'));

      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1', userName: 'Cool_Mod'));
      store.applyClearUserMessages('u2');
      store.applyChatClear();

      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
      expect(store.deletedMessageActor('m2'), isNull);
      expect(store.deletedMessageActor('m3'), isNull);
      expect(store.deletedMessageActor('nope'), isNull);
    });
```

f) In `group('lifecycle wiring')`, 'EventSub lifecycle callbacks drive the
store actions', replace the `emitDelete` construction with:

```dart
      emitDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1', userName: 'Cool_Mod'));
      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
```

(the following `expect(store.isMessageDeleted('m2'), isFalse);` stays.)

g) In `test/chat/twitch_eventsub_service_test.dart`, the Wave B
lifecycle-dispatch test feeds an inline `message_delete` frame — its
payload needs the now-required field. In the frame map, after
`'target_user_id': 'u2',` add:

```dart
      'user_name': 'Cool_Mod',
```

and after `expect(deletes.single.targetUserId, 'u2');` add:

```dart
    expect(deletes.single.userName, 'Cool_Mod');
```

- [x] **Step 5: Run the store tests to verify they fail**

Run: `bash flutterw test test/chat/twitch_chat_store_test.dart`
Expected: FAIL — compile error: `applyMessageDelete` takes a String,
`deletedMessageActor` isn't defined, too few arguments to
`ChatMessageDeleteEvent`.

- [x] **Step 6: Implement the store changes + wiring**

In `lib/stores/views/twitch_chat.dart`:

a) Right after the `_deletedMessageIds` declaration (~line 154), add:

```dart
  /// Display name of the moderator who deleted a message, keyed by
  /// messageId — plain Map, same [lifecycleVersion] reactivity story as
  /// [_deletedMessageIds]. Only single deletes carry an actor (purge and
  /// /clear payloads don't), so those ids are absent here.
  final Map<String, String> _deletedMessageActors = <String, String>{};
```

b) Right after `isMessageDeleted` (~line 531), add:

```dart
  /// Display name of the moderator who deleted [messageId] — null for
  /// purges, /clear, and unknown/untombstoned ids. Plain read (reactivity
  /// rides [lifecycleVersion]).
  String? deletedMessageActor(String messageId) =>
      this._deletedMessageActors[messageId];
```

c) Replace the `applyMessageDelete` action (~line 561) with:

```dart
  @action
  void applyMessageDelete(ChatMessageDeleteEvent event) {
    final visible = this
        .messages
        .any((message) => message.messageId == event.messageId);
    if (visible && this._deletedMessageIds.add(event.messageId)) {
      this._deletedMessageActors[event.messageId] = event.userName;
      this.lifecycleVersion++;
    }
  }
```

d) In `_appendMessage`'s eviction loop (~line 518), prune the actor too:

```dart
    while (this.messages.length > kMaxMessages) {
      this._deletedMessageIds.remove(this.messages.first.messageId);
      this._deletedMessageActors.remove(this.messages.first.messageId);
      this.messages.removeAt(0);
    }
```

e) In `_clearLifecycle()` (~line 599), wipe the map first:

```dart
  void _clearLifecycle() {
    this._deletedMessageActors.clear();
    this._deletedMessageIds.clear();
    this.systemNotices.clear();
    this._arrivalSeq = 0;
  }
```

f) In `connectChat`'s factory call (~line 342), replace
`(event) => this.applyMessageDelete(event.messageId),` with:

```dart
        (event) => this.applyMessageDelete(event),
```

g) Regenerate the MobX action wrapper — the action signature change
regenerates `lib/stores/views/twitch_chat.g.dart`:

Run: `bash flutterw pub run build_runner build --delete-conflicting-outputs`

- [x] **Step 7: Run focused tests, then the full gates**

Run: `bash flutterw test test/chat/twitch_chat_store_test.dart test/chat/twitch_lifecycle_dto_test.dart test/chat/twitch_eventsub_service_test.dart`
Expected: PASS (all).
Then: `bash flutterw test`
Expected: PASS (full suite — the `<message deleted>` widget assertions still
stand; the row hasn't changed yet).
Then: `bash flutterw analyze`
Expected: 0 errors + exactly 6 pre-existing warnings.

- [x] **Step 8: Commit**

```bash
git add lib/types/classes/twitch/eventsub/chat_lifecycle_events.dart \
  lib/types/classes/twitch/eventsub/chat_lifecycle_events.freezed.dart \
  lib/types/classes/twitch/eventsub/chat_lifecycle_events.g.dart \
  test/chat/fixtures/twitch/channel_chat_message_delete.json \
  test/chat/twitch_lifecycle_dto_test.dart \
  lib/stores/views/twitch_chat.dart \
  lib/stores/views/twitch_chat.g.dart \
  test/chat/twitch_chat_store_test.dart \
  test/chat/twitch_eventsub_service_test.dart
git commit -m "feat(chat): delete actor name flows DTO -> store (deletedMessageActor)"
```

---

### Task 2: Row — dimmed content + marker + reveal line + tap

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`
- Test: `test/chat/native_twitch_chat_view_test.dart`

**Interfaces:**
- Consumes: nothing from the store directly (the row stays prop-driven); the
  `/clear` window test's tombstone assertions move with this task because
  they assert row output.
- Produces (consumed by Task 3's window):
  - `TwitchChatMessageRow({…, this.isDeleted = false, this.deletedActor, this.isDeletedExpanded = false, this.onDeletedTap})`
  - Rendering contract: `isDeleted` → body = dimmed `_messageSpans()` + ` —Deleted` marker; tappable + expandable iff `isDeleted && deletedActor != null`.

- [x] **Step 1: Write the failing row tests**

In `test/chat/native_twitch_chat_view_test.dart`:

a) Add a span finder next to `collectWidgetSpans` (top level, after it):

```dart
/// Finds the first TextSpan carrying exactly [text] (the row's spans sit
/// one level down inside `Text.rich`'s wrapper).
TextSpan findTextSpan(InlineSpan root, String text) {
  TextSpan? found;
  void visit(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text == text) found ??= span;
      span.children?.forEach(visit);
    }
  }

  visit(root);
  if (found == null) throw StateError('no TextSpan with text "$text"');
  return found!;
}
```

b) REPLACE the whole existing test 'a deleted message keeps the author,
tombstones the body' with:

```dart
    testWidgets('a deleted message shows dimmed content plus the marker',
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

      /// Content stays (emote included) — only the marker is appended.
      expect(richText.text.toPlainText(), 'Emoter: Hello \u{FFFC} —Deleted');
      /// Twitch mod view: content non-italic and dimmed harder than the
      /// (italic) marker; the emote dims via a matching Opacity. The text
      /// fragment is split for third-party emote tokenization, so the
      /// first token carries the dimmed style.
      final marker = findTextSpan(richText.text, ' —Deleted');
      expect(marker.style?.fontStyle, FontStyle.italic);
      final content = findTextSpan(richText.text, 'Hello');
      expect(content.style?.fontStyle, isNull);
      expect(content.style!.color!.a, lessThan(marker.style!.color!.a));
      final emote = collectWidgetSpans(richText.text).single;
      expect(emote.child, isA<Opacity>());
      expect((emote.child as Opacity).opacity, 0.5);
    });

    testWidgets('tapping a deleted row with an actor fires the callback',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          isDeleted: true,
          deletedActor: 'Cool_Mod',
          onDeletedTap: () => tapped = true,
        )),
      );

      await tester.tap(find.byType(TwitchChatMessageRow));
      expect(tapped, isTrue);
    });

    testWidgets('an expanded deleted row reveals who deleted it',
        (tester) async {
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          isDeleted: true,
          deletedActor: 'Cool_Mod',
          isDeletedExpanded: true,
        )),
      );

      expect(
        find.text("Cool_Mod deleted Viewer32's message"),
        findsOneWidget,
      );
    });

    testWidgets('a purged message (no actor) is not tappable, no reveal',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          isDeleted: true,
          isDeletedExpanded: true,
          onDeletedTap: () => tapped = true,
        )),
      );

      expect(find.byType(GestureDetector), findsNothing);
      expect(find.textContaining('deleted Viewer32'), findsNothing);

      await tester.tap(find.byType(TwitchChatMessageRow));
      expect(tapped, isFalse);
    });
```

c) In the `NativeTwitchChatView` group, '/clear tombstones the rows and
banners between old and new', update the `containsAll` list:

```dart
      expect(
        texts,
        containsAll(<String>[
          'Viewer32: Hi chat —Deleted',
          'Emoter: Hello Kappa —Deleted',
        ]),
      );
```

- [x] **Step 2: Run the row tests to verify they fail**

Run: `bash flutterw test test/chat/native_twitch_chat_view_test.dart`
Expected: FAIL — compile error: `deletedActor`/`isDeletedExpanded`/
`onDeletedTap` aren't parameters; `<message deleted>` assertions mismatch.

- [x] **Step 3: Implement the row changes**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`:

a) Replace the `isDeleted` doc comment + field block with (and add the three
new fields + constructor params):

```dart
  /// Moderation tombstone — username/badges stay; the body renders its
  /// original content dimmed (Twitch mod view) with a ` —Deleted` marker
  /// (set by the window from the store's lifecycle state).
  final bool isDeleted;

  /// Display name of the moderator who deleted this message — only single
  /// deletes carry one (purge//clear payloads don't). Non-null together
  /// with [isDeleted] makes the row tappable ([onDeletedTap]).
  final String? deletedActor;

  /// Whether the actor reveal line under a deleted message is expanded.
  final bool isDeletedExpanded;

  /// Tap handler for a deleted message with a known actor — toggles the
  /// reveal line. Null (or no actor) = not tappable.
  final VoidCallback? onDeletedTap;

  const TwitchChatMessageRow({
    super.key,
    required this.event,
    required this.settingsBox,
    this.isDeleted = false,
    this.deletedActor,
    this.isDeletedExpanded = false,
    this.onDeletedTap,
  });
```

b) Replace the comment block + `build` method (from `/// Badge-less rows
never change` through the closing brace of `build`) with (the badge
`Observer` guard keeps wrapping only the line; the Column MUST stay
`MainAxisSize.min` — rows build inside a ListView's unbounded main axis):

```dart
  /// Badge-less rows never change — an Observer that tracks nothing
  /// spams flutter_mobx's "No observables" warning, so only rows with
  /// badges observe the catalog (arrivals/changes rebuild them;
  /// toggle changes come from the HiveBuilder above the list).
  @override
  Widget build(BuildContext context) {
    final Widget line = this.event.badges.isEmpty
        ? this._richText(context)
        : Observer(builder: this._richText);
    final bool revealable = this.isDeleted && this.deletedActor != null;
    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line,
        if (revealable && this.isDeletedExpanded)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
            child: Text(
              "${this.deletedActor} deleted ${this.event.chatterUserName}'s message",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: revealable
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: this.onDeletedTap,
              child: body,
            )
          : body,
    );
  }
```

c) In `_richText`, replace the deleted branch
(`if (this.isDeleted) TextSpan(text: '<message deleted>', …) else …`)
with:

```dart
            if (this.isDeleted) ...[
              ...this._dimmedMessageSpans(context),
              TextSpan(
                text: ' —Deleted',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ] else
              ...this._messageSpans(),
```

d) Add the dimming helper after `_messageSpans`:

```dart
  /// Body spans for a deleted message — the content stays (Twitch mod
  /// view) but dims hard: text recolors to half of the marker's dim and
  /// emote images get a matching [Opacity]. Structure, spacing and error
  /// builders are preserved.
  List<InlineSpan> _dimmedMessageSpans(BuildContext context) {
    final color = Theme.of(context)
        .textTheme
        .bodySmall
        ?.color
        ?.withValues(alpha: 0.5);
    return [
      for (final span in this._messageSpans())
        if (span is TextSpan)
          TextSpan(text: span.text, style: TextStyle(color: color))
        else if (span is WidgetSpan)
          WidgetSpan(
            alignment: span.alignment,
            child: Opacity(opacity: 0.5, child: span.child),
          )
        else
          span,
    ];
  }
```

- [x] **Step 4: Run focused tests, then the full gates**

Run: `bash flutterw test test/chat/native_twitch_chat_view_test.dart`
Expected: PASS (all).
Then: `bash flutterw test`
Expected: PASS (full suite).
Then: `bash flutterw analyze`
Expected: 0 errors + exactly 6 pre-existing warnings.

- [x] **Step 5: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart \
  test/chat/native_twitch_chat_view_test.dart
git commit -m "feat(chat): deleted rows show dimmed content + marker, tappable actor reveal"
```

---

### Task 3: Window tap wiring + expansion state + docs

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart`
- Test: `test/chat/native_twitch_chat_view_test.dart`
- Docs: `docs/changelog-agent.md`, `docs/session-handoff.md`, `AGENTS.md`

**Interfaces:**
- Consumes: Task 1's `deletedMessageActor(messageId)` + Task 2's row params
  (`deletedActor`, `isDeletedExpanded`, `onDeletedTap`).
- Produces: nothing consumed by later code (final task).

- [x] **Step 1: Write the failing window tests**

In `test/chat/native_twitch_chat_view_test.dart`:

a) Add the import (alphabetical, after the `channel_chat_message.dart`
import):

```dart
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
```

b) Add two tests at the end of the `NativeTwitchChatView` group:

```dart
    testWidgets('tapping a deleted message reveals and collapses the actor',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.appendChatMessageForTest(textEvent('1', 'Viewer32', 'Hi chat'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();

      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: '1', targetUserId: '1', userName: 'Cool_Mod'));
      await tester.pump();

      expect(find.text("Cool_Mod deleted Viewer32's message"), findsNothing);

      await tester.tap(find.byType(TwitchChatMessageRow));
      await tester.pump();
      expect(
          find.text("Cool_Mod deleted Viewer32's message"), findsOneWidget);

      /// The expansion survives a lifecycle rebuild (new message arrives).
      store.appendChatMessageForTest(textEvent('2', 'Late', 'fresh'));
      await tester.pump();
      expect(
          find.text("Cool_Mod deleted Viewer32's message"), findsOneWidget);

      await tester.tap(find.byType(TwitchChatMessageRow).first);
      await tester.pump();
      expect(find.text("Cool_Mod deleted Viewer32's message"), findsNothing);
    });

    testWidgets('a purged message shows content but no tap reveal',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.appendChatMessageForTest(textEvent('1', 'Viewer32', 'Hi chat'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();

      store.applyClearUserMessages('1');
      await tester.pump();

      expect(
        find.text('Viewer32: Hi chat —Deleted', findRichText: true),
        findsOneWidget,
      );

      await tester.tap(find.byType(TwitchChatMessageRow));
      await tester.pump();
      expect(find.textContaining('deleted Viewer32'), findsNothing);
    });
```

- [x] **Step 2: Run the window tests to verify they fail**

Run: `bash flutterw test test/chat/native_twitch_chat_view_test.dart`
Expected: FAIL — the reveal never appears (window passes no actor/tap yet).

- [x] **Step 3: Implement the window changes**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart`:

a) Add the expansion state next to `_lastRenderedCount` (~line 33):

```dart
  /// Ids of deleted messages whose actor reveal is expanded — toggled by
  /// tapping the row. Survives lifecycle rebuilds; dead ids (evicted,
  /// logged out) never render, so the set stays session-bounded.
  final Set<String> _expandedDeletedIds = <String>{};
```

b) In the `itemBuilder`, replace the row construction
(`final event = item as ChatMessageEvent; return TwitchChatMessageRow(…)`)
with:

```dart
                  final event = item as ChatMessageEvent;
                  final actor =
                      this._store.deletedMessageActor(event.messageId);
                  return TwitchChatMessageRow(
                    event: event,
                    settingsBox: settingsBox,
                    isDeleted: this._store.isMessageDeleted(event.messageId),
                    deletedActor: actor,
                    isDeletedExpanded:
                        this._expandedDeletedIds.contains(event.messageId),
                    onDeletedTap: actor == null
                        ? null
                        : () => setState(() {
                              final id = event.messageId;
                              if (!this._expandedDeletedIds.remove(id)) {
                                this._expandedDeletedIds.add(id);
                              }
                            }),
                  );
```

- [x] **Step 4: Run focused tests, then the full gates**

Run: `bash flutterw test test/chat/`
Expected: PASS (all chat suites).
Then: `bash flutterw test`
Expected: PASS (full suite).
Then: `bash flutterw analyze`
Expected: 0 errors + exactly 6 pre-existing warnings.

- [x] **Step 5: Docs — changelog**

At the top of `docs/changelog-agent.md`, after the 2-line header and before
the `## 2026-08-06 — Native chat: message lifecycle (deletions + pause)`
entry, insert:

```markdown
## 2026-08-07 — Native chat: deleted content + actor reveal (mod view)

- Deleted messages now match twitch.tv's moderator view: the original
  content stays (text dimmed to 50% of the marker's dim, emotes at matching
  opacity) with an italic ` —Deleted` marker — replacing Wave B's
  `<message deleted>` tombstone. Uniform across single deletes, timeout/ban
  purges, and `/clear` purges; username + badges untouched.
- Tapping a message deleted via `channel.chat.message_delete` expands an
  inline reveal `<actor> deleted <chatter>'s message`. The DTO gains
  `userName` (the deleting moderator; `targetUserName` deliberately
  unmodeled — the chatter's name comes from the message itself), the store
  keeps a `_deletedMessageActors` map (pruned at the 500-cap, wiped with
  lifecycle), and the window owns a session-bounded expansion set.
  Purge/`/clear` payloads carry no actor — those rows are not tappable.
- Tests: DTO 1 updated, store 1 new + 5 updated, row 1 rewritten + 3 new,
  window 2 new + 1 updated (test counts: chat suites all green; analyze 0
  errors + 6 pre-existing warnings). No scopes, no persistence.
```

- [x] **Step 6: Docs — session handoff**

In `docs/session-handoff.md`, mark the Wave B lifecycle dogfood as passed
and add the new dogfood bullet right after that entry. Replace
`**Maintainer dogfood pending:**` (in the 'Message lifecycle on `master`'
bullet) with `**Maintainer dogfood PASSED 2026-08-07.**` and insert after
that bullet's last sub-item (`- WebView engine, YouTube/Owncast, tablet
unchanged.`):

```markdown
- **Deleted content + actor reveal on `master`** (2026-08-07) — deleted
  messages show their dimmed content with a ` —Deleted` marker (Twitch mod
  view); tapping a mod-deleted message reveals who deleted it. Spec
  `docs/superpowers/specs/2026-08-07-deleted-message-content-design.md` +
  plan `docs/superpowers/plans/2026-08-07-deleted-message-content.md`.
  **Maintainer dogfood pending:**
  - Delete a message from twitch.tv mod tools → content stays, dimmed,
    marker ` —Deleted`; username/badges untouched.
  - Tap it → `<mod> deleted <chatter>'s message`; tap again collapses;
    expansion survives new incoming messages.
  - Time out a user / `/clear` → content + marker but NO tap reveal
    (payloads carry no actor).
  - Deleted message with emotes → emotes render dimmed.
```

- [x] **Step 7: Docs — AGENTS.md chat paragraph**

In `AGENTS.md`, in the Chat paragraph, replace
``(`message_delete`/`clear_user_messages`/`clear` → tombstones + `/clear` banner, best-effort subs)``
with:

```
(`message_delete`/`clear_user_messages`/`clear` → content-visible
tombstones (dimmed content + ` —Deleted` marker, tap reveals the deleting
mod) + `/clear` banner, best-effort subs)
```

- [x] **Step 8: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart \
  test/chat/native_twitch_chat_view_test.dart \
  docs/changelog-agent.md docs/session-handoff.md AGENTS.md
git commit -m "feat(chat): window actor-reveal wiring + docs (deleted content mod view)"
```
