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

## Entry points (same state → same answer everywhere)

| Surface | Check |
|---|---|
| Chat bar account control | signed out: the sign-in / setup pill; signed in: **no account chip** - the account and its sign-out live in the chat header (sheet / Twitch self card), the right side is the mod shield + options on every platform, at phone width too |
| Header sheet / self card | signed in on the selected platform: **Sign out in every chat state** (live, connecting, failed, offline) and on every viewed channel; signed in + chat offline never says "connect your account" |
| Header status row → sheet | what "offline" means for this platform; actions match the state (no "Connect" while signed in) |
| Native chat options sheet | sign-in / sign-out rows, setup row |
| Setup sheets | full setup vs the sign-in-only part; steps match today's third-party console |
| Empty-state CTA | the next step for the actual missing piece |
| Combined sources sheet / builder | per-source state and fixes - every fix button does what it says ("Sign in" opens a sign-in) in "My chats" **and** saved combos |
| Activity feed | sign-in notices, Pro upsell, relay switch |
| Streaming mode + Chat tab + dashboard pane | same behavior in all three hosts |
| Phone vs tablet | side-by-side layouts, sheet heights |

## Shared components

A widget written for one platform carries that platform's assumptions.
When a change touches a shared one (`NativeChatWindow`, user card,
mod sheets, input / read-only strip, pickers, LIVE chips), walk it for
**every** platform that uses it, not just the one in the request.

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
- Failures go through `GeneralHelper.logFailure` (Settings → Logs,
  redacted, rate-limited) - never console-only. A dogfood bug must be
  diagnosable from the user's log export.
- Throttle answers are not quota: map each error `reason` per method
  from the platform's errors table. A stop that promises to resume
  ("after the daily reset") must resume on its own (timer + app resume).
- Creating a platform store starts its chat (YouTube polls on the user's
  API quota, Kick opens a socket). Nothing may read a store that isn't on
  screen - watch computeds / reactions created at app start
  (`lazySingletonCreated` before `GetIt.instance<…>()`).
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
