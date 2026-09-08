# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-09-08** (pricing
finalized with cross-store parity, ASC products submitted for review,
Google package Registered; next: finish RevenueCat + drive the 4.0
release).

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
| Branch | **`master`** (includes "On Air" redesign; `redesign` branch retained as history) |
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

**Goal: ship 4.0.** Store products exist on both stores with locked,
fully regionalized pricing **$4.99/mo, $49.99/yr, $99.99 lifetime**
(2026-09-08): ASC 175/175 territories (equalized-tier fallback), Play
173/173 regions — Play is driven by Apple's equalized tier table per
currency by default (`tool/provisioning`: `play-products
--price-source apple`; details in `changelog-agent.md` 2026-09-08).
Tool suite: 49 tests.

**ASC products SUBMITTED for review (2026-09-08)** — review screenshots
uploaded for all three (spec gotcha + how-to in
[`revenuecat-setup.md`](revenuecat-setup.md) → Notes). Play products are
ACTIVE; their review rides the next app release. Watch ASC for approval
(24–48h typical).

**Google developer verification DONE:** `com.kounex.obsBlade` is
**Registered**. The upload key (A6:24:44, `android-release.jks`) is still
"in review" (justification route) — additive, blocks nothing. **After it
resolves (either way):** delete
`android/app/src/main/assets/adi-registration.properties` (untracked,
one-time registration token) and discard the Play internal-track draft
release `3.3.0 (2026090701)`. Pubspec build number stays `2026090701`.

**RevenueCat wired (2026-09-08):** products + entitlement `pro` +
offering exist dashboard-side, and the public SDK keys are pasted in
`lib/utils/revenuecat_config.dart` — the app now runs the RevenueCat
path by default on iOS/Android/macOS (`test/pro/` green, incl. the
reworked backend-selection fixture). Open:
1. Verify Play RTDN: test notification in Play Console was failing on
   Pub/Sub permissions (topic `projects/obs-blade/topics/Play-Store-Notifications`);
   service account is admin again — retry, allow propagation time.
2. Sandbox dogfood per [`revenuecat-setup.md`](revenuecat-setup.md) §5
   (live prices, buy → entitlement, reinstall restore, lapse revokes).
3. Apple Small Business Program: enroll on the Apple developer site
   (15% commission) if not yet done; Play's tiers are automatic.

**4.0 UI iteration (2026-09-08):** workflow spec ratified
([`superpowers/specs/2026-09-08-ui-iteration-4.0-design.md`](superpowers/specs/2026-09-08-ui-iteration-4.0-design.md))
— system-wide via tokens, **Liquid Glass** direction, everything on the
table (incl. CustomTheme re-mapping). **Phase 1 audit COMPLETE** (plan
`superpowers/plans/2026-09-08-ui-iteration-phase1-audit.md`): digest at
[`redesign/2026-iteration-audit.md`](redesign/2026-iteration-audit.md),
screenshots (untracked, contain LAN IPs) in
`docs/redesign/2026-iteration/before-{phone,tablet}/` — phone set has a
custom purple theme active, tablet set is the default-theme color
baseline. **Phase 2 IN PROGRESS** — companion server running (port in
`.superpowers/brainstorm/`, gotchas:
[`superpowers/visual-companion-gotchas.md`](superpowers/visual-companion-gotchas.md));
unified mockup shell `all-views-v4.html` (Connect/Scenes/Paywall/
Dashboard segments; user naming: "Dashboard" = NOT-connected connect
view, "Scenes" = connected control surface). Dashboard v2 restraint
language ratified by user; Scenes/Paywall/Connect v1 awaiting judgment
calls (neutral sliders, outlined hero logo, compacted wordmark). Full
Phase 2 state checkpoint: `.superpowers/sdd/progress.md` (gitignored).
Mockup builder: resume subagent agent-11. Before Phase 2 "after" captures:
fix the two pre-existing bugs the walk surfaced
(`text_field_date.dart:29` LateInitializationError + duplicate
GlobalKey; Tip Jar settings-row hit-test miss). Runner scheme no longer
has the StoreKit config attached (real sandbox dogfood); re-attach
temporarily for ASC-style paywall shots.

**Paywall bottom-clearance fix** (31e9dfb): sales scroll view now uses
the `CustomSliverList` tab-bar clearance formula — pattern to reuse for
any future non-sliver full-screen tab route.

**Immediate next threads (4.0):**

1. **Finish RevenueCat** (above) → sandbox dogfood per
   `revenuecat-setup.md` §5.
2. **Dogfood the Pro gate** on the workstation via the debug override
   (long-press paywall hero): gate flip mid-session, legacy persisted
   `SelectedChatEngine=native` boot path, settings row states.
3. **Android runtime smoke** (emulator/device) — toolchain builds since
   2026-09-07 (Gradle 8.14 / AGP 8.11.1 / KGP 2.2.20); runtime testing
   still open. Confirm release AABs sign with the upload key
   (`android/key.properties` → `android-release.jks`, A6:24:44).
4. Release mechanics: version/changelog, store metadata
   (`fastlane/metadata`), visual-QA pass
   (`tool/visual_qa/capture_screenshots.sh`).
5. YouTube (post-4.0 ok): GCP key exists
   (`~/.config/obs-blade/youtube-api-key.txt`); run the spike
   (`tool/youtube_spike/`, ≥30 min busy chat, record units into
   `youtube-native-chat-audit.md`). OAuth consent screen + TV client stay
   console-only. The `private/backend-architecture.md` OAuth note is
   **still deferred — sync private docs first**.

Process notes: `AGENTS.md` session-start checklist is resume-proof (run it
anyway). Default process tier **S**. Test gotchas are in
`changelog-agent.md`. `test/pro/` is the purchase/entitlement suite home.

## Verify quickly

```bash
git checkout master && git pull
flutter test test/chat/ test/websocket/ test/persistence/ test/pro/
```

Maintainer: machine-specific verify, simulator, and visual-QA commands are
in `docs/private/maintainer-workflow.md`.

## Doc map

| Doc | Topic |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Short project rules + index |
| [`changelog-agent.md`](changelog-agent.md) | History of agent changes |
| [`chat-native-roadmap.md`](chat-native-roadmap.md) | Native chat API roadmap — waves 1–3 shipped, gate decision + wave 4 next |
| [`superpowers/specs/2026-08-09-mod-overflow-options-design.md`](superpowers/specs/2026-08-09-mod-overflow-options-design.md) | Mod overflow into Options |
| [`superpowers/specs/2026-08-09-chat-notice-meta-design.md`](superpowers/specs/2026-08-09-chat-notice-meta-design.md) | Notice meta + announce chrome |
| [`superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md) | User card |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
