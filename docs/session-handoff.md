# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-08-04** (chat engine switch — on top of native Twitch chat Phase 1).

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

- **"On Air" redesign chapter closed** — merged into `master` (visual review
  accepted on MacBook). Design system lives under `lib/shared/design/`;
  depth in [`redesign/`](redesign/) + [`changelog-agent.md`](changelog-agent.md).
- **Native Twitch chat Phase 1 + chat engine switch on `master`**
  (2026-08-04) — Twitch app "OBS Blade Chat" registered 2026-08-04; OAuth
  device-code login + read-only EventSub chat rendered natively next to the
  WebView embeds. The chat control section is organized around a manual
  WebView↔Native engine switch (persisted `SelectedChatEngine`, default
  WebView — existing installs unchanged; availability seam
  `nativeChatAvailableFor` in `lib/models/enums/chat_engine.dart`). History
  in [`changelog-agent.md`](changelog-agent.md); specs/plans under
  `docs/superpowers/`. **Next chat items:** availability/entitlement gate
  for native chat (plugs into the seam, brings auto-switch-on-login),
  badges/role toggles, chat container UI (prelude to send input), 7TV/BTTV.
- **Maintainer dogfood 2026-08-04: mostly passed** — connect, messages,
  emotes, author colors, background recovery (observe long-term), Force
  Tablet Mode all good. Two UX gaps found + fixed same day (`b3f69d4`):
  inline "Copied to clipboard" feedback in the code dialog; logout is now a
  tappable account chip (icon + display name) in the username bar.
  **Still open: logout path itself untested** — incl. the post-logout
  WebView-fallback check (`_syncWebController` early-returns on unchanged
  URL, `stream_chat.dart:108-112`, so no `loadRequest` is re-issued on
  remount; fix only if the fallback renders blank).
- **Phase 2 input from dogfood (capture when planning):** (a) mobile chat
  needs a proper "window/container" UI — the Phase 2 send input field will
  live there anyway; (b) badges: users want role icons next to names
  (mod/VIP/subscriber/founder/bits/…), ideally per-category toggles —
  mechanics: EventSub `channel.chat.message` payload already carries a
  `badges` array (set_id/id, currently unmodeled), image URLs come from
  Helix *Get Channel Chat Badges* + *Get Global Chat Badges* (work with our
  user token), so it is a DTO extension + badge-image cache + settings
  toggles; (c) 7TV/BTTV/FFZ emotes render as plain text today (graceful
  fallback, nothing breaks) — rendering them needs the third-party 7TV API,
  a product decision; (d) earlier review notes: revocation toast on forced
  logout, message dedup by `messageId`, revoked-refresh-token (Twitch 400)
  is kept-record mid-session and only wiped on next cold-start validate.
- **Next work is open** — pick up whatever is next (store cut, Twitch chat
  Phase 2, paid backend, opportunistic polish). Backend app (OAuth broker)
  registration still deferred — see `private/backend-architecture.md`.
  Connect-overlay success morph is wired (Connecting… → check → Dashboard) —
  verified on device/sim 2026-08-04.
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
