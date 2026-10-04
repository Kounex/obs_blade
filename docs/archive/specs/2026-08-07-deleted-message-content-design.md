# Deleted Message Content + Actor Reveal (Twitch mod view) — Design

**Status:** Approved design (2026-08-07), pre-plan
**Builds on:** Wave B — `docs/superpowers/specs/2026-08-06-chat-message-lifecycle-design.md`
(shipped); this changes only what a tombstone *renders* and adds the
actor reveal. Everything else from Wave B stands.

## Context

Wave B tombstones deleted messages for everyone (`<message deleted>` replaces
the body). On twitch.tv, a moderator/broadcaster instead sees the original
content dimmed with an italic `—Deleted` marker, and clicking the message
reveals who deleted it (`<mod> deleted <chatter>'s message`). Verified against
live screenshots 2026-08-07:

- Original text: **non-italic**, dimmed **strongly** (darker).
- Marker ` —Deleted` (space + em-dash + `Deleted`, no space after the dash):
  **italic**, dimmed **less** (one step brighter than the content).
- Username (full color) and badges are untouched.
- Click expands an inline line under the message naming the deleting
  moderator.

**Viewer entitlement is a non-issue here:** the native chat always shows the
logged-in user's own channel — the EventSub condition pins
`broadcaster_user_id == user_id` (`twitch_eventsub_service.dart:259`,
connect at `twitch_chat.dart:348-350`). The viewer is the broadcaster, whom
Twitch itself shows this view. No scopes, no Helix calls, no entitlement
check.

## Goals

- Deleted messages render their **original content** (text + inline emotes)
  dimmed, with the ` —Deleted` marker, matching Twitch's mod view.
- Tapping a message deleted via `channel.chat.message_delete` expands an
  inline reveal of **who deleted it**.
- Keep the change confined to DTO → store → wiring → row → window; no new
  state systems, no settings, no persistence.

## Non-goals

- No hide path / settings toggle (the screen is staff-only by construction).
- No actor reveal for timeout/ban purges (`channel.chat.clear_user_messages`)
  or `/clear` (`channel.chat.clear`) — those payloads carry **no actor
  field**; these messages get content + marker only, no tap target.
- No multi-channel viewing. Forward-compat note only: if it ever lands, the
  display rule gains a second input (viewer-is-staff of that channel via Get
  Moderators + `moderation:read` silent upgrade); non-staff views fall back
  to the Wave B `<message deleted>` tombstone. The seam is the row's
  `isDeleted` branch — do not build the gate now.
- No changes to `/clear` banner, pause chip, merge arithmetic, service
  subscription posture, scopes, or persistence.

## Verified existing facts

- Row (`twitch_chat_message_row.dart`): single `Text.rich` —
  `children: [badgeSpans…, authorSpan, ': ', tombstone-or-body]`. Spans carry
  **no tap recognizers** and no per-fragment styles (flat recolor is safe).
  `build` wraps the line in an `Observer` only when badges exist (the
  "No observables" guard). The Wave B branch replaces `_messageSpans()` with
  `<message deleted>` (italic, `bodySmall.color`).
- DTO (`chat_lifecycle_events.dart`): `ChatMessageDeleteEvent{messageId,
  targetUserId}` — display fields deliberately unmodeled (nothing consumed
  them). Fixture `channel_chat_message_delete.json` has `broadcaster_*`,
  `target_*`, `message_id` — **no actor (`user_*`) fields**; the real
  payload carries `user_id`/`user_login`/`user_name` = the deleting
  moderator.
- Store (`twitch_chat.dart`): plain `Set<String> _deletedMessageIds`;
  `applyMessageDelete(String messageId)` is visibility-guarded (unknown/
  evicted ids no-op) and idempotent; eviction prune at the 500-cap removes
  the id from the set; `_clearLifecycle()` wipes at both clear sites
  (`logout()`, `_resetToLoggedOut()`). Wiring passes
  `(e) => applyMessageDelete(e.messageId)`.
- The deleted message's own `ChatMessageEvent` stays in `messages` with
  `chatterUserName` — the reveal's target name comes from the message, not
  the delete event (the visibility guard guarantees the message is present).
- Window (`native_twitch_chat_view.dart`): `itemBuilder` switches on
  `ChatSystemNotice`, else passes `isDeleted: store.isMessageDeleted(id)`;
  the row has no tap handling today.

## Design

### Rendering rule (one rule, all three tombstone kinds)

`isDeleted == true` → body = dimmed `_messageSpans()` + marker span:

- **Content spans** (text): recolored to
  `Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)` —
  original styling otherwise preserved (non-italic). Emote `WidgetSpan`s
  (first-party and third-party) wrapped in `Opacity(opacity: 0.5)` so the
  line dims uniformly; structure, spacing, and `errorBuilder`s preserved.
- **Marker span:** text ` —Deleted` (space, U+2014 em-dash, `Deleted` — no
  space after the dash), italic, color plain
  `bodySmall.color` (exactly the brightness Wave B's tombstone used).
- Username + badges untouched. Applies uniformly to single deletes,
  timeout/ban purges, and `/clear` purges (the row cannot distinguish them
  and does not need to).

### Actor reveal (single deletes only)

- Store: new plain `Map<String, String> _deletedMessageActors`
  (messageId → actor display name) next to the tombstone set —
  pruned alongside it at the 500-cap eviction, wiped in `_clearLifecycle()`.
  New getter `String? deletedMessageActor(String messageId)`.
- DTO: `ChatMessageDeleteEvent` gains `required String userName` (the
  deleting moderator's display name). `targetUserName` is deliberately **not**
  modeled — the reveal takes the chatter's name from the message itself
  (`chatterUserName`), and the visibility guard guarantees the message is
  present. Doc comment updated (display fields are now partially consumed).
  Fixture gains `user_id`/`user_login`/`user_name`.
- `applyMessageDelete(ChatMessageDeleteEvent event)` replaces the
  String-typed action: records the tombstone **and** the actor in the same
  idempotent pass (a duplicate delete re-sets the same actor — harmless).
  Wiring becomes `(e) => applyMessageDelete(e)`; store/wiring tests adjust.
- Row API grows: `deletedActor` (`String?`, default null),
  `isDeletedExpanded` (`bool`, default false), `onDeletedTap`
  (`VoidCallback?`, default null). When `isDeleted && deletedActor != null`
  the row is tappable (GestureDetector) and lays out a `Column`: the
  existing rich line, plus — when expanded — a reveal line
  `<actor> deleted <chatter>'s message` (non-italic, `bodySmall` size/color,
  small top padding). The badge `Observer` guard keeps wrapping only the
  line, not the Column.
- Window: `Set<String> _expandedDeletedIds` in State; tap toggles membership
  in `setState`. Survives `lifecycleVersion` rebuilds (deliberate — an
  expansion stays open as new messages arrive). Tappable iff
  `store.deletedMessageActor(id) != null`. The set is session-bounded and
  lazily pruned by visibility (dead ids never render) — same accepted
  posture as `systemNotices`.

### Copy lock

- Marker: ` —Deleted` (em-dash U+2014).
- Reveal: `<actor> deleted <chatter>'s message` — no trailing content repeat
  (Twitch repeats the message text; it is directly above, so we drop it).

## Edge cases

- Purged (`clear_user_messages`) or `/clear`-purged message: content +
  marker, **no tap target** (`deletedMessageActor` returns null).
- Deleted message with emotes: emotes render at 50% opacity; a deleted
  emote-only message still shows its emotes.
- Deleted message with empty/unrenderable content: degrades to username +
  marker (same as a message with no fragments renders today).
- Delete event for unknown/evicted id: no-op (unchanged Wave B guard); no
  actor recorded.
- `/clear` banner (ChatSystemNotice): unchanged, not tappable.
- Expansion state across logout: ids become unreachable (messages cleared)
  and the set stays harmlessly small — session-bounded, no explicit clear.

## Testing

- **DTO:** fixture gains `user_*`; parse test asserts `userName` (and the
  existing fields) — 1 updated test.
- **Store:** actor recorded on delete; null for purge and `/clear`; eviction
  prune drops the actor; `_clearLifecycle` wipes actors; existing
  `applyMessageDelete('id')` call sites updated to the DTO signature.
- **Row:** deleted renders original text + ` —Deleted`; content span color =
  strong dim, marker italic + lighter dim; badges/username intact; emote
  wrapped in Opacity; reveal line shown/hidden; tap callback fires. The Wave
  B tombstone test (`'Emoter: <message deleted>'`) is rewritten.
- **Window:** tap deleted-with-actor → reveal appears, tap again collapses;
  purged message not tappable; expansion survives a `lifecycleVersion` bump
  (new message arrives). Sweep for `<message deleted>` assertions
  (row/window/integration) and update.
- **Docs:** changelog entry; handoff dogfood bullet updated (tombstone
  expectations now content + marker + tap reveal); AGENTS.md chat paragraph
  clause stays accurate ("tombstones" → content-visible tombstones +
  actor reveal).
