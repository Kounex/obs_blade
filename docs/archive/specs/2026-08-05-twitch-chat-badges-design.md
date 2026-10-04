# Twitch native chat — badges & role toggles (design)

Date: 2026-08-05 · Status: approved design (pre-plan) · Track: native Twitch chat, Phase 2

## Context

The native Twitch chat (Phase 1) renders messages without the role badges Twitch
shows next to usernames (broadcaster, moderator, VIP, subscriber, …). Users read
chat hierarchy at a glance from these; the WebView engine gets them "for free"
from Twitch's embed, the native engine must render them itself.

User request: render the badges **and** provide per-category visibility toggles
("mods, subscriber, any roles / titles? maybe more?").

## Decisions (from brainstorming)

- **Toggle set:** core six — broadcaster, moderator, VIP, subscriber, founder,
  bits — plus one **"Other badges"** toggle covering everything else
  (sub-gifter, staff, admin, partner/verified, premium, artist, moments, …).
- **Toggle placement:** a bottom sheet opened from the native-mode chat bar
  ("sheet next to the chat"), not the main Settings page.
- **Settings seam:** the sheet is the generic seam for future native-chat
  platforms — one "Native chat options" sheet whose body is built per selected
  platform; today it renders only the Twitch section. Settings keys are
  platform-namespaced. **No** abstract `NativeChatOptions` interface (YAGNI
  with one implementer).
- **Badge catalog:** separate `TwitchBadgeStore` (approach A) — not folded into
  `TwitchChatStore`, not resolved at message-ingest time. Lookup happens at
  render time so toggles and late catalog loads "just work" via `Observer`.
- **Defaults:** all toggles ON.
- **Native engine only.** The WebView engine already shows Twitch's own badges.

## Verified API facts

- Every EventSub `channel.chat.message` payload already carries
  `badges: [{set_id, id, info}]` (e.g. `{set_id: "subscriber", id: "12",
  info: "12"}`). We receive but currently don't model it.
- Badge images come from Helix:
  - `GET /helix/chat/badges/global` — global sets (moderator, vip, founder,
    bits tiers, staff, premium, …)
  - `GET /helix/chat/badges?broadcaster_id=<id>` — channel sets (subscriber
    tenure variants, channel bits-tier overrides, …)
  - Both accept **any app or user access token — no additional scope**. The
    Phase 1 device-flow token (`user:read:chat`) works as-is; no re-login.
  - Response shape: `{data: [{set_id, versions: [{id, image_url_1x,
    image_url_2x, image_url_4x, title, description}]}]}`
- Badge lookup key is the exact `(set_id, id)` pair from the message; fall back
  to the global catalog when the channel catalog lacks the set.
- Images are plain PNGs on `static-cdn.jtvnw.net`, no auth needed. The project
  has **no** image-caching dependency and gets none — `Image.network` with the
  `image_url_2x` URL (retina-sharp, still tiny) is enough.

## Architecture

### 1. Message DTO — model the badges array

`lib/types/classes/twitch/eventsub/channel_chat_message.dart`

- New freezed class `ChatMessageBadge` with `setId`, `id`, and `info` (String?
  — empty string in payloads, treat leniently).
- `ChatMessageEvent` gains `badges` with `@Default(<ChatMessageBadge>[])`
  (absent in some payload variants → empty list).
- Update the file's doc comment: badges are now modeled; cheer/reply remain
  intentionally unmodeled.

### 2. Helix catalog DTOs

New file `lib/types/classes/twitch/twitch_chat_badges.dart` (freezed, same
pattern as `twitch_user.dart`):

- `TwitchBadgeSet { setId, List<TwitchBadgeVersion> versions }`
- `TwitchBadgeVersion { id, imageUrl1x, imageUrl2x, imageUrl4x, title }`
- Top-level parse helpers unwrap Helix's `{data: [...]}` envelope (see
  `TwitchAuthService.fetchOwnUser` for the established pattern).

### 3. `TwitchBadgeService` — Helix calls

New file `lib/utils/twitch/twitch_badge_service.dart`, mirroring
`TwitchAuthService`'s style (`http.Client` injectable for tests, throws
`TwitchAuthException` with `statusCode` on non-200):

- `Future<List<TwitchBadgeSet>> fetchGlobalBadges(String accessToken)`
- `Future<List<TwitchBadgeSet>> fetchChannelBadges(String accessToken, String broadcasterId)`
- Reuses `TwitchAuthService.helixHeaders`; lift the private `_kHelixBase` const
  into a shared `kTwitchHelixBase` (keeps one definition of the Helix root).

### 4. `TwitchBadgeStore` — catalog cache

New file `lib/stores/views/twitch_badges.dart` (MobX, GetIt lazy singleton
registered in `lib/main.dart` next to `TwitchChatStore`):

- Observables: global catalog and per-channel catalog, each
  `setId → (versionId → TwitchBadgeVersion)`; `bool isLoading`.
- `Future<void> fetch({required String accessToken, required String broadcasterId})`
  — fetches both endpoints in parallel; writes results in one action. Guarded
  by a generation counter (same staleness idea as `_loginFlow` in
  `TwitchChatStore`) so a superseded fetch can't clobber a newer catalog.
- `TwitchBadgeVersion? badgeVersion(String setId, String id)` — channel catalog
  first, global fallback; `null` when unknown (row skips it).
- `clear()` — drops both catalogs (called on logout).
- **In-memory only** — refetched per chat connect, no Hive persistence.
- Failures degrade silently: `GeneralHelper.advLog` + keep prior catalog; chat
  is never blocked by badges. A failed channel fetch with a successful global
  fetch still yields global badges.

### 5. Trigger wiring (minimal `TwitchChatStore` change)

- `connectChat()`: after the EventSub session connects successfully, kick off
  `TwitchBadgeStore.fetch(accessToken: token, broadcasterId: user!.id)`
  unawaited (errors logged, never rethrown). Reconnects harmlessly refetch.
  The store is resolved through a constructor seam (same injectable pattern as
  `eventSubFactory`) so unit tests substitute a fake.
- `logout()` also calls `TwitchBadgeStore.clear()`.
- No other `TwitchChatStore` behavior changes; no `DashboardStore` changes.

### 6. Rendering — `twitch_chat_message_row.dart`

- Wrap the row in (or add) an `Observer` watching `TwitchBadgeStore` and the
  badge toggle settings.
- Render the message's badges **before the username**, in payload order:
  18×pt images (scaling with text scale factor), `AppSpacing.xs` gap, aligned
  to the username baseline line-height; last badge → username gap
  `AppSpacing.sm`.
- Per badge: look up `badgeVersion(setId, id)`; skip when `null` or when its
  category toggle is off. `Image.network(version.imageUrl2x)` — no placeholder
  chrome, no error widget (a broken badge image renders as nothing, message
  text stays intact).

### 7. Toggles — settings keys & filter mapping

Seven new `SettingsKeys` entries (`lib/types/enums/settings_keys.dart`, both
the enum doc-comment style and the kebab-case `name` map):

| Key | name | Badge `set_id`s |
|---|---|---|
| `TwitchChatBadgeBroadcaster` | `twitch-chat-badge-broadcaster` | `broadcaster` |
| `TwitchChatBadgeModerator` | `twitch-chat-badge-moderator` | `moderator` |
| `TwitchChatBadgeVip` | `twitch-chat-badge-vip` | `vip` |
| `TwitchChatBadgeSubscriber` | `twitch-chat-badge-subscriber` | `subscriber` |
| `TwitchChatBadgeFounder` | `twitch-chat-badge-founder` | `founder` |
| `TwitchChatBadgeBits` | `twitch-chat-badge-bits` | `bits` |
| `TwitchChatBadgeOther` | `twitch-chat-badge-other` | every other `set_id` |

- All read with `defaultValue: true` via the existing Settings-box access
  pattern (same as `SettingsKeys.WakeLock`).
- Filtering is pure render-time: a small helper maps `setId → SettingsKeys`
  (the six exact, else `Other`) — unit-testable without Flutter.

### 8. Options sheet — the shared seam

- New widget `NativeChatOptionsSheet` under
  `lib/views/dashboard/widgets/obs_widgets/stream_chat/`:
  - Opened via `ModalHandler.showBaseBottomSheet` (established pattern).
  - Title "Native chat options"; body built per selected `ChatType` — today
    only a Twitch section: section header + 7 switch rows (label + adaptive
    switch, ≥44pt row height, `AppSpacing`/`AppRadius` tokens, `Pressable`
    where tappable rows are used).
  - Future platforms add their section to this sheet's body switch — no new
    entry points in the bar.
- Entry point: a 44pt options icon button (sliders icon) in the native-mode
  control area of the username bar, next to the account chip / connect pill
  (`twitch_account_control.dart` / `chat_engine_switch.dart` area). Visible
  whenever the native engine is selected — toggles apply independent of login
  state.
- Toggling writes the Settings box immediately; the message list re-filters
  live via `Observer`.

## Error handling & edge cases

- Catalog fetch failure (offline, 401 mid-session, Twitch 5xx) → log, keep
  prior catalog, messages render without (or with stale) badges. Never blocks
  or errors chat.
- Superseded fetch (rapid reconnect / account switch) → generation guard drops
  stale results.
- Badge with unknown `(set_id, id)` (new Twitch badge set, catalog not yet
  loaded) → skipped silently.
- `badges` absent/empty in a message → no badge slot rendered at all.
- All toggles off → row renders exactly as today (username + message).

## Testing

- **Unit** (`test/chat/`):
  - `ChatMessageEvent` parsing with badges, with absent badges field, with
    empty `info`.
  - Catalog DTO parsing (Helix envelope unwrap, versions).
  - `TwitchBadgeStore`: lookup precedence (channel > global), unknown → null,
    generation guard drops stale fetch, failure keeps prior catalog (service
    injectable / fakeable, `http.Client` mocked like auth service tests).
  - Toggle mapping helper: six exact set_ids → their keys, arbitrary set_id →
    Other.
- **Widget** (`test/chat/` or widget test dir per existing layout):
  - Message row renders badge images before the username; respects a disabled
    toggle; unknown badge skipped.
  - Options sheet: switches reflect persisted values, toggling writes the
    Settings box.

## Out of scope (explicit)

- 7TV / BTTV / FFZ badges (graceful-degrade policy stands).
- Badge tap actions, tooltips, tenure labels in the row.
- Other platforms' native options (the seam is built, their sections are not).
- Chat input / sending, chat container UI, entitlement gating.
- `user:write:chat` scope addition (belongs to the send-message phase).

## Docs hygiene

No credentials, user ids, or LAN details in code, tests, or docs; the public
Twitch client id reuse follows the existing `kTwitchClientId` precedent.
