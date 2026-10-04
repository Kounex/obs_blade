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
pattern from the YouTube setup sheet applies when the build has no
app-owned client. The shipping path is one OBS Blade Kick app, compiled
in from gitignored `docs/private/kick_oauth.json`
(`--dart-define-from-file`); the secret stays out of this public repo.
Redirect handling is manual-paste (no deep-link infra) — see "open
decisions" below.
Numeric rate limits are unpublished; handle 429.

## Channel discovery (Add chat sheet) — verified 2026-10-03

The official API has **no channel search and no follows / "channels I
moderate" list** (checked against `/swagger/doc.yaml`). What exists:

- **Search:** `GET kick.com/api/search?searched_word=` (the website's own,
  anonymous, same Cloudflare rules as `/api/v2` — app User-Agent). 3+
  characters (shorter: 400 "Please enter at least 3 characters"); answers
  `channels[]` (top 20 by followers: `slug`, `isLive`, `followers_count`,
  `verified` object-or-null, `user.username`), plus `categories[]` /
  `livestreams[]`. Undocumented — the picker keeps a paste-the-slug row.
- **Popular live:** official `GET /public/v1/livestreams?sort=viewer_count&
  language=de&limit=25` filters by ISO 639-1 language; needs **a token**
  (any user token, no scope; or an app token). Marked deprecated; v2 has
  `language_code` but no viewer sort (oldest first, cursor). The anonymous
  website listing (`kick.com/stream/livestreams/{lang}`) **ignores the
  language** (global top 32) — not usable for "in your language". Top
  lists are dominated by `has_mature_content` casino streams; the picker
  drops those.
- **Follows:** `kick.com/api/v2/channels/followed` needs the website
  session cookie (401 with nothing else) — no list possible.

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
| First-party emotes | ✅ | inline tokens + `files.kick.com` CDN + `/emotes/{channel}` list (verified 2026-09-23: this single call bundles the channel's own set AND Kick's platform-wide `Global`/`Emojis` sets — no separate global endpoint exists, but none is needed) |
| 7TV third-party emotes | ✅ | `7tv.io/v3/users/kick/{kick_user_id}` first-class; BTTV/FFZ: no Kick support |
| Pinned messages | ✅ | `PinnedMessageCreated/DeletedEvent` |
| Replies | ✅ | `type:"reply"` + metadata; send via `reply_to_message_id` |
| Viewer count | ✅ | `livestream.viewer_count` on channel payload |
| Raids/hosts | 🔶 | `StreamHostEvent` (host = Kick's raid-ish) |
| Polls / predictions | 🔶 read-only events | no public create/vote API; predictions payload undocumented |
| Multi-chat (other channels) | ✅ | subscribe per chatroom; entries ride `KickUsernames` |

## Not planned (vapor)

Warn/announce/AutoMod/unban-requests (no API), room-mode writes (no API),
polls/predictions UI (read-only events), BTTV bridge (no Kick namespace —
7TV is Kick's only third-party emote provider).

## Open decisions / risks

- Pusher key longevity (uncontractual) — single constant + fallback comment.
- `api/v2/*` is Cloudflare-fronted. A browser User-Agent from dart:io is
  blocked by the security policy (home networks included); reads send
  `User-Agent: OBSBlade`. Datacenter IPs can still 403.
- Kick Developer Terms are gated behind app creation — review before store
  submission of the write path.
