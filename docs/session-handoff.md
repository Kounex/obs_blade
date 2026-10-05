# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-09-25**, top block
updated **2026-10-04** (4.0.1 live, 4.1.0 build 2026100402 in testing) (end of
the combined-chat session: combined chat waves 1–3, channel mod sheets,
picker live tags, status-language cleanup, faster live data. ~47
commits, pushed, deployed to Kounex iOS, user-approved on device.
Details: `changelog-agent.md` 2026-09-24 / 25 entries).

**Update 2026-10-03 — 4.1.0 beta for dogfooding:** build **2026100303**
on TestFlight + Play internal (verified `VALID` / internal, no secret in
either binary; 2026100301 had the Kick client secret compiled in - see
changelog "Kick sign-in: client secret"; 2026100302 lacked the YouTube
read-only fix).
**Kick client secret rotated 2026-10-03** (server side verified, see
changelog); new builds never carry it (`release preflight` guard).
Since build 2026100303, `master` has more YouTube fixes (console-accurate
setup steps, Brand Account / no-channel sign-in, own channel named by
title, header sheet offline vs signed out) - on Kounex iOS as a dogfood
install (92246187), not in a store build: per the user, iterate on device
first and cut the next test build only after an on-device OK.
Build 2026100303: activity feed, TTS, YouTube read-only setup flow,
canvases, plus paywall cards / FAQ / store listings / release notes for
them (details: `changelog-agent.md` 2026-10-03 "4.1.0 beta"). The Play
"what's new" is locked for this build. Nothing submitted; 4.0.1 is still
published 2026-10-04 - `release-promote` 4.1.0 once the user is happy with it on device
(promote also pushes the changed iOS + Play listing text). At the 4.1
store release the maintainer's site gets its pending feature copy
(website project's AGENTS.md § Pending) - the privacy policy for the
Kick events relay + TTS is already live.

**Update 2026-10-03 (later) — chat review fixes, not on a device yet:**
a `/code-review high` + chat journey walk found 8 issues, all fixed on
`master` (`5e72ca18..`; changelog "chat review fixes"): YouTube "polled
too soon" no longer stops the chat for the day + auto-restart after the
quota reset, combined chat no longer starts every platform chat at launch,
own YouTube channel in saved combos = "You", no `UC…` ids as names,
activity empty state, adding a channel shows it, YouTube dead-session /
no-channel states, transport failures in Settings → Logs. The dogfood
phone was offline, so at the user's request these went straight out as
**build 2026100305** (TestFlight `VALID` + Play internal, 4.1.0; build 5 adds the chat bar without account chip; store
notes unchanged, TestFlight "What to Test" = the device check list). Next:
the user's on-device verdict, then `release-promote` 4.1.0 (after 4.0.1 is
published).

**Update 2026-10-05 — session chat history shipped to master** (`e229facf`,
`b8c2b489`, `b97f048f`; changelog same date): `ChatHistoryStore` keeps the
full models evicted from the 500-row live buffers - one global in-memory
200k FIFO across platforms, per-user index, erased on sign-out (not Kick) /
channel removal / app restart, /clear deliberately KEEPS it (mirrors the
content-visible tombstone UX). User cards show 50 rows + a one-way "Show X
older messages" expansion off a lazy list. The cap is **configurable**
(`a941c4ba`..`d7f6055f`): options sheet → All chats → **Session history**
page - explainer, 10k–200k slider in 10k steps (default **50k**), worst-case
memory estimate (cap × 1280 B, green ≤ 75 MB / amber ≤ 150 MB / red above).
Reviewer-approved; NOT on a device yet - dogfood list in the changelog
entry. Also shipped: user-card
history timestamps on YouTube/Kick (`6e015a6b`, in 4.1.0 build 2026100402's
successor). Next: dogfood, then it rides the next 4.1.0 beta.

**Update 2026-10-04 (later) — releases:** **4.0.1 is live on both
stores** (App Store `READY_FOR_SALE`, Play production 2026093001 at
100%; tag `4.0.1`). Watch crash reports / reviews. **4.1.0 build
2026100402** (`64aa7fa4`) is on TestFlight (internal testers) + Play
internal (supersedes 2026100401; adds the post-`7f652104` chat wave -
YouTube emojis + picker, user cards on YouTube/Kick, one options sheet,
scrolled-up reading fixes, background chat recovery, grouped scene-item
toggles, the capped-buffer notice re-fade fix; notes re-approved by the
user, Play what's new adds the emoji bullet). TestFlight "What to Test" =
`fastlane/testflight_notes.txt`.
Next: the user's verdict on that build, then `release-promote` 4.1.0
(also pushes the regrouped store descriptions + promo text), and at the
store release the website's `pending-4.1/` goes live
(`obs-blade-site/AGENTS.md` § Pending).

**Update 2026-10-04 — activity feed status banner + own YouTube
collection** (`2531ef9e..2666bb89`, changelog 2026-10-04; spec
`superpowers/specs/2026-10-04-activity-feed-status.md`): built, tested,
reviewed, pushed, on Kounex iOS and in test build 2026100401.

**Update 2026-10-03 — global Pro pricing overhaul (both stores
re-priced):** a Turkish monthly sub came through at ~€0.80; the audit
found nominal parity was currency-blind AND Apple's equalized-tier matrix
deviates >20% from FX+tax reality in ~30 currencies in both directions.
Both stores now price from one reviewed table
(`tool/provisioning/lib/src/pricing_targets.dart`, Google
convertRegionPrices 2026/01; anchors USD/EUR/GBP nominal, CNY Apple
China, CHF split CH/LI). Applied live: Play fully re-priced (174
regions × all 3 products, instant); App Store subs re-priced via
**scheduled** changes effective **2026-10-05** (approved subscriptions
reject immediate price POSTs — 409 STATE_ERROR; `preserveCurrentPrice`
grandfathers existing subscribers). The one existing subscriber
(Turkish, Play monthly, old cheap price) keeps their price. Post-run
audit: zero subscription outliers; `inspect_products.dart` 175/175
parity on both subs. The iOS lifetime IAP stays on Apple's
auto-equalized schedule (its COP/PEN deviations are Apple's own,
deliberately untouched). Recurring duty: re-run
`bin/audit_prices.dart` + `bin/generate_pricing_targets.dart` when FX
moves (quarterly-ish), workflow in `tool/provisioning/README.md`
§ Pricing table. Details: `changelog-agent.md` 2026-10-03 entry.

**Update 2026-09-27 — intro v2 shipped to dogfood** (awaiting the
user's on-device verdict): the intro was rebuilt as 4 swipeable screens
with code-drawn animated mockups; every user sees it once via the new
`HasUserSeenIntro202609` key. Spec:
`archive/specs/2026-09-27-intro-v2-design.md`, details:
`changelog-agent.md` 2026-09-27 "Intro v2". Verified on the Pixel 7
emulator (full flow + relaunch) and installed on Kounex iOS. Watch
first: tablet/landscape on a real iPad, copy wording, and mockup loop
smoothness on older phones.

**Media hub outside the live scene (2026-09-28, later):** rebuilt on
what OBS 32 really does per source (`restart_on_activate` off = keeps
playing unheard, on = "Restarts when live"); the earlier "On hold" model
was wrong. Probe table: `changelog-agent.md` 2026-09-28 "Media outside
the live scene, per source". Awaiting the user's on-device check; VLC
mapping unprobed.

**Manage subscription (2026-09-28, later):** iOS opens StoreKit's
in-app sheet (also lists TestFlight subscriptions), Android opens Play's
page for the Pro subscription. Installed on Kounex iOS; confirm on the
next TestFlight build that a TestFlight subscription shows and cancels
there. Details: `changelog-agent.md` 2026-09-28 "Manage subscription".

**Releases:** 4.0.1 live on both stores since 2026-10-04 (tagged);
releases are tagged with the bare version, process in
`docs/release-playbook.md` + `.claude/skills/release-*`.

**Update 2026-09-27 (late) - store screenshots redesign** (awaiting the
user's verdict on the composed sets): capture tooling in
`tool/store_screenshots/` (README there; dedicated sims/AVDs only), composed
sets live outside the repo (maintainer's store-shots composer). Also
shipped: statistic detail charts 2-per-row on tablet + `BaseCard` measure
640 -> 720 + wide tier 1040 (user decision), autodiscover no-WLAN
unhandled error; tablet transition row aligned with the cards. The
composed sets are committed (`fastlane/screenshots/en-US` for App Store,
`fastlane/metadata/android/en-US/images` for Play + F-Droid, tablets in
landscape) - F-Droid now shows the Pro-tagged combined chat slide too.
Details:
`changelog-agent.md` 2026-09-27 "Store screenshots".

## Handoff hygiene (read before editing this file)

- **This is a baton, not a history log.** It holds only what the *next*
  session needs to pick up work right now — current branch, immediate open
  threads, pointers to the docs with real depth. If you're about to narrate
  *what happened and why*, that belongs in `changelog-agent.md` (history) or
  a dedicated `docs/*.md` (architecture/design/strategy) — leave only a
  pointer here, not the content itself.
- **Clear and rewrite this file at every handoff**, don't accumulate on top
  of the previous version. A stale "still open" note here caused real
  confusion once already: this file kept saying a release blocker was open
  well after it had actually been resolved on the other machine, because
  nobody reset it — they just left the old narrative in place and it quietly
  went stale.
- **`git fetch --all` before trusting anything here or in `AGENTS.md`** —
  diff your branch against its remote counterpart and skim recent log. This
  file is only as current as whoever last updated it remembered to make it.
- **Non-public docs live in `docs/private/`** (gitignored — this repo is
  public; git will never sync it). The sync is **manual, mandatory, and
  same-turn**: after *any* create/edit/delete there, mirror to the other
  machine immediately — no "sync later", that's how the copies silently
  drift — and verify the mirror with checksums. At session start, confirm
  both copies are in sync *before* trusting or editing anything there.
  Exact commands + machine topology: `docs/private/maintainer-workflow.md`
  (maintainer machines only). Don't let state exist on only one machine.

## Workspace facts

| | |
|---|---|
| Remote | `Kounex/obs_blade` (**public**) |
| Branch | **`master`** (4.0 UI rework merged 2026-09-22; `redesign` kept as history) |
| Users | 500k+ live — persistence + release paths are sensitive |
| Form factors | First-party **phone and tablet** — see `AGENTS.md` + `redesign/design-system.md` § Responsive layouts |

### Machines

The maintainer works from a two-clone setup (headless analyze/test clone +
workstation simulator/device clone). Topology, paths, SDK locations, and
the dogfood handoff rule are maintainer-only and live in
`docs/private/maintainer-workflow.md` (gitignored). Contributors: ignore —
build and test from your own checkout per `AGENTS.md`.

Commit per verified unit proactively (small, logically-scoped commits).
Push when the user asks, and always at wrap-up/handoff — the remote is the
source of truth; never leave work local-only when handing over.

## Right now

**Just closed: the combined-chat session** (NAS, 2026-09-24 → 25,
`82fd1c66..HEAD`, all pushed; the workstation is on the same commit and
"Kounex iOS" runs that release build with `PRO_RELEASE_TEST_UNLOCK` +
the Kick OAuth defines — recipe in `docs/private/maintainer-runbooks.md`
§ Dogfood release). What shipped (details: `changelog-agent.md`
2026-09-24 / 25 entries, rules: `AGENTS.md` § Combined chat):

- **Combined chat, waves 1–3** — merged Twitch + YouTube + Kick timeline,
  "My chats" + saved combos (builder, same-name suggestions, switcher),
  focus jump + "↩ Combined", writing (target chip, replies, per-platform
  long-press sheets, emotes/autocomplete follow the target).
- **Channel mod sheets** for Kick + YouTube (shield always shown while
  signed in; 403 → "not a moderator" toast) and a **tabbed** combined
  mod sheet (one tab per source, blocked tabs explain why + fix).
- **Channel pickers**: own first then A–Z, height-capped + scrolling,
  LIVE · viewers / OFFLINE tags everywhere (YouTube via the quota-free
  `/live` check).
- **Status language**: "LIVE" / live green = streamer on air only;
  connection health is quiet (problem markers only). On-air rings + LIVE
  pip on badges, `LIVE · n · viewers` summary, every combo in the
  switcher shows who's live.
- **Live data**: Twitch poll 10 s + EventSub `stream.online/offline`;
  Kick 15 s for the channel on screen (60 s list) + `channel.{id}`
  `StreamerIsLive` / `StopStreamBroadcast`; YouTube viewers every 30 s.

**Dogfood status:** the user reports everything **currently good** on
device (end of session). Nothing open from this session; the user will
report findings. **Unverified against live services** (only fakes /
docs so far) — watch these first when feedback arrives:
- Kick `StreamerIsLive` / `StopStreamBroadcast` push: the `channel.{id}`
  subscription is verified live, an actual go-live event is not
  captured yet (fallback: the 15 s refresh).
- YouTube poll start/end + moderator list/add/remove (docs-built).
- Twitch `stream.online` / `stream.offline` EventSub (standard, but first
  use in this app).

**Store/Pro state:** products on both stores at **$4.99/mo,
$49.99/yr, $99.99 lifetime**; ASC products approved with 4.0 (2026-09-29);
Play products ACTIVE; RevenueCat live (`pro`); Play RTDN test
notification received (2026-09-30). Open: Apple Small Business Program. Upload key
A6:24:44 still "in review" — after it resolves, delete
`android/app/src/main/assets/adi-registration.properties` and discard
Play internal-track draft `3.3.0 (2026090701)`.

**Immediate next threads:**

1. Act on dogfood findings (combined chat, mod sheets, live data).
2. **Chat: Chatterino "medium" items** (`chatterino-comparison.md`
   verdict table): configurable mod buttons / timeout lengths, custom
   commands with OBS variables, search operators (`from:`, `has:link`,
   `is:first-msg`), OBS-driven streamer mode. Strategic: 7TV cosmetics
   (paints, personal emotes via EventAPI), live emote-set updates.
   YouTube: OAuth own-channel path (`liveBroadcasts.list`), OBS
   `StreamStateChanged` → immediate re-resolve. Watch Kick's Pusher →
   Centrifugo migration risk (the combined chat's Kick live push rides
   the same socket).
3. **Finish RevenueCat** (SBP enroll).
4. **Android runtime smoke** + release mechanics (version/changelog,
   `fastlane/metadata`, visual-QA pass) — the combined chat has never
   run on Android.
5. YouTube quota spike (`tool/youtube_spike/`) — still pending; the 30 s
   viewer refresh adds ~120 units/h per connected chat on top.
6. Astra follow-ups (post-4.0 ok): conversation-owned drafts wave;
   optional live-session strip; syncOffset gating.
7. **Activity feed v1 built (2026-10-03, not yet on a device):** Chat |
   Activity segment, header bell, streaming chip, Kick events relay at
   `kick-events.obs-blade.com` (Kick's webhook URL must point there).
   Check first on a device: Twitch re-sign-in
   for the activity scopes, a real follow / sub / cheer, the Kick relay
   after the webhook URL is set in Kick's developer settings. Next:
   StreamElements / Streamlabs once their API access is approved.
   [`activity-feed-idea.md`](activity-feed-idea.md), spec
   `superpowers/specs/2026-10-02-activity-feed-design.md`.

**Chat conventions (keep them):**
- Sheets: build on `NativeChatSheetScaffold` (pinned header, scrolling
  body); channel-mod rows from `dialogs/channel_mod_chrome.dart`.
- History rows: `isHistorical` + `kChatHistoryOpacity` +
  `ChatHistoryDivider`. Filters via `ChatFilterSettings`, appearance via
  `NativeChatAppearance`.
- "LIVE" / live green = on air only; connection problems use
  `CombinedIssueMarker` / labels, a healthy connection shows nothing.
- Kick / YouTube mod actions: no mod lookup exists — always offer, map a
  403 to `chatNotModeratorText`.
- Network-facing helpers get a live smoke as a throwaway `flutter test`
  file (plain `dart run` can't compile the freezed chat models). Kick's
  `kick.com/api/v2` rejects `dart:io`'s default client with a Cloudflare
  403 — use the app's browser UA or `curl -A` for smokes.

Process notes: default process tier **S** (feature work - OBS, chat, sign-ins, new or existing: **M** via the `feature-work` skill, see `AGENTS.md` § Definition of done); `AGENTS.md` session-start
checklist is resume-proof (run it anyway). Former known flakes are
**fixed** (2026-10-01, changelog same date): the 4
`mod_action_sheet_test.dart` hit-test failures (pin banner overlaying
the first row — `pumpChatView` clears it) and the intermittent
`state_ordering_test.dart` (now deterministic via `FakeObsPeer`
hold/release + a `GetVersion` flush, no wall-clock sync). Random
single-file "loading" `WebSocketException`s on long runs are the NAS
runner flake — run gates through **`dart tool/test_gate.dart`**
(`--runs=N` for consecutive-clean proofs), which auto-retries just
those files and fails only on real test failures. Full serial chat +
persistence gate ≈ 5 min
here (~1150 tests). **Gotchas:** a Hive `put` inside a `testWidgets`
body hangs the whole file at teardown ("Cannot close sink while adding
stream") — wrap it in `tester.runAsync` + `flush()`, or use a plain
`test`. `test/flutter_test_config.dart` holds suite-wide network mocks
(extend it). `pkill -f` patterns matching `flutter` can kill your own
shell — kill by pid. Never answer an interactive `rm -i` — use `rm -f`
(one sat blocked for 19 h this session).
Machine note (this box): **`/tmp` is a 3.8G tmpfs** — if it fills with
`flutter_tools.*` dirs, `flutter test` hangs silently; `rm -rf
/tmp/flutter_tools.*` and re-run. Always `flutter test -j 1` here;
`build_runner` here re-resolves `pubspec.lock` to the older local SDK —
`git checkout pubspec.lock` (and any unrelated `.g.dart`) before
committing.

## Verify quickly

```bash
git checkout master && git pull               # all work lands here now
flutter test -j 1                            # serial on this box
dart analyze                                 # expect baseline infos, 0 errors
```

Maintainer: machine-specific verify, simulator, and visual-QA commands are
in `docs/private/maintainer-workflow.md`.

## Doc map

| Doc | Topic |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Short project rules + index |
| [`changelog-agent.md`](changelog-agent.md) | History of agent changes |
| [`redesign/2026-iteration/state-and-plan.md`](redesign/2026-iteration/state-and-plan.md) | 4.0 shipped; the doc now holds the phase-4 backlog + open decisions |
| [`archive/redesign/ui-polish-audit-2026-09-21.md`](archive/redesign/ui-polish-audit-2026-09-21.md) | 4.0 polish wave: findings→fixes map, calibrations, leftovers (archived) |
| [`chatterino-comparison.md`](chatterino-comparison.md) | Chatterino feature verdicts + YouTube channel→live design (2026-09-24 wave) |
| [`superpowers/specs/2026-09-24-combined-chat-design.md`](superpowers/specs/2026-09-24-combined-chat-design.md) | Combined chat design (waves 1–3 shipped; plans in `archive/plans/`) |
| [`chat-native-roadmap.md`](chat-native-roadmap.md) | Native chat API roadmap — waves 1–3 shipped, Pro gate live; wave-4 item selection next |
| [`redesign-astra-audit.md`](redesign-astra-audit.md) | Astra redesign audit + ratified progressive-adoption verdict, verified master defects, harvest list |
| [`archive/specs/2026-09-14-command-ack-layer-design.md`](archive/specs/2026-09-14-command-ack-layer-design.md) | Command-ack layer (astra phase 2) — ratified design, merged 2026-09-18 (archived) |
| [`archive/specs/2026-08-09-mod-overflow-options-design.md`](archive/specs/2026-08-09-mod-overflow-options-design.md) | Mod overflow into Options (archived) |
| [`archive/specs/2026-08-09-chat-notice-meta-design.md`](archive/specs/2026-08-09-chat-notice-meta-design.md) | Notice meta + announce chrome (archived) |
| [`archive/specs/2026-08-09-chat-user-card-design.md`](archive/specs/2026-08-09-chat-user-card-design.md) | User card (archived) |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`revenuecat-setup.md`](revenuecat-setup.md) | Pro subscription wiring + sandbox dogfood |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
