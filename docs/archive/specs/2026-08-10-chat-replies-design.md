# Chat replies (send side) — design

**Date:** 2026-08-10 · **Process tier:** S · **Scope:** native Twitch chat
(EventSub engine). WebView embeds untouched (reply UI is Twitch's own there).

## 1. What already exists (do not rebuild)

- `ChatMessageReply` DTO fully models the wire `reply` object
  (`channel_chat_message.dart:94`): parent message id/body/user, thread
  info.
- Incoming replies already render: `↩ Replying to @parent: excerpt` line
  above the message row (`twitch_chat_message_row.dart:377-426`), parent
  name tappable via `onMentionTap`, leading `@parent` mention fragment
  stripped from the body (`chat_message_display.dart:15-43`).
- Tombstoned (deleted) parents are safe: the preview uses the wire
  `parentMessageBody`, never a lookup.

**The feature is only the outgoing side:** start a reply, show the target
while composing, send with `reply_parent_message_id`.

## 2. UX

### Starting a reply — long-press on the message

Long-press currently opens the mod action sheet, gated on
`canModerateSelectedChannel`. New behavior for a long-press on a
non-deleted message:

| User | Sheet |
|---|---|
| Moderator (+ `canWriteChat`) | existing `ModActionSheet` with a **Reply** row added at the top |
| Moderator (read-only token) | existing `ModActionSheet`, no Reply row |
| Non-mod with `canWriteChat` | new lightweight **MessageActionSheet** — title + a single **Reply** row (same `_actionRow` card idiom) |
| Non-mod, read-only | nothing (as today) |

Deleted (tombstoned) messages keep today's behavior: no sheet.

No swipe gesture — deliberately. Swipe-to-reply needs new drag infra that
must coexist with vertical scroll and the timer-based mod long-press; not
worth it for v1. May be revisited after dogfood.

### Reply strip (composing)

While a reply target is set, a strip docks directly above the input row
(same conditional-child slot as the dock's error line; the read-only lock
strip early-return takes precedence — a target can't be set in read-only
mode anyway):

```
↩ Replying to @username: excerpt of the parent message…        ✕
```

- One line, ellipsized; excerpt is the parent body's plain text.
- ✕ (Pressable) clears the target.
- Setting a new target replaces the old one.
- Cleared automatically: after a successful send, and on channel switch
  (`selectChannel`) — the parent id is meaningless in another channel.
- If the parent is deleted while composing: still send with the parent id
  (Twitch decides; a reject surfaces via the dock's existing error line).
  No special-casing.

### After sending

The sent message echoes back via EventSub with the `reply` object
populated → renders with the existing preview line. No optimistic local
row (consistent with current send behavior).

## 3. Implementation

### Send path

- `TwitchMessageService.sendChatMessage` gains
  `String? replyParentMessageId`; when non-null the request body includes
  `reply_parent_message_id` (`twitch_message_service.dart:19-36`).
- `_TwitchChatStore`:
  - `@observable ChatMessageEvent? replyTarget` — the full event; carries
    id, author name, and body for the strip.
  - `@action setReplyTarget(ChatMessageEvent)` / `@action
    clearReplyTarget()`.
  - `sendChatMessage(String text)` forwards `replyTarget?.messageId`;
    clears the target on success (keeps it on failure so the user can
    retry).
  - `selectChannel` clears the target.
- Dock `onSend` signature unchanged (`Future<bool> Function(String)`) —
  the target rides store state.

### Dock seam

`NativeChatInput` is deliberately Twitch-free; add a generic
`Widget? contextStrip` rendered as the first child of the send-ready
`Column` (before the error row). The Twitch-specific strip
(`_ReplyTargetStrip`, living next to the dock wiring in
`stream_chat.dart` / the stream_chat widget folder) is an `Observer` over
`twitchStore.replyTarget`, returns `SizedBox.shrink()` when null, and
calls `clearReplyTarget()` from ✕.

### Sheets

- `ModActionSheet` / `showModActionSheet`: optional `VoidCallback? onReply`;
  when non-null, a Reply `_actionRow` (icon `CupertinoIcons.reply`,
  non-destructive) renders above Delete/Timeout/Ban. Callback: dismiss
  sheet → `setReplyTarget(event)` → focus the input field.
- New `showMessageActionSheet(context, {required String authorName,
  required VoidCallback onReply})` in `mod_action_sheet.dart` — same card
  idiom, title "Message from @authorName", single Reply row. (Kept in the
  same file to share the row idiom; the sheet stays tiny.)
- Long-press handler in `native_twitch_chat_view.dart:402-436`: deleted →
  nothing; else `canModerateSelectedChannel` → `showModActionSheet(...,
  onReply: canWriteChat ? … : null)`; else `canWriteChat` →
  `showMessageActionSheet(...)`; else nothing.

Focus: after choosing Reply, request focus on the dock's `FocusNode` so
the keyboard comes up with the strip visible. The dock's focus node is
created in `stream_chat.dart` — wire a callback down the same path
`onSend` already travels.

## 4. Tests

- `twitch_message_service_test.dart`: body includes
  `reply_parent_message_id` when passed; absent when null (extend the
  existing body-shape assertion).
- `fake_twitch_services.dart`: `FakeTwitchMessageService` records
  `lastReplyParentMessageId`.
- `twitch_chat_store_test.dart` `group('sendChatMessage')`: reply target
  id forwarded; cleared on success; kept on failure; cleared on
  `selectChannel`; null → body has no reply param.
- `mod_action_sheet_test.dart`: Reply row present/absent per `onReply`.
- New/extended view test (`native_twitch_chat_view_test.dart` or
  `native_chat_input_test.dart`): strip renders with target (author +
  excerpt), hidden without, ✕ clears; non-mod long-press opens the reply
  sheet (mods keep mod sheet).

## 5. Out of scope

- Swipe-to-reply gesture.
- Thread view (Twitch has no thread UI; `thread_*` fields stay unused).
- Reply actions on notifications/notices (only `ChatMessageEvent` rows).
- WebView engine (Twitch's own embed handles replies there).
