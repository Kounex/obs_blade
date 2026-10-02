# Activity feed — idea, decisions and third-party plan

Status: **v1 built 2026-10-03** (native sources + Kick events relay +
the third-party seam) - design and facts:
[`superpowers/specs/2026-10-02-activity-feed-design.md`](superpowers/specs/2026-10-02-activity-feed-design.md),
history: `changelog-agent.md` 2026-10-03. Open: StreamElements /
Streamlabs clients once their API access is approved (ownership rows
and the `ActivityLedger` gap-fill rules are already in place - a client
is a provider + a mapper). The sections below are the original notes
from 2026-09-27 / 10-02.

## The idea

One place where a streamer sees everything that happened on their channels
(subs, gifts, money, raids/hosts, follows, highlights), grouped usefully,
with a clear split between **new** and **already seen**, plus a **to-thank
queue** so nothing gets forgotten on air.

It's a streamer tool built on the "My chats" own-channel model (see
`AGENTS.md` § Combined chat). Most event types are only sent for your own
channel or channels you moderate.

## Decisions (user, 2026-09-27)

- **Timing:** parked. Ship 4.0 first. This is a 4.1-headline candidate.
- **Placement:** all three surfaces:
  - a Chat | Activity segment in the Chat tab (on tablet, side by side
    with chat),
  - an unread badge button in the chat bar,
  - an "N new" chip on the streaming-mode dashboard.
- **Seen model:** seen **and** thanked.
  - Seen: a per-channel high-water mark, shown as a "new since you last
    looked" divider, a badge count and a mark-all-seen action.
  - Thanked: a swipe on a row marks it thanked. Big events stay in the
    to-thank queue until they are handled.
- **First wave scope:** all of the following:
  1. existing events + Twitch follows, persisted,
  2. Twitch cheers / channel points / hype train (scope upgrade),
  3. per-stream sessions,
  4. third-party donations: StreamElements first, Streamlabs next
     (proposal in "Third-party sources" below).

  That is large. When it's planned, split it into shippable sub-waves in
  roughly that order.

## What already arrives (inventory 2026-09-27)

| Platform | Received and shown in chat today | Missing |
|---|---|---|
| Twitch | `channel.chat.notification`: sub, resub, sub_gift, community_sub_gift, raid, announcement, charity_donation, bits_badge_tier, watch_streak. First-time chatters via `isFirstMessage`. | follows, cheers as events, channel points, hype train, polls/predictions |
| YouTube | superChat, superSticker, newSponsor, memberMilestone, membershipGifting, poll (`YouTubeChatMessageType.parse`) | new channel subscribers (the live chat API doesn't expose them) |
| Kick | subscription, giftedSubscriptions, streamHost (`KickChatroomEventKind`; payload shapes are guessed, no live capture yet) | follows, Kicks gifts (the official API sends these as webhooks only, which needs a server) |

Code anchors:
- Twitch: `ChatNotificationEvent` in
  `lib/types/classes/twitch/eventsub/channel_chat_notification.dart`,
  appended in `TwitchChatStore._appendNotification`.
- YouTube: typed details in `lib/types/classes/youtube/youtube_chat_message.dart`.
- Kick: `_applySubscription` / `_applyGiftedSubscriptions` /
  `_applyStreamHost` in `lib/stores/views/kick_chat.dart`.
- Visibility toggles: `ChatNoticeCategory` / `KickChatNoticeCategory`.

**Core gap:** nothing is persisted. Events are rows in the in-memory chat
buffer (`kMaxMessages = 500`), so a busy chat pushes them out in minutes and
a restart loses them. The feed needs its own event store that is
separate from chat and persisted in Hive. It needs a new `TypeIDs` entry,
so follow `persistence-risk.md`.

## Sketch

- **Normalized event model:** platform, channel, kind, actor, amount
  (bits / currency + value), grouped children (a gift bomb is one row
  that expands to its recipients), timestamp, `seen`, `thanked`.
- **Ingest:** tap the existing per-platform append points and add the
  new sources. Chat keeps rendering its notice rows as it does today.
- **Grouping:** by stream (sessions from the go-live/offline signals we
  already have, with a "This stream" totals header), by person (history
  across streams, which needs persistence), and by type via filter
  chips.
- **Money:** normalized per currency and never converted (bits stay bits).

## New sources to add (*verify* each against the live docs)

- Twitch follows: EventSub `channel.follow` v2 with the
  `moderator:read:followers` scope, which we already request. Get Channel
  Followers can backfill follows missed while the app was closed.
- Twitch cheers `channel.cheer` (`bits:read`), channel points
  `channel.channel_points_custom_reward_redemption.add`
  (`channel:read:redemptions`), hype train `channel.hype_train.*`
  (`channel:read:hype_train`). Request these as one silent scope-upgrade
  bundle, same pattern as `kTwitchManageModToolingScopes`.
- Third-party sources: researched 2026-10-02, see the next section.

## Third-party sources (researched 2026-10-02)

Checked against the live developer docs (sources at the end of this
section). "Unverified" marks what the docs didn't settle.

### Options

| Service | Realtime | Auth / registration | Without our backend? |
|---|---|---|---|
| StreamElements | Astro: plain WebSocket `wss://astro.streamelements.com`, JSON subscribe, server PING every 30 s, `reconnect` message with a resume token | OAuth2 code grant. Client id/secret by **request form** (manual approval). Secret needed for exchange **and refresh**; access tokens last 7-30 days. Alternative: the user's own JWT ("Show secrets" on the SE account page), which SE says is for personal use and must not go in front-end code | Yes with a token-exchange host (same pattern as `tool/kick_auth_proxy/`, which already does refresh). Socket: `web_socket_channel` is enough |
| Streamlabs | Socket.IO `sockets.streamlabs.com?token=` (socket token from `GET /socket/token`, scope `socket.token`) | Self-serve OAuth app; **only 10 whitelisted users until Streamlabs approves it**. Secret in the code exchange; tokens don't expire | Needs the exchange host + a Socket.IO client (none in `pubspec.yaml`; server protocol version unverified) |
| Streamer.bot | WebSocket server on the streaming PC, port 8080, `127.0.0.1` by default (user must switch to `0.0.0.0` for LAN), optional password with salt/challenge SHA-256 | None, no app review | Yes, LAN only, Windows only. Brings Ko-fi, Fourthwall, Throne, TipeeeStream, DonorDrive, Streamlabs, StreamElements |
| TipeeeStream | Socket.IO, user API key or OAuth | User key | Yes. Mostly a French-speaking user base |
| DonationAlerts | Centrifugo WebSocket, scope `oauth-donation-subscribe`, private channels signed via their REST API | OAuth | Yes. Mostly a Russian/CIS user base |
| Ko-fi, Fourthwall, Patreon, Throne | Webhooks only (Ko-fi verified; the rest not checked one by one) | - | No. Needs the relay from `docs/private/` backend plan, or reach them through SE (lists `fourthwall`) / Streamer.bot |

Streamlabs Desktop is not a target here: it has its own remote API
(port 59650) instead of obs-websocket, so its users can't use OBS Blade
anyway. Our users run OBS Studio and can pick either cloud, which makes
SE (free, browser-source based, no cut on tips) a good first fit. Streamlabs
still has the larger registered base (~30M vs ~1M+ monthly active on SE,
vendor/blog figures), so its tip page is the biggest gap after SE.

### Proposed first version: native + StreamElements

Native stays the primary source. SE only adds what native can't get, plus
history. One optional SE login per "My chats" channel.

**What SE adds over native** (types from `channel.activities`; per-type
coverage on Kick and YouTube unverified until a live capture):

- **Tips** from the SE tip page (`channel.tips`, scope `tips:read`):
  amount, ISO currency, message, PayPal/transaction id. Nothing native
  has this.
- **Merch** (SE merch, Fourthwall, Represent providers).
- **Kick:** follows and KICKs gifts (SE added KICKs on 2026-09-13).
  Natively both are webhook-only for us.
- **YouTube new channel subscribers**, which the live chat API never
  sends. SE notes these can lag by hours.
- **History / backfill:** `GET /kappa/v2/activities/{channel}` (scope
  `activities:read`) with `after`/`before`/`limit`/`types` (v3 has
  cursor paging). This is SE's own stored activity feed, so it covers
  time the app was closed, on every platform SE sees.

**Ownership rule (live events).** Every (platform, kind) pair has exactly
one owning source, so live duplicates never happen and no fuzzy matching
is needed live:

| Kind | Owner |
|---|---|
| Twitch sub / resub / gift / raid / charity / cheer / follow / points / hype train | Native |
| YouTube superchat / sticker / member / milestone / gifting | Native |
| Kick sub / gifted subs / host | Native |
| Kick follow, KICKs | Kick webhook relay when built (below), else SE |
| YouTube new subscriber | SE |
| Tips, merch | SE |

SE events of a natively owned kind are dropped while the native
connection for that channel is up.

**Crosscheck (backfill only).** Record per channel when the native
connection was actually live (coverage windows). On SE backfill:

1. Kind owned by SE: insert if its SE `_id` is new.
2. Kind owned by native, timestamp **outside** a coverage window: the
   app missed it, so insert it with source = SE.
3. Kind owned by native, **inside** a window: drop it. Near a window
   edge (± ~2 min), match against stored events on platform + kind +
   actor (`providerId` when present, else lowercased username) + amount,
   and merge (store the SE `_id` on the native row) instead of inserting.

Every stored event keeps its source ids (native message/event id, SE
`_id`), so a second backfill over the same range is a no-op. Gift bombs:
SE flags them with `bulkGifted` / `isCommunityGift` (widget docs); how
that shows up in the activities payload is unverified, so group them on
the actor + time like the native `community_sub_gift`.

**Costs and risks**

- SE OAuth approval is manual: send the request early, it's the long pole.
- Token refresh needs the secret: another client on the exchange host.
  Never ship the JWT path as the default (full account access).
- How SE maps several platforms is unclear: tokens are per SE channel,
  the WebSocket docs say multi-platform users must "switch to the correct
  account", but SE also has a "Multiplatform Activity Feed". Capture this
  with a real Twitch + YouTube + Kick account before designing the login
  UI.
- Payload shapes for anything but follow and tip are only documented by
  example (and an unofficial OpenAPI spec). Plan a live capture into
  `docs/fixtures/` first, like the Kick payloads.
- SE doesn't see Streamlabs tips. Streamlabs is the natural next source
  (same exchange host; needs approval past 10 users).

### Option: Kick webhook relay (researched 2026-10-02)

Gets Kick follows and KICKs for every Kick user, not only SE users.

**Kick side** ([docs](https://docs.kick.com/events/subscribe-to-events)):

- One webhook URL per Kick app (developer settings), so all users'
  events land on one endpoint. Events: `channel.followed`,
  `kicks.gifted`; the same path also brings `channel.subscription.*`,
  `channel.reward.redemption.updated` and `livestream.status.updated`
  with documented payloads (ours from Pusher are guessed).
- Subscribe per channel with `POST /public/v1/events/subscriptions`
  (user token needs `events:subscribe`, not in `kKickChatScopes` today,
  so existing users re-consent; an app token works for any channel id).
- Cap: 10,000 subscriptions per event type per app.
- RSA-SHA256 signature over `message-id.timestamp.body` (public key at
  `api.kick.com/public/v1/public-key`); `Kick-Event-Message-Id` is the
  idempotency key. Failing for over a day auto-unsubscribes the app, so
  a resubscribe job is required.

**Load:** small. Assumed worst case 1,000 channels x ~100 follow/KICKs
events per stream hour x 3 h/day is ~300k events/day, ~3-4/s average,
maybe 50/s peak, ~1 KB each. Signature checks are sub-millisecond; an
open WebSocket per running app is a few KB. Fits in caps like
`kick-auth`'s (128 MB, 50% CPU). Don't route `chat.message.sent` through
it: that's where the load is (and capped at 1,000 for unverified apps).
Chat stays on Pusher.

**Shape:** a separate container (`kick-events`) next to `kick-auth` on
the same host, same Kick app credentials from the env file, own quadlet
caps. Keep `tool/kick_auth_proxy/` stateless. The new service:

1. verifies and dedupes incoming webhooks,
2. stores events per channel for phones that are closed (retention
   limit, deleted on sign-out / unsubscribe),
3. checks a phone owns the channel (phone presents its Kick token, the
   server confirms it against Kick's users endpoint, then issues its own
   session token),
4. streams live events to open apps over a WebSocket (works through the
   Cloudflare tunnel), with a "since" backfill on connect,
5. resubscribes channels after downtime or token changes.

That's the public-backend threat model from
`docs/private/backend-architecture.md`, plus personal data (follower and
gifter names): privacy policy and store privacy labels need updating.

**Check first:** Kick's Pusher `channel.{id}` has `FollowersUpdated`,
listed with `username: unknown` in a
[community event list](https://gist.github.com/Digital39999/ffe7df2bfc08797c2ba19d42e8f739a0)
(mid-2025); another tool reports only the count. KICKs on Pusher aren't
documented. Capture Pusher during a real follow and a real KICKs gift:
if the sender is there, KICKs need no server.

### Sources

- StreamElements: [WebSockets](https://docs.streamelements.com/websockets),
  [topics](https://docs.streamelements.com/websockets/topics),
  [channel.activities](https://docs.streamelements.com/websockets/topics/channel-activities),
  [channel.tips](https://docs.streamelements.com/websockets/topics/channel-tips),
  [OAuth2 + personal access](https://github.com/StreamElements/api-docs/tree/main/docs),
  [KICKs support](https://docs.streamelements.com/changelog/post/2026-09-13-kicks-support),
  unofficial [activities OpenAPI](https://github.com/c4ldas/streamelements-api)
- Streamlabs: [Socket API](https://dev.streamlabs.com/docs/socket-api),
  [register app](https://dev.streamlabs.com/docs/register-your-application),
  [scopes](https://dev.streamlabs.com/docs/scopes),
  [OAuth 2](https://dev.streamlabs.com/docs/oauth-2)
- Streamer.bot: [configuration](https://docs.streamer.bot/api/websocket/guide/configuration),
  [auth](https://docs.streamer.bot/api/websocket/guide/authentication),
  [events](https://docs.streamer.bot/api/websocket/events)
- Kick: [subscribe to events](https://docs.kick.com/events/subscribe-to-events),
  [webhook security](https://docs.kick.com/events/webhook-security),
  [event types](https://docs.kick.com/events/event-types)
- [TipeeeStream API](https://api.tipeeestream.com/api-doc/),
  [DonationAlerts API](https://www.donationalerts.com/apidoc)

## Open questions for planning

- Pro gating: whole feed vs. the extras only (history, recaps,
  third-party donations)?
- Retention: how many streams/days of events to keep on device?
- An end-of-stream recap card (floated as a Pro fit, not decided yet)?
- Haptic or notification on big events while the app is in the foreground?
- SE login: per "My chats" channel or one per SE account? Depends on the
  multi-platform capture.
- Kick webhook relay: Pro only (it's real backend cost), or for every
  Kick user? Decide after the Pusher capture.
- Do SE-only kinds (tips, merch) also count for the to-thank queue by
  default? Likely yes, they're the money events.
