# Native chat user card — Implementation Plan

> **For agentic workers:** Tier **M** (project process policy). One implementer
> pass + one end review. Prefer inline / single implementer subagent over
> per-task SDD. Use TDD on the seams below; gates once at wrap-up.

**Goal:** Twitch-like user card on username/badge tap; long-press for mod;
merged self card when opening header “connected”.

**Architecture:** Shared `ChatUserCardSheet` loads Helix identity/facts via a
thin `TwitchUserService`, messages via `TwitchChatStore` buffer filter.
Message-row taps split: name/badges → card, links unchanged, long-press →
mod sheet. Header status opens the same sheet for `store.user` with a
connection footer.

**Tech stack:** Flutter, MobX/`TwitchChatStore`, Helix (`http`), existing
`ModalHandler` sheets, freezed `TwitchUser`.

**Spec:** `docs/superpowers/specs/2026-08-09-chat-user-card-design.md`

---

## File map

| File | Role |
|---|---|
| `lib/types/classes/twitch/twitch_user.dart` (+ freezed/g) | Add optional `createdAt` |
| `lib/utils/twitch/twitch_user_service.dart` | `fetchUser`, follow-since, self-sub |
| `lib/utils/twitch/twitch_auth_service.dart` | Add `moderator:read:followers`, `user:read:subscriptions` to `kTwitchChatScopes` |
| `lib/stores/views/twitch_chat.dart` | `messagesForChatter(userId)`, scope getters if needed |
| `lib/views/.../stream_chat/dialogs/chat_user_card_sheet.dart` | Sheet UI + `showChatUserCardSheet` |
| `lib/views/.../stream_chat/twitch_chat_message_row.dart` | `onAuthorTap`, `onMessageLongPress`; stop whole-row short-tap mod |
| `lib/views/.../stream_chat/native_twitch_chat_view.dart` | Wire card + long-press mod |
| `lib/views/.../stream_chat/native_chat_window.dart` | Header opens merged self card |
| `lib/views/.../stream_chat/stream_chat.dart` | Pass connection callbacks into card if needed |
| Tests under `test/chat/` | DTO, service fakes, row gestures, sheet, window |

---

### Task 1: Helix user DTO + service + scopes

**Behavior**
- `TwitchUser.createdAt` optional `DateTime?` from `created_at`.
- `TwitchUserService`: `fetchUser(id)`, `followerSince(broadcasterId, userId)` →
  `DateTime?` via `channels/followers`, `selfFollowedAt(userId, broadcasterId)`
  via `channels/followed` (single-user query), `selfSubscription(broadcasterId)`
  → `{tier, months}?` via `subscriptions/user`. All return null on 4xx / missing.
- Append scopes to `kTwitchChatScopes` as in the spec.

**Assert**
- JSON fixture with `created_at` parses.
- Service maps happy-path JSON; 403/404 → null (no throw to UI).

**Commit:** `feat(chat): Helix user service for viewer card facts`

---

### Task 2: Store buffer helper

**Behavior**
- `List<ChatMessageEvent> messagesForChatter(String userId)` — filter
  `messages` where `chatterUserId == userId`, newest first, cap 20.
- Optional: latest event’s `color` for the card header.

**Assert**
- Unit test with a few seeded messages / other chatters ignored / cap.

**Commit:** `feat(chat): filter buffered messages by chatter`

---

### Task 3: `ChatUserCardSheet` UI

**Behavior**
- `showChatUserCardSheet(context, {required userId, connection?})`.
- Header: avatar, colored name, `@login`, badges from newest buffered event.
- Facts rows omit nulls; spinner only on Helix block while loading.
- LIVE divider + compact message list (timestamps; `TwitchChatMessageRow`
  compact or equivalent; no author-tap recursion — pass null taps).
- When `connection != null` (self): divider + status/uptime/actions from
  today’s connection sheet.

**Assert**
- Widget: buffered messages render; fact row absent when service null;
  self footer shows Log out when degraded callback provided.

**Commit:** `feat(chat): user card bottom sheet`

---

### Task 4: Message row gesture split

**Behavior**
- Replace whole-row `onMessageTap` mod with:
  - `onAuthorTap` on badges+username
  - `onMessageLongPress` for mod
- Keep tombstone short-tap reveal; links unchanged.

**Assert**
- Widget: author tap fires card callback; long-press fires mod; short body
  tap does not; link still opens confirm path (existing coverage OK if
  author/long-press covered).

**Wire** in `native_twitch_chat_view.dart`.

**Commit:** `feat(chat): username opens card; long-press opens mod`

---

### Task 5: Header → merged self card

**Behavior**
- `NativeChatWindow` status tap opens `showChatUserCardSheet` for
  logged-in user id with connection footer params (status, callbacks).
- If offline and no user id, keep a minimal connect-only sheet (today’s
  offline branch) — don’t require a card with no identity.

**Assert**
- Update `native_chat_window_test.dart`: live+account opens card with
  “Connected as” / uptime; degraded still exposes Retry/Log out; barrier
  dismiss still works.

**Commit:** `feat(chat): merge self user card into connection header`

---

### Task 6: Gates + docs

- `flutter test test/chat/` (touched files + window/row/card/service).
- `flutter analyze` on touched libs — 0 errors.
- Brief `docs/changelog-agent.md` note; push if user wants / at handoff.

---

## Spec coverage check

| Spec § | Task |
|---|---|
| Username/badges → card | 4 |
| Long-press mod | 4 |
| Links unchanged | 4 (no change to link spans) |
| Merged self header | 5 |
| Avatar / created / follow / sub degrade | 1 + 3 |
| LIVE messages from buffer | 2 + 3 |
| Scopes | 1 |
| Other-user sub skipped | 1 (no broadcaster sub API) |

## Execution note

Secondary-model quota was exhausted earlier this wave — **implement
in-session (tier M controller as implementer)** unless quota recovers;
one self/end review of the diff; no per-task subagent swarm.
