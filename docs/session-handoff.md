# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-08-03** (`redesign` → `master`).

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

Commit per verified unit proactively (small, logically-scoped commits);
push only when the user explicitly asks.

## Right now

- **"On Air" redesign chapter closed** — merged into `master` (visual review
  accepted on MacBook). Design system lives under `lib/shared/design/`;
  depth in [`redesign/`](redesign/) + [`changelog-agent.md`](changelog-agent.md).
- **Next work is open** — pick up whatever is next (store cut, Twitch, paid
  backend, opportunistic polish). Soft leftovers: Twitch Developer Console
  app registrations deferred (Chat Phase 1 + paid OAuth broker) — see
  `private/backend-architecture.md`. Connect-overlay success morph is wired
  (Connecting… → check → Dashboard) — verified on device/sim 2026-08-04.
- **Before a store release:** Android build/test, version/build-number bump
  (see earlier master notes in changelog).

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
| [`redesign/`](redesign/) | "On Air" redesign: design system, audit digest, session notes |
| [`private/monetization-strategy.md`](private/monetization-strategy.md) | Business model — pricing tiers, power-user/Studio revenue plan. **Gitignored.** |
| [`private/backend-architecture.md`](private/backend-architecture.md) | Infra plan for paid backend features. **Gitignored.** |
