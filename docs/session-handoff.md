# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-08-06** (send-input maintainer dogfood passed; chat-only reconnect simulation still open — see the send-input bullet).

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
  `docs/superpowers/`.
- **Native chat window (container UI) on `master`** (2026-08-05) — the
  native engine now renders inside `NativeChatWindow` everywhere it appears
  (mobile tab slot, standalone card, tablet card, streaming mode): inset
  pane, always-tappable status row ("Stream Chat" + connection state), and
  a connection sheet (healthy: account + ticking uptime; degraded: error +
  Retry/Log out; offline: Connect). `TwitchChatStore.chatConnectedAt`
  (in-memory) feeds uptime. Generic params only — the reuse seam for a
  future native YouTube engine. Dogfood passed after one fix round; gates
  145/145 + analyze clean. History in
  [`changelog-agent.md`](changelog-agent.md); spec/plan under
  `docs/superpowers/` (`2026-08-05-chat-container-ui*`).
- **Native Twitch chat Phase 2: role badges + visibility toggles on
  `master`** (2026-08-05) — `ChatMessageEvent.badges` modeled; session-scoped
  `TwitchBadgeStore` (GetIt) caches the Helix global + per-channel badge
  catalogs (fetched fire-and-forget on chat connect, cleared on logout);
  native rows render badge images before the username (channel catalog >
  global, unknown skipped silently); new native chat options sheet
  (per-platform seam) with 7 Twitch badge visibility toggles (default-on,
  persisted `twitch-chat-badge-*` Settings-box keys, live re-filtering).
  Gates green: 133/133 tests, analyze 0 errors + 6 pre-existing warnings.
  History in [`changelog-agent.md`](changelog-agent.md); spec/plan under
  `docs/superpowers/`. **Dogfood:** native bar on a narrow phone + larger
  text scale (the new 44pt options button densifies the right column);
  badge pop-in timing on a live channel (a beat after messages —
  intended); badge↔username spacing read (uniform `xs/2`).
- **Native chat send input on `master`** (2026-08-05) — native chat now
  reads AND writes: `NativeChatInput` dock (pill field + circular send,
  hard 500-char cap, spinner in flight, clears on success, failed sends
  keep the text, inline error line above the dock) in `NativeChatWindow`'s
  new `input` slot. **Silent scope upgrade** (`kTwitchChatScopes` +
  `user:write:chat`): nobody kicked out — pre-upgrade sessions get a
  read-only lock strip with "Re-login to chat"; `canWriteChat` gates on
  the persisted token scopes. Helix `TwitchMessageService` + guarded
  `sendChatMessage` (never throws); no optimistic insert — the sent
  message renders via the EventSub echo; 200-but-dropped surfaces inline
  (`drop_reason.code` → user copy, unknown codes show Twitch's own
  message — the DTO models it as the object it actually is after a
  post-review fix; a second fix keeps a cancelled re-login **upgrade**
  from claiming logged-out while the live session streams on). Widget is
  Twitch-free by design (reuse seam, same as the window). Gates: 168/168,
  analyze 0 errors + 6 pre-existing warnings. Commits `fdd539c..3f0cc56`;
  spec/plan `2026-08-05-chat-send-input*`; history in
  [`changelog-agent.md`](changelog-agent.md). **Maintainer dogfood passed
  2026-08-06** (send + EventSub echo + spinner/clear + cancelled-upgrade
  path all accepted). One scenario still open: chat-only reconnect could
  not be triggered — airplane mode kills LAN+WAN together so the
  dashboard's own reconnect state appears first, and revoking app access
  on the Twitch profile correctly logs out immediately (token invalid →
  nothing to reconnect). Maintainer to simulate separately: kill WAN
  (pull router uplink / DNS-block `eventsub.wss.twitch.tv`) while LAN to
  OBS stays up → chat should enter `reconnecting` via the keepalive
  watchdog (~30s) and recover on its own once WAN returns.

  **Next chat items:** availability/entitlement gate (plugs into
  `nativeChatAvailableFor`, brings auto-switch-on-login), 7TV/BTTV
  rendering, replies/announce as future send polish.
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
  window/container — **shipped 2026-08-05** (`NativeChatWindow`; send
  input docked at its bottom edge the same day); (b) badges — **shipped
  2026-08-05** (role icons next to names + per-category visibility toggles
  in the native chat options sheet); (c) 7TV/BTTV/FFZ emotes render as
  plain text today (graceful fallback, nothing breaks) — rendering them
  needs the third-party 7TV API, a product decision; (d) earlier review
  notes: revocation toast on forced logout, message dedup by `messageId`,
  revoked-refresh-token (Twitch 400) is kept-record mid-session and only
  wiped on next cold-start validate.
- **Next work is open** — pick up whatever is next (store cut, native chat
  availability/entitlement gate, 7TV/BTTV rendering, paid backend,
  opportunistic polish). Backend app (OAuth broker)
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
