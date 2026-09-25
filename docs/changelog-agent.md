# Agent changelog

Running log of upgrade/migration work. Not store release notes.

## 2026-09-25 (afternoon) - Combined chat wave 3: writing

- **Wave 3** (`08bef57e`): combined-view input dock with a target chip
  (platform badge, chevron when more than one source is writable, "Send
  to" sheet, pick persisted as `CombinedChatSendTarget`). The emote picker
  (Twitch / Kick), autocomplete and accent follow the target. Long-press
  routes to the row platform's own sheet (Twitch mod or Copy+Reply,
  YouTube mod or Copy, Kick reply/mod or Copy); a reply locks the chip to
  its platform, and picking another target drops it. Twitch mods can unpin
  from the combined pin stack.
- **Dogfood feedback:** the source-strip dots only said "chat
  connected", not "streamer live". Each chip now adds a LIVE · viewers tag
  (`CombinedChatStore.liveSources`, read off the platform stores: Twitch
  `selectedChannelIsLive`, YouTube connected = live, Kick
  `channelInfo.isLive`). The strip also stays visible above the "Waiting
  for messages" placeholder.
- **Channel pickers (dogfood ask):** every channel dropdown (Twitch /
  YouTube / Kick native, the WebView username dropdown, the combined
  builder's pickers) lists own first, then A–Z
  (`compareChatChannelNames`), and caps the open menu at
  `kChatChannelMenuMaxHeight` (scrolls beyond). Rows show
  `NativeChatLiveTag`: LIVE · viewers / OFFLINE once known, nothing while
  unknown. Twitch now tracks which ids the batch poll answered
  (`liveCheckedIds`), so a channel added since the last poll isn't
  called offline. YouTube got a picker-only live preview
  (`channelLivePreview`, quota-free `/live` page check per channel entry,
  run on menu open / builder open, throttled to 1/min; pinned videos stay
  unknown). The WebView dropdown has no live data (no API there).
- Gotcha: a Hive `put` inside a `testWidgets` body (here: the target pick)
  hangs the whole file at teardown with "Cannot close sink while adding
  stream". Wrap the tap in `tester.runAsync` and `flush()` the box.

## 2026-09-25 - Combined chat wave 2 + dogfood polish

- **Dogfood polish on wave 1** (`e7c597fa`, `580fe8d3`): combined rows
  got a full-width platform tint, a brand stripe on the window's left
  edge and an inline 16px square platform badge (rows' new `leading`
  slot); the "My chats" sheet uses `BaseAdaptiveSwitch` /
  `ThemedCupertinoButton`; "You" in all three channel dropdowns is a
  solid `NativeChatYouChip`.
- **Wave 2** (plan `docs/superpowers/plans/2026-09-25-combined-chat-wave2.md`):
  saved combos + builder + suggestions + combo dropdown + source strip
  focus jump + YouTube background pause. See AGENTS.md § Combined chat.
  Live smoke of the suggestions confirmed "suggest, never auto-add":
  YouTube `@xqc` is a different creator, Kick `ice_poseidon` and
  `ice-poseidon` are two accounts.
- End self-review (reviewer subagent still rate-limited) caught a
  status-change reaction re-activating during a focus jump (would
  resume YouTube while the user is on another platform).

## 2026-09-24 (night) - Combined chat wave 1 + full-buffer scroll fix

- **Likely cause of the announcement "stall"** (`c8c48713`): the native
  views re-pinned to the bottom only when the timeline LENGTH changed. At
  the 500-row cap every arrival evicts one row, so the length stays flat
  and a taller new row (announcement banner, long message) left the list
  stranded above the bottom. All three views now also key on the newest
  item. Regression test fails on the old code.
- **Combined chat, wave 1** (`8175d7a6`, `4ec2fcfb`; spec + plan
  `docs/superpowers/{specs,plans}/2026-09-24-combined-chat*`): see
  AGENTS.md § Combined chat. Brainstorm decisions: chat-type entry, one
  channel per platform, no same-streamer verification (suggest-only
  matching in wave 2), platform icon per row, target picker for writing
  (wave 3), status strip → sources sheet, stacked per-platform pins with
  their own tuck, shared store coupling with "restore on type switch" +
  "focus shortcut keeps the combo" (wave 2).
- End review (done in-session: the reviewer subagent hit the secondary
  model's rate limit) fixed three store bugs: restore point lost across
  an app restart (now persisted as `CombinedChatRestore`), leaving
  Combined mid-activation, unstable Twitch notice keys.
- Gotcha: a YouTube store with an instant `sleep` and an offline channel
  entry spins its recheck loop on microtasks and starves Hive I/O in
  unit tests — give such tests a real 1 ms sleeper.

## 2026-09-24 (evening) - Own "You" chat on Kick + YouTube, centered placeholders

- **Own channel entry on Kick + YouTube** (`dd4f4f1a`): signing in natively
  lists the account's own channel first, marked "You" (Twitch already had
  it). Native-only: never written into the WebView username lists. Kick
  derives the slug from the username (`_` → `-` candidate) and verifies
  it against the channel's `user_id`; the official `GET /channels` (own)
  would need an extra `channel:read` scope, so it was avoided. YouTube
  reads the `UC…` id off the existing `channels?mine=true` call. New
  nullable Hive fields: `KickAuth.channelSlug` (7), `YouTubeAuth.channelId`
  (5) — persistence tests read the exact pre-change frames. Old sessions
  backfill on restore. All three stores expose `isViewingOwnChannel`, the
  groundwork for the merged timeline (`chatterino-comparison.md`).
- **Centered chat placeholders** (`ba5190e5`): empty states, Pro upsell and
  the YouTube waiting state center in the chat viewport (they were
  top-aligned for the old dashboard-scroll host, which no longer exists).
- **Twitch announcement stall — not reproduced.** Widget tests with a
  saturated 500-row buffer, an announcement (+ its twin chat.message,
  link, emote, badge), alternate rows + timestamps on/off, then 8 more
  messages: every row rendered, list stayed pinned to the bottom, no
  layout exceptions. So the widget path is probably not the cause; the
  store/EventSub side (or a real-payload difference) is the next suspect.
  Needs a device repro with logs.

## 2026-09-24 (later) - Dogfood follow-ups: pinned sheet headers, "New messages" divider, optional YouTube entry name

Same session, after the first dogfood install of the Chatterino wave
(release build + Pro test-unlock define, "Kounex iOS"):

- **Pinned sheet headers** (`40d3e3ff`): scrolling the native chat
  options sheet (e.g. Appearance) scrolled the handle / back chevron /
  title away. New `NativeChatSheetScaffold` (`native_chat_chrome.dart`)
  pins handle + header and scrolls only the body; used by the options
  sheet (root + every sub-page), Kick setup sheet and all three user
  cards. The other chat sheets already kept headers outside the scroll.
  **Rule going forward:** sheets with a handle / title / back chevron
  never put those inside the scroll view. Guarded by
  `test/chat/sheet_pinned_header_test.dart` (verified red on the old
  sheet: header moved 160 px).
- **"── New messages ──" divider** (`6ec38e0d`): between the last
  backfilled history row and the first live one, lines in the platform
  brand color (label contrast-nudged), vertical padding, only once a
  live row exists. `isHistorical` now exists on all three engines:
  Twitch recent-messages, Kick join backfill, YouTube's first poll page
  (no page token yet) — all dimmed.
- **YouTube entry name optional** (`51346da1`, `7f61c351`): the dialog
  leads with channel / stream; an empty name is derived on save by
  `YouTubeEntryNamer` — always the channel's display name, never an
  `@handle` (user correction): `@handle`/`c/`/`user/` → channel page
  `og:title` (streamed), `UC…` → RSS feed title, video → oEmbed
  `author_name`; 4 s timeouts, offline fallback = handle without `@`,
  collisions → `Name (2)`. Live-verified (Lofi Girl, NASA, Marques
  Brownlee, nonexistent handle).

Gates: `test/chat/` 1009 pass / 4 known `mod_action_sheet_test` flakes;
analyze at baseline. Deployed to Kounex iOS after each change.

## 2026-09-24 - Chatterino comparison + YouTube channel-follow + six Chatterino ports

Research session (Chatterino2 / Chatterino7 source + multi-platform
YouTube tools) → `docs/chatterino-comparison.md`, then the YouTube fix and
every "cheap, high-value" port from that doc, all on `master`, tier S:

- **YouTube channel entries** (`1db0701c`): entries may be `@handle` /
  `UC…` / channel URL (`lib/utils/youtube_target.dart`) instead of a
  per-stream video id. `YouTubeLiveResolver` scrapes the channel's `/live`
  page canonical (quota-free) → existing 1-unit `videos.list`; the store
  re-checks on `kYouTubeLiveRecheckSchedule` after a stream ends and
  reattaches to the next one (rows of the old stream stay as history).
  WebView follows via `YouTubeWebLiveTracker`. **Live-verified gotchas:**
  Dart's `http` gets the ~1.2 MB desktop page regardless of UA, the
  canonical moves ~30 KB → ~700 KB deep with `Accept-Language`, and
  offline channel pages emit it *after* `</head>` — hence the streaming
  sliding-window scan with no head cutoff (the first two versions failed
  the live smoke, unit tests alone didn't catch it). Unknown handle → 404
  → terminal error. No Hive shape change.
- **Twitch history backfill** (`5d6f8bbf`): `recent-messages.robotty.de`
  (Chatterino's service) on join, IRC lines parsed into
  `ChatMessageEvent` (`isHistorical`, dimmed), once per channel per
  session, toggle `TwitchChatLoadHistory`. `test/flutter_test_config.dart`
  now mocks that service's default client suite-wide. Live smoke: 180
  real messages parsed, 0 fragment/text mismatches.
- **Autocomplete** (`6ede3edf`): `@user` / `:emote` / bare-word chip strip
  over `NativeChatInput` (`completionSource` seam, per-engine feeds in
  `chat_completion_sources.dart`).
- **Readability** (`895148bd`): timeline timestamps, stable zebra rows
  (`ChatRowParity` — index parity strobes on eviction), readable name
  colors (HSL lightness nudge to 3:1 contrast, default on).
- **Emotes** (`8b4c9e73`): FFZ global + Twitch room sets (lowest tie
  precedence), zero-width overlays (7TV `flags & 1`, BTTV fixed list, FFZ
  image modifiers) stacked on the preceding emote.
- **Highlights / ignores** (`7fb905fb`): highlighted + ignored user lists
  (options sheet + long-press rows + Twitch user card), `/regex/` entries,
  censor-to-`***` mute mode (`ChatFilterSettings`). The Twitch *mod*
  sheet deliberately doesn't get the rows — adding them pushed its
  existing rows off the 600px test viewport.

Gates: `test/chat/` 1005 pass / 4 fail (the known pre-existing
`mod_action_sheet_test.dart` hit-test flakes — reproduced identically on a
stash of the pre-change tree); websocket/persistence/utils/pro pass (the
known `state_ordering_test.dart` flake hit once, passed on rerun);
`dart analyze lib` at the 143-info baseline. Not run on a device/sim.

## 2026-09-24 - Pro revert gesture + the sheet drag-back saga (3 debugging rounds) + connect-box sequential crossfade

Follow-on dogfood feedback from the second polish batch, all on `master`,
each round installed to the physical device and re-tested before the next:

- **Pro** revert gesture (`faa1b87b`): the paywall's long-press could only
  turn the debug/test unlock *on* (from the sales view) - once `isPro`
  flipped true there was no way back short of reinstalling. Added the
  mirror long-press on `ProUnlockedView`'s result icon, wired to
  `setDebugOverride(false)`, same `kDebugMode`/`kProReleaseTestUnlock` gate.
- **Sheet drag-back - three real, distinct bugs found in sequence,
  each only surfacing after the previous fix shipped and got tested on a
  real sheet:**
  1. (`943b37e3`) The recovery-tracking only handled a reversal that
     produces a `ScrollUpdateNotification` (scrollable content moving off
     the boundary). A sheet whose content fits without scrolling at all
     (min == max extent, e.g. the YouTube chat setup sheet's short form)
     has no valid scroll direction either way, so its reversal is *still*
     an `OverscrollNotification` - just positive instead of negative,
     which nothing handled. This is the one the user could actually
     reproduce; the generic scrollable-list test case in the prior
     session's fix had passed but didn't match the real sheet's shape.
  2. (`6e6ecf41`) Fixing (1) surfaced a worse bug on real hardware: the
     recovery path called `ScrollPosition.jumpTo()` to stop the
     underlying list from visibly scrolling during recovery.
     `jumpTo()` replaces whatever activity owns that position - including
     the drag activity the user's own still-down finger was actively
     driving. Result: the first reversal step snapped the sheet straight
     back to full size, and the same touch produced zero further
     notifications until lifted and restarted. Dropped the `jumpTo` call
     entirely; the list may drift a few pixels during recovery now, a
     minor cosmetic tradeoff for a drag that actually works.
  3. (`499c37af`) Fling-to-dismiss still felt unreachable, and lowering
     the velocity threshold three times (300 → 150 → 100, `a75aceef`/
     `3debe865`) never fixed it. Root cause, found by reading Flutter's
     own `bottom_sheet.dart`: dragging from a handle area outside any
     `Scrollable` goes through the framework's *own* native drag-to-
     dismiss, which reads **raw pointer velocity** - that's why it "just
     worked" there. Dragging from inside a sheet's content went through
     this app's custom overscroll tracking instead, which read velocity
     from `ScrollEndNotification.dragDetails.primaryVelocity` - the
     scroll view's own *physics-filtered* number, reading far lower for
     the same physical flick. Fixed by tracking raw pointer velocity with
     a `VelocityTracker` (fed from `Listener.onPointerDown`/
     `onPointerMove`) and adopting Flutter's own threshold (700,
     `_kMinFlingVelocity`) instead of continuing to guess against the
     wrong signal.
  Each round added/extended a widget test in
  `test/utils/modal_handler_bottom_sheet_test.dart` that failed against
  the previous state and passes now - six sheet-drag tests there in total.
- **Home** connect-mode crossfade made sequential (`9c96b5ce`): was a
  simultaneous cross-dissolve (outgoing 1→0 and incoming 0→1 over the same
  window); wanted a full fade-out then a full fade-in instead. Both
  AnimatedSwitchers' fade curve is now `Interval(0.5, 1.0)` - applied to a
  forward (incoming) animation it stays at 0 until the midpoint then ramps
  to 1; applied to the same switch's own reverse (outgoing) run it ramps 1
  to 0 by the midpoint then stays at 0. Same curve object, no direction
  branching needed. Pane sizing keeps its own full-duration curve so
  content below the card doesn't jump.
- **Home** refresh icon fade-in start tuned twice more (`a88fff81` →
  `58bfd455` → `de21d285`): 10% → 20% → 25% before the icon starts
  appearing (full opacity still lands at 80% of the arm threshold).

Full gate at wrap-up: `dart analyze lib/ test/` 0 errors (388 pre-existing
baseline infos, same count as every prior wave); `flutter test test/chat/
test/websocket/ test/persistence/` 996/1000 - only the 4 known
`mod_action_sheet_test.dart` hit-test-offset flakes (documented below,
unrelated to this wave).

## 2026-09-23 - Second polish batch (chat search alignment, sheet drag-back, haptics, paywall vortex mark, refresh icon timing)

User feedback on the first batch (dogfooded), 5 more independently
committed units:

- **Chat** search results left-aligned (`1bb5e6df`): the results `Column`
  relied on default center cross-axis alignment, so a message row with no
  flex child (no reply line) shrink-wrapped to its own text width and
  centered instead of spanning the sheet like the live feed. `stretch`
  fixes it.
- **Sheets** drag-to-dismiss can grow back mid-gesture (`750435a9`): the
  overscroll tracker only listened for `OverscrollNotification` (pulling
  further), but a reversed drag doesn't produce more overscroll - the
  scroll view reports a normal `ScrollUpdateNotification` once pixels
  move off the boundary, which the tracker never handled, so a sheet
  could shrink but never grow back before release. Fixed by redirecting
  that notification into growing the sheet and snapping the scroll
  position back to the boundary. Root-caused via print-instrumenting the
  actual notification stream during a reversal (an initial pointer-event-
  based rewrite was tried and reverted - it depended on pointer/frame
  interleaving that doesn't hold up against batched test gestures, and
  likely not against real fast drags either). Regression test drives a
  drag-then-reverse without releasing.
- **Haptics** extended to more state-changing actions (`5ef02599`): every
  dialog confirm/cancel app-wide (one fix in `BaseAdaptiveDialog`),
  stream/record start-stop, record pause/resume, replay buffer
  start-stop/save, studio-mode Transition, hotkey trigger. Audited via a
  subagent survey of existing `HapticFeedback`/`Pressable(haptic:)` call
  sites first to match the established vocabulary (light = state toggle,
  medium = a heavier/destructive action).
- **Pro paywall** vortex mark + badge (`f103e44c`): swapped the generic
  bolt icon for the actual OBS Blade vortex glyph (extracted from the
  app's own icon asset via luminance-based alpha keying against its solid
  navy backdrop - no separate transparent source existed) tinted to the
  theme accent, with a stacked gradient "PRO" badge at the bottom-right
  corner. Verified via a throwaway `RenderRepaintBoundary.toImage()`
  screenshot test (not a real device) - caught two real layout bugs this
  way: the image needs `precacheImage`/`runAsync` in tests to actually
  decode before capture, and `Positioned` (not `Align`) must anchor the
  badge or it inflates the whole Stack's size.
- **Home** pull-to-refresh icon fades in earlier (`6dc5e40c`): the old
  exponential opacity curve didn't fully show until ~85% of the (now
  longer, /8) arm threshold. Replaced with a directly-tunable eased ramp
  that's fully visible by 80%, leaving the last 20% as the pre-existing
  haptic+scale arm window.

Full gate at wrap-up: `dart analyze lib/ test/` 0 errors (388 pre-existing
baseline infos, same count as before this batch); `flutter test test/chat/
test/websocket/ test/persistence/` 994/999 - the 4 known
`mod_action_sheet_test.dart` flakes plus one instance of the known
`state_ordering_test.dart` flake (both already documented below, confirmed
unrelated).

## 2026-09-23 - Five-item polish batch (crossfade fix, scene preview sizing, release Pro-test unlock, benefit copy, em dash sweep)

User-reported/requested batch, 5 independently committed units:

- **Home** connect-mode crossfade dedupe (`09ce1e53`): `AnimatedSwitcher`
  only compares an incoming child's key against the current entry, not the
  whole outgoing list, so revisiting a mode (e.g. Autodiscover) while its
  own previous pane was still fading out rendered two panes on top of each
  other instead of a clean crossfade - reproduced and verified via a
  widget test driving rapid mode switches, not by eyeballing it. Fix: a
  `connectModeSwitchGeneration` counter folded into the pane/title keys so
  every switch is unique regardless of mode reuse.
- **Dashboard** scene preview fixed-aspect fix (`2768c54a`): the preview
  sized itself via `IntrinsicHeight` around the fetched screenshot's own
  decoded dimensions, so opening the pane visibly grew from the "fetching"
  placeholder's arbitrary 150px up to the real image's natural size once
  it decoded. Two direct repro attempts (image swap mid-crossfade; stale
  cached image on re-open) showed a smooth monotonic climb, not a literal
  overshoot-then-correct - the fix (pin to `AspectRatio(16:9)`, matching
  the already-16:9 `ScenePreviewMock`) removes the resize regardless of
  the precise mechanism. Also null-guards the inner `Observer`'s
  `Image.memory` read against a same-frame race with the outer
  `_imageAvailable` gate.
- **Pro** release-build test unlock (`c7eb2979`): store products aren't
  purchasable yet (ASC review pending), so there was no way to exercise
  Pro-gated paths on a release/TestFlight build. Extended the existing
  `kDebugMode`-only paywall long-press override to also work when compiled
  with `--dart-define=PRO_RELEASE_TEST_UNLOCK=true`
  (`kProReleaseTestUnlock` in `pro_ids.dart`) - defaults false, ordinary
  release builds unaffected.
- **Pro** benefit copy rewrite (`0967b065`): the 4 benefit cards predated
  the native chat gap-audit wave and never mentioned Kick chat, multi-chat,
  the wave-3 mod tooling, emotes/badges, or search/highlight/mute. Now 6
  cards (platform card consolidated to cover Twitch+Kick+YouTube, plus
  Multi-Chat, Full Moderation Toolkit, Emotes & Badges, Smarter Chat,
  What's Next); the tablet grid builds rows from the list length instead
  of 4 hardcoded indices; the in-chat locked-pane upsell skips the
  (redundant, given its own headline) platform card.
- **Style** em dash sweep (`ddb96d4e`): every string literal in `lib/`
  that reaches the user (UI text, chat notices, dialog copy, in-app Logs
  viewer messages) had its em dash replaced with a regular hyphen; doc/
  line comments and generated files are untouched. Updated the chat tests
  asserting the exact (now-changed) marker/notice strings.

Full gate at wrap-up: `dart analyze lib/ test/` 0 errors (388 pre-existing
baseline infos across the whole project); `flutter test test/chat/
test/websocket/ test/persistence/` 1000/1004 - only the 4 known
pre-existing `mod_action_sheet_test.dart` hit-test-offset flakes (already
documented in the entry below, confirmed via stash/standalone re-run to
predate and be unrelated to this batch).

## 2026-09-23 — Native chat gap audit: Twitch-parity + general enhancements (17 commits)

User asked for an audit of Twitch's native chat (the most advanced engine)
against Kick/YouTube, plus general cross-engine enhancements — approved
whole-report ("everything", tier S) via `AskQuestion`. Shipped in priority
order, each unit gated (format/analyze/test) and committed on its own:

- **YouTube** live viewer count in the chat header — free field
  (`liveStreamingDetails.concurrentViewers`) on the same `videos.list` call
  already made for `activeLiveChatId`, zero extra quota (`3febe6de`).
- **General** new-message count on the pause/scroll chip, all 3 engines
  (`fae9146a`).
- **Kick** read-only chat-mode banner (slow/followers/subs/emote-only —
  Kick has no write API for these, informational only), sub/gift-sub/host
  notification rows (`KickChatroomEventKind` — these were previously
  dropped as `unknown`), a defensive fix for the live `ChatroomUpdatedEvent`
  nested `{enabled: bool}` shape, options-sheet Event-messages page, 7TV
  third-party emotes, options-sheet Emotes page, a channel emote picker
  (discovered live that the per-channel endpoint bundles Kick's Global +
  Emojis sets too — `docs/kick-chat-audit.md`'s "no verified global-emote
  endpoint" claim was stale, corrected in `04a3566e`), a Badges master
  toggle (per-category `badge_type` values unverified, so one toggle not
  Twitch's per-category set), and LIVE/viewer preview on unselected
  channels in the multi-chat dropdown (`42436442`…`5264e8f7`).
- **General** self-mention/keyword row highlighting (`ChatHighlightSelfMention`
  + `ChatHighlightKeywords`, shared matcher) and a client-side mute-word
  filter, both across all 3 engines (`10c05bad`, `6900f62f`).
- **General** chat search/filter over each engine's buffered history
  (`ChatSearchSheet`, `9a0258e9`) — fixed a MobX "no observables detected"
  warning by reading a cheap observable unconditionally before the
  `Observer` builder's early-return branch (precedent: `AddChatSheet`).
- **General** "Copy message" long-press action, generalizing Twitch's
  lightweight non-mod `MessageActionSheet` (nullable `onReply`, always-on
  Copy) so fully read-only viewers — previously with zero long-press
  affordance at all — get a Copy-only sheet instead of nothing (`5a379e7d`).
- **General** screen-reader semantics on all 3 message row widgets — each
  row collapses into one `Semantics(container: true, excludeSemantics:
  true, label: ...)` node built from raw model fields (not the rendered
  span tree, since the author name flips between a plain `TextSpan` and a
  `WidgetSpan`-wrapped `Pressable`), with `onTap`/`onLongPress` as the two
  surviving explicit actions (`22085b0f`).

New Flutter testing gotcha found along the way: `tester.ensureSemantics()`'s
`SemanticsHandle` must be `.dispose()`d as the literal last statement in
the test body, not via `addTearDown` — Flutter's own end-of-test handle
check runs before the `test` package's `addTearDown` queue, so an
`addTearDown`-registered dispose is always reported as "still active".

Full gate at wrap-up: `flutter analyze` clean (0 errors, only pre-existing
`tool/*` info-lints and a handful of pre-existing warnings unrelated to
this diff); `test/chat/ test/websocket/ test/persistence/` — only the 4
known pre-existing hit-test-offset flakes in `mod_action_sheet_test.dart`
plus one instance of the known pre-existing `state_ordering_test.dart`
timing flake (both confirmed via stash/standalone re-run to predate and be
unrelated to this wave).

Explicitly out of scope (flagged, not built): on-disk scrollback
persistence across app restarts — touches persistence, which AGENTS.md
calls out as needing its own careful pass.

## 2026-09-23 — Kick token exchange proxy

Kick requires a client secret and will not accept a public PKCE client
(probed: omitting the secret is HTTP 400, a wrong secret is 401, including
for client id `01M356MAT9Z4YB9HBESV9ZQN6S`). The phone now posts the code
and PKCE verifier to `https://kick-auth.kounex.com/oauth/token`. Kick's
browser redirect is `https://kick-auth.kounex.com/oauth/callback`: the host
exchanges it and the app polls with a token that never appears in that URL,
so the user does not paste the address bar. The secret stays in
`/etc/kick-auth.env` on the exchange host. `tool/kick_auth_proxy/` is the
localhost-only forwarder.

## 2026-09-23 — Kick sign-in can use an app-owned OAuth client

Pro users should not register their own Kick developer app. The client id
and secret compile in from gitignored `docs/private/kick_oauth.json`
(`KICK_OAUTH_CLIENT_ID` / `KICK_OAUTH_CLIENT_SECRET`). A build without
that file keeps the bring-your-own setup sheet. The browser paste step
stays: Kick has no device flow.

## 2026-09-23 — Kick native read: don't spoof a browser User-Agent

`GET kick.com/api/v2/channels/{slug}` from dart:io with a Safari/Chrome
User-Agent is rejected by Cloudflare ("Request blocked by security policy")
even on a home network — the same call with a plain `OBSBlade` agent
returns 200. The native pane was showing "Could not resolve the Kick
channel" for slugs the WebView opened fine. Reads now send `OBSBlade`.

## 2026-09-23 — Native Kick chat write/mod (W3)

Follows the read engine (`bc29c40f`). Optional sign-in is manual-paste
PKCE (Kick has no device flow; BYO client id/secret in the Kick setup
sheet). Tokens live in a new `KickAuth` Hive box (`TypeIDs.KickAuth` =
16). Send, reply, delete, timeout, and ban go through `api.kick.com`;
refresh rotates both tokens (single-flight). The mod long-press is
offered to any signed-in user — a non-mod's action 403s into a snackbar.
Unban is a store method only (no row). Widget tests that persist a
session use `tester.runAsync` so the Hive write doesn't hang the
fake-async zone.

## 2026-09-22 — WebView chat URL hardening (Twitch darkpopout, YouTube popout form)

Audit of the legacy WebView chat path (verdict + probes in
`chat-webview-audit.md`): it still works today (live-probed, EU IP), but the
YouTube URL rode the bare embed form without `embed_domain` — Google's docs
require one and call mobile-web embedding unsupported, so an enforcement flip
would break every user at once. User-ratified fixes:

- **YouTube** WebView URL → YouTube's own popout form
  `live_chat?is_popout=1&v={id}&embed_domain=localhost` (chat-only chrome;
  `embed_domain` present but unverifiable without a parent frame).
- **Twitch** popout URL gains `?darkpopout` — the bare popout rendered as a
  white card inside the dark app.
- **Per-video YouTube entries stay** (ratified): `@handle/live` auto-resolution
  probed and rejected — mobile UAs don't resolve, EU consent redirects break
  the chain without cookies; reliable resolution = native engine's API-key
  territory. Dialog copy now says any watch/live/share/pop-out link works.
- **Consent-wall detection**: `onUrlChange` watches for bounces onto
  `consent.youtube.com` / `accounts.google.com` (GDPR regions, bot
  heuristics — per-IP/session, not per-country) and floats a hint pill over
  the chat ("tap through it below") instead of looking broken; the wall page
  stays fully interactive and WebView cookies persist (verified: nothing in
  the app clears them), so it's a one-time tap. Detection is AppLog'd for
  support traces.

## 2026-09-22 — `4.0-liquid-glass` merged into `master` (branch closed)

User dogfood-approved the 4.0 UI rework ("happy with the ui rework") →
fast-forward merge `23070815..df1437d9` (**211 commits**, 474 files,
+34k/−18.5k), branch deleted locally/remotely/on the workstation clone —
all clones now track `master`. Pre-merge gate: full suite + analyze; only
failure was the documented pre-existing `state_ordering_test.dart` flake
(passes on re-run, passes on the workstation clone). Dogfood-fix batches
that landed between the polish wave and the merge:

- **Settings/home/dashboard** (`f3dbc40f`…`892159a8`): "Command Failure
  Alerts" shortened to "Failure Alerts" (ellipsis on phones — standing
  rule: settings labels stay short); saved-connection card header
  realigned on one line via the OverflowBox idiom (44pt hit target kept
  invisible, row not inflated); connect-mode switcher (autodiscover /
  scan / manual) is a clean crossfade now — translate animation removed
  per user direction; scene-tile selection ring animates with the fill
  (`boxAnimation`) instead of snapping off instantly.
- **Chat bar YouTube side** (`07a81c4a`): "Set up YouTube" pill uses
  AutoSizeText mirroring the Connect pill (was wrapping to two lines);
  ChatType dropdown overflow fixed — label is Flexible + ellipsizes, the
  superscript beta marker pinned to 10pt (was inheriting body size),
  dead trailing spacer removed (was a 6px paint overflow).
- **Chat header alignment** (`df1437d9`): the username bar stacked three
  horizontal insets (page `md` + `usernameRowPadding` `xs` + the bar's
  own `sm`) over the chat window's single page margin — controls sat
  visibly inboard of the chat card. Bar is inset-agnostic now (hosts own
  the margin), `usernameRowPadding` removed with both call sites;
  streaming-mode floating header keeps uniform panel padding (was
  doubled horizontally).

## 2026-09-22 — Custom theme cleanup on `4.0-liquid-glass`

Theme-system audit against the now-stable token layer (full map: model
fields, presets, editor knobs, wiring) + user-ratified direction (rebuild
the preset lineup, merge the bar knobs, rename labels to the token grammar,
status colors stay fixed). 3 commits:

- **Preset lineup retuned** (`built_in_themes.dart`): Bright Star's accent
  was a 7-char typo (`34bafff` → decoded to a wrong, 95%-alpha sky since it
  shipped) — now `0284c7`; Red Underdog was semantically inverted under the
  two-group grammar (brand blue, controls red) — now brand red `cc0000` +
  blue controls `0a84ff` (YouTube's actual grammar); Pure Indigo gets a
  differentiated readable control violet `a78bfa` (was accent=highlight);
  Snowstorm's accent deepened `7391d1`→`4a6fd1` for filled-CTA contrast;
  highlight pins the correct variant per brightness (`0a84ff` dark /
  `007aff` light — the token layer assumes the dark variant on dark
  themes). UUIDs/createdMS pinned, so active selections survive.
- **Editor** (`add_edit_theme.dart` + `theme_colors_row.dart`): AppBar +
  TabBar merged into one **Navigation Bars** knob (writes both Hive fields;
  presets now ship equal bar values); labels renamed — App Background,
  Cards & Sheets, Navigation Bars, Brand Accent, Controls & Links; "kinda
  the primary color" legacy copy gone; color-dot strip matches the new
  slots/order.
- **Wiring fixes** (`app.dart`): Material slots' highlight fallback is now
  the dark-variant `#0A84FF` the token layer assumes — the default dark
  theme no longer ships two blues (slots baked `#007AFF` from
  `CupertinoColors.systemBlue` while `highlightText` derived from
  `#0A84FF`; the Cupertino override keeps the dynamic color); `surface`
  unifies on the card wash for light themes too (was hardcoded white);
  `hightlightColor` typo renamed; dead `StylingHelper.primary_color`
  removed. `CustomTheme.basic()` seeds new themes with `0a84ff`; dead Hive
  fields (`starred`, `textColorHex`, write-only `dateUpdatedMS`) documented
  as reserved — never reused (field-number stability).

Gates: analyze at baseline, settings + persistence + design suites green.
Known leftovers: the color picker's `useAlpha`/`editableColorValues` paths
are unreachable (no caller enables them) — candidate for removal; user
themes saved with divergent appBar/tabBar values collapse to one value on
next edit (intended merge behavior).

## 2026-09-21 — 4.0 full-app UI polish wave on `4.0-liquid-glass`

Whole-app UI consistency audit (10 parallel area audits over all 274 files in
`lib/views/` + `lib/shared/`, ~120 verified findings) followed by one fix wave
the user approved wholesale. **79 commits**, findings→fixes map + leftovers in
[`redesign/2026-iteration/ui-polish-audit-2026-09-21.md`](redesign/2026-iteration/ui-polish-audit-2026-09-21.md).
Highlights:

- **Functional bugs:** filter-list self-comparison, routing-helper braces,
  dialog padding swap, settings switcher key collision, theme-name validation
  never rendering, `press_flash` dispose-after-deactivate crash,
  `cupertinoOverrideTheme.primaryColor` wrong accent.
- **New status slots:** `destructive` / `destructiveText` / `info` on
  `AppStatusColors`; error reds unified off `colorScheme.error`/raw
  `Colors.red*`; `unreachable` is reachability-only again.
- **Chrome:** both sub-page nav-bar wrappers on `GlassBar` (55pt + specular);
  `AppGlass` in `ModalHandler` sheets; toasts anchor below the full status
  app bar.
- **Chat:** sheet chrome family (drag handles, pane transitions, accent CTA
  grammar), neutral Mod chip, LIVE viewer count on `CountUpText`,
  `highlightText` link/CTA grammar, device-code dialog polish.
- **Motion/press grammar:** press springs from tokens, invisible 44pt hit
  floors (never visual bloat — ratified), reduced-motion gates (confetti,
  chart draw-in, `chatImageFadeIn`, theme crossfade), staggered entrances,
  Connect morph, tap-to-copy version stamp.
- **Ratified calibrations:** green stays for online/reachable/connected;
  hit-target fixes must be visually invisible; paywall hero keeps bolt +
  "OBS Blade Pro" headline; chat brand-fill strategy deferred to Phase-4
  chat-bar frame.

Gates: full suite green, analyze at baseline. Three extension-call sites now
fall back when a bare test theme doesn't register the extensions
(`appGlassOf`, `AdaptiveDialogAction`). Machine note: `/tmp` tmpfs filling up
makes `flutter test` hang silently in the kernel compiler — clean
`/tmp/flutter_tools.*` if a run wedges. Known flake (pre-existing, from the
2026-09-20 confirmed-state ordering wave — unrelated to this wave):
`test/websocket/state_ordering_test.dart` intermittently fails one of its
ack-timeout ordering tests ("Batch request timed out waiting for ack"); it
passes on re-run, sometimes standalone-only.

## 2026-09-20 — Chat independence: dedicated Chat tab (astra port) on `4.0-liquid-glass`

Chat was reachable only inside the dashboard route, which itself only exists
after a successful OBS connect — no session, no chat. The dependency was
purely navigational: chat state lives in the global settings box and the
GetIt chat stores, whose connections never touch the OBS socket. Per the
ratified design (`superpowers/specs/2026-09-20-chat-independence-design.md`,
plan `superpowers/plans/2026-09-20-chat-independence.md`; astra's "chat
first-class" idea translated into our routing idiom — its no-routes shell
was explicitly not adopted):

- **New `Tabs.Chat`** (Home · Chat · Statistics · Settings,
  `CupertinoIcons.chat_bubble_2_fill`) with `ChatTabRoutingKeys`
  (`/tabs/chat` + `/tabs/chat/pro`) — the tab scaffold auto-generates the
  navigator; the IndexedStack keeps chat warm (scroll position + composer
  text survive tab switches).
- **`ChatView`** (`lib/views/chat/chat_view.dart`): the landing-view idiom
  (`TransculentCupertinoNavBarWrapper` `customBody`), `StreamChat`
  full-bleed on phone, 640-capped centered column on larger screens,
  tab-bar bottom clearance reusing the `CustomSliverList` formula.
- **`StreamChat` seams** (defaults = today's dashboard behavior):
  `scrollArbitration: false` skips the pointer-band `Listener` and the
  `DashboardStore` lookup (audit defect #4 simply doesn't apply — no parent
  scroll view); `proRoute` lets the Pro upsell resolve on the host tab's
  navigator (`/tabs/chat/pro` → same `ProPaywallView`).
- **Untouched:** dashboard chat pane (live co-display + tablet
  side-by-side), chat stores, WebView engine.

S-tier wave, 2 production commits + docs (`8fb519fa` seams, `94a70d74` tab).
Gates: full chat suite **663 green** (6 new: 3 seams + 3 tab), analyze at the
472 baseline. Test harness notes: the translucent nav bar wrapper's non-Apple
branch force-unwraps `appBarTheme.backgroundColor` (test themes must set it,
mirroring `lib/app.dart`), and route-push assertions need a second pump for
the Cupertino transition to build the incoming page. Follow-ups (ratified):
conversation-owned drafts wave; optional live-session strip (program pill +
quick mic — the astra focus-swap translation). **Pending: user dogfood** —
pre-connect chat reachability, Dashboard↔Chat tab switching, tablet column.

## 2026-09-20 — Stale-state honesty (astra phase 3, wave 2) on `4.0-liquid-glass`

Second interaction port per the ratified progressive-adoption verdict:
during a reconnect the dashboard used to keep rendering values as if live
while taps sent mutations into the dead socket (intent silently lost; only a
small toast hinted at it). Now, per the ratified design
(`superpowers/specs/2026-09-20-stale-state-honesty-design.md`, astra's
"stale = confirmation channel gone" concept, not its code):

- **`DashboardStore.obsStateStale`** — one plain-getter predicate (=
  `reconnecting`; deliberately NOT `@computed`, no codegen; documented seam
  for future drivers like the collection-changing window).
- **`sendMutation` guard** — refuses sends while stale and returns the new
  `ObsRequestAck.notSent` (`ObsRequestFailureKind.notSent`), bypassing the
  resync re-read + failure toast by construction (the reconnect burst
  re-reads everything, and lands immediately thanks to the D1 wipe).
- **Per-pane `StaleStateBadge`** ("LAST KNOWN STATE - reconnecting to OBS",
  neutral token color, `AppMotion.medium` switcher) docked above the
  Scenes / Scene Items / Audio pane content — one uniform anchor per pane,
  covering phone tabs, tablet side-by-side, and standalone card layouts.
  Values are never dimmed or hidden (astra's honesty rule).
- **`StaleGuard`** (`Observer` → `IgnorePointer` + 0.45 opacity) wraps every
  mutation control: scene buttons, scene-item tiles + slide actions, audio
  sliders/mutes, studio-mode + transition controls, profile/scene-collection
  pickers, exposed controls (stream/record/replay/hotkeys), filter toggles +
  settings, and the app-bar actions menu. Never wraps a scrollable.
- **Toast honesty:** "values shown are the last known state" added to the
  reconnect toast; `RECONNECTING!!!!!` debug log dropped.

S-tier wave, 2 production commits + docs (`f7e2833a` guard, `407acf31` UI).
Gates: full suite **803 green** (3 new guard tests in
`command_ack_dashboard_store_test.dart`), analyze at the 472 baseline.
**Pending: user dogfood** (quit OBS / kill network mid-session → badges +
lockout; restart → snap back).

## 2026-09-20 — Ordering wave MERGED into `4.0-liquid-glass` + dead-transport tag wipe (D1 fix)

User dogfood approved the confirmed-state ordering wave → merged
fast-forward (`191f1f13`, pushed; branch `confirmed-state-ordering` kept at
the same tip). Same commit fixed the wave's one tracked residual (D1):
dead-socket reconnects left stale read tags queued, so the first
post-reconnect responses per read target popped them FIFO, failed the epoch
check and were discarded — gated state converged one read late, or never for
reads only re-driven by events (e.g. `GetSceneList` on a static OBS). Fix:
`_wipeOrderingQueues()` at the `initialRequests()` seam, which only ever runs
on a provably fresh socket (`init()` runs on a brand-new store via
`resetLazySingleton<DashboardStore>()` in the dashboard view's `initState`;
the only other caller is the `_checkOBSConnection` reconnect-success branch).
Live-socket `_resetOrdering()` callers (collection change) keep their FIFO
tags — clearing there would let a stale response pop a fresh send's tag and
apply ungated (the original plan defect). Regression test drives a real
socket swap through the fake peer (`closeSockets()` + reconnect — the
socket-swap support the wave review had scoped): tag queued on the dying
socket, reconnect, fresh burst response must apply immediately (RED pre-fix:
epoch-gated, timed out). The synthetic Test C (initialRequests on a live
socket — a premise production can never reach) was replaced by this
transport-real version. Gates on the merged tree: full suite 800 green
(chat 657 / websocket 46 / persistence+pro+statistics+settings+utils 97),
analyze at the 472 baseline. Flake note: 3 `twitch_chat_store_test.dart`
tests flaked once under machine load (timeout cascade — the file took 4+
min); green standalone and in a quiet full-file re-run. Pre-existing timing
sensitivity in the multi-channel/lifecycle tests, unrelated to this change —
watch it.

## 2026-09-18 — Confirmed-state ordering (astra phase 3, wave 1) built on `confirmed-state-ordering`

First interaction port per the ratified progressive-adoption verdict
(`redesign-astra-audit.md`): DashboardStore applied every read response blind,
so rapid event→re-read races let a stale response clobber fresher event-set
state (scene switches during transition spam, visibility toggles, slider
drags). The wave adds a pure `EventOrdering` component
(`lib/utils/event_read_ordering.dart` — epochs + per-key event journals) plus
in-place DashboardStore seams: tracked read sends push epoch-capturing
`_ReadTag`s onto per-target FIFO queues; responses pop FIFO and apply only if
the tag's epoch matches the current epoch and the journaled events allow it.
Domains: scenes (program/preview/studioMode), scene-item visibility (incl.
group children), audio volume/mute. Epoch resets land on session re-attach
(`initialRequests`), scene-collection changing/changed, `SceneListChanged`,
`InputNameChanged`, and a new `SceneNameChanged` case — which also added the
enum value + typed event class (wire shape `sceneUuid`/`oldSceneName`/
`sceneName` verified against the official obs-websocket protocol doc, v5.0.0+).
Optimistic UX deliberately unchanged; syncOffset deliberately ungated
(follow-up); STALE/pending surfacing is a later wave. Spec:
`superpowers/specs/2026-09-18-confirmed-state-ordering-design.md`; plan:
`superpowers/plans/2026-09-18-confirmed-state-ordering.md`. One plan defect
ratified at review (D1): the plan-mandated unconditional tag-queue clears
contradict the FIFO pop invariant (empty queue = apply ungated, so a stale
response pops a fresh send's tag and applies) — epochs-only is correct on a
live socket; the dead-socket residual (first k post-reconnect responses per
queue get epoch-gated) is track-don't-fix, defect class appended to
`superpowers/plan-defect-checklist.md`, eventual wipe belongs at the
`_checkOBSConnection` success seam. Gates: full suite 800 green
(chat/websocket/persistence/pro/statistics/settings/utils), analyze exactly at
the 472 baseline; final whole-branch review APPROVED FOR DOGFOOD
(`.superpowers/sdd/final-review-ordering.md`). 5 commits on
`confirmed-state-ordering` (`2c11fdde..c9911323`, pushed). **Pending: user
dogfood vs real OBS → merge into `4.0-liquid-glass` on OK.**

## 2026-09-18 — Astra porting scope: inspect-vs-command dropped (Studio Mode covers it)

Design decision, user-ratified: the "inspect-vs-command + Take bar" port from
the astra roadmap is dropped. OBS itself ships the inspect-first concept as
**Studio Mode**, and the app already mirrors OBS's semantics: with studio mode
enabled (opt-in via `SettingsKeys.ExposeStudioControls` + the dashboard
studio-mode checkbox) a scene tap sends `SetCurrentPreviewScene` (inspect —
`scene_button.dart`) and the transition button sends a real
`TriggerStudioModeTransition` (the "Take" commit — made real by the
command-ack wave). An always-on inspect layer would duplicate a concept OBS
users already have and diverge from OBS behavior. Remaining phase-3 ports:
confirmed-state projection (incl. STALE surfacing) and chat independence.
Preference-translation scope narrows accordingly — the Take-dock /
`ExposeStudioControls` collision is gone; hidden-scenes / wakelock / retry
mapping is still owed before the confirmed-state port.

## 2026-09-18 — Empty-batch crash fix (fetchSceneItemsFilters follow-up)

The latent bug found during the command-ack wave is fixed: a scene with no
scene items (`FilterList`) or a profile with no inputs (`Input`) made
`makeBatchRequest` send an empty RequestBatch; OBS answers those with an
empty results list and `BaseBatchResponse.batchRequestType`'s `firstWhere`
threw "No element" — an unhandled async error in `_handleBatchResponse`
(reproduced as a RED test carrying the exact production `StateError` before
the fix). Root-cause fix at the chokepoint: `makeBatchRequest` short-circuits
empty batches (nothing to ask = nothing to send) with an immediate successful
empty `ObsBatchAck`. The `FilterDefaultSettings` call site already guarded
with `isNotEmpty` — that guard stays (explicit, harmless). Regression tests:
unit level (nothing on the wire, empty success ack, no pending leak) and
store level (full crash chain: rejected scene switch → GetSceneList re-read →
GetSceneItemList with empty `sceneItems`). Gates: `test/websocket/` 35 green,
analyze at the 472 baseline. 1 commit on `4.0-liquid-glass` (`9d6619b2`).

## 2026-09-14 — Command-ack layer (astra phase 2) built on `command-ack-layer`

Astra phase 2 per the ratified mini-design
(`superpowers/specs/2026-09-14-command-ack-layer-design.md`): OBS commands are
now awaitable — every request/batch registers a per-UUID completer answered by
the op-7/op-9 response, resolving to a typed `ObsRequestAck`/`ObsBatchAck`
(success / rejected(code, comment) / timeout / connectionLost). Fire-and-forget
callers keep working unchanged; `DashboardStore.sendMutation` routes all
DashboardStore mutations through the ack policy — on definitive failure it
re-reads the confirmed state via the matching `Get*` (self-healing, no
optimistic rollback by hand) and surfaces a deduped toast (per-failure-target
dedup key; slider ticks stay fire-and-forget, `onChangeEnd` commits are acked).
Kill-switch: Settings entry (`SettingsKeys.CommandFailureToasts`, default ON).
The studio-mode button now sends a real `TriggerStudioModeTransition` — it
previously never sent any transition request (pure optimistic UI) and now
self-heals on rejection. 15 call sites converted.

Reviewer pass (independent subagent): SHIP-WITH-FIXES — fixes applied: no
state re-read on `connectionLost` (dead socket would burn a reconnect cycle;
the post-connect init burst re-reads anyway) and the toast dedup key now
includes the failure target so e.g. two different inputs failing in a storm
each surface once. New test seam: `test/websocket/support/fake_obs_peer.dart`
(loopback v5 peer scripting rejections/drops) + `command_ack_test.dart`,
`command_ack_dashboard_store_test.dart`, `command_failure_toasts_entry_test.dart`.
Real-OBS gate per the ratified design: new `tool/obs_local/ack_smoke.dart`
proved rejection (code 600), success-with-restore and mixed-outcome batches
against OBS 32.2.1 / obs-websocket 5.7.4 (docs: `local-obs-e2e.md`).

Known pre-existing bug FOUND, unfixed by design (follow-up candidate):
`fetchSceneItemsFilters` throws "No element" in
`BaseBatchResponse.batchRequestType`'s `firstWhere` when a scene has no items
(empty batch) — unhandled async error in production.

Gates: 780 tests green (chat/websocket/persistence/pro/statistics/settings),
analyze at the 472 baseline, real-OBS smoke OK. 7 commits on
`command-ack-layer` (off `4.0-liquid-glass`). **Merged into
`4.0-liquid-glass` on 2026-09-18 (fast-forward to `c295c218`) after user
dogfood against real OBS (scene switches, sliders, studio-mode transitions,
OBS quit/restart reconnect flow, kill-switch toggle) — approved.**

## 2026-09-14 — Flagged leftovers fixed: logs reset + statistics category clear

Follow-up to the defect-fix wave (user-approved): the two same-pattern
leftovers flagged in the previous entry are now fixed (TDD red-green each):

- **LogsView** reset `LogsStore` in `build` (wiped log filters whenever an
  ancestor rebuilt the view) — converted to a StatefulWidget, reset moved to
  `initState`. Correction to the earlier flag: `intro.dart` and
  `dashboard.dart` already reset in `initState` — grep hit without context;
  no change needed there. New `test/settings/` home (`logs_view_test.dart`).
- **Statistics category entry** in data management now also clears
  `PastRecordData` (it claimed "all entries listed in the statistics tab" but
  left recordings behind); description wording updated. Widget test drives
  the confirm flow (`data_management_view_test.dart`). Test gotcha reused:
  the confirm callback's Hive writes need `tester.runAsync`, real I/O inside
  the fake-async zone hangs the suite at shutdown.

Gates: 758 tests green, analyze at the 472 baseline. 2 commits on
`4.0-liquid-glass`.

## 2026-09-14 — Astra audit defect fixes: Statistics filters + delete-all-data

Two low-risk defect pairs from `docs/redesign-astra-audit.md`'s verified
master-defect table (user-confirmed scope; TDD red-green each):

- **Statistics filter state wiped on rebuilds** — `StatisticsView.build`
  called `GetIt.resetLazySingleton<StatisticsStore>()`; a detail-navigation
  roundtrip flips the `ModalRoute.of` dependency (`isCurrent`), re-runs
  `build`, and silently cleared active filters. Reset moved to `initState`
  (fresh per route creation, survives rebuilds + tab switches). Regression
  test reproduces the roundtrip (`test/statistics/statistics_view_test.dart`
  — new `test/statistics/` home).
- **`DurationFilter.Between` returned true for everything** — born
  unreachable in f541d1ab (2022, 3.0 RC): added to the enum but never to
  `kActiveDurationFilters`. Removed the enum value + dead switch case
  (zero user-facing change — it was never selectable). A real two-bound
  Between filter is new UI, not a defect fix — not built.
- **Delete-all-data omissions** — `deleteAllUserDataPreservingEntitlements`
  now also clears the `PastRecordData`, `Hotkey` and `PurchasedTip` boxes
  (test extended in `test/pro/data_management_delete_all_test.dart`).

Same-pattern leftovers NOT fixed (out of scope, flagged): `resetLazySingleton`
in `build` also lives in `logs.dart`, `intro.dart`, `dashboard.dart`; the
Statistics category entry in data management clears only `PastStreamData`
(recordings survive "All statistics" deletion). Gates: 756 tests green,
analyze at the 472 baseline. 2 commits on `4.0-liquid-glass`.

## 2026-09-14 — Astra harvest phase 1: production fixes land on `4.0-liquid-glass`

User chose `4.0-liquid-glass` as the harvest target (audit sequencing note:
landing on master now would guarantee format-migration merge friction).
Five units cherry-picked from `origin/redesign-astra` as scoped path-applies
(`git diff <commit> -- <paths> | git apply --3way`) — astra's `docs/redesign/`
governing docs, `lib/redesign/` shell and `test/redesign/` deliberately
excluded; three hunks needed manual resolution (tall-style vs short-style
context clashes, astra semantics kept in 4.0 formatting):

- `0d0c978b` → send-race ownership fixes: `twitch_chat.dart` /
  `youtube_chat.dart` capture destination/reply/session before awaiting token
  refresh; feedback and reply-clear only land on the owning conversation;
  YouTube sends append to the owning buffer when it isn't selected.
- `d8621562` → YouTube buffer retirement: a saved label whose video id changed
  retires cursor/liveChatId/messages/moderation keys; retired selection clears
  the visible destination instead of resurrecting stale history.
- `b88494a6` (partial) → `RequestType.TriggerStudioModeTransition` (v5.0+;
  prerequisite for defect #2) + `network_helper.dart` guard: custom envelopes
  no longer pollute `_requestBodyByUUID`.
- `54141fe1` (partial) → shared chat rows (`twitch_chat_message_row`,
  `twitch_chat_notification_row`, `youtube_chat_message_row`) accept optional
  `TwitchBadgeStore`/`ThirdPartyEmoteStore` (GetIt fallback; zero caller
  churn); bundled: long-press retires local hold state when the action fires
  (modal can't stick the wash) + super-chat amount uses foreground contrast.

Emote-picker unit NOT harvested: astra tip is still `54141fe1` — the WIP was
never committed (also noted in the handoff). Gates: 753 tests green
(chat/websocket/persistence/pro), analyze byte-identical to the 472-issue
baseline in touched files. 5 commits on `4.0-liquid-glass`.

## 2026-09-14 — Astra redesign audit: progressive adoption ratified

Full audit of the sibling first-principles redesign (branch `redesign-astra`,
session-workspace architecture): code audit of `lib/redesign/`, digest of its
nine governing docs, review of 22 prototype captures, and source-level
verification of its claims about master's UI. All six defect claims confirmed
on master AND unfixed on `4.0-liquid-glass`: SceneButton tap multiplexing
(browsing = live command), the mislabeled studio-transition button (sends
`SetCurrentProgramScene`), the fire-and-forget command layer (void returns,
log-only failures, no optimistic rollback), hardcoded chat WebView gesture
Y-bounds, Statistics Between-filter no-op + filter reset on rebuild,
delete-all-data box omissions (`PastRecordData`/`Hotkey`/`PurchasedTip`).
Verdict, ratified by the user: **progressive adoption** — keep the On Air/4.0
visual identity (incl. the transition-duration-synced scene-tile fade in
`SelectableBox`), adopt astra's interaction + state architecture in stages:
harvest its tested production fixes first, port confirmed-state projection /
inspect-vs-command / chat independence / stale-state honesty after the 4.0
merge; astra stays a design lab. Audit, harvest list, staging:
`docs/redesign-astra-audit.md`. Docs-only change.

## 2026-09-10 — One-time tall-style reformat (404 files) + verification workflow change

Root cause writeup (user asked why `dart format` churns): the pubspec SDK
floor crossed Dart 3.7 in `c0cb8c12` (2026-07-27), silently flipping the
formatter to the tall style while the tree stayed short-style — every
format run since restyled whole files (403/612 drift measured). User
ratified the one-time migration:

- `dart format lib test integration_test` as one mechanical commit: 404
  files, ~19.5k insertions / 15.5k deletions, pure formatting, zero
  behavior change. Gates after: analyze byte-identical to the pre-format
  baseline (472 issues, all pre-existing — the 17 errors are confined to
  `tool/youtube_spike`'s unfetched generated protos, the rest are infos),
  full `flutter test` 762 green.
- **The "never run `dart format`" gotcha is retired** — the tree now
  matches the SDK formatter's output; formatting changed files is
  expected going forward. (`tool/*` standalone packages were left alone.)
- **Workflow change (user directive):** the agent no longer runs
  simulator visual verification — best-effort code + analyze/test gates,
  the user sims the branch themselves.
- Temp-artifact cleanup: all `/tmp/obs_*` screenshot dirs/logs from the
  visual-QA and drift-fix rounds (~22 MB) deleted.

## 2026-09-09 — 4.0 drift-fix round 2: paywall blur/hero + hardened native-chat gate

Second user review pass on `4.0-liquid-glass`, three directives:

- **Paywall bar blur:** the back-only bar read as solid because the
  paywall's `customBody` was padded below the bar — the blur had nothing
  to filter. New opt-in `extendBodyBehindBar` on
  `TransculentCupertinoNavBarWrapper` (default off; qr_scan /
  license_modal / order keep their padding): the body extends behind the
  bar and `ProSalesView`/`ProUnlockedView` own the top inset, so
  scrolling content passes under the blurred bar like the sliver-based
  views.
- **Paywall hero:** bigger bolt-squircle (72→96) on the scene-tile color
  idiom (§2.2: full-strength accent ring + 12% accent tint fill + accent
  glyph, replacing the solid accent tile), plus an 'OBS Blade Pro' brand
  line underneath — the name was stated nowhere after the bar went
  back-only. Value line stays the pitch headline.
- **Native chat gate hardened + switch unblocked:** the chat-bar engine
  switch no longer intercepts — tapping Native always switches, and
  without Pro the pane renders the locked upsell (padlock tile, "Native
  chat is locked — unlock it with OBS Blade Pro.", benefits taste,
  Explore Pro). The real enforcement moved into the stores:
  `TwitchChatStore.connectChat()` / `YouTubeChatStore.connectChat()` +
  `YouTubeChatStore.selectChannel()` (which started its poll loop
  directly) refuse without the entitlement, via an injectable
  `isProResolver` seam (same pattern as the existing store resolvers) —
  previously a persisted native engine + stored login connected EventSub
  / started polling at cold start behind the locked pane. Username-bar
  native cluster still hides without Pro.
- Tests: engine-switch intercept test rewritten (switch always applies);
  new store-gate tests (EventSub never connects / poll loop never starts
  without Pro); 7 widget-test store constructions got
  `isProResolver: () => true` (their login flows hit the gate through
  `startLogin → connectChat`); two paywall tests center-align their
  `ensureVisible` targets (top-aligned now lands under the translucent
  bar, which eats the tap).
- Gotcha: `dart format` on this repo's files produces massive unrelated
  churn — the checked-in style is NOT the current SDK formatter's
  output. Don't run it; match surrounding style by hand. (Cost one
  revert-and-reapply cycle.)

## 2026-09-09 — 4.0 drift-fix batch: v12 color coding + interaction alignment

User ran the `4.0-liquid-glass` branch and found drift from the ratified
v12 mock: bluish card surfaces instead of the unified neutral gray ladder,
scale-press animation on settings rows (mock = highlight flash), paywall
redundancies (logo next to an app-bar title naming the app). User triaged
ALL findings with three decisions: **(1)** default-theme surfaces = neutral
white-alpha-over-scaffold composite (custom themes keep their card-slot
identity), **(2)** paywall = back-only bar + accent bolt-squircle logo,
**(3)** newly created custom themes also start from the neutral base.
Five commits on `4.0-liquid-glass`, gates green at each step:

- `bddb192a` **surfaces:** scaffold resolved once in `lib/app.dart`;
  `liquidCard` = alphaBlend(white/black 5%, cardColor ?? scaffold) feeding
  cardColor/canvas/dialogs/snackbar/chips/surface; bars on new
  `StylingHelper.liquid_bar_color` #1B1B1F (+ `scaffold_color` #212123);
  `BaseCard` fill = theme.cardColor directly (no double composite);
  `CustomTheme.basic()` defaults → neutral.
- `3a82827c` **press flash:** new `lib/shared/design/press_flash.dart`
  (highlight tint flash, no scale) on settings `BlockEntry` + stats
  `StatsEntry`, replacing Pressable scale; stats Stream/Recording chips now
  16% tint + highlightText/recordingText (were solid `Colors.blue[800]`/red).
- `56e7ce33` **sliders:** sliderTheme in app.dart — hairline track (white
  10%), highlight-55% fill, neutral knobs (#E8E8EC dark / #1C1C1E light),
  transparent border; `audio_slider.dart` dropped its solid-highlight
  override; muted icon textTertiary (was recording-red).
- `994571fd` **Close pill:** highlightText @15% tint + highlightText label
  in `status_app_bar.dart` (was accent-tinted).
- `095e3b6c` **paywall:** dropped the 'OBS Blade Pro' nav-bar title
  (assert in `transculent_cupertino_navbar_wrapper.dart` relaxed to allow
  null middle); hero = 72px accent squircle (`AppRadius.xl`) with
  `CupertinoIcons.bolt_fill`, on-accent ink via estimateBrightness;
  long-press debug Pro override preserved.

Full gate: 760 tests green (`test/chat/ websocket/ persistence/ pro/
shared/ utils/`); `flutter analyze` at baseline. Visual verification shots
(default theme, local OBS + sim) confirmed: neutral cards, red CTA/tab ink,
blue-tinted Close pill, tinted stats chips, white slider knobs, back-only
paywall bar with red bolt squircle. Temp verification test deleted after
the walk. Charts deliberately untouched (token-delta §6.5 open decision).
Doc-debt note: mock/contract docs still describe the paywall wordmark logo
— if the accent bolt stays, `state-and-plan.md`/`token-delta.md` need a
v13 note; §2.5 wording also contradicts the ratified "neutral over
scaffold" resolution and should be amended.

## 2026-09-09 — 4.0: branch `4.0-liquid-glass` — token layer + full view migration

Overnight autonomous wave (user directive: implement in the live app on a
branch, no design-lab shadow clone). 31 commits on `4.0-liquid-glass`,
pushed; the MacBook clone is checked out on it for morning dogfooding.
Contract: `docs/redesign/2026-iteration/token-delta.md`.

- **Token layer (additive, zero visual diff):** `AppTextColors`
  ThemeExtension (textPrimary/Secondary/Tertiary/Ornament + accentText/
  highlightText derived by calibrated lerp — the ratified hexes are pinned
  in `standard`; a single mechanical lerp can't reproduce them, measured
  across sRGB/linear/HSL/OKLCH), `AppStatusColors` extended (program,
  recordingText, favorite, programTagFill), `AppGlass` (barColor/sigma/
  saturate/specularOpacity, `forBar` factory), `AppMotion.ambient` (3s) +
  `AppMotion.reduce(context)` reduced-motion seam (MediaQuery
  disableAnimations, no persisted key), `Pressable(scale:, springy:)`
  (rule-1.6 opt-out; reduced-motion = opacity flash only),
  `StaggeredEntrance(scaleFrom:)` + reduced-motion final-value rendering.
- **Color-group wiring (rule 8):** both `ColorScheme.fromSwatch` sites in
  `app.dart` replaced with explicit schemes — the Material-default-blue
  (#2196F3) leak is gone; highlight = `colorScheme.primary`+`.secondary`
  (all ~45 readers audited, all highlight-semantics), accent =
  `buttonTheme.colorScheme.secondary`. Switches/checkboxes/radios/sliders
  unified on highlight on BOTH platforms (were red-iOS/blue-Android);
  themed slider thumbs no longer transparent; mute/visibility/hide toggles
  read the highlight group; dropdown underline resolves the divider slot.
- **GlassBar** (`lib/shared/design/glass_bar.dart`): single glass surface
  for all floating bars — blur + bar slot @75% + 1px specular edge line;
  fallbacks: non-Apple 0.9-alpha solid, True Dark specular+alpha. Applied
  to the forked TransculentSliverAppBar (paint layer only) and the main
  CupertinoTabBar (specular replaces the custom hairline; inactiveColor
  explicit textTertiary). Status navbar content height 55pt. NOTE: the
  saturate garnish and reduced-transparency fallback are not expressible in
  Flutter 3.44 (no ImageFilter color pass, no MediaQuery flag) — documented
  in code.
- **Per-view migration:** Connect (neutral connect-method segment —
  CupertinoSlidingSegmentedControl exposes no thumb decoration API, so
  track/thumb/label colors only; ghost CTAs demoted, one accent moment;
  online pill neutral per rule 7), Scenes/connected (program tally ring +
  programTagFill PGM tag, inner tab ink accentText, LIVE/REC pills neutral
  "unknown" state while reconnecting via the existing store observable,
  semantic audio-meter gradient with hot zone, exposed-control buttons
  demoted to ghosts, studio-transition button on AppMotion), Settings
  (section headers type-only, decorative icon tiles neutral via new
  `DecorativeIconTile`, text levels), Statistics (CardHeader
  underline/watermark retired, favorite token, calm sort/filter chips,
  chart colors untouched per open decision §6.5), Paywall (hero
  double-naming fixed — bolt tile swapped for the real base_logo.png at
  72px, "OBS Blade Pro" headline dropped, value line is the headline;
  yearly card 5% accent tint only, BEST VALUE badge 8% pill + accentText,
  ONE-TIME neutral; benefits tiles neutralized).
- **Known gaps / follow-ups for Gate 3** — each with what/why/what's-needed
  in `docs/redesign/2026-iteration/state-and-plan.md` → "Known unbuilt
  items": §5 full reconnecting contract (blocking scrim + inert command
  handlers; the neutral unknown pill state IS built), auth-failed error-card
  toast with Edit-password action (unbuilt functionality), paywall
  equivalence line ("$4.17/mo" — gateway exposes only display priceString),
  reconnect_toast still off-token (500ms/easeOut + red/green borders;
  resolves with the §5 work), chat-bar frame (§6.3 open), data-viz colors
  (§6.5 open), tablet composition (§6.1 open — branch requirement was
  no-regressions, verified), GlassBar saturate/reduced-transparency
  inexpressible in Flutter 3.44 (framework ceiling, documented in code).
- Gate: analyze 465 issues = baseline exactly (zero new);
  test/chat+websocket+persistence+pro green. Visual verification:
  visual-QA screenshot walk on iPhone + iPad sims against local OBS —
  both walks "All tests passed" + STATE-CHECK OK; 19 key shots reviewed
  (incl. the Pro paywall, captured on the iPad sim where Pro isn't
  unlocked). The iPad walk surfaced the known `text_field_date.dart`
  LateInitializationError (pre-existing, tablet-width rebuild) — fixed on
  the branch (ff82ed1e, now a proper StatefulWidget; also stops the
  per-build controller leak). Phone QA sim carries a custom purple theme
  (correct group recoloring), iPad QA sim shows the default theme
  (highlight blue / accent red).

## 2026-09-09 — 4.0: color-group directive + branch replaces design lab

- **Color groups ratified (user directive):** every colored element must
  resolve to a named group token, identically on iOS/Android — no
  framework-default leaks — and the group set is the future per-group
  CustomTheme surface. Added as token-delta §1 rule 8, incl. three known
  drift items found during the color-logic audit of the shipping app:
  mute/visibility icons ride Material default blue via
  `ColorScheme.fromSwatch` (no `primarySwatch`), switches split
  red(iOS)/blue(Android), `sliderColor = Colors.transparent` under custom
  themes (`app.dart`).
- **Implementation route changed (user decision):** the throwaway
  `tool/design_lab/` step is dropped — implementing happens in the live app
  on branch `4.0-liquid-glass` (tokens additive-first, per-screen commits,
  screenshot-verified vs the Phase-1 baseline, unmerged until Gate 3; full
  rollback = abandon branch). Updated: workflow spec Phase 3 + risks,
  token-delta §2.4/§4/§8, state-and-plan (next chain, ratified list),
  handoff. Rationale: a shadow clone would drift from the real app; the
  branch is maximally real with rollback intact.

## 2026-09-09 — 4.0 UI iteration: v11–v12 user-directed mock polish

- Context: previous MacBook session (herdr pane, kimi) ran the Gate-2/2b
  rounds (→ v10 mock, token delta v3) and was rate-limited mid-batch; this
  entry closes that batch. All commits from that session were docs-only and
  are now pushed.
- **v11** (built by the session's background builder, verified here): card
  tint reverted to v7 neutral white-5% (user-ratified; cool-tint experiment
  dead) + auth-failed toast left accent bar removed. Recorded in
  `state-and-plan.md`, token-delta §2.5/§5.
- **v12** (this session, served-verified + screenshotted via agent-browser):
  connect-method segment de-accented (v9 thumb underline read as template
  chrome → neutral thumb + white label, token-delta §1 rule 2 amended) and
  paywall hero double naming fixed ("OBS Blade Pro" h2 dropped — logo carries
  the wordmark, value line is now the headline, token-delta §5).
- Current mock is `all-views-v12.html` (local, gitignored — per the artifact
  map in `docs/redesign/2026-iteration/state-and-plan.md`). Next threads
  unchanged: tablet connected-view frame → Flutter design lab → Gate 3.
- Hygiene: `android/app/src/main/assets/adi-registration.properties`
  (AGP-generated, contains a registration id) is now gitignored, not
  committed.

## 2026-09-08 — Provisioning env vars renamed with `OBS_BLADE_` prefix

- All six store-provisioning env vars renamed (`ASC_KEY_PATH`,
  `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_APP_ID`,
  `GOOGLE_APPLICATION_CREDENTIALS`, `GCP_PROJECT_ID` → prefixed with
  `OBS_BLADE_`). Reason: the maintainer's corporate Claude setup consumes
  the standard `GOOGLE_APPLICATION_CREDENTIALS` via ADC, so the OBS Blade
  Play service-account export had to move off the standard var name to
  keep the two Google identities fully separate. Updated: maintainer
  `~/.localrc` export block, `tool/provisioning/` (`commands.dart`,
  `bin/probe_*.dart`, `bin/inspect_products.dart`), `README.md`,
  `CREDENTIALS.md`. Safe because creds are loaded by path and passed to
  `clientViaServiceAccount` explicitly — nothing relies on ADC
  auto-discovery. Tool suite 49/49 + analyze green; live
  `inspect_products.dart` run against both stores verified the renamed
  vars resolve.
- Related (no repo change): gcloud multi-account separation uses a named
  configuration `obsblade` (personal account, project `obs-blade`) next to
  the corporate `default` — `gcp-youtube` shells out to the gcloud binary,
  so it inherits whichever config is active; use
  `CLOUDSDK_ACTIVE_CONFIG_NAME=obsblade` per invocation.

## 2026-09-08 — 4.0 UI iteration: workflow spec + Phase 1 audit

- **Workflow spec** (`docs/superpowers/specs/2026-09-08-ui-iteration-4.0-design.md`):
  system-wide token evolution, Liquid Glass direction, browser mockups for
  breadth → Flutter design lab for finalists → redesign spec. No `lib/`
  edits until the Phase 4 spec.
- **Phase 1 audit complete** (SDD, 6 tasks, docs-only): phone (38) +
  tablet (36) screenshot sets in `docs/redesign/2026-iteration/`
  (gitignored — LAN IPs visible); advisor passes
  (`animation-opportunities.md`, `motion-audit.md` — 3 HIGH: `easeIn`
  FullOverlay entrance, off-token StudioModeTransitionButton,
  ScrollRefreshIcon build side-effects); token sweep (211 hardcoded
  colors — 62 in stream_chat, 41 durations [upper bound], 16 curves,
  87 radii); digest `docs/redesign/2026-iteration-audit.md` (11 quick
  wins / 6 systemic / 8 feel gaps / 6 tablet). Settled contract recorded:
  never animate native chat message insertion.
- Capture-surfaced pre-existing bugs (documented, not fixed — read-only
  wave; block clean "after" captures): `text_field_date.dart:29`
  LateInitializationError + duplicate GlobalKey; Tip Jar hit-test miss.
- Tooling note: `capture_screenshots.sh` needs `DEVICE_ID=<udid>` (the
  `booted` alias fails in `flutter test -d`); iPad QA sim created with
  devicetype `iPad-Pro-11-inch-M4-16GB`.

## 2026-09-08 — RevenueCat keys live

- **RevenueCat path now the default:** maintainer completed the RC
  dashboard (products `pro_yearly`/`pro_monthly`/`pro_lifetime`,
  entitlement `pro`, default offering); public SDK keys pasted into
  `lib/utils/revenuecat_config.dart` → `revenueCatConfigured` true on
  iOS/Android/macOS, app runs `RevenueCatProGateway` instead of the
  legacy direct-IAP fallback (empty keys remain the foss strip state).
- Backend-selection fixture reworked
  (`test/pro/revenuecat_pro_gateway_test.dart`): pins the real-keys
  default per platform via `debugDefaultTargetPlatformOverride` (RC on
  iOS/Android/macOS, legacy on key-less platforms) instead of the old
  empty-keys pinning test. `test/pro/` 63/63 green.
- Remaining RC follow-ups (dashboard/maintainer): Play RTDN test
  notification retry, sandbox dogfood per `revenuecat-setup.md` §5,
  Apple Small Business Program enrollment.

## 2026-09-08 — Store pricing parity, ASC review submission prep, paywall fix

- **Pricing finalized, exact cross-store parity** (`tool/provisioning/`,
  commits 6180d21, 1f5cb5f, b034366, 6560701; tool suite 34 → 49 tests):
  - ASC: equalized-tier fallback for territories without a nominal price
    point (same Apple tier as the USA point) — both subscriptions priced
    175/175 territories, idempotent.
  - Play API root cause: the old `monetization/*` routes return bare
    HTML 404 (silently dead) — current routes are
    `.../subscriptions` / `.../oneTimeProducts`. Fixed + lifetime listing
    drift (em-dash) reconciled live.
  - Play per-region pricing for all 173 regions, pinned via the table's
    `regionVersion` (2025/03 — older versions rejected for
    currency-changed regions like BG).
  - `play-products --price-source apple` (new **default**) drives every
    Play region from the ASC products' equalized tier table per currency
    (`AscProvisioner.appleCurrencyPrices` — one representative territory
    scan per currency): 153/173 regions at Apple tier prices (¥660, ₹210,
    CHF 5.90, …), uncovered currencies keep Google's converted price.
    `--price-source google` keeps convertRegionPrices + EUR/GBP/USD
    nominal parity. Live-applied + idempotency-verified.
- **ASC IAP review screenshot spec (learned the hard way):** must match a
  marketing screenshot size *the uploaded app binary supports* and carry
  no alpha. 1206×2622 (6.3", iPhone 17 Pro sim) was rejected —
  1242×2688 (6.5") flattened RGB works. The paywall shot itself came from
  the simulator via the scheme-attached `ios/obs_blade_storekit.storekit`
  (real product names/prices without sandbox). Uploaded to all three
  products + submitted for review (maintainer, 2026-09-08).
- **Paywall bottom clearance** (31e9dfb): the sales scroll view now uses
  the `CustomSliverList` formula (2×kBottomNavigationBarHeight + half the
  bottom safe area) — the legal row was only reachable via overscroll
  under the translucent tab bar (`extendBody`).
- **Google developer verification:** package `com.kounex.obsBlade` is
  **Registered** (deadline 2026-09-30 moot). Key map verified against
  local files: A6:24:44 = upload key (`android-release.jks`, in review
  via justification), 25:F7:E8 = Google app-signing key, 82:04:2C =
  upgraded signing key for SDK 33+ installs. Cleanup parked until the key
  review resolves (adi token file + internal-track draft release).
- Em-dash archaeology: the original provisioning commit (6bbfd6b) created
  the ASC subscriptions with "Pro — Yearly"; renamed to hyphens in
  065881b which also added the localization reconcile — live names
  verified clean via `inspect_products.dart`.

## 2026-09-04 — Provisioning automation (GCP + store products)

- Tier M. `tool/provisioning/` (standalone package, creds-by-path,
  `--dry-run` everywhere, idempotent check-then-create):
  - `gcp-youtube` — gcloud shell-out: create/reuse project, enable
    YouTube Data API v3, create a restricted API key (GA
    `gcloud services api-keys`, chmod-600 `--out-file`). OAuth consent
    screen + TV client stay console-only (no Google API exists).
  - `asc-products` — ASC API with ES256 JWT from a `.p8`: subscription
    group "Pro", `pro_yearly`/`pro_monthly`, `pro_lifetime` IAP, en-US
    localizations, and **pricing is fully automatable** (pricePoints +
    subscriptionPrices / inAppPurchasePriceSchedules, US base territory).
  - `play-products` — androidpublisher v3 via service account:
    subscription `pro` + base plans `pro-yearly`/`pro-monthly` (RFC-1034 —
    no underscores on Play; RC mapping `pro:pro-yearly` documented in the
    README + CLI output), `pro_lifetime` one-time via
    `oneTimeProducts:batchUpdate allowMissing` (Play has no plain create),
    DRAFT→activate calls, `--package-name` auto-read from build.gradle.
- Review minors fixed: fake-client body collision made the price assert
  near-vacuous (now insertion-ordered, both price bodies asserted);
  Play resume PATCH narrowed to `updateMask=basePlans` (was clobbering
  console-edited listing text); deactivated purchase-option skip now logs
  a reactivate hint. Commits 6bbfd6b8, 024c8083. 24/24 tool tests green.
- **Gotcha (blind API tooling):** verify payload shapes against the
  vendors' machine-readable sources (Apple's OpenAPI spec zip, Play's
  discovery doc) — the HTML docs are JS-rendered/stale; both reviewers
  found the live schemas matched.
- Docs are now script-first: `docs/revenuecat-setup.md` (store products)
  and `docs/youtube-native-chat-audit.md` (GCP key) lead with the
  commands; the manual walkthroughs remain as verification checklists.

## 2026-09-04 — RevenueCat migration (Pro entitlement backend swap)

- Tier M (focused migration on the wave-old seam). One implementer + one
  end review (approve; 4 non-blocking minors noted in review).
- `purchases_flutter: ^10.11.0` added (lockfile diff: the plugin entry
  only). New `ProPurchaseBackend` seam (`lib/utils/pro_purchase_backend.dart`)
  with `RevenueCatProGateway` (`lib/utils/revenuecat_pro_gateway.dart`) +
  `InAppPurchaseProBackend` legacy adapter; platform-neutral `ProProduct`
  replaces `ProductDetails` across `ProStore.products` + the paywall
  (pure type rename there). Selection: explicit injection > RC when
  configured > legacy IAP.
- Config gate: `lib/utils/revenuecat_config.dart` — `kProEntitlementId =
  'pro'`, empty `kRevenueCatAppleApiKey`/`kRevenueCatGoogleApiKey`
  (platform-mapped; macOS → Apple key; other platforms → legacy).
  **Empty keys = today's behavior, byte-safe** (review-verified).
- RC path: `Purchases.configure` (idempotent, self-healing), CustomerInfo
  fetch + listener mirror entitlement state into `BoughtPro` **both
  directions** — inactive overwrites stale-true, fixing the
  direct-IAP lapsed-subscription blind spot without a server.
  Buy mirrors immediately; restore returns entitlement-active and shows
  the dialog directly; purchase-cancelled → false, no error toast.
  `purchase_base.dart`'s pro branch is guarded off when RC is configured
  (tips/blacksmith stay on direct IAP).
- Wiring checklist for the maintainer (dashboard + keys, no app code):
  **`docs/revenuecat-setup.md`** — incl. the legacy `pro_lifetime`
  migration edge (attach it to the `pro` entitlement or pre-RC lifetime
  buyers strand) and the revisit-commented empty-keys selection test
  (`test/pro/revenuecat_pro_gateway_test.dart`).
- Commit 278c54e1. Gate: see wrap-up entry above (same run).

## 2026-09-04 — Pro subscription gate for native chat (full wave)

- Tier L (IAP/entitlement/persistence + new paywall surface + chat-surface
  gating). SDD per checklist: plan
  `docs/superpowers/specs/2026-09-04-pro-subscription-gate-plan.md`,
  verifier pass (3 amendment clusters — biggest: `queryPastPurchases` was
  REMOVED in in_app_purchase 3.3.0; cold-start restore goes through
  `restorePurchases()` + the purchase stream, silent vs explicit split),
  per-task reviews (caught: cold-start guard flag was burned before the
  restore succeeded — a transient error would have spent the
  once-per-install reinstall recovery).
- Strategy binding (`docs/private/monetization-strategy.md`): WebView chat
  + all OBS control stay free forever; sub paired with lifetime buy-out;
  entry points are user-initiated taps only; foss branch strips additively.
- Entitlement core: `lib/utils/pro_ids.dart` (`pro_yearly`/`pro_monthly`/
  `pro_lifetime` — final ids, products not yet created store-side),
  `ProPurchaseService` + injectable `ProPurchaseGateway` seam,
  `ProStore` (MobX; `isPro` = `BoughtPro` box flag ‖ kDebugMode debug
  override; lazy `loadProducts`; guarded once-per-install cold-start
  restore, flag set only after success), `PurchaseBase` pro branch
  (explicit-restore dialog vs silent cold-start via armed-in-flight flag,
  disarmed in `finally`; empty-`productDetails` guard so a purchase with a
  missing product record still unlocks), `_deleteAll` preserves `BoughtPro`
  alongside `BoughtBlacksmith`. Commits cb84febe, 6bb67f9.
- Paywall (`lib/views/pro/`, full-screen route `Pro` on Home + Settings tab
  navigators): hero, benefit cards (carousel + worm on phone, 2×2 grid on
  tablet), yearly-hero/monthly/lifetime pricing from live `ProductDetails`
  with an intentional placeholder state ("Price shown at purchase", buy →
  friendly not-live-yet toast — the shipping state until store products
  exist), explicit restore, terms/privacy links, confetti on the
  not-Pro→Pro edge only, already-Pro thank-you/manage state, hidden debug
  override (long-press hero logo, kDebugMode). Commit 454388c2.
- Gating: `Observer` over `ProStore.isPro` at all three gate sites (no
  rebuildKeys — entitlement read combines flag + debug override); engine
  switch lock badge (`JamIcons.padlock`) + tap intercept (box put skipped);
  single entitlement guard atop `stream_chat.dart`'s native dispatch
  (extracted `_buildNativeChatSlot`, dispatch verbatim — review-verified);
  username-bar native cluster hidden when not Pro (legacy persisted
  `SelectedChatEngine=native` users get the upsell pane, no dead-end login
  pills); settings "OBS Blade Pro" row (Active/Inactive). Whole-`test/chat/`
  impact pass: native-mode tests seed `BoughtPro` in the real box with a
  fake-gateway ProStore. Commit 20e79e9b.
- **Gotcha (in_app_purchase 3.x):** no `queryPastPurchases` — reinstall
  recovery = guarded `restorePurchases()`; restored events also arrive
  spontaneously on iOS, so dialog-vs-silent must key on an armed flag, not
  the event.
- **Gotcha (release-mode-only gating untestable):** `kDebugMode`-gated
  behavior (debug override gesture, `setDebugOverride` no-op) can't be
  tested for release in unit tests — pin the store-level guard and accept
  the UI path as debug-verified.
- Known limitation (planned, not a bug): lapsed subscriptions are not
  detectable client-side; receipt validation belongs to the RevenueCat/
  backend wave.
- Gate: `test/chat/ test/websocket/ test/persistence/ test/pro/` 698 green
  in one run (two load-flake files, different again — each passes in
  isolation), analyze 0 errors / 8 pre-existing warnings / infos ~baseline.
- Store-side TODO (maintainer, no app change needed): create the three
  products with the exact ids; then sandbox purchase/restore dogfood.

## 2026-09-03 — Native YouTube chat engine (full wave)

- Tier L (multi-subsystem: types/services/store/UI/persistence). SDD per
  `docs/superpowers/plan-defect-checklist.md` §1–§4: plan
  `docs/superpowers/specs/2026-09-03-youtube-native-chat-plan.md`, one
  verifier pass (6 amendments landed pre-dispatch), per-task reviews
  (caught 1 Critical: Google device-flow token poll needs `device_code`,
  not Twitch's `code` — fixture had mirrored the bug).
- Feasibility first: `docs/youtube-native-chat-audit.md` (commit ad264dc4)
  — quota is per-GCP-project (~3.6k units/user-hour polling vs 10k/day
  default) so reads are BYO-API-key; gRPC `streamList` quota cost is
  undocumented → spike before any default-on rollout.
- Spike tool `tool/youtube_spike/` (standalone package; setup.sh extracts
  `stream_list.proto` from the guide page — Google serves no raw proto —
  and patches its missing duration.proto import): poll vs gRPC modes,
  EOF/lifetime accounting, GCP-console quota measurement protocol.
  Commits 3bd115c2, be884526. Not yet run against a live chat (no key).
- Core layer: `YouTubeChatMessage` freezed DTO (13 `snippet.type`s +
  `unknown` fallback), `YouTubeAuthService` (Google device flow, scope
  `auth/youtube`, BYO client id+secret via settings with empty app-level
  constants), `YouTubeLiveChatService` (list/insert/delete/bans/
  `getActiveLiveChatId`; quota vs rate-limit vs forbidden exception split),
  `YouTubeAuth` Hive model (typeId 15, box `youtube-auth`), settings keys
  `YouTubeApiKey`/`YouTubeOAuthClientId`/`YouTubeOAuthClientSecret`/
  `SelectedYouTubeNativeChannelId`, data-management clear covers them.
  Commits d3702797, c60fe6e8.
- `YouTubeChatStore` mirrors `TwitchChatStore`: per-video buffers keyed by
  label with liveChatId/pageToken resume on switch-back, poll loop honoring
  `pollingIntervalMillis` net of call duration, rate-limit backoff (×2 to
  60s), quota stop, tombstone/ban reconcile + echo dedup, sign-in-gated
  send, optimistic mod actions. Commits aca65a58, 81542250.
- UI: `nativeChatAvailableFor` += YouTube; `stream_chat.dart` native branch
  dispatches per platform (Twitch path byte-identical — verified in
  review); YouTube timeline/row (icon badges — API has no artwork —,
  Super Chat tier cards, sticker alt-text, poll/gift/milestone notices,
  tombstones), device-code dialog, account control, options sheet, forked
  channel dropdown, mod action sheet (delete/timeout presets/ban), setup
  sheet (key probe, advanced BYO OAuth client, per-video staleness copy).
  Beta warning suppressed when engine == Native. Commits 2d14b647,
  022489b0.
- **Gotcha (root codegen + tool packages):** `build.yaml` now excludes
  `tool/**` — the spike's gitignored pb files on disk broke the app's
  build_runner (`$pb.GrpcServiceName` unresolvable). Any future standalone
  tool with generated code hits this without the exclusion.
- **Gotcha (fixture mirrors bug):** review caught the auth test asserting
  the same wrong param name as production — fake-client tests only prove
  the client sends what the test expects; cross-check request shapes
  against vendor docs, not just self-consistency.
- Gate: `test/chat/ test/websocket/ test/persistence/` 649 green in one
  run (load-flake files move run-to-run — `flutter_tester` WebSocket
  connect — each passes in isolation), analyze 0 errors / 8 pre-existing
  warnings / infos ~baseline (+1 from the spike's local pb files).
- Not dogfooded: needs a real GCP API key + OAuth client. Spike run +
  dogfood are the next threads (see handoff).

## 2026-08-13 — Native chat: roadmap wave 3 (mod tooling bundle)

- Tier S, in-session. Roadmap: `docs/chat-native-roadmap.md` wave 3 — one
  deliberate scope upgrade (`kTwitchManageModToolingScopes` =
  `moderator:manage:warnings`/`unban_requests`/`automod`) folded into
  `kTwitchChatScopes`; pre-upgrade tokens keep working, gated rows start the
  re-login flow (`_requireScopeOr` idiom, same as wave 2's modes).
- Helix surface (`TwitchModerationService`): `warnUser` (POST
  /moderation/warnings), `resolveUnbanRequest` (PUT /moderation/unban_requests
  — an approval also lifts the ban), `getWarnings` (paginated GET, read scope
  already held), `handleAutoModMessage` (POST /moderation/automod/message,
  204, body `user_id` = the *moderator*). New `TwitchWarning` DTO. Commit
  7aba0e3c.
- EventSub `automod.message.hold/.update` **v2** (v1 is legacy with a
  different `message` shape — the sub pins version 2): freezed DTOs, service
  callbacks, channel-scoped pair (`moderator_user_id: self`, re-created per
  `switchChannel`). Commit 1fa79ab5.
- Store: `canWarnUsers`/`canManageUnbanRequests`/`canManageAutoMod` (plain
  live-box reads, same pattern as `canModerateChats`), never-throw
  `warnUser`/`resolveUnbanRequest` (optimistic removal; approval drops the
  ban)/`resolveAutoModMessage` (optimistic; the update echo lands as a no-op),
  `fetchUserWarnings` (plain async, null → card hides the section),
  `ObservableList<AutoModMessageHoldEvent> autoModQueue` with deduped hold /
  idempotent remove, cleared on channel switch + lifecycle resets.
  `connectChat` passes `includeAutoMod: canManageAutoMod` — scope-only gate,
  mirroring `includeModeration` (a connect-time role check would go stale
  across switches; a 403 on a non-modded channel is the degrade path).
  Commit 38ed2a77.
- UI: "Warn…" row in the mod action sheet (compose step, send IS the
  confirm, 500-char cap); Approve/Deny pills on unban-request rows
  (pre-upgrade tokens keep plain Unban); `AutoModQueueSheet` (pure Observer
  over the store queue — no Helix list endpoint exists, holds arrive via
  EventSub only) behind an "AutoMod queue (N)…" row in the channel mod
  sheet; warnings section (up to 3) on the chat user card, mod view +
  non-self only. Commit 046441db.
- **Gotcha (typedef widening touchpoints):** adding EventSub callbacks means
  widening the store's `eventSubFactory` typedef *and every lambda at every
  construction site* (tests use `(_, __, …, __________) => …`) — grep for
  the factory param when the count changes, sed is your friend. The widened
  lambdas trip `unnecessary_underscores` infos; accepted (matches the other
  chat test files).
- **Gotcha (fake counters record failed attempts):** the fakes increment
  `warnCalls`/`autoModCalls`/… *before* throwing — failure tests assert
  `calls == 1` plus the kept row, not `calls == 0`.
- **Gotcha (device-code dialog never settles):** the re-login dialog keeps a
  poll/timer alive — `pumpAndSettle` after tapping a gated row times out;
  use bounded pumps (same idiom as the spinner sheets).
- Gate: `test/chat/ test/websocket/ test/persistence/` 571 green, analyze
  0 errors / infos ~baseline.


- GIF debug sample rendered as a white square with a gray spinner — the
  rendering was fine; the chosen giphy id *is* an iOS-style spinner on
  white. Swapped to the computer-kid gif (visually confirmed animating).
  Commit 5dc1f778. Lesson: eyeball sample media, not just its 200/CTYPE.
- Pin banner rework (dogfood: "looks disabled"): collapsed = muted single
  line; tap anywhere toggles expanded (full text, accent name,
  normal-contrast body, chevron affordance; resets when the pinned
  message changes). Commit 5f963b0e.
- Pin + unpin now confirm everywhere (banner ✕ and mod sheet, both
  directions) — room-visible actions. Same commit.
- Test gotcha (worth remembering): `Text.rich(span)` wraps `span` in a
  root span carrying the merged default text style, so the RichText's
  `text.children` are `[span]` — span-level assertions in widget tests
  must walk one level deeper.
- Gate: `test/chat/` 493 tests green (1m31s), analyze no new issues.

## 2026-08-13 — Dogfood fixes for waves 1+2

- Tier S, in-session, from maintainer dogfood remarks on the physical
  device.
- **Pins appeared unresponsive (root cause: stale codegen).** The store's
  `twitch_chat.g.dart` was last generated 2026-08-10 — before wave 2 — so
  `pinnedMessage`/`banInboxLoading`/`banInboxError` had no atoms and the
  pin/ban methods no actions: the banner only changed when an unrelated
  timeline event rebuilt the view, and a second ✕ tap hit the
  `pinned == null` guard → spurious failure toast. `build_runner` regen
  (diff purely additive) + widget regression test (unpin clears the
  banner with no other store event). Commit e27a56ce.
- **New test gotcha (worth remembering):** mobx's `AsyncAction` caches a
  zone forked from *first use* — a public action awaiting another public
  action breaks under `testWidgets` when the inner action first ran in
  `setUp` (real zone): the awaited work parks outside the fake-async
  zone and `pumpAndSettle` never flushes it. Fix pattern: public async
  actions delegate to a private non-action body (`_fetchPinnedMessage`),
  callers inside other actions call the private body. Same commit.
- Gray-on-gray failure toast: the snackbar theme set a near-card
  background but no `contentTextStyle` — fixed globally in `app.dart`.
  Commit b5190715.
- GIF debug sample rendered as text: its giphy id 404s and the row's
  `errorBuilder` silently falls back to the fragment text. Swapped
  sample + fixture + tests to a verified-live id. Commit 21cddf76.
- Shared-chat source chips were all muted gray — now
  `sourceChannelColor` hashes the origin broadcaster id into a fixed
  8-color palette (stable per channel). Commit c321275a.
- Gate: `test/chat/` 491 tests green (1m32s), analyze no new issues.
  Pubspec.lock churn from a NAS-side `pub get` (matcher/meta downgrades)
  was reverted — don't commit it from this machine.

## 2026-08-13 — Native chat: roadmap wave 2 (pins + ban inbox)

- Tier S, in-session. Roadmap: `docs/chat-native-roadmap.md` wave 2 — all
  free with already-held scopes, no re-login flow.
- Pinned messages: `TwitchPinnedMessage` DTO + `getPinnedChatMessage`/
  `pinChatMessage`/`unpinChatMessage` on `TwitchModerationService` (live
  API is PUT on pin, not POST/PATCH as the roadmap draft said; 200 with
  empty `data` when nothing is pinned — no 404). No EventSub for pins →
  the store refetches on connect/switch and after local pin mutations.
  Slim banner above the native chat timeline (mods get ✕ unpin),
  Pin/Unpin rows in the mod action sheet (replacing an active pin
  confirms first). Pins are always "until stream ends" — no duration UI.
  Commit cf353b6f.
- Ban inbox: `TwitchBannedUser` (empty-string `expires_at` = perma-ban,
  not null) + `TwitchUnbanRequest` DTOs; `getBannedUsers` (own channel
  only — Helix 401s other channels even with a mod token), `unbanUser`,
  `getPendingUnbanRequests` (status param required; read-only — approve/
  deny is wave 3's manage scope). "Bans & requests…" sheet off the
  channel mod sheet; unban drops the user from both lists optimistically.
  Deferred: blocked terms / warnings / mods-VIPs read lists (no action
  attached; revisit with wave 3). Commit 9b45af49.
- Gate: `test/chat/` 489 tests green (1m31s), analyze no new issues.
- Test gotchas: a widget test that calls `selectChannel` must wrap it in
  `tester.runAsync` — it persists the selection to Hive, and real I/O
  never completes in the fake-async zone (parked the suite 10 min);
  sheets with a load spinner never let `pumpAndSettle` settle — bounded
  pumps + the mod-sheet `await refresh → setState` idiom (no Observer in
  sheets).

## 2026-08-13 — Native chat: roadmap wave 1 (correctness)

- Tier S, in-session. Roadmap: `docs/chat-native-roadmap.md` wave 1.
- GIF fragments (`type: "gif"`, live 2026-07-16): `ChatFragmentGif` DTO +
  inline image at 3x emote size, text fallback. Commit f0adf45b.
- Power-ups: `power_ups_gigantified_emote` renders the emote 3x;
  `power_ups_message_effect` stays a normal message (cosmetic animation
  not reproducible). Commit 53c3882c.
- Shared chat: `#channel` source chip on partner-origin messages.
  Cross-channel dedup checked and moot — `switchChannel` keeps only one
  channel's subs live. Commit aeb42ea4; review fix: message-specific
  compact chip (shared chip grew rows 28→30px), row-height regression
  test added (c2ed5c00).
- Dogfood tooling: `kDebugMode`-only "Debug samples" page in the native
  chat options sheet injects crafted GIF / gigantified / shared-chat
  events via `TwitchChatStore.debugInjectMessage` (no-op in release) —
  real shared sessions need two live channels, Twitch CLI payloads are
  fixed. Commit f875e1ea.
- Gate: `test/chat/` 438 tests green, analyze no new issues.
- Test gotcha (worth remembering): a chip's `Text` inflates to a second
  `RichText` — `find.byType(RichText)` in row tests must tolerate or
  filter multiple matches once chrome widgets render inside spans.

## 2026-08-12 — Native chat: API roadmap audit

- New doc `docs/chat-native-roadmap.md`: audited Helix/EventSub surface
  against the native chat. Findings ordered into waves: (1) correctness —
  GIF fragments (live since 2026-07-16, unhandled in `ChatMessageFragment`),
  power-ups message types, shared-chat source chips + multi-chat dedup;
  (2) free with held scopes — pinned messages CRUD, unban, `moderator:read:*`
  inbox surfaces; (3) mod tooling bundle — warn, unban requests, AutoMod v2
  queue (one scope upgrade); (4) post-entitlement streamer actions — points
  redemption feed (read-only; Helix mutation is client-ID-locked), polls/
  predictions, raid out, chatters list. Vapor list recorded (no shared-chat
  session API, Hype Chat/Moments dead, redemption mutation locked, etc.).
  No code changes.

## 2026-08-10 — Native chat: replies (send side)

- Spec: `docs/superpowers/specs/2026-08-10-chat-replies-design.md`. Tier S,
  in-session. Incoming side already existed (DTO + preview row); this ships
  the outgoing half.
- Start a reply: long-press a live message — mods get a Reply row atop
  `ModActionSheet`, non-mods with write scope get a new lightweight
  `MessageActionSheet`; read-only / tombstones stay inert. Choosing Reply
  sets `TwitchChatStore.replyTarget` and focuses the input dock.
- Composing: `NativeReplyStrip` docks above the input via a new generic
  `contextStrip` seam on `NativeChatInput` (✕ cancels; replacing a target
  just retargets).
- Send: Helix `reply_parent_message_id` threaded through
  `TwitchMessageService` ← store (`replyTarget?.messageId`). Target cleared
  on successful send and on `selectChannel`, kept on failure for retry.
- Test gotcha (worth remembering): a real Hive write (`auth.save()`) inside
  `testWidgets`' fake-async zone never completes and hangs the whole suite
  at shutdown — mutate the box's in-memory instance instead.

## 2026-08-09 — Native chat: dogfood polish (evening wrap)

- Mod overflow: combined gear|shield options chip + featured Mod card in
  Options when the bar shield doesn’t fit; omitted when not moderating /
  when shield is on the bar. Spec
  `docs/superpowers/specs/2026-08-09-mod-overflow-options-design.md`.
- Notice meta chips + announcement dual-rail chrome (typed EventSub
  blocks). Spec
  `docs/superpowers/specs/2026-08-09-chat-notice-meta-design.md`.
- Delivery: EventSub `session_reconnect` open-before-close; buffer
  mid-`selectChannel` arrivals by broadcaster.
- Moderation UX: timer/`Listener` long-press with local hold wash so
  username/link `Pressable`s survive; empty timeline includes notices;
  announce accent no longer bleeds onto the next PRIVMSG.
- Harness: shared `FakeSilentIrcSidecar`; chat view keyed by
  `effectiveBroadcasterIdSafe`. InputDialog always uses
  `CustomValidationTextEditingController`.
- Dogfood: user signed off for the day. Next: replies / entitlement gate.

## 2026-08-09 — Native chat: IRC first-msg sidecar

- Spec/plan: `docs/superpowers/specs/2026-08-09-irc-first-msg-sidecar-design.md`,
  `docs/superpowers/plans/2026-08-09-irc-first-msg-sidecar.md`.
- Read-only IRC WebSocket joins the selected channel for `first-msg=1`
  tags; merges onto EventSub rows by message id (`isFirstMessage`). Also
  treats `user_intro` as first-message. Best-effort — IRC failure never
  drops EventSub chat. UI chrome unchanged (magenta + FIRST MESSAGE).
- Gates: `flutter test test/chat/twitch_irc_sidecar_test.dart` green.

## 2026-08-09 — Native chat: user card (viewer profile sheet)

- Spec/plan: `docs/superpowers/specs/2026-08-09-chat-user-card-design.md`,
  `docs/superpowers/plans/2026-08-09-chat-user-card.md`. Tier M: one
  implementer subagent for Tasks 1–5 + end review / gate fixes in-session.
- Ships: tap username/badges → Twitch-like user card (avatar, Helix
  created/follow/self-sub when scoped, LIVE buffer messages); long-press →
  mod sheet; header “connected” opens merged self card + connection
  footer. New scopes: `user:read:subscriptions`, `moderator:read:followers`
  (silent upgrade; rows hide when missing).
- Gates: `flutter test test/chat/` → 347 green; analyze 0 errors on
  touched libs.

## 2026-08-09 — Native chat: appearance controls + nested options sheet

- Options sheet is now a drill-in root (Appearance / Emotes / Badges) with
  page-swap navigation. Appearance: text size, emote size, message spacing
  sliders + separators toggle, live preview row. Additive Settings keys;
  message list/row honor them via HiveBuilder. Spec:
  `docs/superpowers/specs/2026-08-09-native-chat-appearance-design.md`.

## 2026-08-09 — Native chat: multi-chat (channel picker, switch, mod actions)

- Spec/plan: `docs/superpowers/specs/2026-08-09-multi-chat-design.md`,
  `docs/superpowers/plans/2026-08-09-multi-chat.md` (11 tasks). Started
  tier M; implementer subagent died mid-Task-10 on secondary-model quota
  exhaustion → dropped to S in-session (tier policy). End-review was the
  same: self-review in-session rather than a secondary-model reviewer.
- Ships: persisted native channel list + selected id (own channel pinned,
  never stored); add-chat sheet (search / moderated / followed); chat-bar
  channel dropdown (shield markers, long-press remove → own fallback);
  connect-on-switch EventSub on the same websocket session with per-channel
  in-memory history; per-broadcaster badge/emote catalogs; Helix delete /
  timeout / ban via mod action sheet with local tombstone/purge + EventSub
  echo dedup; four new scopes on the silent upgrade path with per-capability
  degradation for pre-upgrade tokens.
- Gates: `flutter analyze` 0 errors (info-level `unnecessary_underscores`
  noise in tests only); `flutter test test/chat/ test/websocket/
  test/persistence/` → 331/331 green. MobX regen for Task 10 actions
  included in the mod-actions commit.
- Deliberate refinements beyond spec: adding a channel switches to it;
  removal is long-press on the dropdown row (spec §2).
- Open: real-Twitch dogfood (spec §6 checklist in the handoff). Next chat
  items after dogfood: replies/announce, then availability/entitlement
  gate.

## 2026-08-08 — Process: tiered SDD (S default) after quota postmortem

- The moderation-actor wave (below) burned a full 5h quota on ~300 LOC:
  5-task SDD with 12 subagent dispatches, ~300KB of process artifacts
  (plan/briefs/reports/reviews/diffs), and 4 full-suite gate runs.
  Postmortem ratified **process tiers** in
  `docs/superpowers/plan-defect-checklist.md` §0 + the AGENTS.md tooling
  section: **S (default)** = controller implements directly, no
  subagents/plan doc; **M** = 1 implementer + 1 end reviewer, prose
  mini-plan; **L** = full SDD as before, reserved for user-flagged risk
  (persistence/protocol/release) or genuine multi-day scope.
- Cross-tier cost rules: gates once at wrap-up (controller re-runs only
  if HEAD moved after the final reviewer), resume subagents for fix
  loops instead of fresh dispatches, terse reports (tail-count test
  output only), secondary model for all dispatches — and if its quota is
  exhausted, drop a tier rather than running the full pipeline on
  primary.

## 2026-08-08 — Native chat: deleting-mod reveal live (channel.moderate v2)

- The tap-to-reveal on deleted messages now works end to end: the EventSub
  session creates a best-effort `channel.moderate` v2 subscription
  (condition `moderator_user_id` = self) whose `delete` actions carry the
  acting moderator — the piece `channel.chat.message_delete` lacks.
- Login now requests the 8-scope `moderator:read:*` bundle Twitch demands
  (`kTwitchModerationScopes`); pre-upgrade tokens skip the subscription
  (`canReadModeration` gate) and keep plain tombstones until re-login.
- Store merge is order-tolerant with `message_delete` (either event may
  land first; the version bumps when the actor arrives). The moderate
  event also tombstones on its own — a failed `message_delete` POST no
  longer loses single deletes.
- New `ChannelModerateEvent` DTO is tolerant (only `delete` modeled,
  fixtures mirror the real twitch-rs v2 envelope). Tests: DTO 3, service
  3, store 5 + gate 2. Gates: full suite green, analyze 0 errors + 6
  pre-existing warnings.

## 2026-08-08 — Native chat: tombstone fix (real message_delete payload)

- **Bug (dogfood):** deleted messages never tombstoned — no dimming, no
  ` —Deleted` marker. Root cause: the `ChatMessageDeleteEvent` DTO required
  `userName` (deleting moderator), a field Twitch's real
  `channel.chat.message_delete` payload does not carry — the fixture had
  invented it (documented example carries only `broadcaster_user_*`,
  `target_user_*`, `message_id`). `fromJson` threw on every real delete,
  the service's parse catch swallowed it, tombstones never applied.
- Fix: `userName` is now nullable (kept forward-compatible — actor reveal
  wiring stays, dormant until Twitch sends the field); the fixture +
  service test now use the real payload shape; the store only records an
  actor when present. Failing-test-first: fixture swap reproduced the exact
  production `TypeError` before the fix.
- Consequence: tap-to-reveal the deleting mod cannot work off
  `channel.chat.message_delete` — needs `channel.moderate` (extra mod
  scopes) if ever wanted. Tombstones (dimmed content + marker) work for
  everyone as designed.

## 2026-08-07 — Native chat: deleted content + actor reveal (mod view)

- Deleted messages now match twitch.tv's moderator view: the original
  content stays (text at half the marker's opacity, emotes at matching
  opacity) with an italic ` —Deleted` marker — replacing Wave B's
  `<message deleted>` tombstone. Uniform across single deletes, timeout/ban
  purges, and `/clear` purges; username + badges untouched.
- Tapping a message deleted via `channel.chat.message_delete` expands an
  inline reveal `<actor> deleted <chatter>'s message`. The DTO gains
  `userName` (the deleting moderator; `targetUserName` deliberately
  unmodeled — the chatter's name comes from the message itself), the store
  keeps a `_deletedMessageActors` map (pruned at the 500-cap, wiped with
  lifecycle), and the window owns a session-bounded expansion set.
  Purge/`/clear` payloads carry no actor — those rows are not tappable.
- Tests: DTO 1 updated, store 1 new + 5 updated, row 1 rewritten + 3 new,
  window 2 new + 1 updated (test counts: chat suites all green; analyze 0
  errors + 6 pre-existing warnings). No scopes, no persistence.

## 2026-08-06 — Native chat: message lifecycle (deletions + pause)

- `TwitchEventSubService` subscribes to four types now — `channel.chat.message`
  (mandatory, unchanged semantics) plus `message_delete`,
  `clear_user_messages`, `clear` (best-effort: POST failures/revocations
  degrade tombstones, never chat; same `user:read:chat` scope, no auth
  change).
- `TwitchChatStore` lifecycle state: plain tombstone id-set + system
  notices merged by arrival sequence (`lifecycleVersion` rebuild counter,
  `catalogVersion` pattern); pruned with the 500-cap; wiped on logout.
- Deleted messages tombstone in place (`<message deleted>`, username +
  badges kept) — single delete, timeout/ban purge, and `/clear` (which also
  inserts a "Chat was cleared by a moderator" banner). `/clear` on an empty
  chat is a no-op.
- Pause chip: scrolled-up chat now shows an explicit "Paused ↓" chip; new
  messages flip it to the existing "New messages ↓" pill; tap resumes.
- Tests: DTO (6), store lifecycle (8), service (3 new + 3 updated), wiring
  (1), row (1), window (3). Gates: chat + websocket + persistence suites
  green, analyze 0 errors (6 pre-existing warnings, none new).

## 2026-08-06 — Native chat: emote picker (first-party + 7TV/BTTV)

- `TwitchEmoteService`: Helix Get User Emotes (first paginated endpoint in
  the app — `after`-cursor loop, hard cap 50 pages); freezed
  `TwitchUserEmote` keeps `emoteType`/`emoteSetId` raw.
- `TwitchEmoteStore` (GetIt, session-scoped, MobX): channel/global split
  by owner, alpha-sorted, generation guard, `catalogVersion` pop-in +
  `isLoading` spinner signal; cleared on logout.
- New `user:read:emotes` scope (silent upgrade — pre-upgrade tokens skip
  the fetch and see a re-login CTA in the sheet, same philosophy as the
  write-scope lock strip). `canReadEmotes` mirrors `canWriteChat`.
- Dock seams: `NativeChatInput` takes an optional external
  controller/focusNode (never disposed by the dock) + a `leading` slot —
  still Twitch-free.
- Picker sheet: search + Channel/Global/Third-party sections (56pt cells,
  2x images, errorBuilder → code text), tap inserts `code + space` at the
  cursor and refocuses the dock; third-party section follows the existing
  7TV/BTTV toggle.
- Tests: service (4), store (5), wiring (3), dock (4 new), picker sheet +
  button (9). Gates: chat + websocket + persistence suites green, analyze
  0 errors (6 pre-existing warnings, none new).

## 2026-08-06 — Native chat: third-party emotes (7TV/BTTV)

- `ThirdPartyEmoteService` (7TV v3 + BTTV v3 — public, no auth): global +
  channel catalogs; 404 → empty map (no provider presence), other
  non-200 → `ThirdPartyEmoteException`; malformed entries skipped.
- `ThirdPartyEmoteStore` (GetIt, session-scoped, MobX): one merged
  catalog, precedence channel > global / 7TV > BTTV on ties, generation
  guard against superseded fetches, `catalogVersion` as the pop-in
  rebuild signal; cleared on logout.
- `TwitchChatStore`: fire-and-forget fetch on connect, gated by the new
  default-on `twitch-chat-third-party-emotes` Settings key (off → no
  third-party contact at all); clear on logout.
- Rows tokenize text fragments (exact, case-sensitive, space-split) and
  swap known tokens for 20px inline images (`Image.network`, animated
  WebP/GIF; errorBuilder → text). Toggle in the native chat options
  sheet ("Twitch — emotes" section).
- Tests: service parsing (9), store (7), wiring (3), row (7), view
  pop-in/toggle (2), sheet (1 new + 1 updated). Gates: chat + websocket +
  persistence suites green, analyze 0 errors (6 pre-existing warnings,
  none new).

## 2026-08-05 — Native chat send input (dock, write scope, Helix send)

- Native chat now **writes**: a send dock sits at the bottom of
  `NativeChatWindow` through its new optional `input` slot (rendered below
  the content with a `BaseDivider` hairline); wired in `stream_chat.dart`'s
  native branch inside the Observer (`onSend: twitchStore.sendChatMessage`,
  `onRelogin: startTwitchLogin`).
- New generic `NativeChatInput` (`stream_chat/native_chat_input.dart`):
  pill `TextField` + circular send button, hard 500 `maxLength` with no
  counter chrome, spinner while in flight, field clears on success, failed
  sends keep the text. Deliberately Twitch-free (plain params — the same
  reuse seam as the window for a future native engine). `canSend == false`
  swaps the field for a read-only lock strip ("Logged in read-only" /
  "Re-login to chat"); send failures surface as a transient inline error
  line above the dock.
- **Silent scope upgrade:** `kTwitchChatScopes` is now
  `['user:read:chat', 'user:write:chat']`. Nobody is logged out — stored
  sessions keep working read-only; `TwitchChatStore.canWriteChat` (plain
  non-reactive getter over the persisted `TwitchAuth.scopes`) gates the
  dock, and pre-upgrade logins get the lock strip with the re-login path.
- New `TwitchMessageService` (injectable `http.Client`, POST
  `$kTwitchHelixBase/chat/messages`, adds its own `Content-Type:
  application/json`) returning freezed `TwitchSendResult {messageId,
  isSent, dropReason}`; the guarded `TwitchChatStore.sendChatMessage`
  action (`@observable sendingChat` / `sendChatError`, `messageService`
  constructor seam) never throws — guards: not logged in / no write scope
  / empty message / already in flight.
- **Post-review fixes** (final whole-branch review caught what the suite
  couldn't): `drop_reason` is a Twitch **object** `{code, message}`, not
  the string the spec's "verified facts" claimed (spec corrected) — new
  `TwitchDropReason` DTO; `_dropReasonText` maps on `code` (AutoMod
  blocked/held, duplicate, rate-limited; unknown codes surface Twitch's
  own `message`, else "Message not delivered ($code)"). And cancelling the
  re-login dialog **mid-upgrade** now restores `loggedIn` when the stored
  session + user are intact — previously the UI claimed logged-out while
  the EventSub session kept streaming invisibly.
- **No optimistic insert by design** — the sent message renders via the
  existing EventSub echo; 200-but-dropped sends surface as the inline dock
  error, never a silent no-op.
- Spec/plan under `docs/superpowers/` (`2026-08-05-chat-send-input*`),
  commits `fdd539c..3f0cc56` (incl. docs + post-review fixes). Gates:
  **168/168** tests (+3 service, +7 store, +8 dock, +1 window slot, +4
  fix-wave), analyze 0 errors + the 6 pre-existing warnings. **Maintainer
  dogfood deferred** (test later) — checklist kept in
  `session-handoff.md`.

## 2026-08-05 — Native chat window (pane, status row, connection sheet)

- New `NativeChatWindow` (`stream_chat/native_chat_window.dart`) wraps the
  native engine everywhere it renders (mobile tab slot, standalone card,
  tablet card, streaming mode): inset pane (plain `cardColor` + hairline —
  the `BaseCard` surface; dogfood found the lightened control idiom read
  brighter than normal cards on a large pane), slim status row ("Stream
  Chat" label + state: connected / connecting… / reconnecting… / failed /
  offline), always tappable.
- Tapping the row opens a connection sheet: healthy → account + live-
  ticking uptime (`_UptimeLine`, 1s `Timer.periodic` accumulating from a
  captured base — `DateTime.now()` recompute is untestable under
  flutter_test fake-async); degraded → last error + Retry + Log out (same
  `ConfirmationDialog` as the account chip); offline → Connect.
- Reusable by construction: the window takes plain params (`ChatType`
  branding, generic `NativeChatConnectionStatus`, strings, callbacks) — no
  Twitch store types. Twitch mapping (`twitchChatWindowStatus`) lives at
  the `stream_chat.dart` call site; logged out always maps to `offline`.
- `TwitchChatStore` gains `@observable DateTime? chatConnectedAt`
  (in-memory; stamped on transition into `live`, kept during
  `reconnecting`, cleared on disconnect/failed) feeding the uptime line.
- Spec/plan under `docs/superpowers/` (`2026-08-05-chat-container-ui*`).
  Dogfood passed 2026-08-05 after one fix round (pane color, "Stream Chat"
  label, ticking uptime). Gates: 145/145 tests, analyze 0 errors + 6
  pre-existing warnings.

## 2026-08-05 — Native Twitch chat: role badges + visibility toggles

- `ChatMessageEvent` now models the payload's `badges` array
  (`ChatMessageBadge`: setId/id/info).
- New `TwitchBadgeStore` (GetIt, session-scoped, in-memory) caches the Helix
  global + per-channel badge catalogs, fetched by the new
  `TwitchBadgeService` with the existing user token (no new scope);
  `TwitchChatStore.connectChat()` kicks the fetch off fire-and-forget,
  `logout()` clears it.
- `TwitchChatMessageRow` renders badge images before the username
  (render-time lookup, channel catalog > global), skipped silently when
  unknown.
- New "Native chat options" sheet (44pt button in the native bar) with
  per-platform sections — Twitch today: 7 badge visibility toggles
  (broadcaster, moderator, VIP, subscriber, founder, bits, other),
  default-on, persisted as plain Settings-box bool keys
  (`twitch-chat-badge-*`), live re-filtering.

## 2026-08-04 (chat engine switch)

- **Chat engine switch (control-section redesign)** — spec
  `docs/superpowers/specs/2026-08-04-chat-engine-switch-design.md`, plan
  `docs/superpowers/plans/2026-08-04-chat-engine-switch.md`.
  - Persisted `ChatEngine` enum (`webView`/`native`, Hive typeId 14) +
    `SettingsKeys.SelectedChatEngine`; default WebView, so existing installs
    are unchanged.
  - `nativeChatAvailableFor(ChatType)` seam in
    `lib/models/enums/chat_engine.dart` — the future
    availability/entitlement gate for native chat plugs in there.
  - Username bar restructured: platform dropdown owns the left column
    (username dropdown only in WebView mode); right column =
    `ChatEngineSwitch` (Twitch only) + mode actions (`UsernameActionRow` for
    WebView — account chip removed; `TwitchAccountControl` for native — chip
    + disconnect dialog when logged in, "Connect Twitch" pill when logged
    out).
  - Slot: native view iff Twitch + native engine + logged in; native +
    logged out → connect empty state (pill relocated there); WebView engine
    → legacy stack regardless of login, empty state back to the username
    prompt only.
  - Disconnect dialog copy no longer claims the WebView takes over after
    logout.

## 2026-08-04 (native Twitch chat Phase 1)

- **Native read-only Twitch chat in the existing dashboard chat slot** —
  full Phase 1 landed on `master` (spec/plan under `docs/superpowers/`).
  Log in via OAuth **device-code grant** (DCF) — chosen over implicit/PKCE
  redirect flows so no localhost callback server or custom URL scheme is
  needed on mobile; dialog shows the code, user authorizes on
  twitch.tv/activate, polling completes login. Chat arrives over **EventSub
  WebSocket** (`channel.chat.message`), rendered natively with inline emotes
  + cheermotes and author colors. Read-only by design: no chat scope
  requested, no Helix send. **WebView fallback retained** for the logged-out
  state, YouTube, and Owncast — the chat slot swaps native ↔ WebView based
  on login state.
- **Files:** `lib/models/twitch_auth.dart` (Hive, typeId 13);
  `lib/utils/twitch/twitch_auth_service.dart` (device-code request, token
  polling/refresh/validate/revoke, own-user fetch) +
  `twitch_eventsub_service.dart` (EventSub WS: reconnect, watchdog,
  keepalive); `lib/stores/views/twitch_chat.dart` (GetIt `TwitchChatStore`:
  login state, token lifecycle, bounded message buffer); DTOs under
  `lib/types/classes/twitch/` (device code, token, user, EventSub envelope,
  `channel_chat_message` — freezed); UI
  `lib/views/dashboard/widgets/obs_widgets/stream_chat/` (`stream_chat.dart`
  slot switch, `native_twitch_chat_view.dart`, `twitch_chat_message_row.dart`,
  `twitch_device_code_dialog.dart`) + `username_action_row.dart`
  connect/logout actions; `http` added as the single new dependency; tests
  under `test/chat/` + `test/persistence/twitch_auth_persistence_test.dart`
  with `test/chat/fixtures/twitch/` message fixtures.
- **Client ID:** `t3muhu36do5wemeeilzl57v48gwcmh` (public — no secret in
  DCF), hardcoded once in `lib/utils/twitch/twitch_auth_service.dart`.
- **Robustness fixes during execution:** EventSub subscription POST failures
  are routed to `onRevoked` (token treated as dead → clean logout state
  instead of a stuck "connecting" WS); cold-start token validation is
  offline-safe (network errors keep the stored session, only a definitive
  401 logs the user out).
- **Verify:** `flutter test test/chat/ test/websocket/ test/persistence/`
  87/87; `flutter analyze` 0 errors (only the 6 pre-existing warnings:
  `input.dart` ×2, `translucent_sliver_app_bar.dart` ×2, `statistics.dart`
  ×2); build_runner clean (no drift). Manual dogfood on a real Twitch
  account pending (maintainer) — incl. the open point whether the WebView
  fallback re-renders after logout given `_syncWebController`'s
  unchanged-URL early-return (`stream_chat.dart`).

## 2026-08-03 (redesign finish batch)

- Stats entry→detail **Hero removed** (plain push); `HeroMode` workaround in
  paginated list gone with it.
- **Unified onboarding:** GettingStarted → WS setup + light app-tour slides;
  deleted OBS version fork (`version_selection`, `twenty_eight_party`,
  `back_so_selection_wrapper`). Screenshot walk updated.
- **Reorder previews** tightened to reuse real leaf widgets (`BaseCheckbox`,
  `BaseDropdown`, `BaseButton`, `StatTile`, scene-item/audio chrome).
- **`DashboardElementsOrder` wired** into live `DashboardContent` via
  `dashboard_element_layout.dart` — compose-when-adjacent (mobile tabs /
  tablet side-by-side for Scene Items↔Audio and Chat↔Stats).
- **Phone + tablet product rule** documented in `AGENTS.md` + design-system
  § Responsive layouts; order screen hint; Force Tablet Mode noted for QA.
- Verify: persistence/chat/websocket tests **38/38**; analyze 0 errors on
  touched paths. Landed as `23248b7` on `origin/redesign`.
- **2026-08-03 workstation close-out:** maintainer accepted the finish batch
  visually; `redesign` merged into `master`. Soft leftovers: connect-overlay
  motion pass; Twitch console registrations (deferred).

## 2026-07-27 (redesign branch)

- **"On Air" visual overhaul on branch `redesign`** (later pushed; tip through
  finish batch is `23248b7`). Full audit (15-agent swarm →
  `docs/redesign/audit-digest.md`), design spec (`docs/redesign/design-system.md`),
  session notes (`docs/redesign/session-notes.md`).
- New design module `lib/shared/design/`: motion/spacing/radius tokens,
  `AppStatusColors` ThemeExtension, app text theme, `Pressable`,
  `StaggeredEntrance`, `AnimatedResultIcon`, `CountUpText`.
- `lib/app.dart` theme factory modernized (real textTheme, pageTransitionsTheme,
  dialog/snackBar/chip sub-themes, status extension) — custom-theme hex→slot
  semantics and all persistence contracts unchanged; zero functional change rule.
- 11-agent restyle: shared UI kit, tab transition, intro cinematic, home,
  dashboard (on-air status cluster replaces `stream_rec_timers.dart`, audio
  mixer gradient meters, chat chrome), statistics (chart draw-in + gradients,
  staggered lists, hero entry→detail), settings (support dialog skeleton +
  icon tiles), custom theme editor (preview cards + 8th appBar bubble), data
  mgmt/logs/customisation (mock previews replace PLACEHOLDERs).
- Verify: `flutter analyze` 143 issues / **0 errors** (master baseline 269);
  `flutter test test/chat test/websocket test/persistence` 38/38; debug build on
  iPhone simulator (release/profile unsupported on this sim image).
- **Visual-QA round:** screenshot harness (`integration_test/screenshot_walk_test.dart`
  + `tool/visual_qa/capture_screenshots.sh`, `--no-uninstall` permanently after a
  sim-data wipe incident — see `docs/redesign/session-notes.md`); 37-shot walk
  incl. live dashboard via local OBS; 6-agent visual inspection (~90 polish
  findings); 8-agent fix swarm (overflow root causes, surface derivation, tab-bar
  unification, copy pass, subpage headers, intro slide frames, Connect button
  wrap, …). Post-fix: analyze 138 / 0 errors, tests 38/38, re-shoot for
  spot-check.

## 2026-07-27

- **Public-repo docs pass:** repo is public — scrubbed tracked files of the
  local OBS dev password, simulator UDID, username-absolute paths, and
  machine nicknames; generalized E2E/tooling docs so any contributor's agent
  can follow them; maintainer-specific machine notes marked as such. Rule
  recorded in `AGENTS.md` (docs hygiene).
- **Merged the upgrade batch to `master`** (fast-forward), deleted
  `chore/flutter-deps-upgrade` (local + origin). Docs now describe a
  master-based flow; open before store release: Android build/test,
  version/build-number bump.
- **Persistence device proof DONE** (release gate closed): master-era dev
  build over the App Store app on a real ~2.5y-old iPhone install (worktree
  `obs_blade_master_check` + 5 throwaway compile shims — master itself
  untouched), real boxes pulled via `devicectl` (`build/phone_backup/`),
  simulator rehearsal passed, CE profile build installed, user verified all
  data, CE write to `app-log.hive` proven. Learnings: debug builds crash on
  cold home-screen launch (flutter#149214) → use profile/release on device;
  `devicectl ... process launch --console` broken in this Xcode (error
  10002) → verify via process list + container pulls.
- Bumped `keyboard_actions` to `^4.2.1` — 4.2.0 breaks the iOS simulator
  build on Flutter 3.44 (`SemanticsConfiguration.isFocused` now `bool?`;
  fixed upstream in 4.2.1). First real device/sim build of the branch.
- Added local OBS ↔ simulator E2E loop on macOS
  (`docs/local-obs-e2e.md`): `tool/obs_local/obs_test_env.sh`
  (start/stop/status for the real OBS instance, reuses running OBS, minimizes
  window) + `tool/obs_local/ws_smoke.dart` (standalone Hello → Identify →
  Identified + GetVersion/GetSceneList/GetInputList probe mirroring
  `AuthenticationHelper` semantics; no new deps). Tests run against the
  existing `Untitled` profile/scene collection per user direction.
- Committed + pushed `chore/flutter-deps-upgrade` so the workstation clone
  can mirror the headless clone for simulator testing.
- Folded workstation-only order-list bottom padding (`kBottomNavigationBarHeight`)
  into the branch before push.
- Updated handoff/AGENTS for dual-machine roles (headless = analyze/test;
  workstation = sim).

## 2026-07-25

- Cloned repo; lean `AGENTS.md` + `docs/`.
- Flutter **3.44.8**; branch `chore/flutter-deps-upgrade`.
- Migrated **Hive → Hive CE**; regenerated adapters; typeIds/fields verified.
- Built **foundation mock data** + committed `*.hive` boxes; open / cold-open /
  copy-reopen tests (`test/persistence/`).
- Classic **hive 2.2.3** writer (`tool/classic_hive_writer/`) → CE open proof
  (`classic_boxes/` + `hive_classic_to_ce_test.dart`); **17** persistence tests
  passing.
- Raised SDK to `^3.12.0`; bumped majors (get_it 9, fl_chart 1, slidable 4,
  plus packages, intl, …); replaced `qr_code_scanner` with `qr_code_scanner_plus`.
- `flutter analyze`: **0 errors**.
- Documented OBS WebSocket v5 architecture for agents
  (`docs/obs-websocket-architecture.md`): layers, handshake, request/event/batch
  patterns, inventories, DashboardStore role, legacy event-name pitfalls.
- **WebSocket connect harden:** conditional Identify auth, 10s staged handshake,
  `ConnectionAttemptResult` UX, `websocketUri` + domain default `ws://`, stream
  pump ownership, QR `obswss://`, FAQ + `docs/websocket-connect-audit.md`,
  `test/websocket/handshake_helpers_test.dart`.
- **DashboardStore WS audit** (`docs/dashboard-store-websocket-audit.md`): fixed
  `SceneListChanged` name, pause stats during collection change, lighter scene
  switch refresh, scoped scene-item enable updates, always track studio mode;
  requestStatus guards + safer UUID lookups on Get/batch handlers.
- **Chat WebView audit** (`docs/chat-webview-audit.md`): Twitch/YT/Owncast embed
  approach vs native EventSub/Helix / YouTube Live Chat APIs; recommended hybrid.
- **Chat Phase 0:** YouTube Live Chat API visibility check documented; fixed
  video-id parsing (`extractYouTubeVideoId`), WebView recreate-on-rebuild, dialog
  copy/validation; Owncast trailing-slash normalize. Tests in `test/chat/`.
- **Session close:** `docs/session-handoff.md` written for next agent; AGENTS.md
  points at it. Chat Phase 1 (native Twitch) parked pending Dev Console creds.

## 2026-09-08 — Visual companion framing-ban learning

Mockup shell failed twice in the user's real browser despite green
headless verification: headless Chrome loaded `file://` copies, which
bypass the companion server's `X-Frame-Options: DENY` /
`frame-ancestors 'none'` headers (and the session-key cookie isn't sent
for iframe subresources). Fix: merged single-document shell
(`all-views-v3.html`), verified in the user's real browser via
kimi-webbridge. Durable lessons documented in
`docs/superpowers/visual-companion-gotchas.md` (indexed in AGENTS.md).


## 2026-09-20 — Chat independence follow-through, streaming-mode cockpit, saved-connection refresh

All on branch `4.0-liquid-glass`, user-dogfooded per wave (iPhone 17 Pro sim,
local OBS test env). Gates throughout: analyze at the 472-issue baseline,
`dart format` on touched files, suites green per AGENTS.md test selection.

- **Chat tab follow-through wave 2 (post-dogfood fixes, landed earlier same
  day before this entry's wave):** 1-line connect pills via AutoSizeText,
  scene-button color-fade fixed (alphaBlend tween), phone stats double-card
  removed, scene-content card background, chat-tab height fix.
- **Tab-bar bottom clearance unified (`48be2608`):** single helper
  `tabBarBottomPadding(context)` in `lib/shared/design/tab_bar_metrics.dart`
  (MediaQuery padding.bottom + AppSpacing.md; TabBase's extendBody Scaffold
  injects the bar's full 84pt extent). All tab screens use it; root-navigator
  modals keep the raw inset.
- **Dashboard chat pane removed (`d63e9bdc`):** `pointerOnChat` arbitration
  retired with it — this fixed the reconnect tap-dead bug at the root
  (user-confirmed). Chat lives in the dedicated tab + streaming mode only.
- **Dashboard content-card grid (`57264645` + `09655fbe` + `ec3158a6`):**
  composer-owned rhythm in `dashboard_element_layout.dart` — 12px side
  margins, 12px gaps, content = card / actions = bare (scene buttons a
  ratified exception). Visibility-aware: toggled-off elements (Expose* flags,
  studio mode) leave no stray gaps. Stats: phone = auto-height measured
  pages (`_SizeReportingWidget`), non-scrollable pages, dots padded; tablet
  keeps the fixed 650 card (known follow-up candidate). Leading md so the
  first block never hugs the app bar.
- **Dashboard element ordering VERIFIED:** reorder persists live via
  `DashboardElementsOrder` HiveBuilder key; composer respects arbitrary order
  (Scene Items/Audio merge only when adjacent); retired `StreamChat` value
  filtered at both read sites. The classic "persisted order misses a newer
  element" case is not reachable — the enum was born with all 10 values
  (`a64f93b5`); if an 11th element is ever added, append-missing-at-read
  hardening is required.
- **Streaming-mode cockpit (chat restored):** `d63e9bdc` had also dropped
  chat from streaming mode — rebuilt (`3528bd75`): drag-resizable full-bleed
  preview (`ResizeableScenePreview` handle re-enabled, height constant-driven
  as `dragHandleHeight`), stream-health strip, scene buttons, chat filling
  the rest; tablet = preview+buttons left, chat full-height right (flex 3:2).
- **Floating chrome (`fe022ddf` + `664a040b`):** health strip became
  `StreamHealthPill` overlaying the preview (chart toggle, top-left pill /
  top-right button); chat header (`ChatUsernameBar`) leaves the layout —
  `StreamChat.hideUsernameBar` seam — and slides in as an overlay card via a
  floating tune toggle. Tune toggle defaults bottom-right above the input
  dock (top-right collided with the native window's own status tag), drags
  vertically along the right edge (clamped clear of header + input/pause-chip
  zones), position persisted as a height fraction. Panel opens toward the
  roomier side. New settings keys: `StreamingModeStatsOverlay` (default on),
  `StreamingModeChatHeaderOpen` (default off), `StreamingModeChatToggleDyFraction`
  (default 1.0). Toggle badge dot = "any chat selected" per-platform rule.
- **Preview handle slimmed (`f207ef22`, `c33cd438`):** 34 → 24 → 18pt bar,
  grip icon rotated 90° at 14pt.
- **Saved-connection card refresh (`dd82fb9e`, `ed4a6d7d`, `7f0ea927`,
  `bc0b7ca1`, `79c76a5d`):** Online pill is GREEN (`AppStatusColors.reachable`,
  mirror of Offline) — supersedes the v12 "online stays neutral" grammar note;
  Connect is filled accent when reachable, ghost otherwise (supersedes the
  all-ghost demotion); pencil replaced by the adaptive ellipsis action sheet
  (Edit / Delete) — `AppBarActions.showActions` extracted as a reusable
  static, card trigger is a slim pill-aligned Pressable; "Last used: x ago" /
  "Never used" stamp via new additive `@HiveField(6) int? lastConnectedMs`
  on `Connection` (build_runner regen, legacy boxes decode null, persistence
  suite green) + `lib/utils/relative_time.dart`; stamps only on fully
  established sessions (handshake success sentinel `DontClose`).
- Test adds: `test/dashboard/stream_health_pill_test.dart`,
  `test/utils/relative_time_test.dart`.
