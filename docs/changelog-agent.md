# Agent changelog

Running log of upgrade/migration work. Not store release notes.

Entries before the 4.0 merge (2026-07-25 → 2026-09-21): [`archive/changelog-agent-pre-4.0.md`](archive/changelog-agent-pre-4.0.md).

## 2026-10-07 - Release: 4.1.0 live on both stores

4.1.0 build 2026100501 (release commit `4c0c3e28`, approved on both
stores after the 2026-10-05 promote) published: App Store via
`release publish ios` (`READY_FOR_SALE`, manual release to everyone),
Play by the user in the Console (managed publishing, production at 100%).
Tag `4.1.0` pushed.

The Play publish surfaced a **stale-language trap**: the store listing had
two languages - en-GB (the listing's *default*, with the pre-4.0
screenshots + text) and en-US (everything the tooling ever pushed). Every
`metadata android` run only updated en-US, so the queued 4.1.0 changes
previewed the old screenshots and the user held the publish. Fixes:

- Synced en-GB = en-US (text + all images, SHA-verified server-side
  against the repo) via a throwaway `fastlane/metadata/android/en-GB`
  copy + the metadata lane, then removed en-GB: the Console's default
  switch needed **en-US translations on all in-app products** first -
  tip_1/2/3 + blacksmith only had en-GB; added en-US copies via
  `oneTimeProducts:batchUpdate` (the legacy `inappproducts` PATCH 400s on
  full/partial bodies, and tip_1 was already migrated to the new model,
  which the legacy API refuses outright). After publish the listing reads
  `languages: en-US` via the edits API.
- New preflight guard (`f77e9167`): `release preflight` fails when the
  Play listing has languages beyond `fastlane/metadata/android`, so this
  drift can't come back.
- Full both-store listing audit before publish (throwaway ASC + Play
  reads): App Store 4.1.0 fully matches the repo (text, URLs, 14
  screenshot md5s, App Preview present); Play matches byte-for-byte
  (text, video URL, 21 screenshots + feature graphic + icon sha1s).

Watch: crash reports / reviews for 4.1.0.

Same session, after the publish:

- **Website 4.1 copy live** - `pending-4.1/` → `site/index.html` +
  `deploy.sh`, verified "OBS Blade 4.1" on https://obs-blade.kounex.com,
  `pending-4.1/` deleted (its AGENTS.md section removed too).
- **iOS 27 creative asset designed** (user asked about the new Header /
  Search results slots): one **universal** 5244×2950 composition via a new
  `universal` layout in the store-shots composer (`apple-universal` set) -
  mark + headline left, iPad + iPhone right, all focal content inside the
  centre safe zone; simulated header/search crops checked. User approved
  it; canonical copy now versioned at `fastlane/assets/ios/universal.png`.
- **Creative asset shipped via new tooling** (`0785d265`): `tool/release`
  learned the App Store Connect **Asset Library API** (OpenAPI spec:
  `appAssetLibraries`, `appAssetLibraryImages`, `appAssetLibraryPlacements`,
  standalone review via `reviewSubmissions` + `reviewSubmissionItems` with
  an `appAssetLibraryImage` item). `release assets ios` validates the PNG
  against Apple's live spec ref data (`appAssetLibraryRefData` - the spec
  serving both PRODUCT_PAGE_HEADER_ASSET + APP_STORE_SEARCH_RESULTS_ASSET),
  uploads (reserve → chunks → commit → poll), and submits for review on
  its own; `release attach ios` places the approved asset on the live
  version's header + search placements (the Console "Publish" equivalent -
  unprobed until the first approval). First run: asset `aa400005-…` from
  `fastlane/assets/ios/universal.png`, standalone submission
  `5e6df008-…` → WAITING_FOR_REVIEW. Play has no equivalent slots (its
  feature graphic already exists), so this is Apple-only.
- **Review gallery hosted:** https://obs-blade-gallery.kounex.com -
  nginx `obs-blade-gallery` container (:8460,
  `/volume1/docker/obs-blade-gallery/`) serves the composer's `out/`
  read-only (re-renders live), Cloudflare tunnel ingress + CNAME +
  Access app behind the same Authentik "Password Protected" policy as
  fleet.kounex.com; on the fleet board via it-env catalog.

## 2026-10-06 - Scene item rows show OBS' source colors (branch `feature/preview-transitions`)

User-facing: OBS 32 lets streamers color-code sources (Sources dock ->
right-click -> Set Color) to scan a busy Sources list; the dashboard's
Scene Items list now tints its rows the same way (read-only - setting
colors stays OBS-side).

- **Facts first** (obs-studio + obs-websocket master, added to
  `obs-protocol-gotchas.md` § Source colors): the color lives on the scene
  item's **private settings** (`color-preset` 0/1/2-9 + custom `color` in
  Qt `HexArgb`), read via `GetSceneItemPrivateSettings` (5.6+,
  undocumented-but-stable, gated on `availableRequests`); group children
  are looked up by the parent group's source name; **no event** fires on a
  color change, so the fetch rides the scene-item list reads (one batch
  per applied list) and a change in OBS appears with the next read.
- **Color math** (`lib/utils/scene_item_color.dart`): presets render at
  33% alpha in OBS' exact palette; custom `#AARRGGBB` maps directly;
  preset 1 with an empty / missing color renders untinted like OBS.
- **Store** (`DashboardStore.sceneItemColors`, keyed
  `<sceneName>|<sceneItemId>`): batch answers set / drop entries; items
  removed from a scene get reconciled out; a failed read keeps the cached
  color; old OBS gets no color requests at all.
- **UI**: the tile wraps its row in the tint inside the Slidable, so it
  travels with the row and slide actions stay behind; no color = the
  exact previous rendering.
- **Verified**: 5 helper unit tests (full preset / custom / garbage
  matrix), 4 fake-peer websocket tests (batch sceneNames incl. group
  children, unsupported OBS, color cleared, item removed), widget shots
  of every state (untinted baseline, presets, custom translucent /
  opaque, tinted group + indented child, locked + hidden tinted row,
  tablet) - looked at, tints full-width with readable icons / text.
- **Left out**: setting colors from the app, canvas scene items (the
  extra-canvas item list), light-theme contrast tuning beyond what the
  33% alpha gives.

## 2026-10-06 - Scene preview plays OBS' scene transitions (branch `feature/preview-transitions`)

User request: the preview cut instantly while OBS faded / swiped. The
preview is a `GetSourceScreenshot` loop of the program *scene*, so OBS
can't hand us mid-transition frames (transitions aren't screenshottable) -
the app plays the transition itself. Experiment branch, not on master.

- **Facts first** (probe on the MacBook's OBS 32.2.2 / obs-websocket 5.7.4
  + source reads, added to `obs-protocol-gotchas.md` § Scene transitions):
  `CurrentProgramSceneChanged` only fires once the transition ENDED;
  `GetCurrentProgramScene` at `SceneTransitionStarted` already names the
  incoming scene; settings come without defaults; override duration
  defaults to 300 ms.
- **Tracker** (`lib/utils/preview_transition/`): frames are tagged with
  their scene; a pure `PreviewTransitionTracker` shows / holds (≤ 400 ms) /
  starts a transition. Contexts come from app switches
  (`setActiveSceneName`) and `SceneTransitionStarted`, which also triggers
  the early program read - **side effect: switches made elsewhere now move
  the scene tiles + items at the transition's start** (before: at its
  end, so the tile highlight ran a full duration late).
- **Look** = OBS' own math (`plugins/obs-transitions`): fade, fade to
  color (switch point, ABGR color), swipe (in/out, 4 directions), slide,
  luma wipe (OBS' 34 masks bundled in `assets/luma_wipes/`, GPL-2.0+, +
  `shaders/luma_wipe.frag`), stinger = hold, cut at its transition point
  (its video is a private source of the transition), plugin kinds
  (Move, ...) = crossfade. Duration: override > current > measured
  Started→VideoEnded > current.
- **UI**: `ScenePreviewImage` (inline + fullscreen) keeps the live frame
  underneath and paints the transition on top; reduce motion cuts.
  Settings → Dashboard → **Preview Transitions** (on by default).
- **Verified**: 25 tracker/spec unit tests, 12 store tests on the fake
  peer, 5 widget tests, widget shots of every kind mid-way (+ 4:3 canvas,
  settings row), and `tool/obs_local/preview_transition_live_test.dart`
  against the real OBS: dashboard follows a switch from elsewhere after
  ~5-20 ms, the preview transition starts 20-65 ms after the switch with
  the right kind / duration / direction (override Fade 1200 ms while
  Swipe is current; a settings change without event picked up).
- **Review round** (fresh-context reviewer, 9 findings, 6 real): studio
  mode no longer moves tiles early (a cancelled T-bar drag sends no program
  event - verified live, tiles stay, preview returns 26 ms after release);
  Cut resolves at once, app taps resolve alongside the program read (live:
  transition 14-17 ms after the tap); a spec only applies to its target;
  stingers without readable settings cut mid-video (measured); caches
  cleared on reconnect / collection change; widget decode races closed.
  Not real: stale replay after a canvas view (the suspend resets the
  transition), cache-evicted "from" frame (it's the frame on screen).
- **Left out**: manual T-bar timing (plays over the configured duration),
  fade to black, other canvases, settings of non-current transitions (kind
  defaults), quick transitions reusing the current transition's name (run
  at its duration).

## 2026-10-05 - Release: 4.1.0 promoted to review (both stores)

Beta build **2026100501** (release commit `4c0c3e28`) went out in the
morning (TestFlight `VALID` + Play internal; store notes unchanged from
2026100402, TestFlight "What to Test" = build-8 list). The user's dogfood
verdict on the session-history wave was "looks very very good", so the same
build was promoted in the afternoon: `metadata ios` created App Store
version 4.1.0 (notes, 14 committed screenshots; the App Preview carried
over from 4.0.1 - verified `COMPLETE` via the ASC API with a throwaway
script riding the release tool's `AppStore` client), `metadata android`
pushed the regrouped Play description + graphics (managed publishing holds
them), `submit ios` (manual release) and `promote android --rollout 1.0`
(user picked 100% over a staged 20%). State: App Store 4.1.0
`WAITING_FOR_REVIEW`, Play production 4.1.0 [2026100501] in review at 100%.
Next: both approved → `release-publish` (`publish ios` + the Play Console
**Publish** button, tag `4.1.0`), then the website's `pending-4.1/` copy
goes live.

## 2026-10-05 - Chat: session-history cap is user-configurable (default 50k)

The `ChatHistoryStore` cap (messages kept beyond the 500-row live
buffers for the viewer cards) was a hardcoded 200k const
(`kChatHistoryCap`). It's now a setting with a UI:

- `lib/stores/views/chat_history.dart`: the const split into
  `kChatHistoryCapMin` (10k) / `kChatHistoryCapDefault` (**50k** - down
  from 200k, ~64 MB worst case at the capacity spike's ~1.25
  KB/message) / `kChatHistoryCapMax` (200k). The store's `cap` is
  settable at runtime: lowering trims the oldest entries (author index
  included) immediately, raising un-gates growth; values clamp into
  range. The persisted value (new additive `SettingsKeys.ChatHistoryCap`
  int, `chat-history-cap`) wins at construction; a constructor `cap:`
  seam (verbatim, unclamped) keeps tests free of the settings box and
  small-numbered. `chatHistoryEstimatedMb` pins the estimate (13/64/128/
  256 MB at 10k/50k/100k/200k).
- Options sheet (`native_chat_options_sheet.dart`): new "Session
  history" entry in "All chats" → own sheet page (back-chevron pattern):
  explainer (session-scoped, cleared on sign-out/app close), 10k-200k
  slider in 10k steps ("50,000 messages" readout), and a "Memory usage"
  row with the worst-case estimate colored by `AppStatusColors` -
  `reachable` ≤ 75 MB (the 50k default reads green), `warning` ≤
  150 MB, `destructive` above. Writes persist and apply to the live
  store at once; Reset restores 50k. `_AppearanceSlider` gained
  optional `divisions` / `valueText`.
- Tests: store cap defaults/persistence/clamping/live-trim/growth +
  the options page (slider steps, estimate colors at low/mid/max, box
  persistence, live-store apply); widget shots
  (`options_sheet_shots_test.dart`) at default/100k/max (the three
  color states), phone + 320 pt.
  The old 201k-fill eviction test now runs at cap 1000 via the seam
  (same mechanics, much faster).

## 2026-10-05 - Chat: resume catch-up for Twitch + Kick (background window no longer lost)

Spec: [`superpowers/specs/2026-10-05-chat-resume-catch-up-design.md`](superpowers/specs/2026-10-05-chat-resume-catch-up-design.md).
Dogfood report: after a longer iOS background stay, combined chat showed
only YouTube catching up (its cursor poll is zero-loss) while Twitch
"flooded" back live with the whole background window missing - EventSub
does not replay a lost session and the connect-time history backfill runs
once per session; Kick's backfill only ever filled an empty buffer.

- Both native stores gained `reconnectAfterResume()`, hooked in
  `main.dart`'s lifecycle observer next to the existing YouTube one
  (`_AppLifecycleObserver`, `AppLifecycleState.resumed`). Twitch
  restarts via `connectChat()` when `chatConnection` is `reconnecting` /
  `failed` (guarded by `_eventSub != null` so a never-connected session
  isn't started); Kick via `_restartConnection()` on `reconnecting` /
  `error` (guarded by a channel selection). The EventSub backoff sleep
  is a non-cancellable `Future.delayed`, so "immediate" is a store-level
  restart - both services re-subscribe on a fresh welcome anyway, no
  service-level `reconnectNow()` needed.
- On resume both stores re-fetch history for the background window and
  merge it **mid-buffer**: timestamp-sorted insert, deduped by message
  id, **not** flagged historical (join-history styling stays a connect
  thing), and TTS-silent (the TTS feed only sees live appends). Twitch
  uses `recent-messages.robotty.de` with limit **800** and honors the
  existing `TwitchChatLoadHistory` setting (a user who disabled
  join-history gets no fetched resume history either); Kick uses the
  channel service backfill (~50 rows, all Kick keeps).
- Gap marker: when the fetched window's oldest row postdates the buffer
  row it ACTUALLY lands after by more than **2 s** (epsilon - judged
  against the insertion predecessor, not the stale pre-fetch tail, so
  live rows bridging the window mid-fetch don't raise a false marker),
  that row's id lands in the new `resumeGapBoundaries` observable set.
  Native Twitch / Kick timelines prepend a `ChatResumeGapDivider`
  ("Some messages while away are missing", `native_chat_chrome.dart`,
  platform-brand color) on those rows; combined chat inserts a synthetic
  `ChatResumeGapMarker` item (key `<platform>:resume-gap:<id>`) into the
  merged timeline, rendered full-width without the source wash and
  borrowing its boundary row's zebra-parity slot so the striping below
  it doesn't flip.
- Boundary ids die with their row: `_trimMessages` (Twitch + Kick), the
  Twitch mid-switch buffer trim, and Kick `releaseScrollback` / `/clear`
  / `reloadChannels` retirement evict them; nothing is persisted. The
  Twitch channel-switch buffer SWAP deliberately keeps them - the
  divider correctly reappears on switch-back. Cap trims during catch-up
  keep feeding `ChatHistoryStore` (the eviction feed point is
  unchanged).
- Mid-buffer inserts don't touch `_arrivalSeq` itself, but growing the
  buffer shifts the position-derived seqs of every row below the insert
  (base = `_arrivalSeq - length + 1` moves with the length) while
  notices keep absolute `afterSeq` - the catch-up decrements the anchors
  in the shifted region, so a /clear banner stays glued to its row
  instead of hopping down by the insert count. Twitch catch-up is
  skipped while `chatConnection == connecting` (a resume mid-initial-
  connect is covered by the join backfill; an interleaved insert could
  mis-order against its prepend), and Kick's hook explicitly no-ops
  `connecting` / `idle` (the in-flight connect flow owns the window; the
  Pro-gate idle is no-connection-by-design, not a dead socket).
- Unread pills: deliberately no special-casing for catch-up rows (left
  as-is after review) - a resume catch-up counts as new arrivals like
  any insert (timeline-length delta), and combined chat's gap-marker row
  adds +1 to that delta while the native timelines render their divider
  inside a message row. Either counting is defensible: the rows ARE new
  to the reader vs. they were said while the app was away, not while the
  reader watched.
- Known limitation: a stale-`live` socket after iOS suspend can't be
  distinguished from a healthy one (services expose no liveness probe),
  so it's left to the watchdog / keepalive (self-heals in seconds); the
  catch-up fetch covers the window regardless - same philosophy as the
  YouTube hook. The symmetric gap case is deliberately unhandled too:
  when the fetch window sits inside live coverage (a hole in live
  DELIVERY, not in the history), nothing is fetched and no gap is
  marked - too narrow to chase.
- Widget shots: `tool/widget_shots/chat_resume_gap_shots_test.dart`
  (Twitch / Kick, phone + 320 px narrow, combined phone + tablet).

## 2026-10-05 - Chat: user cards remember the session beyond the 500-row buffer cap

Follow-up to the same-day capacity spike: messages evicted at the
500-row buffer cap were gone from the user card entirely. The card now
merges a session-only history with the live buffer, so a chatty
channel's evicted rows still show on a chatter's card. In-memory only -
nothing is persisted, an app restart starts empty.

- New `ChatHistoryStore` (`lib/stores/views/chat_history.dart`): one
  global FIFO cap of **200,000** messages across all three platforms
  (per the spike, full freezed models ≈ 1.0-1.4 KB → worst case ~250 MB,
  accepted for a session store; per-platform caps were considered and
  dropped - one chatty channel shouldn't eat another platform's room
  less, the card query is what matters). A per-(platform, channel,
  author) queue index keeps the card lookup microsecond-cheap; global
  eviction pops the index front (per-author order is the filtered global
  order, so that's O(1) and correct).
- Fed **only** at cap-eviction points (Twitch `_trimMessages` incl. the
  channel-switch buffer trim, YouTube page trim / `releaseScrollback` /
  send echo trim, Kick `_trimMessages` / `releaseScrollback`) - history
  and live buffer never overlap. Twitch snapshots the tombstone state
  (deleted / marker / actor) at feed time, before `_forgetEvicted` wipes
  the live records; YouTube / Kick freeze the model's own tombstone
  flag.
- Erasure is only: a channel leaving the list wipes that channel's rows;
  Twitch / YouTube sign-out, dead session and auth reset wipe the
  platform's; an app restart starts empty. **`/clear` (Twitch, Kick)
  deliberately keeps the history** (ratified after review): the app's
  /clear UX is content-visible tombstones - cleared rows stay visible,
  dimmed, with the marker - so the history mirrors it, and rows evicted
  after a /clear carry that tombstone into their snapshot. **Kick
  sign-out deliberately keeps them** - Kick keeps its buffers on
  sign-out (anonymous reads), so the history follows suit. YouTube keys
  by the channel **entry label**, so the auto-rollover to the next
  stream keeps the history (test in
  `youtube_channel_rollover_test.dart`). Known limit, deliberate: a
  message deleted after it was already evicted keeps its feed-time
  snapshot - the delete event can't find it anymore.
- `messagesForChatter` (all three stores) now returns
  `List<UserCardMessage<T>>` (message + nullable tombstone snapshot;
  null = still live), everything retained, newest first as before - the
  old 20-row cap is gone, the card bounds the display instead. Stores
  take a `chatHistoryResolver` ctor seam (default: GetIt, guarded -
  absent in tests that don't register it); `ChatHistoryStore` is a lazy
  singleton in `main.dart`.
- Card UX (all three sheets, shared `UserCardHistoryList`): the retained
  rows render in a lazy `ListView` inside `NativeChatSheetScaffold`
  (new `bodyIsScrollable` - the scaffold slots it with bounded height
  instead of wrapping it in another scroll view; pinned name / facts /
  LIVE / footer unchanged). First **50** rows shown, then a "Show X
  older messages" button (X = remaining retained; hidden at ≤ 50;
  screen-reader label "Show X older messages from \<name\>"; one-way,
  resets when the card reopens).
- Scaffold edge case: the short-sheet fallback (phone in landscape -
  everything scrolls together) can't host a lazy list. Small histories
  (≤ 50) join the shared scroll as before (`bodySharesScrollWhenShort`;
  the list goes shrink-wrap + non-scrolling when the height constraint
  is unbounded); a longer one keeps the pinned layout, whose slots
  scroll on their own.
- Tests: `chat_history_store_test.dart` (incl. a 201k-fill global
  eviction + index consistency), per-store history integration groups
  (eviction / scrollback / wipes / merge order / Kick keeps-on-logout /
  YouTube rollover), card tests (fully-evicted chatter, merge order,
  50-row button + semantics + lazy build on scroll, no button at ≤ 50).
  Two existing card tests updated for lazy rows (offscreen rows aren't
  built anymore).

## 2026-10-05 - Chat: user-card history timestamps on YouTube/Kick + history-capacity spike

User report: the user card's message history shows no timestamps for
YouTube (Kick had the same gap). Plus a sizing question: messages
evicted at the 500-row buffer cap are gone entirely - how much history
could a separate retention list keep?

- Fix (`6e015a6b`): `YouTubeChatMessageRow` / `KickChatMessageRow` got
  Twitch's `showTimestamp` param (forced `formatChatMessageTime` span
  regardless of the timeline setting, semantics label included), and both
  user-card sheets pass it on their history rows. Reviewer-approved.
- Capacity spike (`test/chat/chat_history_capacity_test.dart`, skipped
  by default - run with `--run-skipped`): realistic generated messages,
  RSS-slope memory + churn + query + JSON sizing. Findings: full freezed
  models cost **~1.0-1.4 KB/message** (Twitch/YouTube/Kick alike -
  strings dominate) → 100k ≈ 120 MB, 500k ≈ 600 MB; a slim history
  record (id, author, timestamp, text) costs **~0.5-0.6 KB** → 100k ≈
  55 MB, 1M ≈ 550 MB. Eviction-path churn is ~5 µs/msg *including*
  generation (append + per-user index insert alone is sub-µs); a
  per-user `Map<authorId, List>` makes the card's last-20 query
  microsecond-cheap (full scan: ~0.5 ms at 100k, ~6 ms worst case at
  500k). JSON for persistence: ~160 B/entry → 100k ≈ 15 MB, encode
  ~200-400 ms / decode ~140-390 ms (load lazily / per platform if
  persisted). The full models declare `toJson: false` - persisting them
  would need new serializers; slim records are trivially persistable.
  Sweet spot: slim records, per-platform lists, ~100k/platform
  (≈55 MB each) - full-fidelity rows stay viable for a small recent
  window via the live buffer. Not built (user is deciding).

## 2026-10-05 - Chat: YouTube poll died on a timeout/ban event (uint64 as string)

User report (dogfood, after the background-recovery work): a YouTube
chat in combined chat went to Failed after backgrounding, Retry and even
an app restart failed again at once; Settings → Logs showed
`YouTube chat poll failed - _CastError: type 'String' is not a subtype
of type 'num' in type cast`.

- Root cause: `userBannedEvent` messages carry
  `userBannedDetails.banDurationSeconds`, a YouTube **`uint64`** - and
  Google serializes 64-bit fields as JSON **strings** (discovery doc:
  `type: string, format: uint64`, same rule as `concurrentViewers`,
  which the code already parsed defensively). The model cast
  `as num?` threw on the first timeout/ban in the read chat; the poll
  loop treats an `Error` as a bug, not a network state, so the chat went
  terminal-Failed. A restart failed again because the first page of a
  poll is recent history - the offending event was still in it. The
  docs-built fixture encoded the wrong assumption (`300` as a number),
  so tests passed against a body YouTube never sends.
- Fix: `banDurationSeconds` parses from both forms
  (`_uint64FromJson` in `lib/types/classes/youtube/youtube_chat_message.dart`);
  the fixture now carries the wire-realistic `"300"` string; a
  service-level test parses a banned-event page end to end. Checked the
  whole YouTube layer against the discovery doc: the other numeric chat
  fields (`pollingIntervalMillis`, super-chat `tier`, `memberMonth`,
  `giftMembershipsCount`) are `uint32`/`int32` = JSON numbers, correctly
  cast as-is. Rule + sibling list noted in
  `docs/youtube-native-chat-audit.md` (§ Receive) and a checklist row in
  `docs/chat-journey-checklist.md` § Network-facing code.
- Open (verify on device): the ban *request* sends the duration as a
  JSON number - Google accepts both forms for `uint64` inputs, but a
  live timeout via the mod sheet is still unproven (handoff's
  unverified list).

## 2026-10-04 - Chat: notice rows re-faded on every arrival at the buffer cap

User report (dogfood): in combined chat, social rows (subs,
announcements) replayed their fade-in entrance on every new message -
suspected correctly that it starts once the buffer is full and drops
the oldest row.

- Cause: the Twitch and Combined timeline `ListView.separated`s built
  rows **without keys**. At the 500-row cap every arrival evicts the
  oldest row, shifting every row one index up; unkeyed sliver children
  rematch by index, and wherever the row type at an index flipped
  (message ↔ notice ↔ history-divider wrapper), the subtree - including
  the notice row's one-shot `StaggeredEntrance` controller - was
  discarded and rebuilt, replaying the entrance for rows already on
  screen. Kick / YouTube keyed only the *inner* row widget, which the
  zebra-tint / divider wrappers defeat at the sliver-child level.
- Fix: all four native timelines wrap the outermost row in a
  `KeyedSubtree` with a stable per-item key (Twitch view uses the
  combined store's scheme: `twitch:<id>` / `twitch:notice:<id>` /
  `twitch:system:<kind>:<seq>`; combined uses `CombinedItem.key`) **plus
  `findItemIndexCallback`** on the `ListView.separated` - keys alone do
  nothing in a builder-backed sliver: `SliverChildBuilderDelegate`
  relocates keyed children only via `findIndexByKey`, which returns null
  without the callback (verified against SDK `sliver.dart` /
  `scroll_view.dart`; `ListView.separated` maps item index → child index
  ×2 itself). New row in `chat-journey-checklist.md`.
- Tests: regression tests in `native_twitch_chat_view_test.dart` +
  `native_combined_chat_view_test.dart` (500-row cap, settle a notice's
  entrance, one more arrival → same `StaggeredEntrance` State instance;
  a genuinely new notice still animates) - both failed pre-fix (state
  defunct/recreated), pass now; each half of the fix is pinned
  separately. Full chat gate clean (1508 tests).
- Known leftover: a row that gains / loses the history-divider `Column`
  wrapper rebuilds once (wrapper type changes below the key) - rare,
  only when the first-live row itself is evicted.
- Not on a device yet - on-device check: busy capped Twitch / combined
  chat, watch a sub or announcement stay put when new messages arrive.

## 2026-10-04 - Docs restructure: archive moves, deletions, changelog split

New `docs/archive/` holds concluded records: the three one-shot audits
(hive-ce-source, dashboard-store-websocket, websocket-connect), all 20
shipped SDD plans (`archive/plans/`), 25 shipped-feature specs
(`archive/specs/`), the redesign process docs (`archive/redesign/`), and
the pre-4.0 half of this changelog (pointer above). Deleted:
`superpowers/specs/2026-09-08-ui-iteration-4.0-design.md`,
`redesign/2026-iteration/token-discipline.md` + `dashboard-composition.md`
(wrong since the chat pane removal, `d63e9bdc`), and the unreferenced
`docs/fixtures/pre-hive-ce-adapters/`. Parallel pass trimmed the 12 living
docs; AGENTS.md slimming follows.

## 2026-10-04 - Combined chat: each platform keeps its channel emotes

User report: in ohnePixel's Twitch chat, lines like "SunflowerJam Dance"
showed as text while other emotes rendered. Checked live: SunflowerJam
is in ohnePixel's 7TV set (since 2022-02), Dance in his BTTV channel
set - both channel emotes, neither global; the user watched the
channel in a combined chat with Kick.

- Cause: `ThirdPartyEmoteStore` is shared by Twitch and Kick, and its
  "a superseded fetch must not apply" guard was one counter for the
  whole store - in a combined chat the first platform's connect fetch
  was discarded when the second started, so only the globals rendered.
  Now each source (FFZ / BTTV / 7TV) of each scope (global, a
  broadcaster) remembers the fetch it came from; a result applies only
  over an older one, and a source that fails on a refetch keeps its last
  good catalog (the background network failures used to blank a scope).
- Twitch sign-out no longer clears the shared catalogs (public data;
  it wiped Kick's channel emotes too).
- Not covered (known gaps): 7TV personal emotes (EventAPI), a shared
  chat's source channel's emotes (rows use the viewed channel's set).
- Tests: `third_party_emote_store_test` (two channels at once both land,
  a failed source keeps its catalog - both fail on the old store; the
  same channel's superseded fetch still can't overwrite),
  `twitch_chat_store_test` (logout keeps the shared catalogs).

## 2026-10-04 - Chat after the background; grouped scene item toggles

User reports: (1) after a while in the background, a combined chat with
YouTube failed and the header's Retry kept failing until the app was
fully closed; (2) the eye / lock of a scene item inside a group did
nothing.

- (1) Dogfood Settings → Logs (`app-log.hive` pulled with `devicectl
  device copy from`): `YouTube chat poll failed - ClientException: Write
  failed` (and Kick once) right after the resume; repeats are rate-
  limited out of the log. The poll treats it as transient and retries -
  on the same long-lived `dart:io` client whose pooled connections iOS
  took away; a restart (new client) fixed it. `RenewingHttpClient`
  (`lib/utils/`): a connection-level failure (SocketException /
  HttpException / ClientException) swaps in a fresh client, so the
  caller's own retry goes out on new connections (nothing is resent -
  a POST may have arrived); `renewAll()` on app resume, before
  `reconnectAfterResume`. Default client of every YouTube / Kick /
  Twitch service (21) + the YouTube emoji store. Related:
  flutter/flutter#116101 (iOS sockets defunct after ~5 min in the
  background). The log shows the same long-lived clients failing with
  `Bad file descriptor` again and again for minutes - a dead pool, not a
  one-off; still to be confirmed on the device.
- Review fix: `IOClient.close()` always closes with force (http 1.6.0),
  so renewing aborted requests still running (a send, a device-code
  token poll, a refresh). The client now owns its `HttpClient` and
  closes it without force - idle connections go, running requests
  finish. Resume renews only after a real paused / hidden (not Control
  Center, Face ID, a system sheet).
- (2) obs-websocket names a grouped item's change by its group (a group
  is a scene - source checked, see the gotchas), and the dashboard -
  which confirms a toggle only through that event - dropped every event
  not about the displayed scene. Events of a shown group now patch its
  children; the displayed scene's events only its top level (a child
  sharing a top-level id used to flip along).
- Tests: `renewing_http_client_test` (renew on connection failures only,
  renewAll, the YouTube poll's retry after "Write failed" reads again),
  `state_ordering_test` group case (fails on the old code).

## 2026-10-04 - Busy chat: what you read while scrolled up stays put

User report: in a very busy chat, an old message read while scrolled
up kept "scrolling away". Cause: every view is a top-down list at a
fixed offset, and at the 500-row cap each arrival dropped the oldest
row above the reader - the content shifted up by that row's height,
several times a second. Decision (user): keep the old rows and keep
adding below; past ~2,000 rows the view stops taking new ones.

- `ChatBufferCap` (`lib/stores/shared/`): a buffer's cap, 500 normally,
  2,000 while held. Twitch / Kick / YouTube hold the selected channel's
  buffer (`holdScrollback` / `releaseScrollback`; background buffers keep
  500), the combined store holds its merged cut and all three. The rows
  stay in the store, so deletes / bans / tombstones keep reaching them;
  Twitch keeps the delete records of rows dropped past 2,000 until
  release. Release trims back to 500 (the reader is at the bottom then).
- `ChatScrollback` (view side, all four native views): holds while not
  pinned to the newest row, releases on the way back (and on dispose);
  500 rows before the held cap the list stops taking rows - same rows,
  same order, each drawn from the store's latest copy (Kick / YouTube
  deletes swap the row object), a cleared chat empties it; the unread
  pill keeps counting the live ones.
- Combined: the merged cut is anchored at the row that was oldest when
  the hold began - raising its cap used to bring ~500 cut-off rows back
  above the reader (a jump, and a fake "500 new messages").
- Known limit: a Twitch row that dropped out of the store (past 2,000)
  can't be tombstoned anymore - the store ignores deletes for ids it no
  longer has.
- Review fix of the previous entry: the user card's pinned / body /
  footer column is a measuring layout (`_PinnedSheetLayout`) - the
  history keeps at least a third next to a tall footer (small phone,
  large text), instead of vanishing with Sign out overflowing.
- Tests: Twitch view (the read row's position is unchanged across 60
  arrivals at the cap, pill count, trim on return, freeze past the held
  cap), Twitch / Kick / combined store hold + release; user card at 1.6x
  text on a 375x667 screen, Sign out unscrolled at 1.0x.

## 2026-10-04 - Sheet pages hop like Search; user cards pin all but the history; clear platform tabs

User feedback: Search chat's transition (the options slide down, the
search sheet slides up) felt good, every other sub-page swapped content
in the same sheet and jumped to the new height. Decisions: that hop for
every sheet with a back chevron; on user cards only the messages below
LIVE scroll, the self card's account footer pinned under them; the
selected platform tab must read at a glance.

- `showChatSheetRun` (`native_chat_chrome.dart`): a run of sheets that
  replace each other. A sheet pops with the page to show next (its back
  chevron with the page it came from), null ends the run; the returned
  future waits for the last sheet (message selection chrome stays while
  Timeout / Warn is open). `NativeChatSheetBackTitle` is the shared
  chevron + title.
- Runs: native chat options (every page + Search; coming back restores
  the combined chat's platform tab), channel mod sheet (presets,
  Announce; an applied preset returns to the root), combined Moderate (a
  Twitch step opens standalone, back reopens Moderate on the Twitch
  tab), message mod sheets on Twitch (Timeout, Warn), Kick and YouTube
  (Timeout). The in-sheet `AnimatedSwitcher` step swaps and
  `chatSheetPaneTransition` are gone. Swiping a page down closes the run
  (as Search did).
- `NativeChatSheetScaffold` takes `pinned` (between header and body)
  and `footer`: user cards (Twitch / Kick / YouTube) pin facts,
  Highlight / Ignore and LIVE; the Twitch self card pins its account
  footer. Under 320 pt of room (phone in landscape) all of it scrolls
  together; a pinned block taller than half the room scrolls on its own.
- `CombinedPlatformTab`: selected = solid brand fill, glyph + label in
  the color that reads on it (dark on Kick's green); others neutral
  outline, muted label, brand badge.
- Tests: options pages / combined tab restore / channel mod steps /
  mod action steps (mid-hop both sheets, back, opener future), user
  cards (LIVE + footer stay while the history scrolls, landscape
  fallback); shots `options_page_{midway,sheet}`,
  `user_card_youtube_chatty_{scrolled,narrow,tablet,landscape}`,
  `user_card_twitch_self_chatty`.

## 2026-10-04 - Gray headings; YouTube subscriptions never reorder

User feedback on the previous two: the 17 pt headings read like one more
entry; and live subscriptions jumping to the top (after a 15-30 s check
with no sign of it running) hid channels the user was scrolling to.
Decisions: gray bold headings with more room above; A-Z stays put with
a "Live now" filter.

- `nativeChatSheetSectionStyle`: 17/w700 on the secondary text level;
  section headers get `AppSpacing.lg` above (was `sm`).
- YouTube Add chat: the subscriptions list is A-Z, always - LIVE chips
  fill in place. Under the heading: "Checking who's live 48/200" with a
  spinner while the check runs (`YouTubeLiveStatusService.check(
  onProgress:)`), then All / "Live now N" pills (only when someone is
  live) - Live now lists the live ones, most viewers first. Both take
  the same height, so the rows don't shift when one turns into the
  other. The check runs 10 pages at a time (was 6), 30 per videos.list.
- Shot harness: `MaterialApp` keyed per shot - the route was generated
  once per test, so a second `harness.shot` in the same test showed the
  first shot's widget (older multi-shot specs were affected too).
- Tests: `youtube_add_chat_sheet_test` "LIVE + viewers" (A-Z kept,
  Live now order, progress then pills with rows unmoved, no pills when
  nobody is live), service progress; shots
  `add_chat_youtube_{checking_narrow,subscriptions_narrow,live_only}`.

## 2026-10-04 - YouTube Add chat: LIVE + viewers, live subscriptions first

User request: show whether a channel is live and how many watch, in
the YouTube Add chat search. Decisions: search hits + subscriptions;
subscriptions live first, most viewers on top, the rest A-Z.

- `YouTubeLiveStatusService` (`lib/utils/youtube/`): per channel the
  quota-free `/live` page, then one `videos.list?part=liveStreamingDetails`
  per 24 channels (1 unit) - live only when started and not ended (a
  scheduled stream isn't), `concurrentViewers` when not hidden. Answers
  fill in chunk by chunk, are remembered 1 min, stop when the sheet
  closes; failures leave a row as it was (logged via `logFailure`).
- The sheet's rows show `LIVE · 23.5k` (the chip Twitch / Kick rows
  use); a fresh /live answer overrides the search index's LIVE both ways.
- Review fixes: subscriptions reorder once, when the whole list is
  checked (chips fill in place before) and rows are keyed by channel -
  a press during a reorder used to land on whichever channel moved into
  its slot; without an API key `videos.list` reads with the sign-in
  token (`YouTubeChatStore.accessTokenForRead`), with neither nothing is
  read; a `/live` read gives up after 8 s.
- Tests: `youtube_live_status_service_test` (live / scheduled / ended /
  hidden / offline, failures uncached, TTL, chunks + cancel, token
  fallback), `youtube_add_chat_sheet_test` group "LIVE + viewers"
  (ordering, search override, a press across the reorder); shots
  `add_chat_youtube_*` use a fake service.

## 2026-10-04 - Native chat sheets: Search chat back, headings above rows

User report: Search chat (opened from the options sheet) had no way
back; section headings ("All chats", TTS's Who / What / How) were
smaller than the rows under them, in every native chat sheet.

- `showChatSearchSheet(onBack:)`: from the options sheet a back chevron
  (like the options pages') closes the search and reopens the options
  sheet on the chat view (`showNativeChatOptionsSheet`, now shared with
  the bar button).
- `nativeChatSheetSectionStyle` is title3 (17/w600, sentence case)
  instead of the 11 pt caption - every user of it (options sheet, mod /
  bans / combined mod sheets, Add chat sheets, emote pickers) plus TTS's
  own section labels, which now use it.
- Removed leftovers the analyzer flagged from earlier 4.1 commits
  (unused imports / getter / variable).
- Tests: `native_chat_options_sheet_test` back chevron; picker tests read
  the sentence-case group names; shots `tts_settings`,
  `search_combined_hidden_*` (chevron), `options_*`.

## 2026-10-05 - Native chat options: All chats + per platform, combined search

User request: the platform sheets offered more than the combined chat's.
Decisions: "All chats" + platform tabs in combined (like the combined
mod sheet), the same split without tabs per platform, one search over
the whole combined timeline, account rows stay in the chat header.

- `NativeChatOptionsSheet` for every platform: Search chat, "All chats"
  (shared settings), the platform's section; combined: a
  `CombinedPlatformTab` per platform in the combo (shared with the mod
  sheet), pages (Emotes / Badges / Event messages) follow the tab.
- YouTube's own wrapper sheet (whose "Appearance" row opened the whole
  sheet, plus a sign-out row) and the YouTube / Kick option buttons are
  gone - every platform uses `NativeChatOptionsButton`; YouTube's
  "Chat setup" sits in its section.
- `ChatSearchSheet(Combined)` searches `CombinedChatStore.timeline`
  (time order, each match in its platform's row with the badge).
- Review fixes: every search (Twitch / YouTube / Kick / combined) hides
  what the chat hides (ignored users, mute words in hide mode) - with a
  "Show hidden messages" switch (user request; off by default, a line
  counts the left-out matches, shown ones are dimmed) - and draws
  deleted Twitch messages with their marker; the combined row says "in
  the combined chat" (it reaches back as far as that timeline, 500).
- Tests: `native_chat_options_sheet_test` (rows scroll into view now),
  `channel_mod_panels_test` "combined options sheet"; shots `options_*`.

## 2026-10-05 - Highlight / ignore on the YouTube and Kick user cards

User question: why only on Twitch's user card? The lists were shared
and honored by every platform's rows (and the YouTube / Kick long-press
message sheets had the rows) - only the YouTube and Kick cards never got
`ChatUserListActions`. Both cards now show them (not on your own card),
writing YouTube's display name / Kick's username - what those rows are
matched by. Every user card (Twitch too) stops at 2/3 of the screen
(`kChatUserCardMaxHeightFraction`, was 85%); a long history scrolls
under the pinned name. Tests `user_card_list_actions_test` (incl. a
20-message viewer); shots `user_card_*`.
Review fix to the entry below: the instant copy's owner crown follows
the chat the message went to (`isOwnChannel(label)`), not the selection.

## 2026-10-05 - YouTube: own sent message read "Unknown"

User report (dogfood, combined chat of another streamer): a message
sent via YouTube showed "Unknown" as author; the user card had the name.
Root cause: `liveChatMessages.insert` (part=snippet) answers without
`authorDetails`; that answer was appended at once and the poll's full
copy skipped as a duplicate id. Fix: the instant copy carries our
channel id + title (`isChatOwner` when it's our chat), and the poll copy
replaces it (real badges). Twitch / Kick don't append locally - checked.
Test: `youtube_chat_store_test` "own message in someone else's chat".
Checklist row "Own sent message".

## 2026-10-04 - YouTube chat emojis: drawn + emote picker

User request: a YouTube chat showed "Thanks Remy
:medal-yellow-first-red:" as text - render those and add an emote
button for YouTube. Decisions: bundled set + learned live; member
emojis rendered and in the picker ("Members only"); YouTube emojis only
(regular emoji stay on the keyboard); combined chat too.

- Facts (audit § YouTube emojis): the Data API sends only `:code:`;
  images only in the web chat page's data; no public complete list.
- `YouTubeEmojiStore`: bundled standard set (33, `tool/youtube_emoji_harvest`)
  + learned from `/live_chat?v=` on attach and on unknown codes (4 s
  debounce, max every 2 min per stream, quota-free), persisted in the
  untyped `youtube-emojis` box (member emojis capped at 1,500).
- Rendering in `YouTubeChatMessageRow` (chat, combined, search, user
  card, Super Chat / milestone comments) via `youTubeEmojiTextSpans`;
  rows watch the catalog only when they hold a code.
- Picker (`YouTubeEmotePickerSheet`) in the native YouTube input and
  for a YouTube target in combined chat; Kick's dock button became the
  shared `EmotePickerDockButton`.
- `videos.list` asks `snippet,liveStreamingDetails` (still 1 unit) for
  the broadcasting channel (member section).
- TTS: `:codes:` are emote parts.
- Review fixes: member codes resolve only in their own channel's chat
  (`:_omg:` exists in many channels; standard codes stay global); the
  picker's Recent is a snapshot (no grid moving under the finger); a
  code a page read didn't resolve never triggers another read of that
  stream (hand-typed `:skull:` was ~7 MB/h); a page without chat data is
  logged; YouTube input + picker + send stop at 200 characters
  (YouTube's chat limit - not in the API reference).
- Bundle: 65 of YouTube's public set, harvested from the busiest live
  chats' full Live chat view (member emojis are never bundled - the app
  learns them per chat); missing ones are learned at runtime.
- Tests: `youtube_emoji_test`, `youtube_emoji_ui_test`, store + TTS
  additions; shots `youtube_emoji_*` (placeholder circles - no YouTube
  artwork in the repo).

## 2026-10-04 - 4.0.1 live on both stores

4.0.1 build 2026093001 (the `ws://` domain-mode hotfix + connection
review, see 2026-09-30) released: App Store via `release publish ios
--version 4.0.1` (new option - `publish` used pubspec's version, which
was already 4.1.0), Play by the user in the Play Console (managed
publishing), production at 100%. Tag `4.0.1` on `35a0040f`. Nothing odd
on either store. Watch: crash reports and reviews for 4.0.1; 4.1.0
build 2026100401 is on TestFlight + Play internal for testing.

## 2026-10-04 - activity filters: hidden rows stay new, honest empty state

Filter chip check after the status banner work. Leaving the feed marked
*everything* seen, also rows the chip / "To thank" hid - with "Money"
picked in the Chat tab, the streaming "N new" chip's sheet showed only
money and the hidden follows / subs were gone from the badge unseen.
Now only what the view could show is seen (per-channel high-water mark
stops below the oldest hidden unseen row; "Mark all as seen" stays the
full reset). The To-thank empty state no longer says "All thanked" under
a chip while others wait ("Nothing to thank here - N more under All").
Checked fine: every kind's chip (Power-ups / KICKs / stickers / charity
= Money, YouTube member kinds = Subs, Kick host = Raids, hype trains =
Points), "Mark N thanked" marks only the rows the chip shows, gap
markers and the banner under filters. Tests in `activity_store_test`
(matrix + seen) and `activity_ui_test`; shots `activity_feed_subs_gap`,
`activity_feed_filter_empty`.

## 2026-10-04 - one Pro story: paywall, locked panes, store, website

User request: the shared Pro locked pane, the paywall and the marketing
side tell the same "what Pro does" story. Decisions: 5 grouped paywall
cards, hero line names supporters + TTS, locked panes list the same
group titles (max 4, minus their own), website Pro list grouped (text
only, stays in `obs-blade-site/pending-4.1/`).

- Groups (`ProFeature`, `kProBenefits` order = importance): Every Chat,
  One Place (native + combined + emotes, badges, highlights, search) ·
  Never Miss a Supporter (activity feed) · Hear Your Chat (TTS) ·
  Moderate From Your Pocket · Your Own Themes (renamed from "Make It
  Yours", which the intro and website use for the free customisation).
  `proBenefitTaste(except:)` feeds `ProLockedPane`.
- Store descriptions (iOS + Play) group the Pro list under the same
  names; promo text and FAQ no longer claim "tips" (no tip source is
  built - StreamElements / Streamlabs are still waiting on API access).
- Tablet benefit grid: an odd last card lines up with the column above.
- Privacy policy (live site, deployed 2026-10-04): the activity feed line
  lists what is really kept (follows, subs, raids, cheers, Super Chats,
  KICKs) instead of "tips"; "Last updated" 4 October 2026.
- Tests: `test/pro/pro_story_test.dart`; shots `pro_locked_*`,
  `pro_benefits_*`.

## 2026-10-04 - activity feed: status banner, own YouTube, gaps

From the 2026-10-03 activity review (six findings, all built; spec
`superpowers/specs/2026-10-04-activity-feed-status.md`). User decisions:
own-YouTube detection by OBS + quota-free check, own chat always polled
while live, gaps in the banner + a list marker, banner tucked when calm.

- **Status banner** floating over the feed list (pinned-banner style):
  tucked button (dot = news since last opened), a new action line pops
  it out as one line, tap expands every line with its fix, X tucks;
  seen lines persist (`activity-meta` `statusSeen`). Pure builder
  `lib/utils/activity/activity_status.dart`, matrix-tested; replaces the
  old notices row.
- **Own YouTube without the chat** (`YouTubeOwnActivityPoller`): signed
  in with a channel + Pro; `/live` check (~3 KB with the mobile UA) every
  2 min in the foreground, 30 s while OBS streams to YouTube or somewhere
  unknown; once live `liveChatMessages.list` every 30 s (~600 units/h);
  stands by while the YouTube chat reads the own chat. API key only:
  the banner says sign-in is needed (the key can't tell which channel is
  yours). Sessions start at `actualStartTime`.
- **OBS destination** (`GetStreamServiceSettings`, key never kept):
  "You're live on YouTube / Twitch - set up / sign in" lines.
- **Power-ups**: `channel.bits.use` replaces `channel.cheer` (same
  `bits:read`, no new sign-in).
- **Honest coverage**: a kill closes windows at the last heartbeat (was:
  the next launch, claiming the downtime); a tick lagging > 75 s (iOS
  suspension) splits open windows - except YouTube, whose page token
  catches up. `gapsOf(session)` → banner lines + "Not listening on …"
  rows. YouTube attaches count 2 min back (first page = recent history).
- **Mark N thanked** per stream / day header; the empty state follows
  sign-ins (it read them outside an Observer - stale on a tablet).

Fresh-context review fixes: the poller attaches only to a started
broadcast (`actualStartTime`; an upcoming stream's waiting-room chat
made a fake session and burned quota), ignores answers that land after
it was switched off; the coverage cap (500 windows, seam merge) records
where history was cut so old streams get no invented gaps; "signed in
without a channel" is mirrored to the settings box so the banner knows
it after a restart; the banner's YouTube "Sign in" starts Google's
sign-in instead of opening the OAuth client form.

Tests: `youtube_own_activity_poller_test.dart`, `activity_status_test.dart`,
store gap / freeze / kill tests; shots in `activity_shots_test.dart`
(`activity_status_*`). Gate: activity + chat + persistence 1,640 clean.

## 2026-10-03 - native chat bar: the channel dropdown fills its row

User request: with sign-out in the header sheet, the native bar's right
side is only options (+ the mod shield), yet the channel dropdown stayed
in the left column (max 256 pt, about half the bar) - long names and the
menu's LIVE / OFFLINE chips were cut. Native mode is now two rows:
platform dropdown + engine switch, then the channel dropdown filling all
the width the right cluster leaves (the menu matches the button, so the
chips get it too). User decisions: fill on tablets too (no cap), WebView
mode keeps its two columns. Signed out: the cluster is capped at 60% of
the row and the sign-in pills hug their content (their full-width
`Align` left a gap next to the options button); without a dropdown
(Twitch signed out) options + pill sit right. Tests:
`channel_mod_entry_test.dart` (row geometry at 320 / 400 / 800 pt, the
signed-out pill); shots: `chat_bar_shots_test.dart` (long names, phone /
narrow / tablet, open Kick menu, signed out). Review fix: native and WebView
build different trees, which rebuilt the engine switch on every swap (a
tap jumped instead of sliding) - a per-bar `GlobalKey` keeps it.

## 2026-10-03 - YouTube + Kick Add chat sheets (search, suggestions)

User request: native YouTube (with an API key) and Kick get an Add chat
sheet like Twitch's instead of the plain dialog. Decisions: Kick sheet
always (its search needs no sign-in), YouTube type-ahead search, Kick
shows "Popular live now" when empty, native chat + combo builder only
(WebView keeps the dialogs; YouTube without a key keeps the dialog).

- Shared sheet pieces (`dialogs/add_chat_sheet_chrome.dart`), Twitch's
  sheet moved onto them unchanged.
- YouTube (`youtube_add_chat_sheet.dart`, `YouTubeChannelSearchService`):
  subscriptions when signed in with a channel; `search.list` type-ahead
  (700 ms, 3+ chars, cached; its own 100/day bucket, never chat quota) with
  LIVE, `@handle` + subscribers via one `channels.list`; links / handles /
  video ids taken as is; used-up searches say so and offer `@<word>`.
  Picks stored by `UC…` id under the channel title; native only (the
  WebView selection is left alone).
- Kick (`kick_add_chat_sheet.dart`): anonymous website search (LIVE,
  verified, followers); signed in: official live listing in the device
  language (falls back to all, mature streams dropped); links taken as is;
  the typed slug offered when search fails / finds nothing. No follows API
  exists (website session only).
- Journey walk fixes: a dead session while loading subscriptions / the
  live listing signs out (no endless Retry); a pasted `UC…` id isn't shown
  as a name; YouTube search failures reach Settings → Logs.
- Fresh-context review fixes: `@handle` vs `UC…` forms of one channel
  never matched (a subscription already listed by handle came back as a
  second entry, an own `@handle` added a plain copy) - picks carry the
  other form as an alias (search hit handle / `forHandle` lookup); names
  with "." or "/" ("Mr. Beast") are searched, not taken as links; search
  cache expires after 10 min (stale LIVE).
- Facts: `kick-chat-audit.md` § Channel discovery,
  `youtube-native-chat-audit.md` § Channel discovery. Shots:
  `tool/widget_shots/add_chat_shots_test.dart`.
- Not verified live: YouTube search / subscriptions (no key on the
  maintainer machine) - documented shapes; check on device.

## 2026-10-03 - combo builder "Other…" reuses the platforms' own pickers

User request: adding a channel that isn't listed yet in the combined chat
builder opened a bare text dialog. "Other … channel…" now opens what the
platform's own chat uses (user decisions): Twitch's Add chat sheet in a
pick mode (follows, moderated, live tags, search; the tapped channel is
the pick, nothing greyed out, nothing added to the Twitch list until the
combo is saved - signed out: "Sign in to Twitch to find channels"), the
YouTube / Kick add dialogs (they add to their list as on the platform;
the WebView chat's selection they also set is put back). The dialogs now
return what they saved. Kick has no follow / mod list API and YouTube no
"channels I moderate" one - their dialogs stay what the platform uses.

## 2026-10-03 - chat bar: no account chip, the mod shield fits on phones

Dogfood (TestFlight build 2026100304): the signed-in YouTube chat had no
mod shield and no Moderation entry in its options, while Twitch in the
same space had one. The fit check reserved a fixed 140pt for the YouTube /
Kick account chip (Twitch measured its name), so on phones the shield was
always dropped - and only Twitch folds Mod into its options.

User decision: drop the signed-in account chip on every platform (the
chat header already shows the account). Signed in, the right side is
shield + options (~96pt, fits a 320pt phone); signed out keeps the sign-in
/ setup pills. Sign-out moved: the header sheet's healthy state has a
Sign out row (YouTube, Kick - Kick's sheet now shows the account; Twitch's
header opens the self card); the degraded state no longer shows a dead
Log out row without a session. Dogfood (build 5): the Twitch self card
only offered sign-out while degraded - it has Sign out while live now too. A
state matrix over both sheets found one more: signed in with the Twitch
chat offline, the self card said "connect your Twitch account" with no
Sign out - it offers Reconnect + Sign out now; the header sheet shows Sign
out whenever signed in (no longer only with an offline note). Widget test at phone width
reproduces the missing shield; shots in `tool/widget_shots/chat_bar_shots_test.dart`.

## 2026-10-03 - chat review fixes (`/code-review high` + journey walk)

A `/code-review high` plus a walk of every chat journey against
`chat-journey-checklist.md` and the platforms' current docs turned up 8
verified findings; all fixed (`5e72ca18..`). Not on a device yet (the
dogfood phone was offline) - device check list in the session report.

- **YouTube quota vs throttle:** `rateLimitExceeded` on
  `liveChatMessages.list` means "polled too soon" (Google's errors table),
  not a used-up quota - it backs off now instead of stopping the chat for
  the day. Polls wait the full interval from the answer; a resumed poll
  (switch back, un-pause, app resume) waits out the rest. A real quota
  stop restarts after midnight PT (timer + app resume), says so, and is
  logged. The resume hook moved app-wide (`LifecycleWatcher`) - the Chat
  tab runs without an OBS dashboard.
- **No chats started at launch:** `CombinedChatStore` (created at app
  start) read its sources in a reaction, which created all three platform
  stores - Pro users got a hidden YouTube poll on their API quota and a
  Kick socket + polls, whatever chat was open. The reaction now reads only
  while Combined is active.
- **Own YouTube channel in saved combos** resolves to "You" (activity
  feed rows, session tracking, owner-only moderators) instead of a plain
  copy; copies older builds added for combos are removed once the own
  channel is known (user decision), selection / restore point move to "You".
- **Names, never ids:** the WebView waiting panel (free users) names the
  entry; the combo builder's "Other…" YouTube pick is named by the channel
  title (`YouTubeEntryNamer`); `/live` lookup errors carry no id.
- **Activity empty state** counts a signed-in YouTube channel.
- **Adding a channel shows it** (Kick "can't be found" → Add, Kick /
  YouTube channel menus).
- **YouTube session edges:** a dead refresh token on a write ends the
  session (was "Could not send" forever); a Data API 401 expires the token
  and isn't "not a moderator". A Google account without a channel is
  read-only everywhere with "Switch account" (input strip, header sheet,
  chip, options, combined sources / mod sheets - user decision).
- **Siblings:** combined mod sheet "Sign in to YouTube / Kick" for saved
  combos only retried - opens sign-in now; the shared read-only strip
  overflowed narrow phones - wraps; the combo builder's "Other…" dialog
  disposed its controller mid-animation.
- **Logs:** Kick socket, Twitch EventSub (token refresh, chat subscription,
  dropped events, revocations), IRC sidecar and combined restore failures
  reach Settings → Logs.
- Checklist rows added (throttle ≠ quota, stores start chats, own channel
  in combos, adding shows it, fix buttons in saved combos); facts in
  `youtube-native-chat-audit.md`.
- **Fresh-context review** of the above found 4 more, fixed: combo YouTube
  sources carry `own: true` (signed out / another account → "Sign in",
  never a list copy; older combos get the flag once the own channel is
  known) and a non-own channel removed from the list is re-added when the
  combo is used (was a "Set up" button that did nothing); the copy cleanup
  keeps the entry the WebView engine has selected; the builder's "Other…"
  YouTube lookup shows progress, holds Save, drops a late result after a
  newer pick, says "not found" for a handle without a channel page and
  never overwrites another entry's label; a Data API 401 with no refresh
  token ends the session.

## 2026-10-03 - `feature-work` skill, chat journey checklist, chat logs

Six chat / sign-in misses reached the user past two `/code-review high`
runs (entries below). None was wrong code - each was a wrong assumption,
shared by the code and its tests - so the process changed, not the review
count:

- **`obs-feature` → `feature-work`** (`.claude/skills/feature-work/`):
  generic - OBS, dashboard, chat, sign-ins - and for changes / fixes to
  existing features too (reproduce with real data, name the class of the
  miss, fix its siblings). New phase 0: clarify the request with the
  user (states, platforms, scope, taste) instead of assuming; new last
  phase: a device check list, store test builds only after the user's
  on-device OK. `AGENTS.md` § Definition of done follows it.
- **`docs/chat-journey-checklist.md`:** account states per platform
  (incl. API-key-only, Brand Account without channel, Testing-mode 7-day
  tokens), channel cases (never a `UC…` id as a name), entry points that
  must agree, shared components walked per platform, console steps
  against current docs, honest fakes, logging, device check, release.
- **Logs:** `GeneralHelper.logFailure` - the chat / activity / TTS
  stores' 106 console-only failure logs now reach Settings → Logs
  (message + HTTP status only, tokens / secrets / long opaque strings
  masked, each kind at most once per 5 min). The YouTube no-channel
  sign-in is logged too.
- **Fakes:** real `channels.list?mine=true` answer shapes (no `items`
  key for an account without a channel), and an account-variant matrix
  over sign-in (title / no title / Brand Account / failed lookup) that
  checks state and that no name is a bare `UC…` id.

## 2026-10-03 - YouTube own chat: brand accounts, channel names, header sheet

Dogfood (Kounex iOS), three findings around the signed-in YouTube chat:

- **No "You" after sign-in:** the token was fine (scope `youtube`), but
  `channels.list?mine=true` returned 0 items - the user picked the
  personal Google account, the channel is a **Brand Account**. Picking
  the channel at Google's account step fixed it. The app now says so:
  `YouTubeChatStore.signedInWithoutChannel` (set only when the lookup
  answered with no channel, not on a failed lookup; cleared on sign-in /
  sign-out), and the sign-in dialog stays open with the explanation +
  "Sign in again" (signs out, restarts the device flow) / "Keep".
  Diagnosed by pulling `youtube-auth.hive` with `devicectl device copy
  from --domain-type appDataContainer` (Documents) and replaying the call
  - `GeneralHelper.advLog` only prints, it never reaches the app log.
- **"UCKp5… isn't live right now":** the empty-chat copy used the
  target's form (a bare `UC…` id for the own entry); it now uses the
  entry's name (own entry: channel title). Same slip in the combined
  builder's cross-platform name search (a `UC…` id falls back to the
  pick's label).
- **Header sheet said "Not connected" while signed in:** the sheet read
  the chat state as the account state - right for Twitch (offline =
  signed out), wrong for YouTube / Kick, which read without an account.
  `NativeChatWindow.offlineNote` / `connectLabel`: YouTube explains the
  chat ("<name> isn't live right now…", no channel picked, video without
  chat), shows "Signed in as …" + Sign out when signed in, and "Sign in
  to write and moderate" when read-only; Kick: channel not found / no
  channel picked + "Add Kick channel".
- Test fixes on the way: widget tests that sign in need real time
  between pumps (Hive writes) and an `isProResolver` (no ProStore in
  GetIt) - the earlier Save & connect test had silently ended in the
  error state.

## 2026-10-03 - Kick client secret rotated

The old secret shipped in store builds (entry below). 4.0.x builds could
not complete a Kick sign-in anyway (secret compiled in = no exchange-host
registration and no polling; the paste field is hidden for the app
client), so rotating cost released users nothing.

- The user rotated it in Kick's developer settings; new value in
  `docs/private/kick_oauth_server.json` (synced, checksums match).
- Checked with Kick before the swap (secrets over stdin, never argv):
  new secret → client credentials 200, old → 401 `invalid_client`.
- Hetzner `/etc/kick-auth.env` (shared by `kick-auth` and
  `kick-events`) updated in place, both units restarted; the temporary
  backup holding the old value deleted.
- Verified: both kick-auth hosts pass Kick's client check (dummy refresh
  token → `invalid_grant`, not `invalid_client`); the events relay's
  health is ok, no reconcile failures, and the app's 7 webhook
  subscriptions list fine with the new secret.
- Runbook for next time: test the new secret with client credentials
  from Hetzner, swap the one line, restart both units, probe as above.
- Slip: a probe printed 43 of 48 characters of one app access token
  (client credentials, valid 60 days) into the local session output -
  the redaction ran after a truncation. App-level only (webhook
  subscriptions, public reads), not a user token. Redact before
  truncating.

## 2026-10-03 - YouTube read-only setups: explain, then the sign-in part only

Dogfood report (4.1.0 TestFlight): with only an API key, "Connect
YouTube" (setup sheet, chat bar pill, options "Sign in with Google")
started the device flow and failed straight into "No Google OAuth client
id configured"; the bar pill kept reopening that.

- `YouTubeChatStore.canSignIn` (OAuth client id resolved).
  `startYouTubeLogin` without it shows `YouTubeReadOnlyDialog` (reading
  works with the key; writing, moderating and the own "You" chat need a
  Google sign-in with the user's own OAuth client) with "Add sign-in".
- `showYouTubeSignInSheet`: the setup sheet with `signInOnly` - steps
  (consent screen + test user, "TVs and Limited Input" client), console
  link, client id / secret, Save / Save & connect (needs a client id).
  The bar's Connect pill opens it directly while read-only. The full
  sheet stays in the YouTube chat options ("Chat setup").
- The own "You" chat needs the sign-in: an API key identifies a Cloud
  project, not a YouTube account (`channels.list?mine=true` is OAuth-only).
- Tests in `youtube_setup_sheet_test.dart`, shots
  `tool/widget_shots/youtube_sign_in_shots_test.dart`.
- Follow-up (first real setup hit "configure your consent screen
  first"): the steps now follow today's console - the API's own
  Credentials page (`kYouTubeApiCredentialsUrl`), consent screen via
  Google Auth Platform "Get started" (External), Audience → Test users,
  then the "TVs and Limited Input devices" client; the API key steps link
  the API's library page (Enable). Same steps in the full sheet's advanced
  section. Tip: "Testing" apps get 7-day refresh tokens (Google OAuth
  docs) - "Publish app" avoids weekly sign-outs. Verified: the `youtube`
  scope is on Google's device-flow allow list; the token poll needs the
  client secret.

## 2026-10-03 - Kick sign-in: client secret was compiled into store builds

The 4.1.0 TestFlight build (2026100301) ended Kick sign-in on
`kick-auth.obs-blade.com`'s "Kick did not approve the login" page.
Cause: `docs/private/kick_oauth.json` (since 2026-09-22) held the client
**secret** next to the id, and `tool/release` compiles that file in. With
a secret compiled in, the app skips the exchange host (no
`/oauth/session` registration, paste flow), so the host saw an unknown
state on Kick's redirect (400 page). Checked: the secret is in plain text
in the 4.1.0 ipa (`App.framework/App`) and aab (`libapp.so`, all ABIs).
The release tool passed the same file for 4.0.0 / 4.0.1, so those store
builds very likely carry it too.

- `kick_oauth.json` now holds the client id only; the secret moved to
  `docs/private/kick_oauth_server.json` (host env only, never a define).
- `release preflight` refuses a defines file with any non-empty
  `*SECRET*` key (`Project.forbiddenDefines`, tests).
- Host flow verified with curl: register 204 → poll 202 → callback 302 →
  Kick exchange → poll result; unknown state → the 400 page.
- 4.1.0 rebuilt as 2026100302 without the secret.
- Open: rotating the Kick client secret (it is extractable from the
  shipped binaries) - user decision, see handoff.

## 2026-10-03 - 4.1.0 beta: Pro copy, store listings, release notes

4.1.0 (2026100301) built for dogfooding: TestFlight internal + Play
internal. Nothing submitted for review; 4.0.1 is still in review on iOS.

- **Paywall:** two new benefit cards - "Never Miss a Supporter"
  (activity feed, amber `ProPalette.activity`, black glyph 9.8:1) and
  "Hear Your Chat" (TTS, blue `ProPalette.speech`, white 5.0:1), placed
  2nd/3rd so the native-chat upsell (`kProBenefits.skip(1).take(3)`)
  now names them. Six cards: phone carousel, 3x2 tablet grid. Shot spec
  `tool/widget_shots/pro_shots_test.dart`. Welcome-to-Pro + FAQ "What
  does Pro unlock" name both.
- **Store listings:** description (both stores) gets the two Pro
  bullets + a free canvas bullet; iOS promo text announces 4.1. They
  go up with `release metadata ios|android` at promote (the promote
  skill now covers the Play listing too).
- **Release notes:** store text in the usual two files (486/500).
  New: TestFlight "What to Test" from `fastlane/testflight_notes.txt`
  (Fastfile falls back to the iOS notes) - a tester checklist that never
  reaches the listing. Rewrite it each beta (playbook § Release notes).
- **Website (maintainer):** privacy policy now covers the Kick events
  relay (`kick-events.obs-blade.com`: token used once, channel id/name,
  hashed session keys, events 7 days, 30-day idle removal, method/path/
  status logs), `kick-auth.obs-blade.com`, on-device activity data and
  Android network TTS voices - deployed. The landing page's 4.1 feature
  copy waits for the store release.
- Build machine: a stale pre-SPM `macos/Podfile` (Aug) failed the
  clean-tree preflight; moved out of the clone.

## 2026-10-03 - Activity feed review fixes (`/code-review high`)

Fixes from a high-effort review of the activity feed + Kick relay:
- **Relay client:** a failed WebSocket upgrade counts as "unknown
  session" only on a real 401 status (`WebSocketException.httpStatusCode`).
  The old check matched "401" in the error text, which holds the URL, so
  a cursor like `after=14017` plus any 502/429 dropped a valid session and
  replayed the whole 7-day backlog.
- **Relay server (needs a redeploy):** `reconcile()` read the registered
  channels before its ensure loop and deleted the fresh subscriptions of
  a channel that signed in meanwhile. `subscribed` now means *every*
  event is subscribed, and open sockets get a `status` frame when that
  changes.
- **Ownership:** the relay owns Kick sub / gift / redemption rows only
  while it reports full subscriptions (`ActivityStore.relaySubscribed`,
  shown in the options sheet), so Pusher's copies are no longer dropped
  for kinds Kick never delivers by webhook.
- **Sessions:** a replayed relay status from before the newest session
  is ignored (it reopened today's session and moved its start days back);
  reaching back never crosses into the previous session; a killed
  session ends at the heartbeat only if that heartbeat is from this
  session, and opening a session writes one right away.
- **History / delete:** clearing history moves the follower-backfill
  floor so cleared follows don't come back; a relay sign-in still in
  flight when the user deletes all data, signs out or turns the relay off
  unregisters its new session instead of storing it.
- **UI:** the feed list builds rows lazily (`ListView.builder`, up to
  5,000 rows); day labels count calendar days (DST days read
  "Yesterday" correctly); `gift_paid_upgrade` names the gifter.
- Not a bug: `endVisit()` in the feed's `dispose()` - flutter_mobx defers
  an Observer's rebuild past the frame, so no locked-tree assert.

## 2026-10-03 - Global Pro pricing overhaul (both stores re-priced)

A Turkish buyer got Pro monthly for ~0.80 EUR. Root cause chain, found by
auditing every live price on both stores against Google's conversion table
and independent FX rates (`tool/provisioning/bin/audit_prices.dart`):
1. `asc-products`' nominal-parity rule was currency-blind — a literal 4.99
   in TRY/EGP/ZAR/... (~12 weak currencies).
2. Apple's equalized-tier matrix (the fallback that priced TRY at ~$0.90)
   deviates >20% from FX+tax reality in ~30 currencies in BOTH directions
   (DKK yearly came out at ~$153 for a $49.99 sub).
3. Play inherited Apple's matrix via `--price-source apple`.

Fix: both stores now price from ONE checked-in, reviewed table
(`tool/provisioning/lib/src/pricing_targets.dart`) generated from Google's
`convertRegionPrices` (table version 2026/01 — FX-current, tax-aware,
market-rounded; `bin/generate_pricing_targets.dart`). Anchors USD/EUR/GBP
stay at the nominal 4.99/49.99/99.99; CNY keeps Apple's China pricing (no
Play there); CHF is split per territory (CH/LI price differently on
Google). Over-priced markets (DKK/NOK/SEK/HKD/TWD/COP/ILS/THB) were
corrected DOWN, under-priced ones (TRY/EGP/JPY/...) up. The iOS lifetime
IAP stays on Apple's auto-equalized schedule (that one IS FX-current).
`asc-products` snaps table values to the nearest App Store price point
(>2% deviations are called out); `play-products` pins exact values per
region with the table's regionsVersion.

Live-run gotcha: Apple rejects immediate price POSTs on an APPROVED
subscription (409 STATE_ERROR "Initial price cannot be created again
after subscription is approved") — those territories get a scheduled
price change instead (startDate +2 days, the soonest Apple schedules;
`preserveCurrentPrice: true` — existing subscribers grandfathered, only
new buyers see the new price; the response marks the CURRENT price
record `preserved: true`). Also verified live: the API allows only ONE
future price per territory (a second POST 409s with "You cannot create
more than one future prices" — re-scheduling means DELETE +
re-POST, so the startDate can't be moved earlier cheaply). The single
existing subscriber (Turkish, Play monthly at the old cheap price)
keeps their price. Play takes base plan price updates on ACTIVE plans
directly.

Refresh cadence: re-run the audit + generator when FX moves
(quarterly-ish); workflow in `tool/provisioning/README.md` § Pricing
table. Verification: post-run audit + `inspect_products.dart` parity.

## 2026-10-03 - Kick services on obs-blade.com

The first webhook test delivered nothing: kounex.com runs Cloudflare
Bot Fight Mode (Free plan, zone-wide, no per-host exception), which
answers datacenter clients - Kick's webhook servers - with a 403 JS
challenge. Browsers and phones on home / mobile networks pass, so Kick
sign-in kept working. Moved to the new obs-blade.com zone (no such
check, verified from Hetzner):
- `kick-events.obs-blade.com` is the relay host (the kounex.com one is
  gone - no released app used it). Kick's webhook URL:
  `https://kick-events.obs-blade.com/kick/webhook`.
- `kick-auth.obs-blade.com` serves the token exchange next to
  `kick-auth.kounex.com`, which stays for app versions in the stores.
  New builds post there (`kKickTokenProxyUrl`). The proxy accepts both
  callback URLs (`KICK_OAUTH_REDIRECT_URIS`) and picks the one matching
  the callback's Host header (cloudflared passes it through - checked
  with a temporary echo route). Both callbacks are registered on the
  Kick app (it allows several); new builds use the obs-blade.com one.
  Kick only checks the redirect after the login form, so the first real
  sign-in with a new build is the proof.
- Delivery verified with temporary subscriptions on a big live channel
  (removed after): 1,143 deliveries in a minute, all signature-checked.
  Fixed on the way: the webhook handler read the body with
  `content.read(n)`, which returns only what has arrived - deliveries
  split over network chunks failed their signature (regression test).
  The KickDevDocs key stays as a fallback after the live one. An
  off-by-default `KICK_EVENTS_DEBUG_DIR` keeps the first 10 rejected
  deliveries for diagnosis.

## 2026-10-03 - Activity feed v1 + Kick events relay

Everything that happens on the user's own channels in one feed, with
seen + thanked tracking. Spec:
`superpowers/specs/2026-10-02-activity-feed-design.md`, background and
the third-party plan: `activity-feed-idea.md`. Pro (the native engines
behind it are).

- **Surfaces:** Chat tab gets a Chat | Activity segment (phone; the chat
  stays mounted offstage, the choice persists in
  `ActivityChatTabSegment`), tablet Pro shows both side by side; a bell
  with the unseen count in every native chat header (switches the
  segment in the Chat tab, opens a sheet elsewhere, hidden when the feed
  is beside it); "N new" chip on the streaming-mode preview.
- **Feed:** grouped by stream session ("Live now" / past streams, totals
  per currency / bits / KICKs, never converted) and by day outside
  sessions; filters All / Money / Subs / Follows / Raids / Points;
  "To thank" toggle; swipe = thanked; tap = the person's history with
  "mark all thanked"; "New since you last looked" divider (frozen while
  on screen, everything shown is seen on leave). Options: mark all seen,
  Kick relay switch, clear history.
- **Store:** `ActivityStore` + `ActivityLedger` (`lib/utils/activity/`).
  Two untyped JSON boxes (`activity-events`, `activity-meta`) - no new
  TypeID or adapter. 30 days / 5,000 rows. Sessions from Twitch / YouTube
  / Kick / relay / OBS live signals, start at the platform's own stream
  start (Helix `started_at`, relay `started_at`), 10 min grace, a killed
  app's open session ends at the last heartbeat.
- **Dedup:** each (platform, kind) has a source priority (native, Kick
  relay, StreamElements, Streamlabs - the last two are seams only, ready
  for their API approval). Same id → update; same person + kind + amount
  within 2 min from another source → merge (better source's payload
  wins); a better source covering the channel at that time → drop.
- **Twitch:** own-channel EventSub `channel.follow` v2, `channel.cheer`,
  points redemption add, hype train v2 begin/progress/end - each only
  with its scope. New `kTwitchActivityScopes` (bits:read,
  channel:read:redemptions, channel:read:hype_train) in the device flow;
  older tokens get a "sign in again" notice in the feed. Own chat notices
  (subs, gifts, raids, charity) also while another channel is viewed:
  an own-scoped `channel.chat.notification` sub, created only while away
  (same condition = 409) and dropped before switching back; those
  notices never land in the viewed channel's chat. Follower backfill
  (Helix `channels/followers`, never older than the feed's first run).
  Pro + signed-in users get the Twitch / Kick stores at launch so the
  feed collects without opening chat (YouTube stays lazy - quota).
- **YouTube:** super chats / stickers / memberships / milestones /
  gifting of the own broadcast.
- **Kick:** Pusher sub / gift / host on the own channel (lowest
  priority), plus the relay below for follows, KICKs, subs, gifts,
  redemptions and stream status.
- **Kick events relay** (`tool/kick_events_relay/`, deployed at
  `kick-events.kounex.com` on the Hetzner host, quadlet next to
  `kick-auth`): verifies Kick's RSA signatures (the live public key
  differs from the one printed in KickDevDocs - fetched at start and
  every 6 h), dedupes on message id, keeps 7 days for channels with an
  app session, WebSocket + catch-up GET with a cursor, app-token
  subscriptions (no new user scope), reconcile every 15 min, channels
  without a check-in for 30 days are unsubscribed and deleted. The
  user's Kick token is only used once to look up their channel. 21
  Python tests run in the image (`podman build --target test`). On the
  fleet board with kick-auth. Kick's developer settings must point the
  webhook URL at `https://kick-events.kounex.com/kick/webhook` (user
  action).

Tests: `test/activity/` (ledger, mappers, store, EventSub routing, relay
client, UI), shots in `tool/widget_shots/activity_shots_test.dart`.

Fresh-context review (same day) - 11 findings, all real, all fixed:
the relay session was dropped on every launch (the Kick store's own
slug is null until its async auth restore - sign-out is now read from
the auth box); relay backlog stream status now ends sessions at the
reported end and a restart during the same broadcast continues its
session; feed visits are counted and follow the active tab + app
lifecycle (tabs stay mounted in an `IndexedStack`); "Delete all data"
clears the activity boxes and the relay session; switching Kick
accounts stops the old relay socket; feed sub-widgets got their own
Observers; stores attach only after the boxes loaded; hype trains left
the to-thank queue; relay: stream loop no longer drops an item when two
futures finish together, sessions per channel capped at 10. Not changed:
a re-follow stays one row (follows key on the follower).
Not built: StreamElements / Streamlabs clients (API approval pending),
push notifications while closed, end-of-stream recap.

## 2026-10-02 - Native chat review fixes

A `/code-review high` of native chat (Twitch / YouTube / Kick stores,
sockets, settings, mod sheets, combined chat) reported 10 issues; 8 were
real and are fixed, each with a test that fails on the old code:
- **Twitch overlapping switches:** `selectChannel` runs one switch at a
  time and the latest pick wins (`_activeChannelSwitch`). Two at once
  filed one channel's messages under the other and leaked an EventSub
  subscription (fast dropdown taps, leaving Combined mid-switch).
- **Twitch room mod state:** a switch drops chat settings / Shield Mode /
  ban inbox of the previous channel; reads that come back for another
  channel are ignored, so the mod sheet never shows or patches channel
  A's modes on channel B.
- **Twitch live status:** `/streams` asks for `first=100` - Helix pages 20
  by default, so live channels past 20 read OFFLINE.
- **Cold start offline:** Twitch and Kick keep the stored session on a
  transient failure (offline, 5xx) instead of a login prompt. Twitch:
  EventSub retries the socket on its own, a failed refresh offers retry,
  the moderated-channel list refetches on connect. Kick: an offline
  refresh used to throw out of `init`, so even anonymous reads never
  started.
- **Kick socket:** one socket at a time - a failure fired both onError
  and onDone (two reconnects, notices doubled, an older socket + ping
  timer leaked), and a reconnect pending from before `disconnect` opened
  a second socket after the next `connect` (`_session`).
- **Combined restore race:** leaving drops each restore point only after
  its platform is back, and a new `activate` stops the old restore loop.
  Before, coming back mid-restore saved the combo's channel as the
  channel to return to.
- **YouTube after sign-out:** logout / dead token / wiped box restart
  reading an added channel (only the API key is needed); it stayed idle.
- **Silent sends:** Kick sends no longer wait for the socket (REST); Kick
  and YouTube say why a send can't go out (not resolved / not attached /
  no live stream) and clear that once the chat connects.
Not real: the Kick refresh race (`KickAuthService.refreshToken` already
shares one refresh), and the Twitch dead-session chat wipe (the auth-box
watcher already wipes it; the wipe is now also explicit).

## 2026-10-02 - Chat TTS review fixes

A `/code-review high` of the whole TTS feature (Dart + both bridges + the
sheet) found 10 issues, all fixed:
- **Numbers:** the spam-run rule (4+ same character -> 3) skips digits -
  "10000 bits" was read as "1000".
- **One-word spam combined:** "KEKW KEKW KEKW" combines as "KEKW" with
  its repeats counted (`ChatTtsSpoken.combineText` / `repeats`) - it read
  "KEKW 3 times 4 times"; a count inside a longer message isn't combined.
- **Audio taken (phone call):** `ChatTtsSpeaker.speak` returns false when
  the audio is taken; the queue keeps the message and retries every 2 s
  (`ChatTtsQueue.busyRetry`). Android: the focus request result is
  checked and a focus-change listener cuts off on loss; iOS: an
  interruption blocks `speak` until it ends (or the app comes back from
  the background), and a session that can't be activated counts as busy.
- **Android `stop` during detection / init:** a per-call generation makes
  stale speaks answer without reading (they were read after TTS was off).
- **Voice preview:** `ChatTtsQueue.hold` pauses reading while the sample
  plays; Android's `QUEUE_FLUSH` cut it off with the next chat message.
- **Switching chat:** type / engine changes stop reading (settings
  watch); queued messages of a channel no longer on screen are skipped
  (`ChatTtsQueueItem.isCurrent`).
- **Picker vs bridge:** a voice pick for another region applies only when
  the tag has no voices of its own (first by tag, not dictionary order);
  `voices` marks the voice the default language reads with (`default`) -
  the sheet's voice row and the filler-word language follow it (Android
  reads in the engine's default language, not the phone's; the option is
  "Text-to-speech default" there). Older `voices` answers arriving late
  are dropped.
- **Startup:** TTS no longer creates the Twitch / YouTube / Kick stores
  (their `init` started sign-in / polling); it attaches to existing ones
  and to new ones via GetIt `onCreated`.
Not run on a device yet - both native compiles checked on the
workstation.

## 2026-10-02 - Definition of done for OBS-facing features

Retro on canvas v2 (~5 follow-up "test it again" rounds, each finding
real bugs discoverable from the start): the code was checked against
assumptions (docs + a fake OBS encoding the same assumptions), the scope
stopped at the literal request, and real-world use (Twitch Dual Format)
wasn't researched up front. Now:
- `AGENTS.md` § Definition of done + `.claude/skills/obs-feature/`
  (research -> source-verified facts -> build -> journey sweep -> widget
  shots -> fresh-context review -> report; tier M minimum) and the
  reminder to run `/code-review high` in a fresh session after a feature.
- `docs/obs-protocol-gotchas.md` (facts paid for once) and
  `docs/dashboard-interaction-checklist.md` (journeys x surfaces x state
  changes x form factors).
- `tool/widget_shots/` (headless renders, real theme via the now-public
  `App.buildTheme`).

## 2026-10-02 - Canvas user-flow sweep (final)

Walked the canvas journeys (no extra canvas, Aitum + TikTok, Twitch Dual
Format, landscape Aitum canvas, hiding, groups, reconnect / profile /
collection switches, streaming mode) against the code and
obs-websocket's source; rendered the new states as throwaway goldens.
Fixed:
- **Group lookups were main-canvas only:** obs-websocket resolves names
  inside the given `canvasUuid` (main when absent) - canvas group
  children loaded / toggled against main. Requests carry the canvas,
  child events match the group by `sourceUuid` (new optional
  `SceneItem.sourceUuid`).
- **Canvas resized in Aitum's dock** (no OBS event): stale dimensions
  misdirected Aitum requests and dropped its events. Size-mismatched
  Aitum event → canvas re-read; the 10 s viewed-canvas refresh re-reads
  the canvas list (chains scenes, Aitum state, Dual Format).
- Scene collection switch → canvas re-read; `EPHEMERAL` canvases hidden.
- Dual Format card: status line instead of a caption next to "Start";
  Aitum's own row reads "Separate stream".
Known limits (unchanged): Dual Format on OBS 32.0 (no canvas API in its
websocket) shows nothing extra; shared don't-ask-again for stream /
recording confirmations.

## 2026-10-02 - Twitch Dual Format awareness + shape-aware canvas labels

Research (any-size canvases): OBS has the canvas API (libobs, frontend
`obs_frontend_add_canvas`, multitrack "additional canvas" - one only)
but still **no UI to create canvases** (checked OBS master 2026-10-01);
the only creator in the wild is Aitum Vertical, whose canvas can be any
size (720×1280, 1080×1920, 1080×1350, 1280×720 … 3840×2160, editable)
and is always named "Aitum Vertical". Twitch Dual Format (GA June 2026)
uses Aitum's canvas but sends it with the **main** Start Streaming via
Enhanced Broadcasting.

- Store reads `Stream1/EnableMultitrackVideo` + `MultitrackExtraCanvas`
  (`GetProfileParameter`) and the stream service (`GetStreamServiceSettings`;
  counts only with a `multitrack_video_configuration_url` or
  `rtmp_custom` - OBS's own condition in `BasicOutputHandler`) on
  connect, profile switch, stream start, viewed-canvas refresh.
- Outputs card: Stream row caption "Goes live / Live with the main
  stream (Dual Format)"; starting Aitum's own stream on that canvas asks
  first ("Separate Stream").
- App bar pill → `ExtraCanvasOnAirPill` (Dual Format while main is live,
  or Aitum's own outputs); phone glyph only for portrait canvases.
- `ObsCanvas.outputLabel`: "vertical" for portrait, the canvas name
  otherwise (failure toasts etc.).
- Tests: Dual Format cases in `aitum_vertical_test.dart`, pill / caption
  / dialog / label cases in `canvas_switcher_test.dart`.

## 2026-10-02 - Canvas v2 follow-ups: vertical pill, groups, hiding, more Aitum

- **Vertical on-air pill** in the app bar status row while Aitum's own
  stream / recording runs (phone glyph, LIVE / REC in their signal
  colors, no timer - the plugin reports none). Hidden otherwise and while
  reconnecting; tap = show the Aitum canvas (not in streaming mode, only
  with the picker on). The row is in a scale-down `FittedBox` so three
  pills never overflow narrow phones. Checked as a rendered golden at
  390 pt (throwaway, not committed).
- **Canvas groups** expand like the main items: children via
  `GetGroupSceneItemList` by the group's source name (unique across OBS),
  toggles in the group's scene, patches keyed by (group, id).
- **Hiding on canvases:** Edit Scene Visibility hides canvas scenes /
  items (never switches live). `HiddenScene` HiveField 3 /
  `HiddenSceneItem` HiveField 7 `canvasName` - additive, existing entries
  read null = main; committed persistence fixtures still open.
- **Same-name cross-patch fixed:** `Scene.sceneUuid` + event `sceneUuid`;
  main scene-item enable/lock events must match the displayed scene's
  UUID (name-only fallback without UUIDs).
- **Aitum:** virtual camera row; recording pause / resume (no pause
  events or status in the vendor - the answers are the truth: applied or
  refused-because-already = requested state; caught a real inversion bug
  in the first cut via test); chapter marker (Hybrid MP4 only, refusal
  toast says so). **Not wired: stream key / server** - the vendor only
  overwrites an in-memory setting at an output index it can't list,
  answers success even for an invalid index, nothing to read back.
- Gotcha: `cp` is aliased to `cp -i` on the NAS shell - a restore `cp`
  sat on the overwrite prompt; use `\cp -f`.

## 2026-10-02 - Canvas v2: Aitum Vertical live control

The v2 follow-up of the canvas switcher (`docs/private/feature-requests-2026-10.md`
§ 4). Vendor API read from the plugin source (`Aitum/obs-vertical-canvas`,
`vertical-canvas.cpp`): vendor `aitum-vertical-canvas`, requests pick their
canvas by `width`/`height` (0 = any), every handler answers
`success: true|false`, events carry the canvas size too.

- **Detection:** `CallVendorRequest` `version` after every canvas-list
  read (connect, reconnect, canvas events) when a non-main canvas exists.
  Only an OBS rejection (no such vendor) or a non-`success` answer counts
  as missing; a timeout keeps the old verdict; any Aitum `VendorEvent`
  flips it to available.
- **Which canvas:** the plugin finds its canvas by the fixed name
  `Aitum Vertical` (`CANVAS_NAME`), so the app does too.
- **Live scene:** `current_scene` / `switch_scene` (names - unique within
  a canvas) + the `switch_scene` vendor event. With control, scene taps
  switch live (optimistic, re-read on failure), the live scene gets the
  program tally and the shown scene follows it.
- **Outputs:** `CanvasOutputControls` under the picker - stream /
  recording / backtrack (+ save), explicit start/stop vendor requests,
  confirmation dialogs reused (they now name the canvas, same don't-show
  settings), state from `status` (read on detect + the 10 s refresh while
  viewed) and `streaming_*` / `recording_*` / `backtrack_*` events. Not
  wired: virtual camera, record pause, chapters, stream key/server.
- **Gating:** without control the rows stay visible but muted with a
  "View only - live controls need Aitum Vertical" line; a tap shows why
  (`aitumBlockedReason`: plugin missing / restart OBS - the plugin's
  fresh-install bug, Aitum PR #30 / only the Aitum canvas / still
  checking). The first view-only scene tap per session says the pick is
  "Shown in the app only".
- Plugin refusals go through the command-failure toast
  (`DashboardStore.reportCommandFailure`).
- Tests: `test/websocket/aitum_vertical_test.dart` (fake OBS + fake
  vendor), Aitum / gating cases in `canvas_switcher_test.dart`; the canvas
  reconnect test was de-raced (event vs in-flight item re-read). Gates:
  websocket + dashboard suites clean, analyze 0 errors. **Not verified
  against a real OBS 32.1 + Aitum Vertical yet.**
- `docs/private/feature-requests-2026-10.md` status updated (and
  mirrored) later the same day, once the workstation was reachable.
- **User-flow review (same day)** - walked every dashboard path with a
  canvas viewed; fixed: Settings → Canvases help still said "view only";
  the studio-mode Transition button (main canvas) now hides while another
  canvas is shown; "Take OBS Screenshot" captured the main program scene
  while a canvas was shown - it now saves the shown canvas scene (by
  UUID); Edit Scene Visibility (main-only) let a tap switch the Aitum
  canvas live - canvas taps now explain instead; the outputs card gained
  a "<canvas> outputs" title so it can't be mistaken for the main
  output's exposed Stream / Recording controls.

## 2026-10-02 - Replay buffer connect fix + OBS↔app sync audit

From a store review: connecting to a running OBS never detected an
already-running replay buffer (Save button greyed out until the buffer
was toggled in OBS). Root cause + a full sync-state audit against the
obs-websocket v5 spec:

- **The reported bug:** `GetReplayBufferStatusResponse` read a v4-era
  `isReplayBufferActive` key - v5's field is `outputActive`, so the
  initial read always landed `false` and only the
  `ReplayBufferStateChanged` event (correct key) fixed the state.
  Regression tests drive the initial burst against the loopback fake OBS
  (`test/websocket/replay_buffer_status_test.dart`).
- **Audit result:** no other wrong-key DTO in any live path (every
  response/event/batch DTO checked against generated `protocol.md`).
  Found and fixed instead:
  - **Canvas view broke after a reconnect** - the `CanvasViewStore` init
    reaction only tracked `availableRequests.contains(GetCanvasList)`,
    which never flips across a reconnect (the set is never cleared), so
    the store kept listening on the dead socket: no canvas events, stale
    list, until the dashboard was re-entered. The reaction now tracks the
    session identity too.
  - **Inputs created/removed outside a scene** (global audio devices,
    unplaced sources) never refreshed `allInputs` - `InputCreated` /
    `InputRemoved` are now in `EventType` and re-read the input list.
  - **Structural filter changes** (add/remove/rename/reorder/settings)
    went stale until the next scene-item re-read - those events now
    re-read the shown scene's filters.
  - **Profile switch** only updated the name - video settings and the
    record directory are per-profile in OBS and are now re-read.
  - Screenshot requests sent a nonexistent `compressionQuality` key
    (v5: `imageCompressionQuality`) - silently ignored, default happened
    to match; aligned.
  - Dropped the dead initial `GetStreamStatus`/`GetRecordStatus` sends
    (responses discarded by design since the 1s stats batch owns
    stream/record state).
- **Known, not fixed (protocol limits):** record directory / video
  settings / hotkey list / transition list have no change events in v5
  (initial-read only; profile switch now covered); `SceneListChanged`
  doesn't fire on reorder (spec's own TODO); main-canvas item events
  match by scene name, so a same-named non-main canvas scene could
  cross-patch (canvas view itself matches by UUID).
- Tests: `replay_buffer_status_test.dart`, `event_driven_refresh_test.dart`,
  canvas reconnect case in `canvas_view_store_test.dart` - each verified
  to fail against the pre-fix code. Gates: websocket + dashboard suites
  clean, analyze 0 errors.

## 2026-10-01 - Canvas switcher v1, chat text-to-speech, app-wide Wake Lock

From a user's feature request (report + decisions:
`docs/private/feature-requests-2026-10.md`). Not verified against a real
OBS 32.1 / device yet - analyze + unit/widget tests only.

- **Wake Lock** applies app-wide (`lib/utils/wake_lock_helper.dart`,
  startup + resume + Settings), **default off** now (was on, dashboard
  only). Release note: users who never touched it lose the dashboard
  default - "turn it on in Settings".
- **Canvases** (OBS 32.1+): `CanvasViewStore` + `makeScopedRequest`
  (ack `responseData`, DashboardStore skips scoped responses - a test
  proves the guard), canvas picker / scene buttons / preview (canvas
  aspect, clamped) / items (visibility + lock) for a non-main canvas,
  view-only. `ExposeCanvasSwitcher` (Dashboard customisation, default on);
  streaming mode resets to main. OBS only emits enable/lock item events
  for non-main canvases (created/removed are main-only) - 10 s re-read
  while viewing.
- **Chat TTS**: `liveMessages` streams on the three native stores, pure
  `chatTtsUtterance` + `ChatTtsQueue`, `ChatTtsStore` (Pro, persisted
  on/off), speaker in the `NativeChatWindow` header (tap / long press /
  waiting chip), settings sheet + options-sheet page, one-off hint.
  Speech is the app's own platform channel (`com.kounex.obsBlade/tts`:
  `AVSpeechSynthesizer` in `AppDelegate.swift` - playback, voicePrompt,
  mix + duck, session released after each message; `TextToSpeech` in
  `MainActivity.kt`; Android `TTS_SERVICE` `<queries>` entry).
  `flutter_tts` was tried first and dropped: it's CocoaPods-only, the
  iOS project is SPM-only (`81a41a27`) - the dogfood build regenerated a
  Podfile and failed `pod install` (stale `RunnerTests` target). Check new
  iOS plugins for `Package.swift` before adding them.
- TTS bridge hardened after a `flutter_tts` source comparison: per-message
  watchdog in `ChatTtsQueue` (10 s + 150 ms/char → stop + move on), iOS
  stops on `AVAudioSession` interruptions and picks the best installed
  voice (premium > enhanced > default, no novelty / Personal Voice),
  Android ducks other audio (transient focus) and restarts a dead engine
  with one retry, input capped at `getMaxSpeechInputLength`. New
  `voices` channel method + "Voices on this phone" section in the TTS
  sheet (groundwork for per-message language detection, next).
- TTS language: a default language picker (installed languages, best
  voice each, "Phone language" default) + an opt-in "Detect each
  message's language" toggle - native detection on the message body
  (no username), ≥3 words / ≥12 letters, ≥60% confidence, same base
  language as the default keeps the default voice, no installed voice →
  default. iOS prefers the phone's region for a detected language,
  Android too, offline voices first.
- TTS sheet polish: the language list is a "Read in" dropdown (new
  optional `BaseDropdown.menuMaxHeight`), new Volume slider (10-100 %,
  iOS `utterance.volume`, Android `KEY_PARAM_VOLUME`), and the first-enable
  hint is a speech bubble anchored above the speaker (tail on it, right
  edges aligned) instead of the fullscreen status overlay. Test gotcha:
  `DropdownButton` reports a pick after its close animation on the fake
  clock - a Hive write from `onChanged` then never finishes and teardown
  hangs; pick through `onChanged` inside `runAsync`.
- Spammy chat: repeated words collapse ("KEKW 5 times"), identical short
  messages waiting in the queue are combined ("Viewer, ModName and 13
  others: KEKW"; one person → "Viewer: KEKW 5 times"; on by default,
  only ever merges what's already waiting), "Skip emote-only messages"
  toggle. Filler words from `ChatTtsPhrases` (en, de, es, fr, pt, it,
  nl, pl, tr, ru, ja, ko, zh; by the default TTS language) - a
  translation service was considered and rejected for four fixed
  phrases (offline, instant, no keys, no chat content leaves the phone).
  The non-English phrases are my translations - worth a native check.
- Crawled the real iPhone voice list (dogfood-only export
  `Documents/tts-voices.json`, pulled with `devicectl device copy from
  --domain-type appDataContainer`): 178 voices, 49 locales, 39 base
  languages, **all quality 1** (no enhanced/premium downloaded), 112 of
  them Eloquence (Eddy, Grandpa, … - robotic, not flagged novelty).
  Tie-break on iOS now Siri > Apple regular > Eloquence; the bridge
  marks its pick (`preferred`) so the sheet shows exactly that voice.
  Phrase table grown from 13 to all 39 languages (+ `no`/`iw`/`in`
  aliases).
- Voice per language: "Voice" dropdown (Automatic + the language's
  voices, readable labels - Siri / Enhanced / Premium / robotic on iOS,
  "Voice DEB · high quality · needs internet" for Android ids) with a ▶
  preview reading a per-language sample; "Voices for other languages"
  sheet when detection is on; per-platform help (iOS directions,
  Android buttons for the TTS settings / voice data install).
- Sheet freeze fixed at the source: listing voices resolved each
  voice's "preferred" flag through the best-voice lookup, which re-read
  the system voice list per uncached language (iOS
  `speechVoices()` ~49x, Android `engine.voices` IPC per call) on the
  main thread - and detection re-read it per message. Both bridges now
  cache the list (iOS: refreshed on `availableVoicesDidChange`; Android:
  on engine restart / each listing) and build the listing on a
  background queue. Help text no longer hard-codes menu paths ("search
  Settings for Voices" / "text-to-speech" - Apple moved it to Live
  Speech on iOS 27).
- Process slips this round (caught by the build, fixed): the iOS bridge
  rewrite dropped `ManageSubscriptions` (spliced to EOF), and a
  `dart format lib` touched 5 unrelated files (reverted before commit -
  happened twice; format the changed files by path only).
  Splice native files by exact class boundaries; format changed files
  only.
- Gotcha: `build_runner build --build-filter` right after a pubspec
  change deleted ~30 committed `.g.dart` files (restored from git) - run
  it without the filter, or check `git status` after.

## 2026-10-01 - Test suite de-flaked + sped up, test_gate wrapper

Goal-driven pass over the whole suite (baseline: 368s wall, 4 consistent
failures, several timing races). All changes test/-only plus the tool; no
lib/ changes.

- **mod_action_sheet_test.dart**: the 4 long-standing hit-test failures were
  the login pin fetch leaving the sample pin banner over the first chat row
  (the banner overlays the timeline), so `longPress()` hit the banner. Fixed
  via a shared `pumpChatView` helper that clears the pin after the fetch
  flushed.
- **state_ordering_test.dart** (the intermittent one): rewritten off
  wall-clock sync (300ms ackDelays, 400-500ms settles, 1s waitFor caps) onto
  deterministic gates - `FakeObsPeer` can now hold/release acks
  (`heldRequestTypes`, `holdRequestFor`, `releaseOne`/`releaseAll`,
  closeSockets purges held acks; it also ignores stray non-WebSocket
  upgrades), and a `flushPeer()` round-trip
  (`NetworkHelper.makeRequest(GetVersion)`) proves a released response was
  processed (single-socket in-order delivery). 10.7s -> ~1s, 15/15 stable.
- **9 more wall-clock sites hardened** across websocket/home/settings/chat/
  dashboard (condition-polling with 5s caps replaces fixed settles; two more
  files onto the hold/flush pattern). 90/90 repeat runs green. Benign sites
  (real-time ack-timeout test, prove-a-negative drains) documented as left.
- **twitch_chat_store_test.dart 75s -> ~1s**: all 14 `TwitchChatStore(`
  sites now inject `FakeSilentIrcSidecar` - every connect had been making a
  REAL WebSocket attempt to irc-ws.chat.twitch.tv (~600ms, swallowed). Same
  one-liner applied to the 11 other chat test files that constructed the
  store without the override (suite rule: no real network in tests). Chat
  suite 2:58 -> 2:19. native_chat_options_sheet_test ~12s -> ~5s (shorter
  Hive-close windows).
- **tool/test_gate.dart** (new, `dart tool/test_gate.dart [--runs=N]
  [targets]`): serial json-reporter runner that detects the NAS runner load
  flake ("Unable to connect to flutter_tester process: WebSocketException"
  on a file's `loading` test), retries just those files (3 attempts), and
  fails only on real test failures. `--selftest` covers the classifier.
  Documented in AGENTS.md.
- Proof: 3 consecutive full-suite gate runs clean (1627/1627 each); the
  runner flake fired in runs 2 and 3 and was auto-recovered both times.
  Full suite ~368s -> ~215s per run.

## 2026-09-30 - 4.0.1 submitted to both stores, release skills

4.0.1 (2026093001, release commit `35a0040f`) carries today's fixes (entries
below). Built on the workstation over SSH: TestFlight (processed, internal
testers) + Play internal, then `metadata ios` (created the 4.0.1 version:
notes, the committed screenshots; the App Preview carried over from 4.0.0,
checked via the ASC API), `submit ios` (manual release) and
`promote android` at 100% (managed publishing holds it). Same notes on both
stores, 444/500 chars on Play. The Mac slept between the uploads and the
submit - SSH timed out until it woke; the release-over-SSH recipe now uses
`caffeinate`. Also: `docs/release-playbook.md` + project skills
`release-beta` / `-promote` / `-direct` / `-publish`, tag `4.0.0` added on
`57af832f` (releases are tagged with the bare version from now on).

## 2026-09-30 - iOS body text without Material letter spacing

User decision after a side-by-side on the simulator: on iOS / macOS the body
slots (bodyLarge / bodyMedium / bodySmall) set letterSpacing 0 so SF Pro
keeps its own spacing; Android keeps Material's (+0.5 / +0.25 / +0.4) for
Roboto. Keyed on the device font (`defaultTargetPlatform`), not the
ForceNonNativeElements widget platform. Note: Material's spacing is merged
by `Theme.of` from the typography geometry wherever the theme leaves it
null - `ThemeData.textTheme` itself carries none. Titles / labels unchanged.

## 2026-09-30 - FAQ list sizing, log legend dots

FAQ answers read in two sizes: `EnumerationBlock` set its lead-in in
`titleSmall` (13/w500) while entries and plain answers are body (15). Title,
markers and entries (custom ones too) now share `bodyMedium`.
`EnumerationEntry.marker` replaces the bullet, centered on the first line via
a middle-aligned `WidgetSpan`; the log explanation used a `LevelDot` inside a
custom entry next to the default bullet (two dots per type). Nested entries
get `◦`. FAQ iOS path updated to "Privacy & Security". Checked on the iPhone
17 Pro simulator (throwaway integration test, removed). Not changed: body
text keeps Material's letterSpacing (0.25) - on SF Pro it reads airy next
to the tight headings; app-wide typography call.

## 2026-09-30 - Connection setup review (autodiscover, modes, saved cards)

Follow-up to the domain-mode bug below: a pass over every connect path. All
of these predate 4.0 (same code in 3.2):
- Quick Connect: OBS percent-encodes the password in the Connect QR
  (`QUrl::toPercentEncoding`, verified in obs-websocket `ConnectInfo.cpp`);
  it was used encoded, so passwords with special characters failed. Parser
  moved to `lib/utils/obs_connect_uri.dart` + tests.
- Saved cards: `ReachableBuilder` read the box once, so deleted cards stayed
  and edited endpoints kept their old dot. Now follows every box change,
  re-checks only on new/changed endpoints, drops stale overlapping checks,
  comparator fixed (0 -> -1). Widget test `test/home/reachable_builder_test.dart`.
- Edit dialog trimmed the password on save (a rename broke `" pw "`).
- Autodiscover results inherited the Manual IP/Domain toggle ("Hostname" label,
  domain validation for a discovered IP).
Left as is (efficiency is fine): isolates for the scans (async I/O, cheap),
the saved check waits for all hosts (unreachable ones hold every dot up to
5s), autodiscover is WLAN + /24 only and doesn't verify the peer is OBS.
`test/chat/mod_action_sheet_test.dart` + `channel_mod_sheet_test.dart` fail
already on the 4.0 release commit - unrelated, not investigated.

## 2026-09-30 - Saved domain-mode connections always read offline (4.0 bug)

First 4.0 user report: a saved `ws://<IP>` connection (domain mode) connects
fine but its card says offline; fine on 3.2. Cause: the card probe for domain
mode read `channel.closeCode` after 5s and counted a *closed* socket as
reachable. That only worked by accident with web_socket_channel 2.4 - the
dart:io socket stayed unlistened, pongs were never processed and dart:io
closed it (1001) after the 500 ms ping. 3.x listens immediately, a live
socket stays open, closeCode stays null -> offline. Second bug in the same
path: an unreachable domain host left `ready`'s error unhandled, which killed
the scan isolate, so every card stayed on "checking". Now the probe awaits
`ready` (bounded by the 5s connect timeout). Regression test:
`test/websocket/saved_connection_reachability_test.dart` (local WS server).

## 2026-09-30 - 4.0 released on both stores

Pre-release check against the live stores first: 4.0.0 PENDING_DEVELOPER_RELEASE
with every review item APPROVED (version, both subscription versions, the
group version), subscriptions priced 175/175 territories, Apple server
notifications V2 pointing at RevenueCat, RevenueCat offering `pro` current
on iOS and Android (Play packages map to `pro` + base plans), Play
production 4.0.0 (2026092805) at 100% with all products ACTIVE, Play RTDN
test notification received by the user, and nothing but
`integration_test/`, docs, fastlane and tooling changed since the build.
Then `release publish ios --yes` (4.0.0 READY_FOR_SALE) and the user
published the held Play changes. ASC still listed `pro_monthly` /
`pro_yearly` with state IN_REVIEW right after the release although their
subscription versions were ACCEPTED - expected to follow the version.

## 2026-09-29 - 4.0 submitted to both stores (manual release)

`submit ios` no longer uses deliver: a first subscription can't go through
`subscriptionSubmissions` (409 "no pending version for submission", also
with the version in a draft). The ASC review submission takes items: the
app version, each subscription's `subscriptionVersion`, and - while the
group was never approved - its `subscriptionGroupVersion`
(SUBSCRIPTION_SUBMISSION_REQUIRES_GROUP_VERSION, only visible in
`meta.associatedErrors`, which the API client prints now). ASC added the
subscription versions to the draft on its own with the app version; item
relationship ids only come back with `include`. Release type pinned MANUAL,
`publish ios` releases an approved version. Play: promoted internal ->
production at 100%, managed publishing holds it. Age rating: the new
2025 questions answered (UGC + messaging yes, rest no) - still 4+.

## 2026-09-29 - Store preview videos on the 4.0 listings

The user approved the v2 video cuts (store-shots `out/video/`, rendered
2026-09-29). App Store: `release preview ios <mp4>` (new; fastlane's
deliver can't upload previews) uploaded `appstore-iphone.mp4` to 4.0.0's
en-US `IPHONE_67` set through the ASC API, poster `00:00:05:00` - Apple
processed it (COMPLETE). deliver's `overwrite_screenshots` leaves
previews alone. Play: the listing takes a YouTube link only - the user uploaded
`play-phone.mp4` unlisted (YouTube made it a Short; Play Console rejects
`/shorts/` links, so `video.txt` holds the `watch?v=` form of the same id),
pushed with `release metadata android`, read back from the listing. The
YouTube API can't do the upload for us: videos.insert from unaudited
projects created after 2020-07-28 is locked private.

## 2026-09-29 - Store captures: OBS safety review fixes

Review of the video mode found a stray test could go live on the user's
real OBS profile: record_watch.py dying left the app running the test
while record.sh's teardown restored the user's profile. Fixed in depth
(README "OBS safety"): the wrappers stop the app/flutter/recorders
before the teardown (cleanup trap installed first, runs once, also on
HUP/TERM); missed acks fail the tests; the video test checks over its
own obs-websocket connection that OBS is on the demo profile +
collection with a 127.0.0.1 stream server before every OBS-changing
step; obs_demo.dart verifies each switch before destructive calls,
teardown/offline only stop outputs on the demo profile (safe twice,
before setup, next to a live user stream) and restore Studio Mode;
record_watch.py stops recorder + test process group when interrupted;
the sink loop is found by pidfile + name; media loops are renamed into
place only after the seam check.

## 2026-09-28 - Store captures: video mode for app previews

App Store previews (2.3.4: app captures only) and the Play preview need
real recordings. `tool/store_screenshots/record.sh` (README "Video mode")
records `integration_test/store_video_test.dart` per clip on the store
devices: REC_START / REC_STOP / CUE markers, cues.json, constant 30 fps
H.264 per clip; seeding shared with the screenshot test
(`store_capture_support.dart`, `common.sh`; screenshot flow unchanged).
Findings: the live binding must be `fullyLive` (~4 fps otherwise);
`tester.tap` paints a crosshair (device pointer events don't); a scene
tile's label never hit-tests (its ring is stacked on top); iOS keyboard
is region-specific with a first-use sheet - the reply is typed with the
fake text input. Android: debug JIT + in-guest `screenrecord` gave ~20
fps; profile build (`flutter drive`) + the emulator's host-side recorder
give ~40-49. The demo "Game Capture"/"Webcam" play seamless 8 s loops
rendered from `render(t)` pages. Clips: store-shots
`projects/obs-blade/recordings/`.

## 2026-09-28 - Delayed state after scene switches: OBS freezes, two app fixes

Dogfood: after a scene switch / pad tap, scene items, media state and
even the audio meters arrived seconds late. Measured instead of guessed:
- App stores (NetworkStore + DashboardStore in a throwaway flutter test)
  against the real OBS on the workstation, no network hop: scene items
  apply ~225 ms after the tap, also for a quick switch back - the ack
  layer and ordering guards add nothing.
- Raw WebSocket clients on loopback (MacBook) and from the wired NAS at
  the same time: both saw the same ~13 s silence (no InputVolumeMeters,
  requests answered in one burst after), about once a minute. OBS had
  been running 8 days with Mic/Aux "Shure MV7" disconnected, retried
  every 2 s (4230x `coreaudio_get_device_name failed`). Not proven as the
  cause, strongest lead. The old 3 s keepalive turned such freezes into
  reconnects; since f9732f03 (15 s) they show as late state.
App fixes: the in-program read right at CurrentProgramSceneChanged /
SceneTransitionEnded raced OBS's next-frame deactivation (~55 ms later)
- a follow-up read 250 ms later (`kMediaInProgramSettle`); and
`mediaInputs` is a custom-equality `Computed` so meter ticks (allInputs
replaced ~20x/s) no longer rebuild the whole media hub.

## 2026-09-28 - Manage subscription: StoreKit sheet in the app

The App Store web page (`apps.apple.com/account/subscriptions`) doesn't
list sandbox / TestFlight subscriptions, so testers couldn't cancel.
Neither `purchases_flutter` 10.11 nor `in_app_purchase_storekit` 0.4.11
exposes `AppStore.showManageSubscriptions(in:)`, so a small method
channel `com.kounex.obsBlade/subscriptions` lives in `AppDelegate.swift`
(iOS 15+ = deployment target; answers false for the iPad app on a Mac
-> web page fallback). Dart side: `lib/utils/manage_subscriptions.dart`.
After the sheet closes `ProStore.refreshPlan(fresh: true)` invalidates
RevenueCat's CustomerInfo cache first (a cancel is no transaction, the
SDK wouldn't notice). Android: Play's documented deep link to the Pro
subscription (`?sku=pro&package=com.kounex.obsBlade`). RevenueCat
Customer Center (`purchases_ui_flutter`) was considered and skipped:
heavy native UI dependency, overlaps the plan switch, plan requirement
unclear. Installed on Kounex iOS (development-signed = sandbox); the
TestFlight case itself needs the next TestFlight build.
Dogfood follow-up: lifetime + a still-renewing subscription showed the
cancel notice's "Open subscriptions" next to "Manage subscription" (same
action) - lifetime now never shows "Manage subscription".

## 2026-09-28 - Media outside the live scene, per source (corrects "On hold")

User report: after switching away from a playing clip's scene, the hub
showed it locked / "On hold" while its time kept running. Probed OBS 32
over WebSocket (ffmpeg source, audio file):

| `restart_on_activate` | leaves program | while not live | goes live |
|---|---|---|---|
| off | keeps PLAYING, cursor runs (unheard) | pause, resume, stop work; play-from-stopped ends at once; restart parks at 0:00; seek ends the clip | carries on |
| on (OBS default) | stops (ENDED) | play is queued (PLAYING, cursor frozen) | always plays from the start, even after a manual stop |

So the earlier "On hold" model was wrong for "off" and the frozen-cursor
observation belonged to "on". The hub now reads each media input's
settings (`GetInputSettings`; OBS omits defaults, so a missing
`restart_on_activate` = on) into `DashboardStore.mediaLiveBehavior`, and
`MediaPlayback` (`media_status.dart`) decides time, label and enabled
buttons for pads, rows and the transport sheet: "off" keeps the clock
running with pause/stop/resume enabled; "on" reads "Restarts when live";
VLC `pause_unpause` reads "On hold at 0:07 · resumes when live" (VLC
mapping `stop_restart` / `pause_unpause` / `always_play` is from the OBS
source, **not probed** - no VLC on the workstation). "Stop all" stays
enabled for clips playing unheard (they really play). No settings event
exists in OBS WS v5 - re-read on hub open, input list reload and sheet
open.

## 2026-09-28 - Pro plan switch, Android subscriptions, media outside the live scene

From the TestFlight sandbox test (monthly bought fine once the RevenueCat
offering `pro` was made current - the empty `default` offering had
made the paywall say "Not live yet"):

- **Android paywall:** RevenueCat names Play subscriptions
  `pro:pro-yearly` / `pro:pro-monthly`; the exact-id filter dropped them,
  so Play users would only have seen Lifetime. `canonicalProProductId`
  (pro_ids.dart) maps store ids to plan ids everywhere.
- **Tiered plan switch** (user design): `ProPlanState` from CustomerInfo
  (active subscriptions + renewal, lifetime owned). Monthly -> yearly or
  lifetime, yearly -> lifetime, lifetime -> nothing (and no "Manage
  subscription"). Monthly -> yearly is a Play product change
  (`StoreProductChangeInfo`, time proration); the App Store switches
  within the group at the next renewal (both subscriptions are level 1).
  Lifetime next to a still-renewing subscription shows a cancel notice
  with the store's subscription page.
- **Media hub:** OBS accepts play for a media source outside the live
  scene and reports PLAYING, but the cursor never moves (checked against
  OBS 32). Starting (play/restart/prev/next/seek) is locked there in
  list, pads and transport sheet; stop/pause stay; label "Not in the
  live scene".

## 2026-09-28 - Legal pages live on the website

The bundled privacy policy still said the app sends no data anywhere -
wrong for 4.0 (RevenueCat, the Kick sign-in relay, chat platforms). The
website (obs-blade.kounex.com, relaunched by the user with privacy
policy + imprint) is now the single source of truth: Settings → Misc
"Privacy Policy" and a new "Imprint" row, and the paywall's Terms /
Privacy links open the pages in the in-app browser (`openLegalPage` in
`lib/utils/legal_links.dart`, snackbar when nothing can open them).
`PrivacyPolicyView` and its route are gone. Neither store requires an
offline copy - only a link in the app and in the listing.

## 2026-09-27 - Store screenshots: capture tooling, stats detail on tablet

Redesign of the App Store / Play screenshots (user ask: automated, real
app, intro style, 5-8 per size). Composition lives outside the repo (the
maintainer's store-shots composer); the repo holds the capture side.

- **Capture tooling** (`tool/store_screenshots/`, README there): a
  separate "OBS Blade Store Demo" OBS profile + scene collection with
  fictional content (synthwave racer, illustrated facecam, overlays,
  audio beds), streaming to a local ffmpeg RTMP sink; `capture.sh` runs
  `integration_test/store_screenshots_test.dart` per device with clean
  status bars. The test seeds stats, a saved connection and combined
  chat (fake-backed stores, fictional viewers) and prints `SHOT:` /
  `CROP:` markers. Must run on dedicated sims/AVDs - it writes app data.
  Gotcha: the chat stores have to be swapped while the intro is the root
  route; the tab shell (all tabs built eagerly) and a fresh
  `CombinedChatStore` bind their observers to whatever GetIt returns at
  that moment.
- **Statistic detail on tablet** (user report): chart cards had a fixed
  350 width inside a 640 column (~608 usable), so two never fit a row.
  `StatsChartGrid` sizes them from the available width (2 per row on
  tablet, 1 on phone, min 300). New wide tier `kWideContentMaxWidth`
  1040 for the detail; reading measure `kBaseConstrainedMaxWidth`
  640 -> 720 (every `BaseCard`, user decision).
- **Autodiscover without WLAN**: the scan's `NotInWLANException` was an
  unhandled async error when nothing listened yet (fresh install behind
  the intro); the stored future is now marked handled.

## 2026-09-27 - YouTube chat recovers on its own after background / restart

User report: combined chat, all three platforms live, app backgrounded
or restarted - Twitch and Kick came back, YouTube sat on "Failed" until
it was connected again by hand with the key already in place.

- **Poll loop:** any error other than quota / rate limit / chat ended
  was terminal, including the socket iOS kills while the app is
  suspended. Transient failures (no HTTP answer, 408, 5xx) now retry:
  a dropped `liveChatMessages.list` backs off in place on the same
  cursor, a failed `videos.list` resolve backs off 2s → 60s. The chat
  shows `connecting` with the reason meanwhile. A 4xx (bad key, chat
  disabled, not found) is still terminal.
- **Cold start:** a token refresh that failed without an HTTP answer
  escaped `init`, leaving the store `unconfigured` ("Needs setup") with
  no poll - exactly what re-saving the setup sheet fixed. Offline / 5xx
  refresh failures now keep the session (the next write refreshes
  again), and a dead refresh token still starts the API-key reads.
- **Resume nudge:** `reconnectAfterResume` (called from the dashboard's
  lifecycle hook, only when the store already exists) restarts a failed
  or backing-off poll and rechecks a channel waiting for its stream.
  Paused (combined focus elsewhere) and quota-exhausted polls stay put.

## 2026-09-27 - Chat sign-ins survive an overnight close

User report: after a night the app asked to connect Twitch again, and
Kick showed "signed in" with a read-only chat whose Sign in button
opened a sheet that showed the account as signed in. Not an install
issue - access tokens (Twitch ~4h, Kick/YouTube shorter) had expired.

- **Kick / YouTube:** `canWrite` required an unexpired access token, but
  the token is only refreshed when a write runs, and the input stays
  locked while `canWrite` is false - so after expiry nothing ever
  refreshed it. It now accepts an expired token that has a refresh
  token. A write whose refresh comes back 400/401/403 signs out Kick
  (`_endSessionIfDead`) instead of leaving a signed-in account that
  cannot write.
- **Twitch cold start:** `init` validated the stored access token as is,
  so an expired one got a 401 and wiped the session. It now refreshes an
  expired token first, and a token that validate rejects gets one
  forced refresh before sign-out. A 400 from the token endpoint
  (Twitch's "invalid refresh token") also counts as a dead session.
- **Twitch refresh is single-flight** (`_refreshInFlight`), like Kick's.
- **Twitch EventSub + IRC reconnects** take a fresh token from
  `tokenProvider`. Before, they reused the token given to `connect`, so
  a reconnect more than 4h later got a 401 on the subscription POST, and
  that read as a revoked session and logged the user out.

## 2026-09-27 - Media hub (soundboard)

A third surface next to Scene Items / Audio for every media source.
Spec: `superpowers/specs/2026-09-27-media-hub-design.md`.

- Phone: a **Media** tab in the Scene Items / Audio card. Tablet: a
  full-width Media card under the pair. When the user's order splits
  the two, the hub card follows the later one.
- **Pads** (default): tap = play from the start (soundboard), long
  press = transport sheet; accent ring, progress bar and remaining time
  while playing. **List**: time `0:12 / 1:05` + restart / play-pause /
  stop. Transport sheet: seek (`SetMediaInputCursor`), VLC previous /
  next. Toolbar: Pads|List (persisted `MediaHubViewMode`), Stop all,
  Arrange (reorder + hide per connection).
- **Not in program** marker (speaker-slash, dimmed): `GetSourceActive`
  per media input, re-read on program switch, `SceneTransitionEnded`
  and any eye toggle - only once the hub has asked. The empty state
  explains the nested "Soundboard" scene tip.
- Progress is extrapolated from the last `GetMediaInputStatus` (OBS
  sends no cursor events); `MediaClock` ticks only for playing rows.
- Persistence: settings keys only (`ExposeMediaHub` default true,
  `MediaHubViewMode`, `MediaHubLayouts` JSON keyed `name:`/`host:` like
  hidden scenes) - no Hive type changes. Malformed layout JSON reads as
  the default layout.
- Scene item rows drop their media transport (lock returns) while the
  hub is on; hub off → rows keep it.
- Tests: `test/media/media_hub_layout_test.dart`,
  `test/dashboard/media_hub_test.dart`, store test in
  `command_ack_dashboard_store_test.dart`. Not yet run on a device or
  against a real OBS.

## 2026-09-27 - Intro v2: short welcome with live mockups

The old intro (Getting Started stage + 5 slides, WebSocket setup
screenshots behind a 5 s lock, icon tile + paragraph per slide) was
rebuilt from scratch. Spec: `superpowers/specs/2026-09-27-intro-v2-design.md`.

- One swipeable flow, 4 screens: Welcome (vortex mark turning inside
  sweeping accent rings + wordmark, open-source / obs-websocket small
  print), Dashboard (device mockup: LIVE/REC timers running, scenes
  switching with press + PGM, moving meters; morphs phone → tablet
  side-by-side), Make it yours (Settings → Customisation: switches flip
  on and light up Studio Mode tallies / Transition / record / replay /
  hotkey controls, then Elements Order drags Audio to the top), Stats
  (real `StatTile`s ticking, bitrate sparkline drawing, past sessions).
- Mockups are code, not screenshots: real tokens / leaves
  (`OnAirPill`, `SceneTallyChip` made public for this, `StatTile`,
  `BaseAdaptiveSwitch`, `DecorativeIconTile`), authored at a fixed size
  and scaled as a whole; loops run only on the visible page, park on a
  representative frame under reduced motion, ignore text scaling (copy
  clamps at 1.3x). Light, dark and custom themes follow automatically.
- Navigation: free swipe, Back · expanding dots · Next, Skip top-right
  (Close from Settings), last page stretches into "Get started".
  No slide lock. Tablets: visual + copy side by side, larger type.
- New seen-key `HasUserSeenIntro202609` gates launch - every existing
  user sees v2 once. `HasUserSeenIntro202208` is kept, no longer read.
  Skip / Get started persist it; the Settings entry writes nothing.
- WebSocket setup help left the intro (FAQ covers it); the three
  `assets/images/intro/*.png` screenshots are deleted. `IntroStore`
  shrank to `currentPage`.
- Tests: `test/intro/intro_view_test.dart` (swipe/Next/Back, Skip +
  Get started persist, Settings entry doesn't, reduced motion).
  Screenshot walk updated (40-43). Visually checked headless at
  phone / small phone / tablet, dark + light; not yet run on a device.

## 2026-09-27 - Android: glass bars blur like iOS

Dogfood: Android nav/tab bars were only see-through (0.9 alpha, no
blur) - `GlassBar` gated `BackdropFilter` on `isApple`. The gate
predates today's WebView setup: `webview_flutter_android` 4.x renders
through texture-layer composition by default (no
`displayWithHybridComposition`), which a backdrop filter samples like
any layer. Blur now runs on every platform. Follow-up: the True Dark
no-blur rule is gone too - one glass everywhere. Verified on the Pixel 7 API 36 emulator (Settings
nav bar, tab bar). Still open: blur over a *live* chat WebView on a
real Android device (the jank concern token-delta §3 flagged).

## 2026-09-27 - Android: links open again, intro links on the baseline

First Android emulator dogfood (Pixel 7, API 36): every `SocialBlock`
link showed "Couldn't open link".

- Cause: Android 11+ package visibility. With targetSdk >= 30 the
  manifest must declare `<queries>` for the intents it probes, otherwise
  `canLaunchUrl` sees no handler and returns false. Not emulator-only -
  the manifest never had the block, so real devices are affected too.
  Added VIEW http/https + SENDTO mailto queries.
- Intro slide inline links (`WidgetSpan` + `SocialBlock`) used the
  default bottom placeholder alignment and sat above the line; now
  `PlaceholderAlignment.baseline` / alphabetic.
- Verified on the emulator: the WebSocket link opens Chrome, links
  render on the text baseline.

## 2026-09-27 - Dashboard: Stats unwrapped on tablet too

Dogfood: in tablet mode the Stats element still sat inside a titled
"Stats" card with a fixed 650px frame. It now uses the phone
composition on both form factors - no wrapping card (the stat
containers are cards already), auto height from the tallest page.

## 2026-09-27 - Scene switch: stale item lists, fade on every switch

Dogfood: a scene switch occasionally kept showing the previous scene's
items; items only animated when coming from an empty scene.

- Cause (not the ack layer): obs-websocket processes requests on a
  thread pool, so responses can arrive out of send order. After a quick
  A -> B switch, A's GetSceneItemList response could land after B's and
  replace B's items. GetSceneItemList now applies only when its request
  body's scene is the displayed scene (the per-scene ordering tag is
  still popped so the FIFO stays aligned). GetGroupSceneItemList skips
  when the group's children are already present (no double splice).
- New observable `sceneItemsSceneName` (set with the item list). The
  scene-item rows key their `StaggeredEntrance` on (scene, parent group,
  item id), so every switch replays the entrance; `rise: 0` - fade only.
- Tests: `FakeObsPeer.ackDelayFor` / `responseDataFor` (per-request delay
  and payload, i.e. out-of-order answers); ordering test for the late
  item list (fails without the guard); widget test for the fade-only
  replay on a switch between two populated scenes (fails without the key).

## 2026-09-27 - Pro paywall: colour pass (calmer, readable)

Dogfood feedback on the overhaul: too colourful, halo has to go, should
not look AI-generated, colours must stay readable.

- Hero back to the pre-overhaul version (no platform halo, no chips).
- Benefit cards: neutral liquid cards; colour only in one solid icon
  tile per card (platform card: Twitch / Kick / YouTube brand tiles +
  neutral combined tile). Dropped radial washes, tinted borders, glow
  tiles, action chips, theme swatches, tag pills and hue-tinted page
  dots (back to the neutral worm dots).
- Plan card: plain `BaseButton` CTA (no gradient / glow), no per-plan
  icons, no gold Lifetime; badges as caption text in neutral levels.
- Contrast checked against every built-in theme's real card colour:
  tile glyphs >= 4.3:1 on their fills (YouTube fill deepened to #E00000,
  Kick carries a black glyph); accent-as-text removed from the selected
  plan row (Pure Indigo was 2.4:1); low-contrast tiles get a hairline.

## 2026-09-26 (night) - Pro paywall overhaul: fewer cards, more colour

- Benefits 8 -> 4 themed cards: Every Chat, One Place (Twitch/Kick/YouTube
  marks in brand colours -> combined mark), Moderate From Your Pocket,
  Chat, Supercharged, Make It Yours (built-in theme swatches). Each card
  has an identity hue (radial wash, hairline, glow tile, tags); the page
  dots take the current card's hue. Carousel height = tallest card
  (invisible sizing pass), so copy / text scale can't overflow; tablet
  grid rows equalise via IntrinsicHeight.
- Pricing 3 cards -> 1 plan card: selectable rows (radio, icon, badge,
  price; Lifetime in gold), Yearly preselected, one gradient CTA
  ("Get Pro <plan>") + a plan-specific fine-print line.
- Hero: blurred platform-hue halo turning behind the vortex (static under
  reduced motion) + Twitch / Kick / YouTube chips.
- Legal links wrap instead of overflowing at large text sizes.
- Design system: paywall colour exception written down (§ Per-surface
  direction). `ProPalette` holds the hues.
- Tests: plan selection retargets CTA + buy; benefit titles from
  `kProBenefits`.

## 2026-09-26 (evening) - Spacing: nav-bar top gap + full-bleed Pro carousel

- Pushed pages (translucent nav bar) now start content `AppSpacing.lg`
  below the bar instead of ad-hoc 0/12: `DataBlock` gets the same `xl`
  section rhythm as `ActionBlock` (Data Management's first caption sat
  flush under the bar), dense `ActionBlock` keeps an `lg` gap to the card
  edge, About / FAQ / Privacy / log detail / Elements Order / Chat tab
  move 12 -> 16.
- Pro paywall: the sales column drops its shared gutter so the benefits
  carousel runs to the screen edges (neighbour cards peek in from the
  edge instead of being clipped at 16 px); every other section pads
  itself, max width grows by the gutter so tablet width is unchanged.
  `viewportFraction` 0.88 -> 0.94 keeps the centered card aligned with
  the hero and pricing cards.

## 2026-09-26 (later) - Ack layer: survive WLAN stalls, no false failures

Dogfood: a scene switch OBS applied showed "Scene switch failed" and put
the app into reconnect. Cross-read of the device app log and OBS's own
log: a multi-second WLAN stall hit the 3 s ping keepalive (dart:io closes
after ping + 3 s without pong), the app reset a socket that would have
recovered, and every in-flight ack was failed as connectionLost -> toast.
Each reconnect's first attempt then died with 4007 because the stats poll
wrote to the not-yet-identified socket.

- Keepalive `NetworkHelper.socketPingInterval` 15 s; `requestAckTimeout`
  35 s (> 2x keepalive, so a stall ends as ack or connection loss); a
  timeout on a dead socket resolves as connectionLost.
- connectionLost / notSent are "unconfirmed": log only, no toast, no
  resync - the reconnect burst re-reads. No session -> notSent.
- `NetworkStore.setOBSWebSocket` publishes `activeSession` only after
  Identified; a failed reconnect keeps the old (dead) session as target.
- Reconnect loop pauses the stats poll, tries once immediately, resumes
  polls + the preview loop; the dashboard stream's onDone triggers
  `checkConnectionNow`.
- `sendRequest` / `sendBatchRequest` (untracked) for reads, polls and
  slider ticks; `makeRequest` / `makeBatchRequest` only where awaited.
- Preview screenshots carry `imageWidth` (device short side, capped at the
  canvas from new `GetVideoSettings`) - was full canvas (3440 px here).
- Maintainer setup finding: the OBS Mac's Tailscale exit node had LAN
  access off, so replies to the phone went via the exit node (~5x RTT);
  enabled `--exit-node-allow-lan-access`.

## 2026-09-26 - 4.0: base-app pass (dashboard + OBS control)

Audit of the non-chat app (dashboard controls, OBS v5 coverage, connect /
stats / settings), then everything but the "bigger" items shipped:

- **Safety / feedback:** start confirms no longer red; stream/record
  confirms send explicit `Start*`/`Stop*` (a race can't invert the
  confirmed intent); hotkeys fire immediately + "Fired: X" overlay on ack;
  screenshot via new `sendBatchMutation`; scene collection / profile
  switch confirm (`DontShowSwitchCollectionProfileMessage`); one reconnect
  signal (inline stale badges; `ReconnectToast` = tokenized "Reconnected"
  flash only); `checkConnectionNow()` on app resume + connectivity back.
- **OBS features:** split file + chapter markers (gated on GetVersion
  `availableRequests` → `DashboardStore.supportsRequest`), scene item lock
  (+ `SceneItemLockStateChanged`), per-input audio sheet (balance +
  monitoring, loaded on open, live via Input* events), media transport on
  ffmpeg/VLC rows (`mediaStates`, MediaInput* events → re-read), text
  source editing (`GetInputSettings` / `SetInputSettings` overlay).
- **A11y:** scene tiles collapse to one node ("Gameplay, on program" +
  mode hint); labelled eye/lock/filter/media/text/mute buttons; volume
  slider reads a percentage.
- **Settings:** "Kick Chats" data row; FAQ entries for Quick Connect, chat
  engines, Pro.
- Dropped dead `PlayPauseMedia` / `TransitionToProgram`. Stale notes in
  `dashboard-store-websocket-audit.md` and `state-and-plan.md` marked.
- Deferred (post-4.0): Live Activity / ongoing notification, home widget,
  Shortcuts, filter create/edit, stats export, connection sort, `ssid`.

## 2026-09-25 (evening) - 4.0: Pro copy refresh + version bump

- **Pro benefits** (`kProBenefits`) rewritten for what 4.0 actually
  ships: new **Combined Chat** and **Custom Themes** cards (Pro already
  unlocked themes, it just wasn't said), "Multi-Chat" became **Every
  Channel** (combos + live-at-a-glance), moderation copy is honest about
  what's Twitch-only (AutoMod, unban requests, chat modes). Eight cards
  now; the tablet grid is already count-agnostic.
- Paywall hero line, the "Welcome to Pro" thank-you and the locked native
  chat pane follow the same copy (the pane no longer says "Native Combined
  Chat" - Combined is native-only).
- `pubspec.yaml` → **4.0.0+2026092501**. Store metadata / README carry no
  Pro copy - untouched.

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
- **Channel mod sheets for Kick + YouTube, tabbed in Combined** (dogfood
  ask). Verified against the live API docs (2026-09-25): Kick's public
  API only has send / delete / ban-timeout-unban (no modes, clear,
  announce, ban list, moderators); YouTube adds polls (`pollEvent`
  insert + `liveChatMessages.transition` close) and owner-only
  `liveChatModerators` list/insert/delete, no modes/clear/announce/ban
  list. Kick panel: modes read-only, bans seen this session (own + other
  mods' `UserBannedEvent` echoes, `ChatBanEntry`) with Unban, unban by
  username (anonymous slug → `user_id`). YouTube panel: start/end poll,
  bans seen (liftable only when issued here — `ban()` now returns the
  ban id `liveChatBans.delete` needs), moderators on the own channel +
  "Make moderator" in the message sheet. Both shields show whenever
  signed in with write access (no mod lookup exists); a 403 sets
  `modActionForbidden` / `moderationForbidden` and toasts
  `chatNotModeratorText` instead of a raw error. Combined: shield →
  `CombinedChannelModSheet`, one tab per moderatable source (Twitch when
  it moderates the combo channel), each tab the platform's own panel
  (`ChannelModSheet(embedded: true)` for Twitch). Shared rows:
  `dialogs/channel_mod_chrome.dart`. Poll creation is untested live.
  Dogfood follow-up: the combined sheet always shows one tab per source
  (the shield too, whenever the combo has sources). A tab that can't be
  moderated (`combinedModBlock`: not set up / signed out / old Twitch
  scopes / not a Twitch mod / unavailable) dims with a lock and explains
  why, offers the fix (reusing `combinedSourceFix`) and lists what that
  platform's mods could do (`kCombinedModCapabilities`).
- **Live vs connected, disambiguated** (dogfood: "x/y live" counted
  connections and the green dots read as on air). Rule now: "LIVE" and
  the live green mean only *streamer on air*; a healthy chat connection
  is quiet. `CombinedSourceStatus.live` → `connected`. Combined card:
  on-air ring + "LIVE" pip on the badge, `CombinedLiveSummary` (LIVE ·
  n · viewers, or "Offline"), a red ⚠ `CombinedIssueMarker` count for
  sources that need the user. Badge stack: ring = on air, corner marker
  = connecting (amber spinner) / needs attention (red !), plain = fine.
  Source strip: `LIVE · viewers` / issue + label / "Offline". Sources
  sheet: two lines ("On air · 850 viewers" + "Chat connected"). Platform
  window headers: connected = neutral dot, no label (only connecting /
  reconnecting / failed / offline print).
  Follow-up: the LIVE pip is 6pt without an outline (merges with the
  ring, fits the 26px switcher badge), and the switcher shows on-air
  rings + a LIVE summary for every combo, not only the selected one
  (`CombinedChatStore.liveSourcesOf` over the platforms' per-channel
  live data; `refreshLivePreviews` when the sheet opens). With several
  sources live the card stays one chip: "LIVE · 3 · 12.4k".
  Dogfood bug: viewer counts froze after the connect. Kick resolved the
  selected channel's `channelInfo` (live + viewers) once per connect —
  the minute-interval preview round now carries fresh `livestream` data
  into it (`_applyLiveInfo`). YouTube read `concurrentViewers` once per
  stream — the poll loop now re-reads it every
  `kViewerRefreshInterval` (2 min, 1 quota unit each). Twitch already
  re-polls every minute.
- **Faster live data + instant on/off air** (dogfood: "the faster the
  better"). Intervals sized to each platform's limits: Twitch batch poll
  10 s (`kTwitchLivePollInterval`; one Helix request covers ≤100 ids),
  Kick 15 s for the channel on screen (`kKickSelectedLiveInterval`, one
  anonymous request) + 60 s for the list, YouTube viewers 30 s
  (`kViewerRefreshInterval`, ~120 units/h ≈ 3% over the chat poll).
  Push instead of poll for the flip itself: Twitch EventSub
  `stream.online` / `stream.offline` v1 (no scope; wired via
  `TwitchEventSubService.onStreamStatus` so the store's factory seam
  stays put), Kick `channel.{id}` Pusher channel (`StreamerIsLive` /
  `StopStreamBroadcast` — community-documented, subscription verified
  live 2026-09-25, events not yet captured on a real go-live).
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
