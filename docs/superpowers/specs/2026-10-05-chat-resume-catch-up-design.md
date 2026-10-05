# Chat resume catch-up (Twitch + Kick) — design

2026-10-05 · status: ratified by the user (feature approved 2026-10-05), build
held until the other session's chat-history work fully settles.

## Problem

User report (dogfood): combined chat dominated by Twitch with occasional
YouTube. After a longer stay in the iOS background, reopening the app showed
**only YouTube messages catching up**, then Twitch "flooding" again live.

Mechanics (traced, no guesswork):

- iOS freezes the process: timers stop, sockets die. **Nothing** arrives on
  any platform while suspended; the in-memory buffers survive.
- **YouTube** reads by cursor polling (`nextPageToken`). The cursor survives,
  so on resume (`main.dart` lifecycle → `YouTubeChatStore.reconnectAfterResume`)
  the poll pages through everything said meanwhile — zero loss.
- **Twitch** reads over an EventSub WebSocket. It reconnects via watchdog +
  backoff, but Twitch does not replay messages of a lost session. The
  connect-time history backfill runs **once per broadcaster per session**
  (`_backfilledBroadcasters`), so the background window is lost.
- **Kick**: Pusher socket reconnects with backoff; its history backfill runs
  **only into an empty buffer** — never on resume. Window lost.

## Facts (verified)

- Twitch history: community `recent-messages.robotty.de` (what Chatterino
  uses; `TwitchRecentMessagesService` already parses its raw IRC into
  `ChatMessageEvent` with message ids + `tmi-sent-ts`). **Count-based window:
  the last N messages (≤ 800)** — time coverage varies from minutes (busy
  chat) to hours (quiet). Moderated messages are dropped server-side.
  Anonymous, no auth.
- Kick history: `GET /channels/{id}/messages` — **newest ~50 only**.
- Dedupe already solved at connect: Twitch backfill filters ids already in
  the buffer; Kick `_applyBackfill` dedupes by id. Same helpers apply on
  resume.
- The combined timeline is a stable k-way merge by platform timestamp
  (`mergeCombinedStreams`), so late rows slot into their chronological place.
- The session `ChatHistoryStore` (shipped same day, `e229facf`) is fed only
  at cap-eviction points — the catch-up insertion must route through the
  normal trim path so evicted rows keep landing there.
- TTS listens only to live arrivals (no backfill, no restores) — catch-up
  stays silent like the connect-time backfill.

## Design

**Resume hook** — `main.dart`'s lifecycle observer calls
`TwitchChatStore.reconnectAfterResume()` / `KickChatStore.reconnectAfterResume()`
next to the YouTube one (same registration guard). The hook forces an
immediate reconnect when the socket is dead/backing off (instead of waiting
out the watchdog/backoff) and kicks the catch-up fetch.

**Catch-up fetch (per store, best-effort, anonymous GET):**

- Remember the newest message timestamp in the active channel's buffer at
  suspend time (or simply filter against buffer state at apply time).
- Twitch: fetch recent-messages with `limit: 800`; keep rows with
  `tmi-sent-ts` **newer than the newest pre-resume row** and ids not already
  in the buffer.
- Kick: `backfillMessages(channelId)`; same filter on `createdAt`.
- Insert the block at the **timestamp-sorted position** — live rows may have
  beaten the fetch after the socket reconnected, so this is a mid-buffer
  insert, not an append/prepend. Then the normal cap trim runs (feeds
  `ChatHistoryStore` as usual).
- Inserted rows are **not** `isHistorical`: the reader had the chat open,
  these are late, not join-history — no dimming, no "New messages" divider.

**Gap marker** — honest loss signal:

- If the oldest catch-up row is **newer than the last pre-suspend row**
  (beyond a small epsilon), the history window didn't reach back → insert a
  one-line divider row between the pre-suspend rows and the catch-up block:
  "Some messages while away are missing" (`ChatHistoryDivider` visual idiom,
  own key for semantics/tests).
- Overlap or adjacency → no marker (full coverage).
- Kick's ~50-row window means busy chats nearly always show the marker;
  quiet chats often get full coverage. Twitch's 800-row window covers most
  real background stays except very busy chats / very long stays.

**Scope:** the channel each store is currently reading (Twitch effective
broadcaster, Kick selected slug) — combined chat merges one channel per
platform, so per-store single-channel catch-up covers "My chats" and combos
alike. YouTube is already zero-loss and untouched. No persistence across app
kills; no true background receiving (impossible on iOS).

## Deliberately left out

- Re-running Twitch's `isHistorical` join-backfill semantics on resume.
- Gap markers for sockets that drop while the app is *foregrounded* (short
  reconnects already redeliver / the window is seconds; revisit if dogfood
  shows it).
- Asking robotty for more than 800 (its max).

## Tests

- Store tests (both engines): buffer with pre-suspend rows → resume fetch
  returns overlap + new rows → new rows land sorted before later live rows,
  deduped, not historical; cap trim still feeds `ChatHistoryStore`.
- Gap marker: appears when the catch-up's oldest row postdates the last
  pre-suspend row; absent on overlap/adjacency.
- Resume hook: dead/backing-off socket reconnects immediately; connected
  socket is not disturbed (YouTube's hook test is the pattern).
- Widget shots: the gap divider row in a native timeline + combined.

## Device check list

1. Combined chat (Twitch + YouTube), background 5–10 min with the Twitch
   chat active → reopen: Twitch catch-up rows appear in order (not a flood
   of only-new), YouTube as before.
2. Same with a very busy Twitch chat / longer stay → the "missing" divider
   shows once, chat continues.
3. Kick chat backgrounded in a busy chat → ~50-row catch-up + divider.
4. Single-platform native tabs behave the same; scrolled-up reader keeps
   position (cap-hold path).
