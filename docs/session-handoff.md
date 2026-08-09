# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-08-09 evening**
(workstation wrap-up; dogfood OK; push `master`).

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

**Native chat dogfood wave closed** on workstation (user happy with
current behavior). Shipped since last handoff baton:

- Channel Mod room sheet + adaptive bar entry; when shield doesn’t fit →
  combined options chip + featured Mod card in Options (mod-gated only).
  Spec: [`superpowers/specs/2026-08-09-mod-overflow-options-design.md`](superpowers/specs/2026-08-09-mod-overflow-options-design.md).
- Notice meta chips + announcement dual-rail chrome.
  Spec: [`superpowers/specs/2026-08-09-chat-notice-meta-design.md`](superpowers/specs/2026-08-09-chat-notice-meta-design.md).
- EventSub `session_reconnect` open-before-close; mid-`selectChannel`
  buffering so rows aren’t dropped.
- Mod long-press hold wash without eating username/link taps (local wash).
- Shared `NativeChatTextField`; InputDialog always uses validation
  controller.

**Next product threads** (no active WIP): replies; availability/entitlement
gate; anything left on the multi-chat dogfood checklist in
`changelog-agent.md`. Default process tier **S**.

**Cursor note:** visual companion under Cursor needs
`visual-companion-cursor` (foreground `--foreground` start) — bare
Superpowers `start-server.sh` dies when the shell exits.

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
| [`superpowers/specs/2026-08-09-mod-overflow-options-design.md`](superpowers/specs/2026-08-09-mod-overflow-options-design.md) | Mod overflow into Options |
| [`superpowers/specs/2026-08-09-chat-notice-meta-design.md`](superpowers/specs/2026-08-09-chat-notice-meta-design.md) | Notice meta + announce chrome |
| [`superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md) | User card |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`private/`](private/) | Gitignored — monetization / backend |
