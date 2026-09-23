# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-09-23** (native chat
gap audit — Twitch-parity + general enhancements — shipped and pushed, 17
commits. Details: `changelog-agent.md` 2026-09-23 "Native chat gap audit").

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

**Just closed: native chat gap audit.** User asked to audit Twitch's
native chat (most advanced engine) against Kick/YouTube and generally
enhance all 3 — approved the whole report ("everything", tier S) via
`AskQuestion`. All 17 items shipped, gated, committed, and pushed
(`3104eceb..22085b0f`); full writeup: `changelog-agent.md` 2026-09-23
"Native chat gap audit". `AGENTS.md`'s Chat/Kick chat/General native chat
paragraphs were updated to match (a couple of earlier commits in this same
wave — Kick emote picker, pin banner — had shipped without the doc update;
caught and fixed this pass). No open thread here; next session picks a new
priority (see below) or continues chat work if the user re-opens it (wave
4 / entitlement gate still pending per `chat-native-roadmap.md`).

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

1. **Finish RevenueCat** (RTDN retry, sandbox dogfood §5, SBP enroll).
2. **Dogfood the Pro gate** via debug override (long-press paywall hero):
   gate flip mid-session, legacy persisted `SelectedChatEngine=native`
   boot path, settings row states.
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
`test/websocket/state_ordering_test.dart` flake (intermittent, passes on
re-run; don't chase it as a regression). `test/pro/` is the
purchase/entitlement suite home.
Machine note (this box): **`/tmp` is a 3.8G tmpfs** — if it fills with
`flutter_tools.*` dirs, `flutter test` hangs silently in the kernel
compiler ("Free up space"); `rm -rf /tmp/flutter_tools.*` and re-run.
Always `flutter test -j 1` here; `flutter pub get` if a restored
`pubspec.lock` makes the tool re-resolve.

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
