# Native YouTube chat — feasibility audit + build plan

Companion to [`chat-native-roadmap.md`](chat-native-roadmap.md) (Twitch). Verified
against live Google docs on **2026-09-03**. Scope: how far a native YouTube live
chat engine can go, reusing the Twitch native seams, and what deliberately
won't be attempted.

Code anchors (Twitch side, reused): `lib/models/enums/chat_engine.dart`,
`lib/views/dashboard/widgets/obs_widgets/stream_chat/` (`NativeChatWindow`,
`NativeChatInput`, chrome), `lib/stores/views/twitch_*.dart` (store patterns),
`lib/utils/twitch/` (service idioms).

## TL;DR

Read + write + moderate is buildable to near-parity with the Twitch engine.
The binding constraint is **quota economics, not API surface**: quota is
**per GCP project, not per user**, and REST polling burns the 10,000-unit/day
default in ~2.8 user-hours. The gRPC `streamList` endpoint is the only
scalable read path but its quota cost is undocumented — the spike tool
(`tool/youtube_spike/`) exists to measure it before any default-on rollout.

## API surface (2026-09 snapshot)

### Receive

- **`liveChatMessages.list` (REST polling)** — `GET /youtube/v3/liveChat/messages`
  with `liveChatId`, `part=id,snippet,authorDetails`; follow `nextPageToken`,
  honor server-provided `pollingIntervalMillis` (faster polling →
  `rateLimitExceeded`). ~5 units/call (community-verified; Google removed the
  live rows from the quota table). First page returns recent history;
  `offlineAt` signals stream end; `activePollItem` carries the active poll.
- **`liveChatMessages.streamList` (gRPC server-streaming)** — documented,
  production-present, actively maintained (guide refreshed 2026-06). Service
  `V3DataLiveChatMessageService.StreamList` on `youtube.googleapis.com:443`;
  Google publishes `stream_list.proto` (proto2). Auth: **API key
  (`x-goog-api-key`) or OAuth Bearer**. Resume via last `nextPageToken`.
  **Not in the REST discovery doc → no `package:googleapis` support**; needs
  vendored proto + `package:grpc` (pure Dart, works on iOS/Android). Streams
  can EOF after seconds — reconnect/backoff is on us. **Quota cost
  undocumented — measure before committing** (that's the spike).

### Send

- **`liveChatMessages.insert`** — `textMessageEvent` and `pollEvent` (2–4
  options; poll creation first-class since 2026-07). Scopes `youtube` /
  `youtube.force-ssl`. ~20–50 units/insert (community numbers) — cheap
  relative to reads.

### Moderation

- `liveChatMessages.delete` (204; cannot delete other mods' messages),
  `liveChatBans.insert/delete` (`type=temporary` + `banDurationSeconds`, or
  permanent), `liveChatModerators.list/insert/delete` (list is owner-only).
- Deletions/bans arrive **in-stream** as `tombstone` / `userBannedEvent`
  (with `banType`, duration, acting mod id) → local reconcile + echo dedup
  pattern from the Twitch store transfers directly.

### Auth

- Read of public chats works with a plain **API key** (no OAuth).
- Send/delete/ban need OAuth scope `youtube` (or `youtube.force-ssl`).
- All YouTube Data API scopes are **sensitive, not restricted**: production
  needs OAuth app verification (consent screen, brand, scope verification —
  free, plan weeks) but **no paid CASA assessment**.
- **Device flow exists** and explicitly allows `youtube` / `youtube.readonly`
  (not `force-ssl`) → Twitch-style device-code login UX is implementable
  (`twitch_device_code_dialog.dart` as the template). Google steers phones to
  the installed-app flow; device flow is off-label but functional.

### Quota reality (the crux)

- 10,000 units/day per project, midnight PT reset. Since ~2025-12:
  `search.list` / `videos.insert` are separate 100-calls/day buckets;
  everything else shares the 10k pool.
- Polling math: 5 units × 720 calls/hr ≈ **3,600 units/user-hour** → ~2.8 h
  of one user on one chat per day at the default quota.
- Quota is charged to **the project whose key/client makes the call** —
  per-user OAuth tokens do **not** give per-user quota. 500k users on one
  OBS Blade project is a non-starter without a mitigation:
  1. `streamList` proves quota-cheap per connection (undocumented — spike),
  2. **BYO API key** (power-user path — shipped in this build),
  3. server-side fan-out relay (backend decision — out of scope here),
  4. quota extension form (sized for server analytics, not per-user polling).
- Stream binding: `videos.list?part=liveStreamingDetails&id=…` →
  `liveStreamingDetails.activeLiveChatId` (1 unit). OBS Blade already stores
  bare video ids (`lib/utils/youtube_video_id.dart`), so binding is one cheap
  call per session.

## Feature parity vs the Twitch native engine

| Feature | YouTube | Verdict |
|---|---|---|
| Text timeline + history | `list` first page = recent history | ✅ parity |
| Send (with read-only lock strip pre-auth) | `insert` | ✅ parity |
| Delete / timeout / ban | `delete`, `liveChatBans` + in-stream echo | ✅ parity (no durations picker beyond seconds) |
| Super Chat | amount/currency/tier; tier→color fixed & derivable | ✅ |
| Super Sticker | amount/tier/stickerId/altText; **no image URL** (CSV mapping only) | ✅ alt-text rendering |
| Memberships / milestones / gifting | full detail incl. received-gift | ✅ |
| Polls | read (`pollEvent`, `activePollItem`) + create; tallies owner-only | ⚠️ partial |
| Badges | booleans only (`isChatOwner/Moderator/Sponsor/Verified`) — no artwork | ⚠️ icon-based badges |
| Tombstones / ban events | `tombstone` (content-free), `userBannedEvent` | ✅ |
| Custom emoji / 7TV / BTTV | not exposed; plain text only | ❌ cut |
| Pinned messages | not exposed (Innertube only) | ❌ cut |
| AutoMod queue / warn / unban requests / shield / chat modes | **no API surface at all** | ❌ cut (wave-3 Twitch features have no YouTube analog) |
| Multi-chat (multiple videos) | per-video `liveChatId` buffers | ✅ same store pattern |

## What we build (this wave) — **SHIPPED 2026-09-03**

Plan: [`superpowers/specs/2026-09-03-youtube-native-chat-plan.md`](superpowers/specs/2026-09-03-youtube-native-chat-plan.md).
All five items landed (see `changelog-agent.md` 2026-09-03 entry for commits):
spike tool (pending a real-key measurement run), core layer,
`YouTubeChatStore`, UI + setup sheet, gates. Remaining before any
default-on/app-owned-key rollout: run the spike on a busy chat and record
the streamList quota numbers here.

**Getting the GCP key is scripted** (2026-09-04): `tool/provisioning/`
`gcp-youtube` — `gcloud auth login`, then one command creates the project,
enables YouTube Data API v3, and writes a restricted API key (chmod 600).
Console-only remainder: OAuth consent screen + "TVs and Limited Input"
client (no Google API exists for those). Then run the spike per
`tool/youtube_spike/README.md`.

1. **Spike tool** (`tool/youtube_spike/`) — Dart CLI: takes API key + video
   id, runs `streamList` and/or REST polling against a busy chat, prints
   quota deltas measured from the GCP quota side + message counts/latency.
   Decides the default-read-path question.
2. **Core layer** (`lib/utils/youtube/`) — hand-rolled REST services
   (http-client-injectable, same idiom as `lib/utils/twitch/`): live chat
   list/insert/delete, bans, videos.list binding, Google OAuth **device
   flow** auth service (scope `youtube`), token refresh/revoke, persisted
   auth model (Hive, mirroring `lib/models/twitch_auth.dart`).
3. **`YouTubeChatStore`** — mirrors `TwitchChatStore` structure: auth state
   machine, adaptive poll loop honoring `pollingIntervalMillis` (generation-
   guarded), per-video buffers + switch, send, delete/timeout/ban with local
   reconcile + echo dedup, tombstones.
4. **UI** — engine gate extended (`nativeChatAvailableFor`), native branch of
   `stream_chat.dart` parameterized, `YouTubeChatMessageRow` (icon badges,
   Super Chat tiers, sticker alt text, poll rows, gift/milestone notices),
   account control + device-code dialog modeled on the Twitch ones, chat-bar
   dropdown over the stored YouTube video ids.
5. **Configuration UX** — Settings/native-setup sheet: WebView (default) vs
   Native; native read needs an API key (guided BYO-key entry; app-owned key
   slot as a constant for later once quota story is proven); sign-in
   (device flow) unlocks send/mod. WebView fallback untouched.

## Vapor / cut list — do not plan on these

- Innertube (unofficial internal API): no quota, full badge art/pins — but
  ToS-risky, schema-churny, no Dart client. Wrong foundation for 500k users.
- PubSubHubbub: push only for video uploads/metadata — **no chat push**.
- Pinned messages, AutoMod, warn, unban requests, shield mode, chat-mode
  setters, real badge artwork, custom/third-party emotes — no official API.
- Moderator enumeration for non-owners (`liveChatModerators.list` owner-only).
- Embedding an app-owned API key as the default read path before the
  streamList quota measurement exists.

## Sources

- [LiveChatMessages: list](https://developers.google.com/youtube/v3/live/docs/liveChatMessages/list)
- [LiveChatMessages: streamList](https://developers.google.com/youtube/v3/live/docs/liveChatMessages/streamList)
- [Streaming Live Chat guide](https://developers.google.com/youtube/v3/live/streaming-live-chat)
- [liveChatMessage resource](https://developers.google.com/youtube/v3/live/docs/liveChatMessages)
- [LiveChatMessages: insert](https://developers.google.com/youtube/v3/live/docs/liveChatMessages/insert) · [delete](https://developers.google.com/youtube/v3/live/docs/liveChatMessages/delete)
- [LiveChatBans: insert](https://developers.google.com/youtube/v3/live/docs/liveChatBans/insert) · [LiveChatModerators: list](https://developers.google.com/youtube/v3/live/docs/liveChatModerators/list)
- [OAuth scopes (devices guide)](https://developers.google.com/youtube/v3/guides/auth/devices) · [Limited-input device flow](https://developers.google.com/identity/protocols/oauth2/limited-input-device) · [App verification](https://support.google.com/cloud/answer/10311615)
- [Quota costs](https://developers.google.com/youtube/v3/determine_quota_cost) · [Audit & quota extension](https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits)
- [Live API revision history](https://developers.google.com/youtube/v3/live/revision_history)
- Community quota measurements: [SO liveChatMessages.list cost](https://stackoverflow.com/questions/67232262/how-much-quota-cost-does-the-livechatmessages-list-method-incur), [willusher.io](https://www.willusher.io/general/2020/11/13/vis2020-streaming-infrastructure/)
