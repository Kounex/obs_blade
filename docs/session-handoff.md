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
git checkout master && git pull
flutter test test/chat/ test/websocket/ test/persistence/
```

Maintainer: machine-specific verify, simulator, and visual-QA commands are
in `docs/private/maintainer-workflow.md`.

## Doc map

| Doc | Topic |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Short project rules + index |
| [`changelog-agent.md`](changelog-agent.md) | History of agent changes |
| [`superpowers/specs/2026-08-09-mod-overflow-options-design.md`](superpowers/specs/2026-08-09-mod-overflow-options-design.md) | Mod overflow into Options |
| [`superpowers/specs/2026-08-09-chat-notice-meta-design.md`](superpowers/specs/2026-08-09-chat-notice-meta-design.md) | Notice meta + announce chrome |
| [`superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md) | User card |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
