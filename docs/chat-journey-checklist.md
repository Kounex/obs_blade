# Chat journey checklist

Walk this before reporting a chat change as done - new feature or a fix
to an existing one (`feature-work` skill). Every row is a place where a
change has broken something before. Code review reads code against its
intent; this list is how the *assumptions* get checked. Add a row
whenever a review, a dogfood round or a user finds a new kind of miss.

For each row: what does the user see, what does a tap do, and is that
still right? Answer from the code, a test and a widget shot
(`tool/widget_shots/`), not from memory.

## Journeys (who goes through this)

Write the 3-6 real user setups for the change first, then walk each
through the sections below. Examples:

- Solo Twitch streamer, phone in streaming mode, signed in
- YouTube streamer whose channel is a **Brand Account**
- Viewer / mod who never streams, reads a friend's chats (no own channel)
- Multi-platform on an iPad: combined chat + activity side by side
- Someone who only pasted a YouTube API key (read-only)
- Free user (no Pro) - WebView chat only

## Account states, per platform

Every state must give a correct status, a working next step and no dead
end (a button that only reopens the same failure).

| Platform | States to walk |
|---|---|
| Twitch | signed out · signed in · token from before a scope upgrade (missing scopes → "sign in again" notice) · token expired / revoked · viewing own channel vs another · mod vs not |
| YouTube | no API key · **API key only (read-only)** · key + OAuth client, not signed in · signed in with a channel · **signed in without a channel** (personal account picked for a Brand Account channel - `channels.list?mine=true` has no `items`; read-only everywhere, "Switch account") · "Testing" OAuth app: refresh token dies after 7 days - **also while the app stays open** (the next write ends the session) · quota exhausted (restarts after midnight PT) vs polled too soon (`rateLimitExceeded` - back off, not quota) · own-channel lookup failed (retries on next launch) |
| Kick | anonymous (reads need no account) · signed in · no channel picked · channel not found · build without the app client (bring-your-own setup) |
| Pro | not Pro · Pro · Pro lapsed while a native engine runs |

Status words mean one thing everywhere: "LIVE" / live green = on air.
"Offline" for YouTube / Kick is the **chat** (not live, no channel), not
the account - Twitch is the only engine where offline means signed out
(`NativeChatWindow.offlineNote`).

## Channels

| Case | Check |
|---|---|
| Own channel ("You") | appears only with a known channel; named by its title |
| Channel-id-only entries | **a bare `UC…` id is never shown as a name** (empty state, header, pickers, combined builder search) |
| Handle ≠ display name | the label the user gave / the channel title wins over the handle |
| Live / offline / between streams | empty-state copy names the channel; auto-rollover to the next stream |
| Channel entry vs pinned video | video entries don't roll over; copy says "video" |
| Multi-chat switch | per-channel history; selection persisted; switching back restores |
| Combined chat | the change behaves the same inside the combined timeline and its pickers / builder |
| Own channel in a combo / picker | resolves to the "You" entry (activity feed, owner-only tools), never a plain copy in the platform's list |
| Adding a channel | from every entry point (empty state, "can't be found", channel menu) the chat then shows the added channel |
| User card actions | highlight / ignore (and the platform's mod actions) on the card of **every** platform, never on your own card; the name written is the one that platform's rows match (Twitch login, YouTube display name, Kick username) |
| Own sent message | shows our name + badges at once and after the platform's echo (YouTube's insert answer has no authorDetails - the instant copy is filled in, the poll copy replaces it), in the platform chat **and** combined chat |
| Emotes / emojis per platform | Twitch / Kick / YouTube rows draw them (YouTube: `:codes:` from the emoji catalog, unknown ones stay text until learned), the emote button is in every writable input incl. combined chat's targets, TTS treats them as emotes |
| Add chat sheets (Twitch / YouTube / Kick) | every state: empty (signed out / in), typing < 3 chars, results (LIVE + viewers - YouTube checks each hit / subscription with visible progress, subscriptions stay A-Z with a Live now filter; a hidden count = LIVE alone; a failed check = no claim, already-listed checked off, own channel), no hits, failure (the typed handle / slug still offered), link pasted, dead session (signs out, no endless Retry), pick mode for the combo builder (nothing saved) |

## Entry points (same state → same answer everywhere)

| Surface | Check |
|---|---|
| Chat bar layout (native) | the channel dropdown fills the row next to shield / options / sign-in pill on phone, 320 pt and tablet; long names + LIVE chips in the open menu; signed out without a dropdown the controls sit right; WebView keeps its columns |
| Chat bar account control | signed out: the sign-in / setup pill; signed in: **no account chip** - the account and its sign-out live in the chat header (sheet / Twitch self card), the right side is the mod shield + options on every platform, at phone width too |
| Header sheet / self card | signed in on the selected platform: **Sign out in every chat state** (live, connecting, failed, offline) and on every viewed channel; signed in + chat offline never says "connect your account" |
| Header status row → sheet | what "offline" means for this platform; actions match the state (no "Connect" while signed in) |
| Native chat options sheet | one sheet for every platform: Search chat, "All chats" (Appearance, Highlights, Mute words, Session history, TTS - shared settings), then the platform's own section (Twitch: Emotes, Badges, Event messages, Chat history; Kick: Emotes, Badges, Event messages; YouTube: Chat setup); combined: platform tabs for the combo + search over the merged timeline. Account rows live in the chat header, not here |
| Sheet pages (back chevron) | every page of a sheet - options pages, Search, channel mod presets / Announce, Timeout / Warn - opens as its own sheet in the old one's place (both slide), back reopens where it came from (combined: same platform tab), an action / dismiss ends the run, the selected message stays marked until the last sheet closes |
| Third-party emotes | combined chat: every platform's channel emotes render (7TV / BTTV / FFZ), not just globals; a failed refetch keeps the last catalog; signing out of one platform leaves the others' emotes |
| Scrolled up in a busy chat | at the cap (500), reading an old message: it stays where it is while rows arrive below (nothing dropped above), the pill counts; back at the bottom the buffer trims to 500; past ~2,000 the list stops taking rows - every platform + combined |
| Rows at the buffer cap | with the buffer full, every arrival evicts the oldest row: an already-visible notice (sub / announcement) must NOT replay its entrance fade, a tombstone must not re-fade - only the genuinely new row animates (rows need stable keys + `findItemIndexCallback`; keys alone don't relocate children in a builder sliver) |
| User cards | long history: only the messages below LIVE scroll (name, facts, lists, LIVE pinned; self card: account footer pinned below); phone in landscape: all scrolls together (a history of ≤ 50 rows joins the shared scroll; a longer one stays lazy in the pinned layout); history rows show a timestamp on **every** platform (Twitch / YouTube / Kick), even with the timeline timestamps setting off; retention past the 500-row buffer: the card merges the session history (older rows behind the live ones, feed-time tombstone snapshot on history rows), shows the first 50 + a "Show X older messages" button (screen reader: "… from \<name\>"), one-way, reset on reopen; a chatter fully evicted from the buffer still has their history on the card |
| Session history erasure | `/clear` (Twitch / Kick) **keeps** the retained rows - the app's /clear UX is content-visible tombstones (cleared rows stay visible, dimmed, with the marker), so history mirrors it, and rows evicted after a /clear land in history with that tombstone snapshot; erasure is only sign-out / auth death (Twitch / YouTube - **Kick sign-out keeps them**, its buffers survive for anonymous reads), a channel leaving the user's list, and app restart; a YouTube rollover keeps the entry's rows (keyed by the entry label, not the video id); deleting a single message after it was evicted does NOT retro-update its history snapshot |
| Session history cap (Session history page) | options → "All chats" → Session history: slider 10k-200k in 10k steps, **default 50k** (persisted `ChatHistoryCap` setting), memory estimate row (1.25 KB/message → MB, green ≤ 75 MB / amber ≤ 150 MB / red above) tracks the slider; changes apply live - lowering trims the retained history (oldest first) immediately, raising just un-gates growth; a running session's cap change needs no restart, user cards see the trimmed/enlarged history accordingly |
| Setup sheets | full setup vs the sign-in-only part; steps match today's third-party console |
| Empty-state CTA | the next step for the actual missing piece |
| Combined sources sheet / builder | per-source state and fixes - every fix button does what it says ("Sign in" opens a sign-in) in "My chats" **and** saved combos |
| Activity feed | status banner lines per platform state (incl. API key only, live on a platform that isn't set up), Pro upsell, relay switch; collected with the chat on another platform / another channel / the WebView engine |
| Streaming mode + Chat tab + dashboard pane | same behavior in all three hosts |
| Phone vs tablet | side-by-side layouts, sheet heights |

## Shared components

A widget written for one platform carries that platform's assumptions.
When a change touches a shared one (`NativeChatWindow`, user card,
mod sheets, input / read-only strip, pickers, LIVE chips), walk it for
**every** platform that uses it, not just the one in the request.

Lists that fill in after they show (live checks, lookups): say it's
running (progress, not a silent wait), and never reorder rows the user
may be scrolling or pressing - fill in place, offer a filter / sort
instead (2026-10-04: live subscriptions jumped to the top mid-scroll).

## Copy

- Names, never ids (`UC…`, numeric user ids, slugs where a title exists).
- An error says what to do next, in the user's terms.
- Instructions for third-party consoles (Google Cloud, Kick developer
  settings, Twitch) are checked against the **current official docs**
  when written - consoles move (Google's consent screen is "Google Auth
  Platform" now) - with a deep link where one is stable.

## Network-facing code

- Fakes answer like the real service, starting from the awkward cases:
  missing keys (not empty lists), no channel, error bodies, 401 / 403 /
  429. Capture a real answer (ids changed) when in doubt; a fake that
  agrees with the code proves nothing.
- Numeric model fields: check the discovery doc's wire type, not the
  prose docs - a Google `uint64` is a JSON **string** on the wire
  (`banDurationSeconds`, `concurrentViewers`, `amountMicros`, poll
  `tally`), a cast `as num` kills the poll on the first real event
  (2026-10-05: YouTube chat Failed after a timeout in the read chat).
  Parse both forms.
- Failures go through `GeneralHelper.logFailure` (Settings → Logs,
  redacted, rate-limited) - never console-only. A dogfood bug must be
  diagnosable from the user's log export.
- A list a sheet loads with the session token (subscriptions, live
  listing) ends a dead session like a write does - otherwise its Retry
  is a dead end.
- Throttle answers are not quota: map each error `reason` per method
  from the platform's errors table. A stop that promises to resume
  ("after the daily reset") must resume on its own (timer + app resume).
- Creating a platform store starts its chat (YouTube polls on the user's
  API quota, Kick opens a socket). Nothing may read a store that isn't on
  screen - watch computeds / reactions created at app start
  (`lazySingletonCreated` before `GetIt.instance<…>()`).
- "Listening" state (activity coverage, connection flags) must not
  survive what the app can't see: a kill (close at the last heartbeat)
  and an iOS suspension (timers stop, sockets die) - check what the
  user is told after both.
- App resume: a socket-based chat (Twitch, Kick) reconnects a dead /
  backing-off socket immediately and re-fetches the background window
  merged into the buffer (sorted, deduped, TTS-silent); when the
  history window didn't reach the pre-suspend tail, a "Some messages
  while away are missing" divider marks the gap instead of silently
  pretending completeness. Poll-based chat (YouTube) is zero-loss by
  cursor.
- Live smoke for new endpoints: a throwaway `flutter test` file; the
  Kick / Cloudflare user-agent notes are in the handoff § Chat
  conventions.

## Device check (before any store test build)

End the report with a short tap list for the user's dogfood install:
the journeys and states the change touches, including once from a fresh
state (signed out, nothing configured). Store test builds
(`release-beta`) only after the user's on-device OK.

## Release

- No secret in a build: `release preflight` refuses `*SECRET*` defines;
  app-owned secrets live on the exchange host only.
