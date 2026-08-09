# Native chat user card — design

**Date:** 2026-08-09 · **Status:** approved (design) · **Process tier:** M

## Intent

Let viewers inspect a chatter the way Twitch’s web viewer card does: avatar,
identity, badges, account facts, and that user’s recent messages in the
current channel. The same card is the home for **yourself** when opening the
header “connected” control, with today’s connection actions kept underneath.

## Ratified decisions

| Question | Decision |
|---|---|
| Implementation shape | Shared `ChatUserCardSheet` + thin Helix helper (not forked self/other sheets) |
| Username / badges tap | Opens user card |
| Links in message body | Keep existing confirm-and-open (nested detectors win) |
| Mod actions | **Long-press** on the message row → existing mod sheet (only when `canModerateSelectedChannel`) |
| Header “connected” | **Merged sheet**: self user card + connection block (status, uptime, Retry / Log out / Connect) |
| Data richness (v1) | Match Twitch as closely as scopes/APIs allow; hide rows that fail or lack scope |
| Out of scope v1 | Twitch bell / open-on-twitch icons, whisper, block/report, WebView chat |

## 1. Interactions

### Message row (`TwitchChatMessageRow`)

- Wrap **badges + username** in a tappable target → `showChatUserCardSheet(userId, …)`.
- Do **not** wrap the whole row in a short-tap mod handler anymore.
- When the row may be moderated: `onLongPress` → `showModActionSheet` (same sheet as today).
- Deleted-message reveal tap stays as today (short tap on tombstone).
- Link `WidgetSpan`s unchanged.

### Header (`NativeChatWindow`)

- Status / “connected” pressable opens the **merged** sheet for the logged-in
  user (`user.id` from `TwitchChatStore`), not the bare connection sheet alone.
- Offline / degraded / live connection actions remain in the bottom section
  of that sheet (reuse the existing action rows and uptime line).

## 2. Sheet UI

Bottom sheet (`ModalHandler.showBaseBottomSheet`, `maxHeightFraction` ~0.85,
barrier dismissible, drag enabled), scrollable body.

**Header**

- Circular avatar (`profile_image_url`; placeholder if missing)
- Display name in chatter color when known (from latest buffered message /
  event color; else theme primary)
- Optional `@login` under the name when it differs from display name
- Horizontal badge row from the user’s **latest** buffered `ChatMessageEvent`
  in the current channel (same badge store / toggles as the list)

**Account facts** (each row: icon + one line; omit if unavailable)

| Row | Source | Notes |
|---|---|---|
| Account created on … | Helix `GET /users?id=` → `created_at` | Extend `TwitchUser` with optional `createdAt` |
| Following since … | See §3 | Hide if not following / no scope / error |
| Tier N — Subscribed for … | See §3 | Hide if not subscribed / no scope / error |

**Messages**

- Hairline + centered **LIVE** label (channel-live accent; reuse soft live
  coral already used for viewer count when theming)
- Up to **20** of that user’s messages from the **current channel buffer**,
  newest first, compact rows (timestamp + badges + name + body; reuse
  `TwitchChatMessageRow` in `compact: true` or a thin read-only variant)
- Empty: “No messages in this chat yet”
- Loading Helix: small spinner in the facts block only; messages can show
  immediately from the buffer

**Self / merged footer** (only when `userId == store.user?.id`)

- Divider
- Connection status chip/label + uptime when live (existing `_UptimeLine`)
- Retry / Log out when degraded; Connect when offline — same callbacks the
  header sheet has today

## 3. Helix + scopes

New thin helper (e.g. `TwitchUserService` or methods on an existing service):

| Call | Purpose | Scope |
|---|---|---|
| `GET /helix/users?id=` (and login for self already) | Avatar, login, display name, `created_at` | App access / user token (already) |
| `GET /helix/channels/followers?broadcaster_id=&user_id=` | Other user’s follow date for **selected** channel | **`moderator:read:followers`** (add to `kTwitchChatScopes`) |
| `GET /helix/channels/followed?user_id=&broadcaster_id=` | Self follow date for selected channel | `user:read:follows` (already) |
| `GET /helix/subscriptions/user?broadcaster_id=` | Self sub to selected channel | **`user:read:subscriptions`** (add to `kTwitchChatScopes`) |
| Broadcaster `GET /helix/subscriptions?broadcaster_id=&user_id=` | Other user’s sub | `channel:read:subscriptions` — **do not add in v1** (broadcaster-only; hide row for others) |

**Degradation**

- Missing scope → omit that fact row (no re-login CTA required on the card;
  silent upgrade on next device login picks up new scopes, same as emotes).
- Network / 4xx → omit that row; still show buffer content + basic identity.
- Cache per `userId` for the sheet lifetime only (no Hive persistence).

## 4. Store / wiring

- `TwitchChatStore`: helper to list buffered messages for a `chatterUserId`
  in `effectiveBroadcasterId` (pure filter over the visible list / channel
  buffer — no new EventSub).
- Expose chatter color from the newest matching event when opening the card.
- `stream_chat` / `native_twitch_chat_view`: pass long-press + username tap
  callbacks; stop short-tap mod.
- Connection sheet content moves into a footer section of `ChatUserCardSheet`
  (or a composed `ChatSelfSheet` that is 90% the user card) so we don’t
  maintain two profiles.

## 5. Testing

- Widget: username tap opens card; long-press opens mod when allowed; link
  tap still confirms; short tap on body does nothing for mod.
- Widget: card shows buffered messages; facts omit when service returns null.
- Unit: user DTO parses `created_at`; follow/sub helpers map Helix JSON.
- Existing connection-sheet tests retargeted to the merged self sheet.

## Non-goals / follow-ups

- Other-user subscription months without broadcaster token
- Persistent user cache across sessions
- Actions: timeout/ban shortcuts on the card (long-press row remains the path)
