# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-10-17** (4.2
additions session).

**Live:** 4.1.0 (build 2026100501, tag `4.1.0`) on both stores. Branch
`master`. Releases now run through **store-release** (`release.yaml`,
user commit `5438fc60`); the old `tool/release` stays until a beta went
through store-release on both stores - the next 4.2.0 beta is that beta.

**4.2.0 - next: new beta build.** Build 2026101101 (TestFlight + Play
internal, release commit `007ffabb`) is **superseded**: 2026-10-17 added
#93 Search on Start (`4cb078c9`) and the iOS QR landscape fix #95
(`c40cef0c`, qr_code_scanner_plus 2.3.0) - details: `changelog-agent.md`
2026-10-17. Release notes (both stores, Play ≤ 500 chars) and the tester
checklist `fastlane/testflight_notes.txt` ("test build 2") are updated.
**Build 2026101701** (release commit `b5978aa4`, pushed) goes straight to
TestFlight + Play internal - the user skipped the dogfood device step
for this one (2026-10-17), 4.2 goes live after the beta test. Waiting
on the MacBook (offline): pull there, `release preflight` (first run of
store-release - read the `beta` dry-run plans once), then build +
upload detached per `release-beta` step 6, then `release status`. After
that: beta test incl. upgrade over 4.1.0 -> `release-promote`.
`/code-review high` on
`4.1.0..HEAD` ran 2026-10-17: 3 real findings fixed (`cdb345df`,
`d00ae5ea`), the rest noted as not changed - changelog same date.

Not verified live (MacBook was offline): Android QR orientation (#95 -
no defect found in zxing's source, not reproduced), the replay buffer
read on connect against a real OBS (#96, fixed in 4.1.0 by `e65f3aaf`),
and `instant_replay.trigger` fired from the Hotkeys sheet with
obs-studio's `instant-replay.lua` loaded (user email, see below).

**On 4.2 publish (user said: post then):** reply on GitHub + close -
#100 (fade transitions now play in the preview - 4.2), #96 (fixed in
4.1.0: the app read an old v4 field), #93 (Settings -> General -> Search
on Start). #95: reply with the iOS fix, ask the reporter which platform
they use and to retest on 4.2 - close only if they confirm or don't
answer. Email from an Android volleyball streamer (instant-replay.lua
hotkey): answer drafted in the 2026-10-17 session - the existing Hotkeys
sheet triggers it (Settings -> Dashboard -> Customisation -> Hotkeys,
then search `instant_replay.trigger`); the user sends it.

**Watch:** crash reports + reviews for 4.1.0. Open follow-ups:

1. **Creative assets**: v1 header + search images are live (4.1.0 en-US).
   In review: **v2 header + v3 search images** (2026-10-11, submission
   `1ec1788c-…`) and, since 2026-10-12, the same compositions as
   **15 s "live image" videos** (assets `eec00005-…` header /
   `2cc00005-…` search, submission `58711c06-…`; rendered by store-shots
   cuts `appstore-header` / `appstore-search`, never committed - render
   ad hoc on the NAS). **When approved:** `release attach ios` (dry run,
   then --yes) places the newest approved asset per slot - the videos
   win over the images once they're through. Then ask for phone
   screenshots / a screen recording of the product page + a search
   result: how iOS plays them (loop, autoplay, muted, poster) is
   unverified.
2. Upload key A6:24:44 still "in review" → after it resolves, delete
   `android/app/src/main/assets/adi-registration.properties` and discard
   Play internal-track draft `3.3.0 (2026090701)`.

**Store/Pro state:** 4.1.0 live; products approved on both stores
($4.99/mo, $49.99/yr, $99.99 lifetime; global price overhaul 2026-10-03);
RevenueCat live (`pro`); Play RTDN test received. Open: Apple Small
Business Program enrollment.

**Backlog threads (unchanged, pick up as agreed):** Chatterino "medium"
items (`chatterino-comparison.md`); YouTube quota spike
(`tool/youtube_spike/`); activity feed next: StreamElements/Streamlabs
once API access is approved; Kick Pusher → Centrifugo migration risk;
intro v2 tablet/landscape check; media hub VLC mapping unprobed; Astra
follow-ups (post-4.0 ok).

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
| Branch | **`master`** (everything lands here; `feature/preview-transitions` merged 2026-10-07) |
| Users | 500k+ live — persistence + release paths are sensitive |
| Form factors | First-party **phone and tablet** — see `AGENTS.md` + `redesign/design-system.md` § Responsive layouts |
| Live version | **4.1.0** (build 2026100501, tag `4.1.0`) on both stores since 2026-10-07 |

### Machines

The maintainer works from a two-clone setup (headless analyze/test clone +
workstation simulator/device clone). Topology, paths, SDK locations, and
the dogfood handoff rule are maintainer-only and live in
`docs/private/maintainer-workflow.md` (gitignored). Contributors: ignore —
build and test from your own checkout per `AGENTS.md`.

Commit per verified unit proactively (small, logically-scoped commits).
Push when the user asks, and always at wrap-up/handoff — the remote is the
source of truth; never leave work local-only when handing over.

## Process notes (keep them)

- Default process tier **S**; feature work (OBS, chat, sign-ins, UI in
  dashboard/chat): **M** via the `feature-work` skill (see `AGENTS.md`
  § Definition of done).
- Test gates on the NAS through **`dart tool/test_gate.dart`**
  (`--runs=N` for consecutive-clean proofs) - auto-retries the
  flutter_tester load flake. Full serial chat + persistence gate ≈ 5 min
  (~1150 tests). Don't run `flutter test` concurrently with analyze.
- Gotchas: a Hive `put` inside a `testWidgets` body hangs the file at
  teardown - wrap in `tester.runAsync` + `flush()`, or use a plain `test`.
  `test/flutter_test_config.dart` holds suite-wide network mocks.
  `/tmp` on the NAS is a 3.8G tmpfs - `flutter_tools.*` dirs filling it
  hang `flutter test` silently (`rm -rf /tmp/flutter_tools.*`). Always
  `flutter test -j 1` here; `build_runner` here re-resolves `pubspec.lock`
  to the older local SDK - `git checkout pubspec.lock` before committing.
  `pkill -f <pattern>` matching your own command kills your shell - kill
  by pid. Never answer an interactive `rm -i`/`cp -i` - use `-f`.
- Chat conventions: sheets on `NativeChatSheetScaffold`; mod rows from
  `dialogs/channel_mod_chrome.dart`; history rows `isHistorical` +
  `kChatHistoryOpacity` + `ChatHistoryDivider`; "LIVE"/live green = on air
  only (connection problems use markers); Kick/YouTube mod actions: always
  offer, map 403 to `chatNotModeratorText`; network-facing helpers get a
  live smoke as a throwaway `flutter test` file; Kick's `kick.com/api/v2`
  needs a browser UA.

## Verify quickly

```bash
git checkout master && git pull               # all work lands here
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
| [`chatterino-comparison.md`](chatterino-comparison.md) | Chatterino feature verdicts + YouTube channel→live design |
| [`superpowers/specs/2026-09-24-combined-chat-design.md`](superpowers/specs/2026-09-24-combined-chat-design.md) | Combined chat design (waves 1–3 shipped; plans in `archive/plans/`) |
| [`chat-native-roadmap.md`](chat-native-roadmap.md) | Native chat API roadmap — waves 1–3 shipped, Pro gate live |
| [`chat-engines.md`](chat-engines.md) | Native chat engines + shared mechanics (shipped state) |
| [`redesign-astra-audit.md`](redesign-astra-audit.md) | Astra redesign audit + ratified progressive-adoption verdict |
| [`release-playbook.md`](release-playbook.md) | Store releases; skills `release-beta` / `-promote` / `-direct` / `-publish` |
| [`revenuecat-setup.md`](revenuecat-setup.md) | Pro subscription wiring + sandbox dogfood |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
