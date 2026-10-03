# Activity feed: status banner, own YouTube collection, gaps — design

**Status:** built 2026-10-04 (dogfood pending). Follows the 2026-10-03 activity review
(six findings). Base design:
[`2026-10-02-activity-feed-design.md`](2026-10-02-activity-feed-design.md).

## Decisions (user, 2026-10-04)

| Question | Decision |
|---|---|
| YouTube live detection | Signed in with a channel: quota-free `/live` check of the own channel every 2 min while the app is in the foreground, every 30 s while OBS streams (any destination - multistream plugins hide where it goes), right away on OBS go-live / app resume. Quota is spent only once live is confirmed |
| Own chat while another chat is on screen | Always poll the own chat while live (a second poll while another YouTube chat is watched) |
| API key only | The feed needs the YouTube sign-in to know which channel is yours - the banner says so with a Sign in action |
| Gaps | Banner lists the newest stream's gaps + a marker row at that spot in the list |
| Calm state | Banner tucked (small status button, top right). It comes out by itself only for something that needs action |
| Bulk thanks | "Mark N thanked" per stream / day header |
| Power-ups | `channel.bits.use` replaces `channel.cheer` |

## Journeys

1. Twitch-only streamer, phone in streaming mode, WebView chat engine.
2. Multi-platform on an iPad, YouTube chat not on screen (Twitch chat or a
   friend's YouTube chat selected).
3. YouTube streamer with only an API key; OBS streams to YouTube.
4. YouTube signed in with a Brand-Account mix-up (no channel).
5. Kick streamer with the relay switched off.
6. Phone locked mid-stream for 15 minutes (iOS suspends the app).
7. Not Pro.

## Facts (checked 2026-10-04)

- `channel.bits.use` v1, scope `bits:read` (same as `channel.cheer`):
  `user_*`, `bits`, `type` = `cheer` | `power_up` | `custom_power_up`,
  `message {text, fragments}` (optional), `power_up {type, emote,
  message_effect_id}`, `custom_power_up {title, reward_id}`. Covers
  cheers **and** Power-ups; `channel.cheer` covers cheers only. Not sent
  when the streamer uses a Power-up for free in their own channel.
  (dev.twitch.tv EventSub types + reference.)
- OBS `GetStreamServiceSettings`: `streamServiceType` `rtmp_common` with
  `streamServiceSettings.service` = `Twitch`, `YouTube - RTMPS`,
  `YouTube - HLS` (obs-studio `plugins/rtmp-services/data/services.json`);
  `rtmp_custom` carries `server`. Kick has no OBS preset (custom IVS
  server) - not detected. The settings also hold the stream **key**:
  never log or keep the response.
- YouTube `/live` check with the app's mobile user agent: the canonical
  link sits ~3 KB into the page and the resolver stops reading there
  (desktop UA: ~700 KB) - a check every 2 min is cheap.
- `liveChatMessages.list` ~5 units/call; `pollingIntervalMillis` is a
  minimum. The own-chat poller for the feed polls every 30 s (~600
  units/h vs ~3,600 at 5 s); a page holds up to 500 messages and the
  page token continues, so nothing is skipped, only up to 30 s late.
  The first page re-delivers recent history (ids dedupe).
- iOS suspends the app in the background: sockets die, Dart timers don't
  fire. A coverage window left open across a suspension claimed that
  time as listened; the store now detects the freeze by the 30 s tick
  lagging and splits open windows at the last tick.

## Design

- **`YouTubeOwnActivityPoller`** (`lib/utils/activity/`): needs no
  YouTube store (reads the stored session's channel id + API key).
  Waiting → `/live` check on the schedule above → `videos.list` (1 unit,
  also `actualStartTime` for the session start) → `liveChatMessages.list`
  every 30 s, mapped with `youTubeActivityFromMessage`. Stands by while
  the YouTube store itself polls the own chat. Quota exhausted → stops
  until the reset; rate limit / network → backoff; chat ended → waiting.
- **Coverage** per platform is the union of coverers (`twitch`,
  `youtube-store`, `youtube-own`, `kick`). Startup closes windows a kill
  left open at the last tick (`alive`), not at the next launch.
- **Gaps** = parts of a session where a platform of that session had no
  coverage, ≥ 60 s. Kick with the relay is never gappy (it replays).
- **OBS destination**: read once per OBS go-live (and on connect while
  live) → `obsLivePlatform`.
- **Status items** (pure builder, tested as a matrix): per platform the
  current state + next step, plus the newest stream's gaps. Severity
  action / warning / info / ok. Acknowledged ids persist in
  `activity-meta`; the tucked button shows a dot while any non-ok item
  is unacknowledged; a new action item brings the banner out.
- **Banner** floats over the feed list (glass, like the pinned-message
  banner): collapsed one line, tap expands to every item with its
  action, ✕ tucks. Same in the Chat tab, iPad pane and streaming sheet.

## Left out

- Kick OBS detection (no preset; the relay knows Kick's live state).
- Push notifications for gaps.
- Filling Twitch subs / cheers missed during a gap (no API for past
  events).
