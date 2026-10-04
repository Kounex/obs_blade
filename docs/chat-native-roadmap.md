# Native Twitch chat — API roadmap audit

Audit of the Twitch API surface (Helix + EventSub) against the native chat
implementation, to decide what else is worth building. Verified against live
dev.twitch.tv docs on **2026-08-12**. Status snapshot: waves 1–3 shipped
2026-08-13 (state in `AGENTS.md` / `changelog-agent.md`); the Pro entitlement
gate shipped via RevenueCat (2026-09). Open: which wave-4 items (if any) to
build — see `session-handoff.md` next-threads.

Code anchors: `lib/utils/twitch/`, `lib/stores/views/twitch_*.dart`,
`lib/views/dashboard/widgets/obs_widgets/stream_chat/`.

## What "shared chat" is (platform fact)

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

## Waves 1–3 — SHIPPED 2026-08-13

Details in `AGENTS.md` / `changelog-agent.md`; one line each:

- **Wave 1 (correctness, no auth changes):** GIF fragments, power-ups
  message types, shared-chat source chips (dedup verified moot —
  `switchChannel` keeps exactly one channel's subscriptions live).
- **Wave 2 (free with held scopes):** pinned messages (Helix chat pins,
  refetch on connect/switch + after local mutations), unban + ban inbox
  (`GET /moderation/banned` is own-channel only).
- **Wave 3 (mod tooling, one scope-upgrade bundle
  `kTwitchManageModToolingScopes`):** Warn…, unban-request approve/deny,
  live AutoMod queue (`automod.message.hold/.update` v2), warnings read
  surface. Pre-upgrade tokens keep working and get the re-login CTA on the
  gated rows.

## Wave 4 — streamer actions

The Pro gate shipped, so nothing blocks these anymore — pick deliberately;
each is its own build.

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

Waves 1–3 shipped 2026-08-13. Next: wave-4 item selection, then build.

## Sources

- [EventSub subscription types](https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types/)
- [Helix API reference](https://dev.twitch.tv/docs/api/reference/)
- [Twitch API changelog](https://dev.twitch.tv/docs/change-log)
- [Send Chat Message drop-reason issue](https://github.com/twitchdev/issues/issues/896)
- [Hype train v1 withdrawal](https://discuss.dev.twitch.com/t/legacy-get-hype-train-events-api-and-eventsub-hype-train-v1-subscription-types-deprecation-and-withdrawal-timeline/64299)
- [Custom power-ups API](https://discuss.dev.twitch.com/t/introducing-api-and-eventsub-support-for-custom-power-ups/64708)
