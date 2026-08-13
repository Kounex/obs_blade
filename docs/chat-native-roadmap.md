# Native Twitch chat — API roadmap audit

Audit of the Twitch API surface (Helix + EventSub) against the native chat
implementation, to decide what else is worth building. Verified against live
dev.twitch.tv docs on **2026-08-12**. Status snapshot: waves 1–3 shipped (see
`session-handoff.md`); replies shipped both directions; only the
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

## Wave 1 — correctness, no auth changes — **SHIPPED 2026-08-13**

Live gaps in what we already receive; small, no scope upgrades.

- **GIF fragments** ✅ — `ChatFragmentGif` modeled, rendered inline at 3x
  emote size with text fallback (`channel_chat_message_gif.json` fixture,
  `gif_fragment_row_test.dart`).
- **Power-ups message types** ✅ — `power_ups_gigantified_emote` renders the
  emote at 3x; `power_ups_message_effect` is a cosmetic animation we can't
  reproduce → keeps rendering as a normal message (`power_ups_row_test.dart`).
- **Shared-chat source chips** ✅ — `#channel` chip before the author when
  `source_broadcaster_user_*` points at a partner channel
  (`shared_chat_row_test.dart`). **Dedup verified moot:** `switchChannel`
  keeps exactly one channel's subscriptions live, so a shared-session message
  can never arrive twice in one view.

## Wave 2 — free with current scopes — **SHIPPED 2026-08-13**

The token already carries everything these need — no re-login flow.

- **Pinned messages** ✅ (GA 2026-05-29) — `GET/PUT/DELETE /helix/chat/pins`
  (the live API is PUT, not POST/PATCH as drafted) under
  `moderator:manage:chat_messages` / read via the held
  `moderator:read:chat_messages`. No EventSub for pins → the store refetches
  on connect/switch and after local pin mutations. Slim banner above the
  timeline (mods get ✕ unpin) + Pin/Unpin rows in the mod action sheet
  (replacing an active pin confirms first). Pins are always "until stream
  ends" — no duration UI. `pin: true` on Send Chat Message deliberately not
  used (kept out — pin-from-compose adds little over pinning after send).
- **Unban + ban inbox** ✅ — `DELETE /moderation/bans` under held
  `moderator:manage:banned_users`; `GET /moderation/banned` (own channel
  only — Helix 401s even with a mod token for other channels) and
  `GET /moderation/unban_requests?status=pending` (read-only; approve/deny
  is Wave 3's manage scope) feed a "Bans & requests…" sheet off the channel
  mod sheet. Unban drops the user from both lists (also resolves their
  pending request).
- **Deferred informational lists** — blocked terms, warnings read,
  moderators/VIPs: pure read surfaces with no action attached; revisit with
  Wave 3 where their manage counterparts land.

## Wave 3 — mod tooling (one scope-upgrade bundle) — **SHIPPED 2026-08-13**

Best phone-form-factor features Twitch's API offers; shipped as one bundle so
the silent scope upgrade happens once (`kTwitchManageModToolingScopes` —
`moderator:manage:warnings`/`unban_requests`/`automod` — folded into
`kTwitchChatScopes`; pre-upgrade tokens keep working and get the re-login CTA
on the gated rows).

- **Warn users** ✅ — `POST /helix/moderation/warnings`; "Warn…" row in the
  mod action sheet swaps to a reason-compose step (the send is the confirm,
  500-char cap). The warned user must acknowledge in chat before chatting
  again — no local ack surface needed. `channel.warning.send/.acknowledge`
  EventSub subs deliberately not taken (the confirm toast is enough).
- **Unban-request approve/deny** ✅ — `PUT /helix/moderation/unban_requests`;
  request rows in the "Bans & requests…" sheet gain Approve/Deny pills
  (approve also lifts the ban, both confirm; optimistic removal). Pre-upgrade
  tokens keep the plain Unban pill. EventSub create/resolve subs deliberately
  not taken — the sheet refreshes on open.
- **AutoMod queue** ✅ — `automod.message.hold/.update` **v2** (channel-scoped
  pair, re-created per switch; `moderator_user_id: self`) feed a live
  `autoModQueue` on the store; "AutoMod queue (N)…" row in the channel mod
  sheet opens the queue sheet with Allow/Deny confirms
  (`POST /helix/moderation/automod/message`). Rows: message + "AutoMod ·
  category · level N · time" (or "Blocked term"). The update echo is an
  idempotent remove.
- **Warnings read surface** ✅ — `GET /helix/moderation/warnings` (read scope
  already in the held bundle) lists up to 3 recent warnings on the chat user
  card, mod view only, non-self only.
- Cut: blocked-terms and mods/VIPs lists (pure reads, no paired manage action
  surfaced), suspicious-user flagging (events only, no list endpoint),
  shield-button AutoMod badge.

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

1. ~~Wave 1 (correctness)~~ — shipped 2026-08-13
2. ~~Wave 2 (free — pins + unban + ban-list inbox)~~ — shipped 2026-08-13
3. ~~Wave 3 (mod tooling bundle — one scope upgrade)~~ — shipped 2026-08-13
4. Entitlement gate decision, then Wave 4

## Sources

- [EventSub subscription types](https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types/)
- [Helix API reference](https://dev.twitch.tv/docs/api/reference/)
- [Twitch API changelog](https://dev.twitch.tv/docs/change-log)
- [Send Chat Message drop-reason issue](https://github.com/twitchdev/issues/issues/896)
- [Hype train v1 withdrawal](https://discuss.dev.twitch.com/t/legacy-get-hype-train-events-api-and-eventsub-hype-train-v1-subscription-types-deprecation-and-withdrawal-timeline/64299)
- [Custom power-ups API](https://discuss.dev.twitch.com/t/introducing-api-and-eventsub-support-for-custom-power-ups/64708)
