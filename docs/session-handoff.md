# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-09-21** (branch
`4.0-liquid-glass`: full-app UI polish wave landed — 10-area audit → 79
commits, gates green, pushed; next: user dogfoods the branch → Gate 3 →
merge. Details below + `changelog-agent.md` 2026-09-21).

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
| Branch | **`4.0-liquid-glass`** (all 4.0 work; `master` untouched; `redesign` kept as history) |
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

**Goal: ship 4.0.** All code lives on `4.0-liquid-glass` (pushed; checked
out on the workstation clone — `flutter run` there shows it). Read
[`redesign/2026-iteration/state-and-plan.md`](redesign/2026-iteration/state-and-plan.md)
first — cold-start briefing (ratified grammar, what shipped, known unbuilt
items, Gate-3 input).

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

**4.0 UI polish wave LANDED (2026-09-21, 79 commits):** full-app audit
(10 parallel area audits, all 274 UI files, ~120 verified findings) → one
fix wave, user-approved wholesale ("trust you on all"). Findings→fixes map,
ratified calibrations (green stays for online/reachable; hit-target fixes
must be visually invisible; paywall hero keeps bolt + headline), and known
leftovers (Gate-3 input):
[`redesign/2026-iteration/ui-polish-audit-2026-09-21.md`](redesign/2026-iteration/ui-polish-audit-2026-09-21.md).
Waves: A shell/theme wiring + shared kit (incl. `destructive`/
`destructiveText`/`info` status slots); B per-area (GlassBar on both
sub-page nav-bar wrappers, chat sheet chrome + color grammar, streaming
cockpit, home Connect morph, pro paywall entrances, statistics + settings
polish); C follow-ups. Gates: full suite green, analyze baseline.

**What to look at while dogfooding (user, phone + tablet — Settings →
Force Tablet Mode for phone-width):** sub-page nav bars (55pt + specular),
chat chrome (sheet handles, neutral Mod chip, count-up LIVE viewers,
device-code dialogs), streaming-mode cockpit (floating chrome, stale-aware
health pill, peak-hold meters), statistics (filter chips, chart draw-in,
count-up detail grid), settings (version stamp tap-to-copy, theme editor
captions), pro paywall (staged entrances, squircle hero). Then Gate 3:
fresh review of branch diff + on-device feel, **findings triaged to the
user BEFORE applying — standing rule** → merge or iterate.

**Astra ports status:** progressive adoption ratified; harvest phases
landed incl. command-ack layer, confirmed-state ordering, stale-state
honesty, chat independence (dedicated Chat tab; dashboard chat pane
removed), streaming cockpit, saved-connection refresh — all merged +
dogfood-approved (history: `changelog-agent.md` 2026-09-14→20).
inspect-vs-command/Take bar will NOT be ported (Studio Mode covers it).
Open follow-ups: conversation-owned drafts wave; optional live-session
strip; syncOffset gating.

**Immediate next threads (4.0):**

1. **User dogfood of the polish wave** (above) → Gate 3 → merge.
2. **Finish RevenueCat** (RTDN retry, sandbox dogfood §5, SBP enroll).
3. **Dogfood the Pro gate** via debug override (long-press paywall hero):
   gate flip mid-session, legacy persisted `SelectedChatEngine=native`
   boot path, settings row states.
4. **Android runtime smoke** (emulator/device) — toolchain builds since
   2026-09-07; confirm release AABs sign with the upload key
   (`android/key.properties` → `android-release.jks`, A6:24:44).
5. Release mechanics: version/changelog, store metadata
   (`fastlane/metadata`), visual-QA pass
   (`tool/visual_qa/capture_screenshots.sh`).
6. YouTube (post-4.0 ok): run the spike (`tool/youtube_spike/`, ≥30 min
   busy chat) with the GCP key; the `private/backend-architecture.md`
   OAuth note stays deferred — **sync private docs first**.

Process notes: `AGENTS.md` session-start checklist is resume-proof (run it
anyway). Default process tier **S**. Test gotchas are in
`changelog-agent.md`. `test/pro/` is the purchase/entitlement suite home.
Machine note (this box): **`/tmp` is a 3.8G tmpfs** — if it fills with
`flutter_tools.*` dirs, `flutter test` hangs silently in the kernel
compiler ("Free up space"); `rm -rf /tmp/flutter_tools.*` and re-run.
Always `flutter test -j 1` here; `flutter pub get` if a restored
`pubspec.lock` makes the tool re-resolve.

## Verify quickly

```bash
git checkout 4.0-liquid-glass && git pull   # 4.0 work lives here; master is untouched
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
| [`redesign/2026-iteration/ui-polish-audit-2026-09-21.md`](redesign/2026-iteration/ui-polish-audit-2026-09-21.md) | 4.0 polish wave: findings→fixes map, calibrations, Gate-3 leftovers |
| [`chat-native-roadmap.md`](chat-native-roadmap.md) | Native chat API roadmap — waves 1–3 shipped, gate decision + wave 4 next |
| [`redesign-astra-audit.md`](redesign-astra-audit.md) | Astra redesign audit + ratified progressive-adoption verdict, verified master defects, harvest list |
| [`superpowers/specs/2026-09-14-command-ack-layer-design.md`](superpowers/specs/2026-09-14-command-ack-layer-design.md) | Command-ack layer (astra phase 2) — ratified design, merged 2026-09-18 |
| [`superpowers/specs/2026-08-09-mod-overflow-options-design.md`](superpowers/specs/2026-08-09-mod-overflow-options-design.md) | Mod overflow into Options |
| [`superpowers/specs/2026-08-09-chat-notice-meta-design.md`](superpowers/specs/2026-08-09-chat-notice-meta-design.md) | Notice meta + announce chrome |
| [`superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md) | User card |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`revenuecat-setup.md`](revenuecat-setup.md) | Pro subscription wiring + sandbox dogfood |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
