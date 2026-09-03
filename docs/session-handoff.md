# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-09-03** (NAS wrap-up;
native YouTube chat wave shipped, pending spike run + dogfood).

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

**Native YouTube chat wave shipped on `master`** (2026-09-03): engine
selectable in the chat bar (WebView↔Native), REST-poll timeline (Super
Chat/Sticker/membership/poll rows, tombstones, ban events), device-flow
sign-in for send + delete/timeout/ban, BYO-API-key setup sheet (reads are
BYO — quota is per-GCP-project), spike tool `tool/youtube_spike/` for the
gRPC `streamList` quota question. Details:
[`youtube-native-chat-audit.md`](youtube-native-chat-audit.md) +
[`changelog-agent.md`](changelog-agent.md) (2026-09-03 entry) + plan
`superpowers/specs/2026-09-03-youtube-native-chat-plan.md`.
**Not yet run against a live chat** — no GCP key exists yet.

Twitch wave 3 (mod tooling) shipped 2026-08-13 and was still **not
dogfooded** at that handoff; confirm before it goes stale.

**Immediate next threads:**

1. **GCP project setup** (maintainer, off-repo): create throwaway key →
   run the spike ≥30 min on a busy chat → record units/connection-hour in
   the audit doc. That number decides app-owned-key/default-on viability.
   OAuth client (TV/limited-input type) registration details belong in
   `private/backend-architecture.md` — **deferred: macbook was unreachable
   at wrap-up, private-doc sync would have stranded state on one machine.
   Sync first, then write it.**
2. **Dogfood YouTube native** on the workstation: real key + sign-in,
   poll cadence on a busy chat, Super Chat rendering, mod actions.
3. Twitch wave-3 dogfood (above), then availability/entitlement gate
   decision — gates Twitch wave 4 AND YouTube polish.

Process notes: `AGENTS.md` session-start checklist is resume-proof (run it
anyway). Default process tier **S**. Test gotchas are in
`changelog-agent.md`; new this wave: root `build.yaml` excludes `tool/**`
(standalone tool pb files broke app codegen), fake-client request-shape
tests can mirror a production bug (cross-check vendor docs).

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
| [`chat-native-roadmap.md`](chat-native-roadmap.md) | Native chat API roadmap — waves 1–3 shipped, gate decision + wave 4 next |
| [`superpowers/specs/2026-08-09-mod-overflow-options-design.md`](superpowers/specs/2026-08-09-mod-overflow-options-design.md) | Mod overflow into Options |
| [`superpowers/specs/2026-08-09-chat-notice-meta-design.md`](superpowers/specs/2026-08-09-chat-notice-meta-design.md) | Notice meta + announce chrome |
| [`superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md) | User card |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
