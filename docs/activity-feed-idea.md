# Activity feed — parked idea (post-4.0)

Status: **parked 2026-09-27**, nothing built. Decisions below come from the
user; everything marked *verify* still needs checking against live docs
before planning.

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
  4. third-party donations (Streamlabs / StreamElements).

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
- Streamlabs / StreamElements: each has its own OAuth app registration
  plus a realtime socket. Check terms, whether app review is needed, and
  whether a mobile client can hold the socket without our own backend.

## Open questions for planning

- Pro gating: whole feed vs. the extras only (history, recaps,
  third-party donations)?
- Retention: how many streams/days of events to keep on device?
- An end-of-stream recap card (floated as a Pro fit, not decided yet)?
- Haptic or notification on big events while the app is in the foreground?
