# Multi-chat (native Twitch) — design

**Date:** 2026-08-09 · **Status:** approved (design), pre-plan · **Process tier:** M

## Intent

The native Twitch chat today is hardwired to the logged-in user's own channel
(`TwitchChatStore` singleton; `user.id` doubles as the channel everywhere).
Multi-chat lets users add *other* streamers' chats — because they moderate
them or simply want to view/chat there — and switch between them. The user's
own channel stays the main/default one.

## Ratified decisions (from brainstorming)

| Question | Decision |
|---|---|
| Simultaneous panes? | **No** — one visible chat at a time with fast switching |
| Capabilities in other channels | **View + chat + mod actions** (delete / timeout / ban where you're a mod) |
| Discovery sources | **All three**: Search Channels autocomplete, "Channels you moderate", "Channels you follow" |
| Switching UX | **Dropdown in the chat bar** (native branch of `ChatUsernameBar`, `UsernameDropdown` idiom) |
| Relation to WebView engine | **Native-only list** — WebView's `TwitchUsernames` / `SelectedTwitchUsername` untouched |
| Non-visible channels | **Connect-on-switch** — only the visible channel holds live EventSub subs; in-memory per-channel history survives switching back |
| Architecture | **A: parameterize `TwitchChatStore`** — singleton stays, channel id threaded through; per-channel buffers are the seam if multi-pane ever returns |
| Process tier | **M** — 1 implementer subagent + 1 end reviewer, prose mini-plan, gates once at wrap-up |

Rejected: store-per-channel registry (B) — pays a real refactor (GetIt churn,
per-instance lifecycle, UI rebinding) for a deferred option; connect-on-switch
would tear instances down anyway.

## 1. Data model & persistence

New additive keys in the settings box (`HiveKeys.Settings`, untyped
`Box<dynamic>`) — no migration of existing data:

- `NativeChatChannels`: persisted list of `{id, login, displayName, addedAt}`
  (small typed model or map list, matching existing settings-box patterns).
  The user's **own channel is never stored here** — it's derived from
  `TwitchAuth` and always pinned first.
- `SelectedNativeChatChannelId`: `String?` — `null` = own channel (the
  default; existing users see zero behavior change).

In-memory only (never Hive, matching today's chat-content model):

- Per-channel message buffer cache: `Map<channelId, List<ChatMessageEvent>>`
  (same 500 cap as the live list) plus tombstone sets/maps and
  `systemNotices` snapshots, so switching back restores recent history.
  Dies with the app session.

WebView engine, `TwitchUsernames`, `SelectedTwitchUsername`: **untouched**.

New key constants go in `lib/types/enums/settings_keys.dart` next to the
existing `TwitchChat*` keys.

## 2. Discovery picker & switching UX

**Add-chat picker** — "Add chat…" entry at the bottom of the channel
dropdown opens a bottom sheet:

- Debounced search field on top → Helix **Search Channels** typeahead
  (login + display name + follower count, live/offline indicator).
  Selecting a result resolves `id/login/displayName` once and stores it —
  replaces the WebView-era "spell it right" free text with validated picks.
- With an empty field, two quick-pick sections below:
  - **Channels you moderate** (Get Moderated Channels)
  - **Channels you follow** (Get Followed Channels, live first)
  Tapping adds the channel and closes the sheet.
- Already-added channels render checked/disabled; duplicate adds impossible.

**Switching** — native branch of `ChatUsernameBar`
(`lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart`)
gains a channel dropdown in the `UsernameDropdown` idiom:

- Own channel first (marked "You"), then added channels.
- Channels you moderate carry a small shield marker (from the moderated set).
- Remove affordance: long-press a channel row in the dropdown → confirm →
  removed from `NativeChatChannels`; removing the selected channel falls
  back to own channel.

## 3. Connection lifecycle & per-channel catalogs

**`TwitchChatStore`** (`lib/stores/views/twitch_chat.dart`, stays a GetIt
singleton):

- New observables: `selectedChannelId` (`null` = own), the persisted
  channels list, the moderated-channel id set.
- Effective broadcaster id = selected channel or own id; threaded through:
  - EventSub subscription conditions in
    `TwitchEventSubService._createSubscriptions`
    (`lib/utils/twitch/twitch_eventsub_service.dart`) —
    `broadcaster_user_id` = effective channel, `user_id` = own id (session
    user) stays. The service's single `_userId` field becomes
    `{sessionUserId, broadcasterId}`.
  - `sendChatMessage` → `broadcaster_id` = effective channel,
    `sender_id` = own id (`lib/utils/twitch/twitch_message_service.dart`).
  - Catalog fetches (badges, third-party emotes, first-party emotes).
- `selectChannel(id)`:
  1. Snapshot current messages/tombstones/notices into the buffer map.
  2. Drop the old channel's EventSub subscriptions
     (`_subscriptionIds` already tracks ids for teardown).
  3. Create subs for the new channel on the **same websocket session** —
     no reconnect.
  4. Restore the new channel's cached buffer (or empty list).
  5. Re-fetch badges/emotes for the new channel.
  Chat bar shows a brief connecting state during the switch.
- `channel.moderate` v2 stays **own-channel only** (condition
  `moderator_user_id` = you + `broadcaster_user_id` = you) — unchanged; it
  exists for the deleting-mod reveal on your own tombstones.

**Catalog stores** become per-broadcaster keyed:

- `TwitchBadgeStore` (`lib/stores/views/twitch_badges.dart`): single
  `channelBadges` slot → `Map<broadcasterId, …>`.
- `ThirdPartyEmoteStore` (`lib/stores/views/third_party_emotes.dart`): same
  treatment (service `fetch({broadcasterId})` already parameterized).
- `TwitchEmoteStore` (`lib/stores/views/twitch_emotes.dart`): service
  `TwitchEmoteService.fetchUserEmotes(accessToken, userId:, broadcasterId:)`
  already takes a separate `broadcasterId` — pass the effective channel;
  update the now-stale "userId doubles as broadcasterId" comment
  (`twitch_emotes.dart:49`).
- Emote picker in another channel shows that channel's emotes + your usable
  sets.

**UI widgets**: `NativeChatWindow` / `NativeChatInput` are already
channel-agnostic (params only, `native_chat_window.dart:44`) — no
structural change; all `StreamChat` instantiation sites share the singleton
and therefore all show the selected channel (intended with one visible
chat).

## 4. Mod actions & scopes

**Mod detection**: on login (cached per session), call **Get Moderated
Channels** → set of channel ids the user moderates. Own channel counts as
full-mod implicitly (broadcaster). This set gates the dropdown shield
markers and the mod action sheet.

**Action UI**: in a channel you mod, tapping a live message opens an action
sheet:

- **Delete message** → Helix Delete Chat Messages → tombstone immediately.
  EventSub `message_delete` also arrives — **dedupe by `messageId`** so the
  local tombstone and the EventSub one don't double up (the same dedup
  mechanism is the fix class for the known duplicate-`/clear` double-banner
  review note).
- **Timeout…** → duration presets (10 min / 1 h / 24 h) → Helix Ban User
  with `duration`.
- **Ban** → Helix Ban User without `duration`.

Timeout/ban purge that user's messages to tombstones locally; EventSub
confirms. In channels you don't mod there is no action sheet — tap keeps
its current meaning (actor reveal on tombstones only).

**New scopes** (silent scope-upgrade consent, same pattern as the
moderation bundle):

| Scope | Enables |
|---|---|
| `user:read:follows` | followed-channels picker section |
| `moderator:read:moderated_channels` | moderated section + mod gating |
| `moderator:manage:chat_messages` | delete message |
| `moderator:manage:banned_users` | timeout / ban |

Pre-upgrade tokens degrade per capability: picker shows search only, no
shield markers, no mod actions; locked capabilities show the established
re-login CTA pattern. New Helix calls live in small services next to
`TwitchMessageService` (`lib/utils/twitch/`), thin DTOs under
`lib/types/classes/` per existing conventions.

## 5. Error handling

- Picker fetch failures (search / followed / moderated) are independent —
  failed section shows inline error + retry; the rest keep working.
- Send rejected by the channel (banned, followers-only, …) → Helix error
  surfaces via the existing `chatError` banner path; no optimistic insert
  (unchanged rule).
- Switch-to-channel subscription failure → chat pane shows error state
  with retry; dropdown unaffected (no silent revert).
- Mod action failure (e.g. mod status revoked) → snackbar, no local
  tombstone; moderated set re-fetched on next login.
- Removing the selected channel → fall back to own channel.

## 6. Testing & dogfood

Unit tests (`test/chat/`, existing mock-service patterns):

- Channel switching: buffer save/restore, sub teardown/creation on the
  shared session, connecting state.
- Mod gating from the moderated set (incl. own-channel implicit mod).
- `messageId` dedup (delete + `/clear` paths).
- New persistence keys round-trip; `null` selected id = own channel.
- Catalog per-broadcaster keying (two channels' catalogs coexist).

Widget tests: picker sheet (search results, sections, duplicate-disabled),
channel dropdown (own-first order, shield markers, remove → fallback).

Dogfood checklist (real Twitch, fresh login — consent screen now bundles
12 scopes, sanity-check readability first):

1. Search-add a channel by partial name; add from "Channels you moderate"
   and "Channels you follow"; duplicates disabled.
2. Switch between channels: fast, history restored on return, badges /
   emotes / third-party emotes correct per channel.
3. Chat in another channel (send + receive).
4. In a channel you mod: delete a message, timeout (preset), ban →
   tombstones/purges locally and on twitch.tv; no double tombstones.
5. Emote picker per channel; deleted message with emotes renders dimmed.
6. Pre-upgrade token: search-only picker, no shields, no mod actions,
   CTA shown.

## Out of scope (explicit)

- Multiple simultaneous panes (seam kept via per-channel buffers).
- WebView engine changes.
- `channel.moderate` v2 for other channels (own-channel only).
- Custom timeout durations / reasons, unban, other mod endpoints.
- Unread badges (requires keep-warm, rejected).
