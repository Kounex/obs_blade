# Kick chat audit (2026-09-22)

Fourth chat platform next to Twitch / YouTube / Owncast: WebView embed (free)
+ native engine (Pro). Everything below was **probed live** against kick.com
on 2026-09-22 unless marked otherwise. Research sources: Kick help center,
[docs.kick.com](https://docs.kick.com) + swagger, KickDevDocs repo,
[Digital39999's Pusher event-types gist](https://gist.github.com/Digital39999/ffe7df2bfc08797c2ba19d42e8f739a0),
chatterino7 Kick fork.

## WebView embed (free tier)

- URL: `https://kick.com/popout/{channel}/chat` — **documented by Kick
  themselves** for OBS chat docks (help.kick.com article 7978574). Verified:
  HTTP 200, no `X-Frame-Options` / `frame-ancestors`, dark-only UI (fits the
  app), read works logged out.
- Ask: channel slug or any kick.com link — `extractKickChannelSlug`
  (`lib/utils/kick_channel_slug.dart`) normalizes channel pages and the
  popout-chat link.
- No embed param, no consent-wall history known (unlike YouTube); the
  generic consent-wall hint added for YouTube (`stream_chat.dart`
  `_syncWebAuthWall`) is host-scoped to Google, so Kick doesn't false-trigger
  it.

## Native read (Pro) — Pusher websocket, no auth

Kick's chat fan-out runs on hosted Pusher (unofficial but ubiquitous —
Chatterino forks, bots, overlays all ride it; tolerated ecosystem):

- Socket: `wss://ws-us2.pusher.com/app/32cbd69e4b950bf97679` (protocol 7).
  App key is hardcoded in Kick's frontend, stable 2023→2026, **not
  contractual** — if it dies, re-scrape from browser devtools (single
  constant in `kick_pusher_service.dart`).
- Subscribe `chatrooms.{chatroom_id}.v2`; ping every 30s
  (`activity_timeout: 120`).
- Slug → ids: `GET /api/v2/channels/{slug}` (no auth) — returns chatroom id,
  chat modes (slow/followers/subscribers/emotes + intervals), subscriber
  badge artwork, livestream + viewer count.
- Backfill: `GET /api/v2/channels/{channel_id}/messages` (recent buffer).
- Live `ChatMessageEvent` payload captured verbatim: sender identity with
  **name color**, legacy `badges[]` (type/text/count: broadcaster, moderator,
  subscriber+months, sub_gifter, vip, og, founder, staff, verified) AND
  `badges_v2[]` with direct artwork URLs (`ext.cdn.kick.com/chat/badges/…`),
  reply metadata (`type:"reply"` + `original_sender`/`original_message`).
- Emotes: inline `[emote:{id}:{name}]` tokens →
  `https://files.kick.com/emotes/{id}/fullsize` (verified 200).
- Lifecycle events: `MessageDeletedEvent`, `UserBannedEvent`
  (`expires_at` null = perma, set = timeout), `UserUnbannedEvent`,
  `ChatroomClearEvent`, `ChatroomUpdatedEvent` (mode changes live),
  `PinnedMessageCreated/DeletedEvent`, `PollUpdate/DeleteEvent`,
  `StreamHostEvent`, `SubscriptionEvent`, `GiftedSubscriptionsEvent`.

## Native write / mod (Pro) — official API, BYO OAuth app

`https://api.kick.com/public/v1` (swagger: `/swagger/doc.yaml`):

| Action | Endpoint | Scope |
|---|---|---|
| Send message (as user, incl. replies) | `POST /chat` (`type:"user"`, `broadcaster_user_id`, `reply_to_message_id?`) | `chat:write` |
| Delete message | `DELETE /chat/{message_id}` | `moderation:chat_message:manage` |
| Timeout (1–10080 min) / ban | `POST /moderation/bans` (`duration?`) | `moderation:ban` |
| Unban / remove timeout | `DELETE /moderation/bans` | `moderation:ban` |

**Auth reality:** OAuth 2.1 auth-code + PKCE (S256 mandatory) at
`id.kick.com`. **No device flow** (probed: `/oauth/device/code` → 404) — so
no Twitch-style scan-a-code login. Any user can register an app
(2FA → kick.com/settings/developer), so the **BYO client id/secret**
pattern from the YouTube setup sheet applies. Redirect handling needs a
custom scheme / loopback — see "open decisions" below.
Numeric rate limits are unpublished; handle 429.

## Twitch → Kick capability map

| Twitch native feature | Kick | Notes |
|---|---|---|
| Realtime read (EventSub) | ✅ Pusher `ChatMessageEvent` | no auth, richer identity payload than Twitch IRC |
| Send (Helix) | ✅ `POST /chat` | needs user OAuth (BYO app) |
| Delete message | ✅ `DELETE /chat/{id}` + `MessageDeletedEvent` inbound | |
| Timeout / ban / unban | ✅ `POST/DELETE /moderation/bans` | `UserBannedEvent.expires_at` distinguishes timeout vs perma |
| Warn | ❌ | no endpoint/scope |
| Announce | ❌ | |
| Room modes r/w | 🔶 read only | `chatroom` object + `ChatroomUpdatedEvent`; **no write API** |
| AutoMod queue | ❌ | Kick has no AutoMod API |
| Unban requests | ❌ first-class | channel-points redemption is the idiomatic workaround — skip |
| Role badges | 🔶 partial | types+months in payload; artwork via `badges_v2` + channel `subscriber_badges`; mod/vip/broadcaster artwork not shipped → own assets or v2-only |
| First-party emotes | ✅ | inline tokens + `files.kick.com` CDN + `/emotes/{channel}` list; no verified global-emote endpoint |
| 7TV third-party emotes | ✅ | `7tv.io/v3/users/kick/{kick_user_id}` first-class; BTTV/FFZ: no Kick support |
| Pinned messages | ✅ | `PinnedMessageCreated/DeletedEvent` |
| Replies | ✅ | `type:"reply"` + metadata; send via `reply_to_message_id` |
| Viewer count | ✅ | `livestream.viewer_count` on channel payload |
| Raids/hosts | 🔶 | `StreamHostEvent` (host = Kick's raid-ish) |
| Polls / predictions | 🔶 read-only events | no public create/vote API; predictions payload undocumented |
| Multi-chat (other channels) | ✅ | subscribe per chatroom; entries ride `KickUsernames` |

## Build waves

- **W1 (landed, 5974b63c):** `ChatType.Kick` + WebView popout path, username
  management (slug extractor + dialog), all switch seams.
- **W2:** native read — Pusher client, backfill, buffers, tombstones / ban
  reconcile / clear banner, badges_v2 + emote inline rendering, Pro gate via
  the shared seams. No auth.
- **W3:** native write/mod — BYO OAuth (PKCE) setup sheet section, send +
  reply, delete/timeout/ban on long-press for modded channels. No "am I a
  mod" lookup exists — surface API 403s honestly (YouTube-minimal idiom).
- **Not planned (vapor):** warn/announce/AutoMod/unban-requests (no API),
  room-mode writes (no API), polls/predictions UI (read-only events), BTTV
  bridge (no Kick namespace), global emote picker (no list endpoint).

## Open decisions / risks

- W3 redirect handling: custom URL scheme `obsblade://` (needs iOS/Android
  manifest entries + app_links handling) vs loopback server (Kick docs flag a
  127.0.0.1 bug) vs manual code paste (zero infra, clunky). Decide at W3.
- Pusher key longevity (uncontractual) — single constant + fallback comment.
- `api/v2/*` is Cloudflare-fronted; datacenter IPs can 403 — fine on device.
- Kick Developer Terms are gated behind app creation — review before store
  submission of the write path.
