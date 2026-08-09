# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-08-09** (multi-chat
wave shipped on `master`; dogfood open).

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

**Multi-chat wave shipped** on `master` (spec
[`docs/superpowers/specs/2026-08-09-multi-chat-design.md`](superpowers/specs/2026-08-09-multi-chat-design.md),
plan [`docs/superpowers/plans/2026-08-09-multi-chat.md`](superpowers/plans/2026-08-09-multi-chat.md);
Tasks 1–10 + wrap-up docs). Process: started tier M, dropped to S mid-wave
when secondary-model quota exhausted — see `changelog-agent.md` 2026-08-09
entry. Gates green at wrap-up (331 chat/ws/persistence tests).

**Open: dogfood (user, real Twitch).** Fresh Twitch login first (consent
now bundles 12 scopes — sanity-check readability), then spec §6:

1. Search-add a channel; add from moderated/followed; duplicates disabled.
2. Switch + history restore; badges/emotes correct per channel.
3. Chat (send + receive) in another channel.
4. In a modded channel: delete / timeout / ban — tombstones/purges both
   sides, no doubles.
5. Per-channel emote picker; deleted message with emotes renders dimmed.
6. Pre-upgrade token: search-only picker, no shields/actions, CTA shown.

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
