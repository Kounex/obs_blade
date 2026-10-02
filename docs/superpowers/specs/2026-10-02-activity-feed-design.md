# Activity feed v1 + Kick events relay — design

**Status:** building 2026-10-02. Process tier L (persistence + protocol +
UI + a new public service). Background and the third-party research:
[`../../activity-feed-idea.md`](../../activity-feed-idea.md).

## Goal

One place that collects what happened on the streamer's **own** channels
(the "My chats" model): subs, gifts, money, raids, follows, channel
points, hype trains, KICKs. It splits **new** from **seen**, keeps a
**to-thank** queue, and survives restarts. Third-party sources
(StreamElements, Streamlabs) plug into the same intake later and only
fill gaps.

## Decisions (user)

| Question | Decision |
|---|---|
| Surfaces | Chat \| Activity segment in the Chat tab (tablet: side by side), unread badge button in the chat bar, "N new" chip in streaming mode |
| Seen model | Seen = per-channel high-water mark ("new since you last looked" + badge + mark all seen). Thanked = swipe; big events stay in the to-thank queue until handled |
| Retention | Phone 30 days; relay 7 days, a channel with no app check-in for 30 days is unsubscribed |
| Relay host | `kick-events.obs-blade.com` on Hetzner, own container next to `kick-auth` (first `kick-events.kounex.com`: that zone's Bot Fight Mode blocks Kick's webhook servers) |
| Fleet board | Add both `kick-auth` and `kick-events` |
| Gating | Pro: every native source behind the feed is Pro already (native engines never start without it) |

## Journeys

1. **Solo Twitch streamer, phone in streaming mode.** Follows, subs,
   cheers arrive during the stream. The "N new" chip shows the count; the
   to-thank list holds the subs/cheers until they swipe them after a
   shout-out.
2. **Multi-platform (Twitch + YouTube + Kick) on an iPad.** Combined
   chat left, Activity right. Filter "Money" at the end of the stream,
   "This stream" totals per currency/bits/KICKs.
3. **Kick streamer who opens the app only on breaks.** The relay keeps
   follows / KICKs / subs while the app is closed; on open the backlog
   lands under "new since you last looked".
4. **Streamer viewing a friend's Twitch chat** (multi-chat) while live.
   Their own subs/raids/follows still reach the feed, and never show up
   in the friend's chat.
5. **Twitch token from before the upgrade.** Subs, raids, follows work;
   the feed offers "Sign in again to add cheers, channel points and hype
   trains".
6. **Not Pro / signed out everywhere.** Activity shows the Pro upsell or
   the sign-in hint; nothing is collected.

## Facts (verified 2026-10-02)

Twitch EventSub (reference + scopes pages):

- `channel.follow` v2: scope `moderator:read:followers` (already
  requested), condition `broadcaster_user_id` + `moderator_user_id`.
  Payload `user_id/login/name`, `followed_at`.
- `channel.cheer` v1: `bits:read`. `is_anonymous`, `user_*` (null when
  anonymous), `message`, `bits`.
- `channel.channel_points_custom_reward_redemption.add` v1:
  `channel:read:redemptions`. `id`, `user_*`, `user_input`, `status`,
  `redeemed_at`, `reward{id,title,cost,prompt}`.
- `channel.hype_train.begin/progress/end` **v2** (v1 deprecated):
  `channel:read:hype_train`. `id`, `level`, `total`, `progress`, `goal`,
  `top_contributions[{user_*, type, total}]`, `started_at`,
  `expires_at` / `ended_at`, `type` (treasure / golden_kappa / regular),
  `is_shared_train`.
- Backfill: `GET /helix/channels/followers` (`moderator:read:followers`)
  returns `followed_at`, newest first.
- Chat notifications are already subscribed per **viewed** channel. A
  second `channel.chat.notification` sub with the same condition is a
  409, so the own-channel one exists only while another channel is
  viewed.

Kick (KickDevDocs repo + `api.kick.com/swagger/doc.yaml`):

- One webhook URL per app (developer settings, "Enable Webhooks"). All
  subscriptions of the app deliver there. Disabling webhooks drops all
  subscriptions.
- `POST /public/v1/events/subscriptions` with an **app token**
  (client-credentials at `id.kick.com/oauth/token`) needs
  `broadcaster_user_id`; any channel works. No new user scope, so no
  re-consent. `GET` lists them (filter `broadcaster_user_id`), `DELETE
  ?id=` removes. Cap 10,000 per event type per app.
- Headers `Kick-Event-Message-Id` (ULID, idempotency key),
  `-Subscription-Id`, `-Signature` (base64 RSA PKCS#1 v1.5 SHA-256 over
  `id.timestamp.body`), `-Message-Timestamp`, `-Type`, `-Version`.
  Public key at `api.kick.com/public/v1/public-key`.
- Failing for over a day unsubscribes the app from that event.
- Payloads v1: `channel.followed {broadcaster, follower}`,
  `channel.subscription.new|renewal {subscriber, duration, created_at}`,
  `channel.subscription.gifts {gifter (nulls when anonymous), giftees[],
  created_at}`, `kicks.gifted {sender, gift{amount,name,type,tier,message},
  created_at}`, `channel.reward.redemption.updated {id, user_input,
  status, redeemed_at, reward, redeemer}`, `livestream.status.updated
  {is_live, started_at, ended_at}`. User objects carry `user_id`,
  `username`, `channel_slug`.
- Identity check: `GET /public/v1/users` with the user's token returns
  the token's own user (works with a bring-your-own app token too).
- From Hetzner, Python reaches `api.kick.com`; `id.kick.com` goes
  through curl like `kick-auth` (Cloudflare fingerprinting).

## Design

### Event model

`ActivityEvent` (plain class, hand-written JSON with a version field):
`id`, `platform` (twitch / youtube / kick), `channelId`, `kind`,
`actor` (id, login, name, anonymous), `amount` (value + unit: ISO
currency, `bits`, `kicks`, `viewers`, `months`, `subs`, `points`;
optional display string), `tier`, `message`, `title` (reward / gift
name), `recipients`, `timestamp`, `sources` (source → source event id),
`seq` (insert order), `thanked`.

Kinds: follow, sub, resub, giftSub (count; one row for a bomb), raid,
cheer, redemption, hypeTrain, charity, superChat, superSticker,
member, memberMilestone, memberGift, kicks, host, tip, merch.

**Big** (to-thank) by default: everything except follow, redemption and
host.

### Intake and dedup (`lib/utils/activity/`)

- Sources: `native`, `kickRelay`, `streamElements`, `streamlabs`.
  `ActivityOwnership` gives each (platform, kind) a priority list, e.g.
  Kick follow `[kickRelay, streamElements]`, Kick sub
  `[kickRelay, native, streamElements]`, Twitch sub
  `[native, streamElements, streamlabs]`, tip `[streamElements,
  streamlabs]`.
- `ActivityProvider` is the seam a source implements: `source`,
  `events` stream, `backfill(since)`, coverage callbacks. Native
  platform stores, the relay client and later SE / Streamlabs all feed
  `ActivityStore.ingest(event, source)`.
- Coverage windows per (source, platform, channel): when a source was
  really connected for that channel. Persisted.
- `ingest`:
  1. same source id already stored → update in place;
  2. fuzzy match (platform, channel, kind, actor id or lowercased login,
     amount, |Δt| ≤ 2 min) → merge the source id; a higher-priority
     source's fields win; `seq` / `thanked` stay;
  3. a higher-priority source was covering that channel at the event
     time → drop (it reported it, or will);
  4. else insert.
- Follows key on (channel, follower) so live and backfilled follows
  never double. Hype trains key on the train id and update in place.

### Native taps

- **Twitch:** own-channel chat notifications (sub, resub, gifts, raid,
  charity), shared-chat notices from other channels skipped. New
  own-channel EventSub subs: follow v2, cheer, points redemption, hype
  train v2 — each only when the token carries its scope.
  `kTwitchActivityScopes` joins the device-flow scope list. Follower
  backfill on connect (since the feed was first enabled, at most 30
  days).
- **YouTube:** super chat / sticker / member / milestone / gifting of
  the user's own broadcast (message ids are stable, the poll's history
  re-delivers them, dedup handles it).
- **Kick:** Pusher subscription / gifted subs / host for the own channel
  while it's the selected one (payloads guessed, lowest priority).

The stores expose a broadcast `activityEvents` stream and report
coverage. `ActivityStore` attaches like `ChatTtsStore` (never creates a
store itself, except: at startup, Pro + signed in to Twitch / Kick
creates those two stores so the feed collects without the chat being
opened; YouTube is never auto-created, polling costs quota).

### Sessions

A session is open while any own source is live (Twitch own-channel live
poll / `stream.online`, Kick relay `livestream.status.updated` or Pusher
on the own channel, YouTube connected to the own broadcast, OBS
streaming). It closes 10 min after the last source went offline. The
feed groups by session ("This stream" totals), events outside one by
day.

### Persistence

Two untyped Hive boxes, JSON strings only — **no new TypeID or adapter**:
`activity-events` (key = event id) and `activity-meta` (seen marks,
sessions, coverage, seq, relay cursor, feature-enabled-at). Pruned on
open and daily: older than 30 days or more than 5,000 events.

### UI

- Chat tab: Chat \| Activity segment (phone); tablet wide: side by side.
- Activity view: header (mark all seen, filter chips All / Money / Subs
  / Follows / Raids / Points), To thank (N) toggle, sessions with
  totals, rows with platform icon, actor, kind line, amount; swipe =
  thanked; tap = the person's history sheet; new rows accented, divider
  under the newest unseen run.
- Chat bar: Activity button with an unread badge.
- Streaming mode: "N new" chip opens the feed as a sheet.

### Kick events relay (`tool/kick_events_relay/`)

Python 3.12 + aiohttp + cryptography, SQLite, quadlet with memory / CPU
caps, binds localhost, Cloudflare tunnel `kick-events.obs-blade.com`.

- `POST /kick/webhook`: verify signature; deliveries older than 24 h are
  acknowledged but not kept (retries of a real event stay possible),
  dedupe on message id, keep only registered broadcasters, store, push
  to open sockets. Always 200 once verified (bad signature → 403).
- `POST /v1/session {access_token}`: `GET /public/v1/users` with it →
  broadcaster; ensure subscriptions with the app token; return an
  opaque session token (stored hashed, 30-day sliding expiry). The user
  token is never stored.
- `GET /v1/events?after=&limit=`, `GET /v1/stream?after=` (WebSocket,
  backlog then live, ping 25 s), `DELETE /v1/session`.
- Jobs: reconcile subscriptions every 15 min, purge events > 7 days,
  drop broadcasters without a check-in for 30 days.
- Events pass through raw (type, version, payload); mapping to
  `ActivityEvent` happens in the app.

## Left out (and why)

- StreamElements / Streamlabs clients: waiting on their API approval;
  the seam + ownership rows exist.
- Push notifications while the app is closed: needs APNs / FCM plumbing;
  the relay already stores what arrives.
- Kick chat through the relay: the load and the 1,000-channel cap for
  unverified apps; chat stays on Pusher.
- End-of-stream recap card: not decided.
