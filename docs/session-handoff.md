# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-09-04** (NAS wrap-up;
Pro subscription gate wave shipped, pending store products + dogfood).

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

**Pro subscription gate wave shipped on `master`** (2026-09-04): native
chat engines (Twitch + YouTube) are entitlement-gated — chat-bar engine
switch lock badge + intercept, native-pane upsell, username-bar cluster
hidden, settings "OBS Blade Pro" row. Full-screen paywall at route `Pro`
(both tab navigators): benefits browser, yearly/monthly/lifetime pricing
from live `ProductDetails` with a deliberate placeholder state (the state
every user sees until products exist), explicit + guarded cold-start
restore, debug entitlement override (long-press hero, kDebugMode).
Entitlement = `ProStore.isPro` (`BoughtPro` box flag + debug override).
Details: plan `superpowers/specs/2026-09-04-pro-subscription-gate-plan.md`
+ [`changelog-agent.md`](changelog-agent.md) (2026-09-04 entry).
**Store products don't exist yet** — everything degrades gracefully;
nothing user-facing charges.

Native YouTube chat wave shipped 2026-09-03 (see changelog); **not yet
run against a live chat** — no GCP key exists. Twitch wave 3 dogfood also
still open since 2026-08-13.

**Immediate next threads:**

1. **Take Pro live** (maintainer): store products are scripted — run
   `tool/provisioning/` `asc-products` + `play-products` (creds: ASC `.p8`
   API key, Play service-account JSON; see its README), then the
   RevenueCat dashboard part of [`revenuecat-setup.md`](revenuecat-setup.md)
   (entitlement `pro`, offering, two public SDK keys into
   `lib/utils/revenuecat_config.dart`). **Attach `pro_lifetime` to the
   `pro` entitlement before flipping** or pre-RC lifetime buyers strand.
   Then sandbox-test purchase/restore/expiry-revocation.
2. **Dogfood the Pro gate** on the workstation via the debug override
   (long-press paywall hero): gate flip mid-session, legacy persisted
   `SelectedChatEngine=native` boot path, settings row states.
3. YouTube: GCP key is scripted too — `gcloud auth login` once on the
   NAS, then `tool/provisioning` `gcp-youtube`, then run the spike
   (`tool/youtube_spike/`, ≥30 min busy chat, record units into
   `youtube-native-chat-audit.md`). OAuth consent screen + TV client stay
   console-only. The `private/backend-architecture.md` OAuth note is
   **still deferred — macbook unreachable; sync private docs first**.

Process notes: `AGENTS.md` session-start checklist is resume-proof (run it
anyway). Default process tier **S**. Test gotchas are in
`changelog-agent.md`. `test/pro/` is the purchase/entitlement suite home
(no precedent existed before this wave).

**Cursor note:** visual companion under Cursor needs
`visual-companion-cursor` (foreground `--foreground` start) — bare
Superpowers `start-server.sh` dies when the shell exits.

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
