# YouTube chat quota: stream reads, quiet-chat polling

2026-10-19. Trigger: a Pro user's IRL stream hit the 10,000-unit daily
quota of their own API key after a couple of hours.

## Why the quota ran out

No bug: the chat polled `liveChatMessages.list` (5 units) at Google's
`pollingIntervalMillis`, as documented. At 3-5 s that is 3,600-6,000
units an hour, plus 120 for the 30 s viewer count, so 10,000 units last
1.6-2.7 hours. Everything else is small or idle in that setup: the
own-channel activity poller stands by while the chat shows the own
channel, moderation reads run only on demand, and channel search has its
own bucket.

## What changes

1. **Reads go over `liveChatMessages.streamList`** (gRPC server
   streaming, `youtube.googleapis.com:443`, API key as `x-goog-api-key`).
   Google bills **5 units per call** (quota table 2026-10-15, confirmed
   in Cloud Monitoring) and closes every call ~10.3 s after it starts:
   ~1,700 units an hour per chat, against 3,750-9,000 for polling at
   Google's 2-5 s interval (measured, see the end). Each answer maps onto
   the poll's `YouTubeLiveChatPage`, so rows, tombstones, bans, Super
   Chats and the activity feed are unchanged
   (`lib/utils/youtube/youtube_live_chat_stream.dart`).
2. **The poll stays as the fallback, with quiet-chat pacing.** Google's
   interval is the floor. Each empty page in a row stretches the wait by
   half, up to 10 s (`kYouTubeQuietPollCeiling`). A page with anything in
   it snaps back. A page holds up to 500 rows and the token carries on,
   so nothing is dropped, only delayed.
3. **No timing settings** (the user's call). The defaults adapt on their
   own; streaming leaves no cadence to tune.

## Read loop rules (`YouTubeStreamPolicy`)

One policy (`lib/utils/youtube/youtube_stream_policy.dart`), used by the
chat's read loop (`_attachAndPoll`) and the own-channel activity poller
(`YouTubeOwnActivityPoller`, fallback poll every 30 s). The poller closes
its call on standby (the chat reads the own chat), stop, a new chat and
back from the background.

- Stream first. "Opened" means Google accepted the call (billed): its
  first page, its clean end, or 2 s after the connection came up without
  a refusal (`kOpenGrace`). Not the headers: Google sends them ahead of a
  refusal too, and in a quiet chat holds them until the call's closing
  answer ~10 s in. The chat shows connected from then on, with no row
  needed.
- Google closes every call ~10.3 s after it starts: reconnect at once
  from the last `nextPageToken`. A call's length counts from its start.
- Three opened calls in a row that each closed within 5 s of starting
  cost more than polling at Google's 2-5 s interval, so the chat polls
  for 10 min and then tries one call again (`kYouTubeStreamRetryAfter`).
- A read after a poll waits out that poll page's interval - the stream
  too. Sooner, a call with the poll's token answers `PERMISSION_DENIED`
  (the poll: `rateLimitExceeded`), which would mean another 10 min of
  polling after every hand-back.
- A long call that drops reconnects at once, with no "reconnecting"
  flash (Google may rotate calls).
- A call that never opened (dead zone, no network) isn't billed. It
  reconnects after 1 s, then 2 s, and shows "reconnecting" (reconnect
  waits double, capped at 60 s; a restarted loop - resume, switch back -
  counts short calls afresh). After 3
  in a row, one poll checks: in a dead zone the poll can't get through
  either (free retries); its first answer hands back to the stream. If
  the stream still can't open while the poll works (gRPC blocked), the
  chat polls for 10 min.
- These go to the poll at once, because its answers tell quota, rate
  limit, permission and a missing chat apart: `RESOURCE_EXHAUSTED`,
  `PERMISSION_DENIED`, `NOT_FOUND`, `UNIMPLEMENTED` and anything else
  unexplained.
- These end the chat (no poll): a `chatEndedEvent` row, `offlineAt`.
- `FAILED_PRECONDITION` means ended **or** disabled (gRPC can't tell
  which): one poll asks. `liveChatEnded` ends the chat. A disabled chat
  shows the poll's error and Retry / resume recover it. If the poll
  answers normally and the stream says it again, the chat polls for
  10 min (no stream/poll ping-pong). Taking it as
  "ended" would skip that video for a channel entry until the stream
  ends.
- Stream and poll page tokens work both ways (measured). A page token
  the poll refuses (400) anyway: the poll starts over once without it
  (rows deduped by id).
- History: on a call without a token, rows published before the call
  started are dimmed (the poll dims its whole first page).
- The poll banner: the poll answer repeats `activePollItem` on every
  page, the stream isn't known to. So the stream keeps the banner until
  that poll's own row says `closed`.
- Viewer count: on a timer every 30 s while a call is open (no pages in a
  quiet chat to hang it on).
- Cancel: every `_pollFlow` bump (switch, pause, sign-out, dispose,
  restart) closes the open call. Without that, a call waiting in a quiet
  chat would never notice it was superseded.
- iOS suspension / dead zones: a server stream never writes, so a dead
  socket doesn't fail on its own. grpc's keepalive can't help: on a ping
  timeout it only *finishes* the connection (graceful GOAWAY, which waits
  for the open call). The streamer brings its own connection
  (`ClientTransportConnectorChannel`, TLS with ALPN `h2`). It pings every
  30 s and terminates the connection after 20 s without an answer, which
  fails the call so it reconnects. App resume after a real stay in the
  background (not Control Center / Face ID) replaces an open call with a
  new one from its token (5 units).

## Activity poller sibling fix

The poller took any 403 / 404 as "ended" and never re-attached that
video, so a chat switched off and on mid-stream stopped feeding the
activity feed. Now only `liveChatEnded` / `offlineAt` / a `chatEndedEvent`
row end it. A 403 / 404 waits and looks again (`videos.list`, 1 unit):
5 min, doubling while the same chat keeps answering 403 (a permission
problem rather than a switched-off chat), up to 60 min. A page token the
poll refuses (400) starts the poll over once, as in the chat.

## Journeys

1. IRL streamer, own channel on a phone, 3 h on mobile data with dead
   zones and phone locks: stream; drops reconnect from the token; resume
   starts a new call.
2. Desktop streamer, combined chat (YouTube + Twitch): unchanged. Pause
   closes the call, resume opens one from the token.
3. Viewer on someone else's channel; the stream ends: `offlineAt` /
   `FAILED_PRECONDITION` → offline → recheck schedule → rollover.
4. A key or network gRPC can't use (permission, blocked HTTP/2): the poll
   takes over at once and shows its usual errors; the stream is retried
   every 10 min (5 units).
5. Quota used up: the stream answers `RESOURCE_EXHAUSTED` → poll →
   `quotaExceeded` → stops until the midnight-PT reset, as before.
6. Quiet chat on the poll fallback: waits stretch to 10 s and snap back
   on the first row.

## Measured 2026-10-19

`tool/youtube_spike/` on the obs-blade key, three live chats at once for
30 min (details: `docs/youtube-native-chat-audit.md` § Quota reality):

- Every call closes ~10.3 s after it starts (median; max 25 s in a
  Google-side stall), in busy and quiet chats alike; 424 calls, 0
  errors, no GOAWAY.
- 5 units per call in Cloud Monitoring → ~1,650-1,730 units/h per chat.
  With the viewer count: ~5.5 h of chat a day on 10,000 units, up from
  ~1.1-2.7 h. A whole-day IRL stream still needs a quota increase
  (Google's free extension form) or a second key.
- Found and fixed: the 10 s short-call threshold sat on Google's 10.3 s
  close, and in a quiet chat late headers made every call look instant
  (→ 10 min of polling); the hand-back to the stream went out within
  the poll's interval (→ `PERMISSION_DENIED` → 10 min of polling, every
  time).

Still open: whether streamed answers repeat `activePollItem` (the banner
rule assumes they may not) - needs a chat with a running poll.

## Left out

- The viewer-count refresh (30 s, 120 units/h) stays: small, and it
  becomes the main cost only if streams prove long-lived.
