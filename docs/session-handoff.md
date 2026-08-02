# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-08-02**.

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
| Branch | `redesign` (off `master`; `master` is current through the public-repo hygiene pass) |
| Users | 500k+ live — persistence + release paths are sensitive |

### Machines

| Host | Path | Role |
|---|---|---|
| **Headless** (NAS) | `~/agent/obs-blade` | `pub get` / `analyze` / unit tests only. **Never `flutter run`.** |
| **Workstation** (MacBook) | `~/development/flutter/obs_blade` | Same branch — simulator/device runs, integration tests, visual-QA screenshots. The heavy lifter for anything needing a running app. |

Do not commit/push unless the user explicitly asks.

## Right now

- **`redesign` branch: "On Air" visual overhaul — not committed/pushed yet,
  user reviews first.** Verification passing: `flutter analyze` 138
  issues/0 errors (master baseline 269), `flutter test test/chat
  test/websocket test/persistence` 38/38. Visual-QA round 2 complete with
  re-shoot verification. Full detail: [`redesign/session-notes.md`](redesign/session-notes.md)
  · design spec: [`redesign/design-system.md`](redesign/design-system.md) ·
  audit: [`redesign/audit-digest.md`](redesign/audit-digest.md).
- **Redesign follow-ups**, from session-notes.md: a motion pass on device
  for the connect-overlay success morph + confetti (not verifiable from
  static screenshots); `DashboardElementsOrder` (typeId 12) wiring is still
  dormant, needs maintainer sign-off before the dashboard actually reads it.
- **Chat Phase 1 (native Twitch)** — still paused, needs Twitch Developer
  app credentials (client id + redirect URI) from the user. Unchanged since
  Phase 0 (see `chat-webview-audit.md`).
- **Twitch developer application for the paid-tier OAuth broker** — separate
  from the chat item above, see `private/backend-architecture.md` component
  #4/#5. Identified as the longest-lead-time item for the paid backend work;
  **not yet actually started** — worth kicking off independent of build order.
- **NAS is currently synced to this branch via a git bundle, not a normal
  fetch** — `redesign` isn't pushed to origin yet. If it still isn't by the
  next session, re-bundle from the workstation rather than assuming a plain
  `git fetch` will see it.

## Verify quickly

```bash
# Headless (NAS)
cd ~/agent/obs-blade
~/flutter/bin/flutter test test/chat/ test/websocket/ test/persistence/

# Workstation (MacBook, login shell so PATH picks up Flutter)
cd ~/development/flutter/obs_blade
flutter test test/chat/ test/websocket/ test/persistence/
# Simulator: flutter devices && flutter run -d <sim-id>
# Visual-QA: tool/visual_qa/capture_screenshots.sh (keeps --no-uninstall)
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
| [`redesign/`](redesign/) | "On Air" redesign: design system, audit digest, session notes |
| [`private/monetization-strategy.md`](private/monetization-strategy.md) | Business model — pricing tiers, power-user/Studio revenue plan. **Gitignored.** |
| [`private/backend-architecture.md`](private/backend-architecture.md) | Infra plan for paid backend features. **Gitignored.** |
