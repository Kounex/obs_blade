# Native chat: message lifecycle (deletions + pause indicator) — design

**Date:** 2026-08-06 · **Status:** approved (brainstorm) · **Wave:** B of the
Twitch native-chat roadmap (A = emote picker, shipped; C = per-message mod
actions, depends on B's tombstone infra; D = channel modes; E = AutoMod queue)

Wave B gives the native Twitch chat a message lifecycle: deleted messages
tombstone in place (single delete, timeout/ban purge, `/clear`), `/clear` adds a
system banner, and the implicit scroll-up pause becomes an explicit indicator.

## Verified facts (Twitch EventSub, checked 2026-08-06)

Source: [EventSub subscription types](https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types/).

- `channel.chat.message_delete` v1 — a moderator removed a specific message.
  Event: `broadcaster_user_*`, `target_user_*`, `message_id`.
- `channel.chat.clear_user_messages` v1 — a moderator/bot cleared all messages
  from a specific user (timeout/ban purge). Event: `broadcaster_user_*`,
  `target_user_id/login/name`.
- `channel.chat.clear` v1 — a moderator/bot cleared the whole chat room.
  Event: `broadcaster_user_*` only.
- Authorization for all three (confirmed on the docs page for `clear` +
  `clear_user_messages`; `message_delete` is the same family): **user token
  with `user:read:chat` from the chatting user** — the scope the app already
  requests (`kTwitchChatScopes`). No moderator status needed for user tokens;
  no new scope, no silent-upgrade path in this wave.
- Condition shape for all three is identical to the existing
  `channel.chat.message` subscription: `{broadcaster_user_id, user_id}`.
- One subscription POST per type; all ride the existing dedicated EventSub
  websocket session (`TwitchEventSubService`).
- Payload field names above are from the docs page; the implementation plan
  pins them against the docs' example payloads as test fixtures (same method
  as the earlier chat waves).

Existing app facts (verified in code):

- `TwitchEventSubService` today subscribes to exactly one type
  (`channel.chat.message`): filter at `twitch_eventsub_service.dart:139`,
  POST body at `:183`, dedicated session, per-notification try/catch.
- `TwitchChatStore.messages` is an `ObservableList<ChatMessageEvent>` capped
  at `kMaxMessages = 500` (`twitch_chat.dart:45`, eviction at `:479-481`),
  cleared on logout (`:271`). There is NO `messageId` dedup — duplicates
  double-render (EventSub is at-least-once).
- `ChatMessageEvent` carries `chatterUserId` and `messageId`
  (`channel_chat_message.dart:17-21`) — both match keys the lifecycle needs.
- The native window already pauses implicitly: `_pinnedToBottom` flips false
  when the user scrolls up (24px threshold), auto-jump to newest only while
  pinned, and a "New messages ↓" pill appears when messages arrive while
  unpinned (`native_twitch_chat_view.dart:160-243`). Tapping the pill re-pins
  and animates to the bottom.

## Product decisions (from brainstorm)

1. **Single delete → tombstone in place.** Row stays, username + badges kept,
   body replaced with italic dimmed `<message deleted>`. (Not removal — keeps
   conversation context; Twitch-web parity.)
2. **Timeout/ban purge (`clear_user_messages`) → same tombstone** for all of
   that user's visible messages. (One consistent rule; the broadcaster keeps
   context of what was said.)
3. **`/clear` → tombstone everything currently visible + a system banner** in
   the scroll: "Chat was cleared by a moderator". (A bare wipe would read as
   a glitch in an OBS remote.)
4. **Pause indicator:** scrolled-up state becomes an explicit chip —
   "New messages ↓" when unread arrived (today's pill), otherwise a dimmer
   "Paused ↓". Tap either → re-pin + scroll to bottom. No manual toggle.

## Architecture (Approach A — store-owned lifecycle state)

Chosen over B (`isDeleted` on the wire DTO — pollutes the API model, banner
still needs a second mechanism) and C (per-message view-model wrapper — most
machinery, touches every consumer, YAGNI for one flag + one notice type).

### Subscriptions — `TwitchEventSubService` generalized

- The hardcoded single type becomes a fixed set of four:
  `channel.chat.message` (existing) + the three lifecycle types.
- One POST per type at session start, same condition/transport as today.
- **Best-effort:** a failing lifecycle POST (403/5xx/network) is logged and
  skipped — chat messages must never be blocked by a tombstone subscription
  failing. Same degrade philosophy as badges/third-party emotes.
- Envelope dispatch routes on `metadata.subscriptionType` to per-type
  handlers (today's `:139` early-return becomes a switch); unknown types keep
  being ignored silently.

### DTOs — 3 tiny freezed classes (`lib/types/classes/twitch/eventsub/`)

- `ChatMessageDeleteEvent` — `messageId`, `targetUserId` (both required).
- `ChatClearUserMessagesEvent` — `targetUserId` (required).
- `ChatClearEvent` — `broadcasterUserId` (required); no other payload fields
  we consume.
- Defensive parsing identical to `ChatMessageEvent` (required ids, tolerate
  extras). Display/login fields exist in the payloads but are deliberately
  not modeled — nothing consumes them (YAGNI).

### Store — `TwitchChatStore`

- New: plain `Set<String> _deletedMessageIds`; new: plain
  `List<ChatSystemNotice> systemNotices` (`ChatSystemNotice` =
  `(afterSeq, kind)` — one kind for now: `chatCleared`; `afterSeq` explained
  below). Both are **plain containers**: rows render inside the HiveBuilder
  whose builder runs outside Observer tracking, so UI reactivity rides a
  public `@observable int lifecycleVersion` counter bumped in the same
  actions — the exact pattern the emote catalogs (`catalogVersion`) and the
  picker already use.
- Arrival ordering: the store already appends in arrival order; a monotonic
  `_arrivalSeq` increments per message appended, and each notice captures the
  current value. Merging uses **arrival sequence, not wall-clock time** —
  `channel.chat.message` events carry no sent-at field, and local receipt
  times would skew. A notice sorts after every message with
  `seq <= afterSeq` and before the rest; evicted-message seqs simply fall
  out of the merge.
- New actions, all idempotent:
  - `applyMessageDelete(messageId)` → set add (unknown/evicted id = no-op).
  - `applyClearUserMessages(targetUserId)` → scan visible `messages`, add
    every id whose `chatterUserId` matches.
  - `applyChatClear()` → add all current ids + append the banner notice
    (afterSeq = current arrivalSeq). **Empty chat = full no-op** (no
    tombstones, no banner) — nothing was deleted, so nothing is marked;
    mirrors Twitch showing nothing, and keeps the window's
    `messages.isEmpty` empty-states correct.
- Cap pruning: the index-0 eviction at `kMaxMessages` also drops the evicted
  id from `deletedMessageIds` — the set stays bounded by the same 500.
- Logout/`_disconnectChat` clears the set and the notices alongside
  `messages`.
- No `messageId` dedup exists today (duplicates double-render); tombstoning
  is id-based, so duplicate rows all tombstone together — no special casing
  needed.

### Rendering

- `TwitchChatMessageRow` reads `deletedMessageIds.contains(event.messageId)`
  in its own Observer (the badge pattern) — tombstone branch keeps
  username/badges, renders the body as italic dimmed `<message deleted>`,
  and skips emote/third-party/badge parsing for the body.
- The window merges `messages` + `systemNotices` by arrival sequence in its
  builder (O(n) at n ≤ 501, notices are rare); notices render as centered
  divider rows.
- **Pause chip:** in the window's Stack, the single `_unreadWhileScrolledUp`
  branch becomes two states of one chip: unread-arrived → accent
  "New messages ↓" (today), otherwise-when-unpinned → dimmer "Paused ↓".
  Same tap handler (re-pin + `_scrollToBottom()`). No new state fields.

## Error handling

- Lifecycle subscription POST failure → `advLog` + continue without
  tombstones for the session.
- Malformed lifecycle notification → defensive parse throws inside the
  service's per-notification try/catch → logged, session and other
  notifications unaffected.
- Lifecycle events for evicted/unknown ids → no-ops (set semantics).
- `/clear` under load: O(visible), bounded by the 500 cap.

## Testing (TDD, established harnesses/fakes)

- **Service:** 4 subscription POSTs with correct type/condition bodies;
  dispatch routes each lifecycle type to its handler; lifecycle-POST failure
  leaves the session live (messages still flow); malformed lifecycle frame
  logged + swallowed.
- **Store:** single delete; user-purge matches only `chatterUserId`,
  idempotent, evicted-id no-op; `/clear` tombstones all + appends notice;
  cap eviction prunes the id set; logout clears set + notices.
- **View:** row tombstone branch (username kept, body replaced, no emote
  parsing); notice divider in merged position; chip states
  (pinned → none; unpinned + no unread → "Paused ↓"; unpinned + unread →
  "New messages ↓") + tap-to-resume.

## Out of scope

- Wave C (per-message mod actions: delete/timeout/ban buttons) — consumes
  this wave's tombstone infra.
- Mod-only "Deleted Messages: Brief/Full" visibility modes (Twitch mod
  preference) — our tombstone is always-on, single rule.
- AutoMod held-message queue (Wave E), channel modes (Wave D).
- Any new scope or auth-flow change (none needed).
- WebView engine, YouTube/Owncast, tablet-specific behavior (unchanged).

## Dogfood notes (for the handoff)

- Single delete from twitch.tv mod tools → tombstone in OBS Blade.
- Timeout a chatty user → all their visible messages tombstone.
- `/clear` → everything tombstones + banner; new messages flow after it.
- Kill the lifecycle subscriptions (e.g. revoke mod status edge) → chat still
  works, no tombstones (degrade path).
- Scroll up slowly/quickly → "Paused ↓" chip; new message while paused →
  pill flips to "New messages ↓"; tap → resume at bottom.
- 500-cap rollover after tombstones → no growth/leak (spot-check only).
