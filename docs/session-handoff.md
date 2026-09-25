# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-09-25** (end of
the combined-chat session: combined chat waves 1–3, channel mod sheets,
picker live tags, status-language cleanup, faster live data. ~47
commits, pushed, deployed to Kounex iOS, user-approved on device.
Details: `changelog-agent.md` 2026-09-24 / 25 entries).

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
the Kick OAuth defines — recipe in `docs/private/maintainer-workflow.md`
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

**Store/Pro state (unchanged):** products on both stores at **$4.99/mo,
$49.99/yr, $99.99 lifetime**; ASC products submitted 2026-09-08 — watch
for approval; Play products ACTIVE; RevenueCat live (`pro`). Open: Play
RTDN test notification (Pub/Sub perms), sandbox dogfood per
`revenuecat-setup.md` §5, Apple Small Business Program. Upload key
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
3. **Finish RevenueCat** (RTDN retry, sandbox dogfood §5, SBP enroll).
4. **Android runtime smoke** + release mechanics (version/changelog,
   `fastlane/metadata`, visual-QA pass) — the combined chat has never
   run on Android.
5. YouTube quota spike (`tool/youtube_spike/`) — still pending; the 30 s
   viewer refresh adds ~120 units/h per connected chat on top.
6. Astra follow-ups (post-4.0 ok): conversation-owned drafts wave;
   optional live-session strip; syncOffset gating.

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

Process notes: default process tier **S**; `AGENTS.md` session-start
checklist is resume-proof (run it anyway). Known flakes (don't chase):
4 `mod_action_sheet_test.dart` hit-test-offset failures (reproduce on
the pre-change tree too), `test/websocket/state_ordering_test.dart`
(intermittent), random single-file "loading" `WebSocketException`s on
long runs (rerun the file). Full serial chat + persistence gate ≈ 5 min
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
| [`redesign/2026-iteration/state-and-plan.md`](redesign/2026-iteration/state-and-plan.md) | 4.0 cold-start briefing (read first) |
| [`redesign/2026-iteration/ui-polish-audit-2026-09-21.md`](redesign/2026-iteration/ui-polish-audit-2026-09-21.md) | 4.0 polish wave: findings→fixes map, calibrations, leftovers |
| [`chatterino-comparison.md`](chatterino-comparison.md) | Chatterino feature verdicts + YouTube channel→live design (2026-09-24 wave) |
| [`superpowers/specs/2026-09-24-combined-chat-design.md`](superpowers/specs/2026-09-24-combined-chat-design.md) | Combined chat design (waves 1–3 shipped; plans next to it) |
| [`chat-native-roadmap.md`](chat-native-roadmap.md) | Native chat API roadmap — waves 1–3 shipped, gate decision + wave 4 next |
| [`redesign-astra-audit.md`](redesign-astra-audit.md) | Astra redesign audit + ratified progressive-adoption verdict, verified master defects, harvest list |
| [`superpowers/specs/2026-09-14-command-ack-layer-design.md`](superpowers/specs/2026-09-14-command-ack-layer-design.md) | Command-ack layer (astra phase 2) — ratified design, merged 2026-09-18 |
| [`superpowers/specs/2026-08-09-mod-overflow-options-design.md`](superpowers/specs/2026-08-09-mod-overflow-options-design.md) | Mod overflow into Options |
| [`superpowers/specs/2026-08-09-chat-notice-meta-design.md`](superpowers/specs/2026-08-09-chat-notice-meta-design.md) | Notice meta + announce chrome |
| [`superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md) | User card |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`revenuecat-setup.md`](revenuecat-setup.md) | Pro subscription wiring + sandbox dogfood |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
