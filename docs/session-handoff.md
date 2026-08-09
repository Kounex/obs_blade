# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-08-09** (multi-chat
wave: Tasks 1–9 committed, Task 10 implemented-but-uncommitted, gates
pending — see "Right now").

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
  public). Git will never sync it. If you create or edit anything there,
  copy it to the other machine immediately:
  `scp docs/private/*.md macbook:~/development/flutter/obs_blade/docs/private/`
  (or NAS-ward: `scp docs/private/*.md nas:~/agent/obs-blade/docs/private/`).
  Same goes for any other file that's deliberately outside git — don't let
  state exist on only one machine.

## Workspace facts

| | |
|---|---|
| Remote | `Kounex/obs_blade` (**public**) |
| Branch | **`master`** (includes "On Air" redesign; `redesign` branch retained as history) |
| Users | 500k+ live — persistence + release paths are sensitive |
| Form factors | First-party **phone and tablet** — see `AGENTS.md` + `redesign/design-system.md` § Responsive layouts |

### Machines

| Host | Path | Role |
|---|---|---|
| **Headless** (NAS) | `~/agent/obs-blade` | `pub get` / `analyze` / unit tests only. **Never `flutter run`.** |
| **Workstation** (MacBook) | `~/development/flutter/obs_blade` | Same branch — simulator/device runs, integration tests, visual-QA screenshots. The heavy lifter for anything needing a running app. |

Commit per verified unit proactively (small, logically-scoped commits).
Push when the user asks, and always at wrap-up/handoff — the remote is the
source of truth; never leave work local-only when handing over.

## Right now

**Multi-chat wave in flight** — spec
[`docs/superpowers/specs/2026-08-09-multi-chat-design.md`](superpowers/specs/2026-08-09-multi-chat-design.md),
plan [`docs/superpowers/plans/2026-08-09-multi-chat.md`](superpowers/plans/2026-08-09-multi-chat.md)
(11 tasks). Process: tier M, but the implementer subagent died mid-Task-10
(secondary-model quota exhausted) → dropped to S in-session per tier
policy.

**State on `master` (all LOCAL-ONLY, not pushed):**

- Spec `855313a`, plan `cd3ed14`, Tasks 1–9: `6d719c9..7279de1`.
- **Task 10 (mod action sheet) implemented, UNCOMMITTED** in the working
  tree: modified `lib/stores/views/twitch_chat.dart`,
  `native_twitch_chat_view.dart`, `twitch_chat_message_row.dart`,
  `test/chat/support/fake_twitch_services.dart`,
  `test/chat/twitch_chat_store_test.dart`; new
  `lib/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/mod_action_sheet.dart`,
  `test/chat/mod_action_sheet_test.dart`.
- One compile error fixed post-mortem (`twitch_chat.dart` — `displayName`
  is `String?`, now `?? this.user!.login` fallback). After the fix:
  `flutter test test/chat/mod_action_sheet_test.dart
  test/chat/twitch_chat_store_test.dart` → **84/84 green**.
- Unrelated pre-existing churn: `android/.settings/org.eclipse.buildship.core.prefs`
  modified — leave it out of the Task 10 commit.

**Exact next steps (in order):**

1. Sanity-review the uncommitted Task 10 diff (`git diff`) against plan
   Task 10; check `twitch_chat.g.dart` — if MobX regen output is missing
   or stale, run `flutter pub run build_runner build
   --delete-conflicting-outputs`.
2. Gates: `flutter analyze` (0 errors; ≤6 pre-existing warnings) and
   `flutter test test/chat/ test/websocket/ test/persistence/` (all green).
3. Commit Task 10:
   `feat(chat): mod actions — delete/timeout/ban with local reconcile`.
4. End-review pass over the wave diff (`git diff 0a2f510..HEAD`) against
   the spec — tier-M reviewer remnant; secondary quota was exhausted, so
   self-review in-session and note that in the changelog.
5. Wrap-up docs: `docs/changelog-agent.md` wave entry + reset this
   handoff file (multi-chat shipped, dogfood open).
6. Push (handoff rule).

**Dogfood (user, real Twitch — after push):** fresh Twitch login first
(consent now bundles 12 scopes — sanity-check readability), then spec §6:
search-add a channel, add from moderated/followed, switch + history
restore, chat in another channel, delete/timeout/ban in a modded channel
(tombstones/purges on both sides, no doubles), per-channel emote picker,
pre-upgrade token degradation (search-only picker, no shields/actions).

**Previous wave:** actor-reveal dogfood (channel.moderate v2) **PASSED**
(user-verified 08-08/09). Earlier open threads from the send-input wave
(chat-only reconnect simulation, logout path) remain untouched — pick up
anytime, see git history for the 08-08 handoff text if needed.

**Next work after multi-chat dogfood:**

- Replies/announce — send polish (was queued behind the chat gate;
  multi-chat jumped the queue).
- Store cut — Android build/test + version/build-number bump first.
- Paid backend — OAuth broker registration still deferred; see
  `private/backend-architecture.md`.
- The availability/entitlement gate (`nativeChatAvailableFor` +
  auto-switch-on-login) — still the named next chat item.

**Process (tiers — S is the default):** size the process to the change.
S = implement directly in-session (no subagents/plan doc), TDD + gates
once. M = 1 implementer subagent + 1 end reviewer, prose mini-plan. L =
full SDD (verifier pass, per-task reviews, defect probes) — only on user
risk flag or genuine multi-day scope. Cost rules: gates once at wrap-up,
resume subagents for fix loops, terse reports, secondary model for all
dispatches (quota exhausted → drop a tier, don't run full pipeline on
primary). Policy + rationale:
[`docs/superpowers/plan-defect-checklist.md`](superpowers/plan-defect-checklist.md)
§0; defect probes + codegen rules §2–§4 apply to L waves; append new
ratified defect classes at wrap-up.

## Verify quickly

```bash
# Headless (NAS)
cd ~/agent/obs-blade && git checkout master && git pull
~/flutter/bin/flutter test test/chat/ test/websocket/ test/persistence/

# Workstation (MacBook, login shell so PATH picks up Flutter)
cd ~/development/flutter/obs_blade
flutter test test/chat/ test/websocket/ test/persistence/
# Simulator: flutter devices && flutter run -d <sim-id>
# Visual-QA: tool/visual_qa/capture_screenshots.sh (keeps --no-uninstall)
# Tablet smoke: Settings → Force Tablet Mode, confirm adjacent pairs side-by-side
```

## Doc map

| Doc | Topic |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Short project rules + index |
| [`changelog-agent.md`](changelog-agent.md) | History of agent changes (not this file) |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy + Phase 0/1+ |
| [`obs-websocket-architecture.md`](obs-websocket-architecture.md) | OBS WS v5 model |
| [`websocket-connect-audit.md`](websocket-connect-audit.md) | Connect gaps (mostly fixed) |
| [`dashboard-store-websocket-audit.md`](dashboard-store-websocket-audit.md) | DashboardStore event handling |
| [`persistence-risk.md`](persistence-risk.md) / [`hive-ce-source-audit.md`](hive-ce-source-audit.md) | Hive CE safety |
| [`upgrade-plan.md`](upgrade-plan.md) | Flutter/package bump status |
| [`local-obs-e2e.md`](local-obs-e2e.md) | Local OBS ↔ simulator E2E loop (macOS) |
| [`superpowers/plan-defect-checklist.md`](superpowers/plan-defect-checklist.md) | Process policy — tiers (§0, S default), verifier pass, defect probes, codegen checklist |
| [`superpowers/specs/2026-08-09-multi-chat-design.md`](superpowers/specs/2026-08-09-multi-chat-design.md) | Multi-chat design (approved) |
| [`superpowers/plans/2026-08-09-multi-chat.md`](superpowers/plans/2026-08-09-multi-chat.md) | Multi-chat implementation plan (11 tasks) |
| [`redesign/`](redesign/) | "On Air" redesign: design system, audit digest, session notes |
| [`private/monetization-strategy.md`](private/monetization-strategy.md) | Business model — pricing tiers, power-user/Studio revenue plan. **Gitignored.** |
| [`private/backend-architecture.md`](private/backend-architecture.md) | Infra plan for paid backend features. **Gitignored.** |
