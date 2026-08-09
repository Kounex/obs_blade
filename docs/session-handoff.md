# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-08-09** (user card
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

**User card wave shipped** on `master` (spec
[`docs/superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md),
plan [`docs/superpowers/plans/2026-08-09-chat-user-card.md`](superpowers/plans/2026-08-09-chat-user-card.md)).
Tier M: implementer subagent Tasks 1–5; gate fixes + docs in-session.
Gates: `flutter test test/chat/` → **347** green.

**Channel Mod actions sheet shipped** on `master` (`ChannelModSheet`:
clear, chat modes, shield, announce; entry via shield button + native
options sheet when moderating).

**Open: dogfood (user).** Fresh Twitch login (consent now includes
`user:read:subscriptions` + `moderator:read:followers`), then:

1. Tap a username/badges → card (avatar, created, follow/sub if scoped,
   LIVE messages from buffer).
2. Long-press a message in a modded channel → mod sheet; short tap body
   does not; links still open.
3. Header “connected” → your card + connection footer (uptime / logout).
4. Pre-upgrade token: fact rows that need new scopes simply omit.

**Also still open from earlier waves:** multi-chat dogfood checklist (see
`changelog-agent.md`); replies; store cut; entitlement gate.

**Process (tiers — S is the default):** see
[`docs/superpowers/plan-defect-checklist.md`](superpowers/plan-defect-checklist.md)
§0.

## Verify quickly

```bash
# Headless (NAS)
cd ~/agent/obs-blade && git checkout master && git pull
~/flutter/bin/flutter test test/chat/ test/websocket/ test/persistence/

# Workstation (MacBook, login shell so PATH picks up Flutter)
cd ~/development/flutter/obs_blade
flutter test test/chat/ test/websocket/ test/persistence/
# Simulator: flutter devices && flutter run -d <sim-id>
```

## Doc map

| Doc | Topic |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Short project rules + index |
| [`changelog-agent.md`](changelog-agent.md) | History of agent changes |
| [`superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md) | User card design |
| [`superpowers/plans/2026-08-09-chat-user-card.md`](superpowers/plans/2026-08-09-chat-user-card.md) | User card plan |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`private/`](private/) | Gitignored — monetization / backend |
