# Native Twitch chat — API roadmap audit

Audit of the Twitch API surface (Helix + EventSub) against the native chat
implementation, to decide what else is worth building. Verified against live
dev.twitch.tv docs on **2026-08-12**. Status snapshot: native chat dogfood wave
closed (see `session-handoff.md`); replies shipped both directions; only the
availability/entitlement gate remains on the old checklist.

Code anchors: `lib/utils/twitch/`, `lib/stores/views/twitch_*.dart`,
`lib/views/dashboard/widgets/obs_widgets/stream_chat/`.

## What "shared chat" is (context for wave 1)

Twitch's collab feature (Stream Together): a host starts a shared chat session
from the dashboard, guest streamers join; each channel keeps its own stream and
chat, but **every message sent in any session channel is broadcast to all
session channels**. On the wire, the same message arrives on each subscribed
channel's `channel.chat.message` with `source_broadcaster_user_*` /
`source_message_id` / `source_badges` filled in when it originated elsewhere.
Moderation propagates too (`channel.moderate` carries
`shared_chat_delete/timeout/ban`). Sending as a user goes to all session
channels (no per-channel opt-out with user tokens). **There is no API to
create/join/leave sessions** — dashboard only, so this is display/dedup work
for us, not a management feature.

## Wave 1 — correctness, no auth changes

Live gaps in what we already receive; small, no scope upgrades.

- **GIF fragments** — since 2026-07-16 `channel.chat.message` fragments include
  `type: "gif"` (`gif_id`, `url`). Our `ChatMessageFragment`
  (`lib/types/classes/twitch/eventsub/channel_chat_message.dart:55`) models only
  text/emote/mention → GIF messages degrade to fallback text today.
- **Power-ups message types** — `power_ups_message_effect` /
  `power_ups_gigantified_emote` arrive inline on `channel.chat.message`
  (`message_type` + `message_id`-level fields); no rendering case.
- **Shared-chat source chips + dedup** — tag rows with a "from #channel" chip
  when `source_broadcaster_user_id` is set, and dedup when multi-chat follows
  two channels in the same session (same payload arrives once per channel
  subscription). `shared_chat_*` notifications are already normalized; messages
  are not.

## Wave 2 — free with current scopes

The token already carries everything these need — no re-login flow.

- **Pinned messages** (GA 2026-05-29) — full CRUD `GET/POST/PATCH/DELETE
  /helix/chat/pins` + `pin: true` on Send Chat Message, all under
  `moderator:manage:chat_messages` (held). Long-press mod-sheet extension.
  Caveats: `pin` is mutually exclusive with `reply_parent_message_id`;
  unresolvable reply parents **silently drop** the send (`is_sent: false`) —
  surface that as failure, never retry blindly.
- **Unban** — `DELETE /moderation/bans` under held `moderator:manage:banned_users`.
- **Read surfaces under the held `moderator:read:*` bundle** (required for
  `channel.moderate` v2 anyway): banned-users list, blocked terms, unban-request
  list (read-only), warnings read, moderators/VIPs lists. Enables a
  ban/unban inbox view at zero auth cost.

## Wave 3 — mod tooling (one scope-upgrade bundle)

Best phone-form-factor features Twitch's API offers; ship as one bundle so the
silent scope upgrade happens once.

- **Warn users** — `POST /helix/moderation/warnings` +
  `channel.warning.send/.acknowledge`; `moderator:manage:warnings`.
- **Unban-request inbox** — `GET/PUT /helix/moderation/unban_requests` +
  EventSub create/resolve; `moderator:manage:unban_requests` (read part already
  held). Approve/deny queue.
- **AutoMod queue** — `automod.message.hold/.update` **v2** +
  `POST /helix/moderation/automod/message`; `moderator:manage:automod`.
- Optional: suspicious-user flagging (`moderator:read/manage:suspicious_users`,
  Add/Remove GA since 2026-02). Note: no "list suspicious users" endpoint —
  events only.

## Wave 4 — streamer actions (needs the entitlement decision first)

These justify the availability/entitlement gate; sequence the gate *with* this
wave rather than before it.

- **Channel-points redemption feed** — EventSub
  `channel.channel_points_custom_reward_redemption.add/.update` +
  `...automatic_reward_redemption.add` v2; `channel:read:redemptions`. Fires for
  all rewards incl. dashboard-created. **Read-only by design** — Helix
  reward/redemption mutation is client-ID-locked (unchanged 2026); do not plan
  a fulfill/refund queue.
- **Polls & Predictions create/end** — `POST/PATCH /helix/polls`,
  `/helix/predictions` + begin/progress/(lock)/end events;
  `channel:manage:polls` / `channel:manage:predictions`. Third-party create
  works, no client-ID restriction. Broadcaster token only — no moderator
  variants exist. Biggest build (forms + live progress UI).
- **Raid out** — `POST/DELETE /helix/raids`; `channel:manage:raids`.
  Broadcaster-only, cancel only during countdown.
- **Get Chatters viewer list** — `GET /helix/chat/chatters`;
  `moderator:read:chatters`. Works for mod-of-other-channels persona.

## Nice-to-have / watchlist

- Hype-train banner — `channel.hype_train.*` **v2 only** (v1 withdrawn,
  `GET /helix/hypetrain/events` removed 2026-02); `channel:read:hype_train`.
- Bits celebration rows — `channel.bits.use` (cheers + power-ups + custom
  power-ups); `bits:read`. Custom power-ups API GA 2026-05.
- Creator goals progress — `channel:read:goals` (bit-goal types added 2026-06).
- Clips from phone — `POST /helix/clips` (+ `/helix/clips/vod`); `clips:edit`.
- `GET /helix/users/authorizations` (app token) for scope-upgrade UX — needs a
  backend, out of scope for the pure client.

## Vapor list — do not plan on these

- Create/join/leave shared chat sessions via API (Stream Together dashboard only)
- Hype Chat (product discontinued 2023) · Moments (shut down 2023)
- Manage/fulfill channel-point redemptions for rewards not created by our
  client (client-ID lock, still in force)
- Permitted-terms Helix API · "list suspicious users" GET · "raid initiated"
  EventSub (only `channel.raid` on landing)
- Moderator-scoped polls/predictions · moderator raid-start (broadcaster token
  required)
- Whisper history/threads (send/receive exist but rate-limited, no history —
  weak fit)
- Streamer-consumable Drops API (org-scoped) · Guest Star (3+ years in beta —
  auto-deletion risk)

## Suggested order

1. Wave 1 (correctness — GIF fragments are live degradation today)
2. Wave 2 (free — pins + unban + ban-list inbox)
3. Wave 3 (mod tooling bundle — one scope upgrade)
4. Entitlement gate decision, then Wave 4

## Sources

- [EventSub subscription types](https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types/)
- [Helix API reference](https://dev.twitch.tv/docs/api/reference/)
- [Twitch API changelog](https://dev.twitch.tv/docs/change-log)
- [Send Chat Message drop-reason issue](https://github.com/twitchdev/issues/issues/896)
- [Hype train v1 withdrawal](https://discuss.dev.twitch.com/t/legacy-get-hype-train-events-api-and-eventsub-hype-train-v1-subscription-types-deprecation-and-withdrawal-timeline/64299)
- [Custom power-ups API](https://discuss.dev.twitch.com/t/introducing-api-and-eventsub-support-for-custom-power-ups/64708)
