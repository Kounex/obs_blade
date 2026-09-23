# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-09-24** (Pro revert
gesture + the sheet drag-back saga — three real bugs found and fixed in
sequence, each caught by dogfooding the previous fix on the physical
device — + connect-box sequential crossfade + refresh-icon tuning,
shipped and pushed, 10 commits. Details: `changelog-agent.md` 2026-09-24
"Pro revert gesture + the sheet drag-back saga...").

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

**Just closed: dogfood-driven follow-up to the second polish batch** (NAS
session, process tier S throughout, every round built + installed to the
physical device and re-tested before the next). All 10 commits pushed
(`faa1b87b..499c37af`); full writeup: `changelog-agent.md` 2026-09-24
"Pro revert gesture + the sheet drag-back saga...". Workstation is on
`499c37af` too (built/installed/launched this session).

**Confirmed working by the user, live on device, this session:**
- Sheet drag-to-dismiss: grows back on a mid-gesture reversal (not just
  shrinks), the drag no longer dies after the first reversal step, and
  fling-to-dismiss now works from *inside* a sheet's scrollable content
  (previously only worked from a handle area outside it). Three separate
  root causes found and fixed in `lib/utils/modal_handler.dart`'s
  `_SheetOverscroll` - see the changelog entry for the blow-by-blow, worth
  reading before touching that class again.
- Home connect-mode crossfade: sequential fade (full fade-out, then full
  fade-in) instead of a simultaneous cross-dissolve.
- Home refresh icon: fades in starting at 25% of the pull threshold, full
  by 80%.

**Shipped but not explicitly re-confirmed by the user this session**
(implementation verified via tests, not called out again in feedback):
- Pro paywall vortex mark + stacked "PRO" badge (from the prior batch) -
  still only verified via an offscreen widget-test screenshot with a
  placeholder accent color, never confirmed against the real theme/device.
- The new revert gesture on `ProUnlockedView` (long-press the result icon
  to undo the debug/test unlock) - shipped this session, not tried live.
Worth a deliberate look at both next session if they haven't come up.

**Confirmed pre-existing, unrelated:** the 4 `mod_action_sheet_test.dart`
hit-test-offset flakes (documented in the audit-wave entry further below
in `changelog-agent.md`) - reproduce identically on commits before this
session's changes, so not a regression from this work. Also saw one
`test/chat/automod_queue_sheet_test.dart` "loading" WebSocketException
this session - passed cleanly in isolation immediately after, looked like
the same infra-level flake class as the documented ones, not a real
failure.

**Longer-running goal: 4.0 is shipped from `master`.** The 4.0 UI rework
(full-app polish wave + custom-theme cleanup + dogfood-fix batches) merged
and is dogfood-approved. Cold-start briefing on the ratified grammar + what
shipped:
[`redesign/2026-iteration/state-and-plan.md`](redesign/2026-iteration/state-and-plan.md);
findings→fixes map + known leftovers:
[`redesign/2026-iteration/ui-polish-audit-2026-09-21.md`](redesign/2026-iteration/ui-polish-audit-2026-09-21.md).

**Store/Pro state:** products exist on both stores with locked regionalized
pricing **$4.99/mo, $49.99/yr, $99.99 lifetime** (ASC 175/175 territories,
Play 173/173 regions). ASC products SUBMITTED for review 2026-09-08
(review screenshots uploaded) — watch for approval; Play products ACTIVE.
RevenueCat path is live (`pro` entitlement; keys pasted). Open: verify Play
RTDN test notification (Pub/Sub perms — service account admin again, retry);
sandbox dogfood per `revenuecat-setup.md` §5; enroll Apple Small Business
Program. Google developer verification DONE (`com.kounex.obsBlade`
Registered); upload key A6:24:44 still "in review" — after it resolves:
delete `android/app/src/main/assets/adi-registration.properties` and
discard Play internal-track draft `3.3.0 (2026090701)`.

**Immediate next threads:**

1. **Confirm the two not-yet-re-checked items** above (Pro paywall vortex
   mark/badge, the unlocked-page revert gesture) if they come up - both
   already installed on the workstation's dogfood device.
2. **Finish RevenueCat** (RTDN retry, sandbox dogfood §5, SBP enroll).
3. **Android runtime smoke** (emulator/device) — toolchain builds since
   2026-09-07; confirm release AABs sign with the upload key
   (`android/key.properties` → `android-release.jks`, A6:24:44).
4. Release mechanics: version/changelog, store metadata
   (`fastlane/metadata`), visual-QA pass
   (`tool/visual_qa/capture_screenshots.sh`).
5. YouTube (post-4.0 ok): run the spike (`tool/youtube_spike/`, ≥30 min
   busy chat) with the GCP key; the `private/backend-architecture.md`
   OAuth note stays deferred — **sync private docs first**.
6. Astra open follow-ups (post-4.0 ok): conversation-owned drafts wave;
   optional live-session strip; syncOffset gating. inspect-vs-command/Take
   bar will NOT be ported (Studio Mode covers it).

Process notes: `AGENTS.md` session-start checklist is resume-proof (run it
anyway). Default process tier **S**. Test gotchas are in
`changelog-agent.md` — incl. the known pre-existing
`test/websocket/state_ordering_test.dart` flake and the 4
`mod_action_sheet_test.dart` hit-test-offset flakes (both intermittent/
pre-existing, don't chase as regressions). `test/pro/` is the
purchase/entitlement suite home. New pattern noticed this session on full
multi-directory runs: occasionally exactly one file fails at the
"loading" step with `WebSocketException: Invalid WebSocket upgrade
request` - a different, random file each run, always passes cleanly on
its own immediately after. Looks like the same infra-level class as the
above two, not a real regression signal - re-run the specific file before
trusting a "loading" failure.
Machine note (this box): **`/tmp` is a 3.8G tmpfs** — if it fills with
`flutter_tools.*` dirs, `flutter test` hangs silently in the kernel
compiler ("Free up space"); `rm -rf /tmp/flutter_tools.*` and re-run.
Also watch for **stale `flutter_tester` processes** lingering across
separate `flutter test` invocations in the same session (kill by pid,
`ps aux | grep flutter_tester`) — they starve a fresh run the same way a
full tmpfs does. Always `flutter test -j 1` here; `flutter pub get` if a
restored `pubspec.lock` makes the tool re-resolve.

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
| [`chat-native-roadmap.md`](chat-native-roadmap.md) | Native chat API roadmap — waves 1–3 shipped, gate decision + wave 4 next |
| [`redesign-astra-audit.md`](redesign-astra-audit.md) | Astra redesign audit + ratified progressive-adoption verdict, verified master defects, harvest list |
| [`superpowers/specs/2026-09-14-command-ack-layer-design.md`](superpowers/specs/2026-09-14-command-ack-layer-design.md) | Command-ack layer (astra phase 2) — ratified design, merged 2026-09-18 |
| [`superpowers/specs/2026-08-09-mod-overflow-options-design.md`](superpowers/specs/2026-08-09-mod-overflow-options-design.md) | Mod overflow into Options |
| [`superpowers/specs/2026-08-09-chat-notice-meta-design.md`](superpowers/specs/2026-08-09-chat-notice-meta-design.md) | Notice meta + announce chrome |
| [`superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md) | User card |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`revenuecat-setup.md`](revenuecat-setup.md) | Pro subscription wiring + sandbox dogfood |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
