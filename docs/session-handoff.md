# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-10-07** (the 4.1.0
publish session).

**Update 2026-10-07 — 4.1.0 LIVE on both stores; feature branch merged
back into master.** Build 2026100501 (release commit `4c0c3e28`, tag
`4.1.0` pushed): App Store `READY_FOR_SALE` (manual release to everyone),
Play production at 100% (user pressed **Publish**). The publish surfaced a
stale-language trap: the Play listing's **default language was en-GB**
with pre-4.0 content - every `metadata android` push only ever updated
en-US, so the queued 4.1.0 changes showed the old screenshots. Fixed
(details: `changelog-agent.md` 2026-10-07): en-GB synced → removed (needed
en-US translations on the 4 tip IAPs first, written via
`oneTimeProducts:batchUpdate`), and `release preflight` now fails when the
store has listing languages beyond `fastlane/metadata/android`
(`f77e9167`). Both stores' listings audited byte-for-byte against the repo
before publish - clean. **`feature/preview-transitions` merged into
master** (`bd0a5581`, gates green: 1930 tests) - work from master again;
the remote branch is kept for now.

Also shipped 2026-10-07 (details: changelog same date): website 4.1 copy
live on obs-blade.kounex.com; **universal App Store creative asset** (iOS 27 Header + Search results)
approved by the user, versioned at `fastlane/assets/ios/universal.png`
(5244×2950, from the store-shots composer's `apple-universal` set) and
**submitted to App Review** via the new `release assets ios` command
(Asset Library API; asset `aa400005-…`, WAITING_FOR_REVIEW) - once
approved: `release attach ios` places it on the live version's header +
search results (placement create on a READY_FOR_SALE version is the
Console "Publish" equivalent - unprobed until this first approval);
compositor's review gallery hosted at
**https://obs-blade-gallery.kounex.com** (Cloudflare Access/Authentik, NAS
:8460, re-renders live).

**Watch:** crash reports + reviews for 4.1.0. Open follow-ups:

1. **Creative assets (2026-10-10)**: the universal image was approved and
   placed (live since 2026-10-09), but cropped badly per slot on iPhone
   (header cut the headline, search card mostly empty). Replaced by two
   dedicated images, `fastlane/assets/ios/header.png` (3840×1646) +
   `search.png` (3840×2560), submitted together via `release assets ios`.
   **When approved** → `release attach ios` (dry run, then --yes) on the
   workstation: it deletes the universal's placement per slot and places
   the new one (delete + create is unprobed on a live version). Check on
   a phone afterwards. How to make new ones: store-shots `AGENTS.md` → "Creative assets".
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
