# Session handoff (for the next agent)

Read this first after `AGENTS.md`. Last updated: **2026-07-27**.

## Workspace facts

| | |
|---|---|
| Remote | `Kounex/obs_blade` (**public** — keep tracked files free of credentials, personal paths, device IDs, LAN addresses) |
| Branch | `master` — upgrade batch (`chore/flutter-deps-upgrade`) **merged 2026-07-27**, branch deleted; new work on fresh branches off `master` |
| Users | 500k+ live — persistence + release paths are sensitive |

### Machines (maintainer-specific — external contributors can ignore)

| Host | Path | Role |
|---|---|---|
| **Headless** | `~/agent/obs-blade` | `pub get` / `analyze` / unit tests — Flutter `~/flutter` **3.44.8**. **Never `flutter run`.** |
| **Workstation** | `~/development/flutter/obs_blade` | Same branch for **simulator / device** work. Flutter via `~/.dotfiles/flutter/sdk` (**3.44.0** as of sync). iPhone simulator available. |

Do not commit/push unless the user explicitly asks. Prefer pull before editing so the
two clones stay aligned.

## What’s in the merged upgrade batch (now on `master`)

Themes of work from 2026-07-25/27 sessions (merged 2026-07-27):

1. **Hive → Hive CE** — adapters, typeIds **0–12** preserved, persistence tests +
   classic→CE open proof + **device proof on a real long-lived install**
   (2026-07-27, see `persistence-risk.md`).
2. **OBS WebSocket connect harden** — conditional Identify auth, 10s handshake,
   `ConnectionAttemptResult`, `websocketUri`, stream pump ownership, QR `obswss://`.
3. **DashboardStore WS audit** — event name fixes, lighter scene refresh, scoped
   item updates, `requestStatus` guards. **Do not multi-store-split** unless asked.
4. **Chat Phase 0** — YouTube video-id parse + WebView lifecycle + dialog
   validation (see below).
5. **Local OBS E2E loop** (macOS) + `keyboard_actions` 4.2.1 build fix +
   iOS toolchain migration (SwiftPM plugins, deployment target 13).

Docs under `docs/` describe each area. Changelog: `docs/changelog-agent.md`.

## Open / next work (priority)

### Chat — Phase 1 (paused here)

**Context:** Stream chat is still a WebView (Twitch popout / YT live_chat /
Owncast official embed). Full audit + YouTube API visibility:
[`docs/chat-webview-audit.md`](chat-webview-audit.md).

**Phase 0 done:**
- `lib/utils/youtube_video_id.dart` + `test/chat/youtube_video_id_test.dart`
- `stream_chat.dart` — controller once; reload only when URL changes
- YouTube add/edit dialog validates/persists bare video ids
- Owncast base URL trailing-slash normalize

**Recommended next (needs user):** Twitch Developer app credentials
(client id + redirect URI) → native chat UI shell + OAuth
(`user:read:chat` / `user:write:chat`) → EventSub receive + Helix send + emotes.
Keep YouTube/Owncast on WebView until Twitch native sticks. YouTube native is
API-feasible but Phase 4 (gRPC `streamList`, Google OAuth, quotas).

**Do not** start more JS injection into platform embeds.

### Persistence / release

- ~~Before store release: user device-open of an upgraded long-lived install~~
  **Done 2026-07-27** (see `persistence-risk.md`): real ~2.5y install upgraded
  on-device, data intact, CE read+write proven. Remaining before merge:
  Android build check (deferred by user), version/build-number decision.
- Ask before further commit/PR; work happens on branches off `master` (pull
  both machines first).

### Other parked notes

- **Local OBS E2E loop (macOS)** — real OBS + simulator testing:
  [`docs/local-obs-e2e.md`](local-obs-e2e.md) (`tool/obs_local/`).
- DashboardStore: keep monolith; optional `part` split only if asked.
- `freezed` may resolve to a `-dev` version (analyzer clash with
  `hive_ce_generator`) — see `upgrade-plan.md`.
- Odd path: `lib/.../stream_chat/chat_username_bar.dart/` is a **directory**
  named `*.dart`.

## Verify quickly

```bash
flutter test test/chat/ test/websocket/ test/persistence/
# Simulator (GUI machine): flutter devices && flutter run -d <sim-id>
# full analyze is noisy with infos; prefer scoped paths when editing
```

## Doc map

| Doc | Topic |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Short project rules + index |
| [`changelog-agent.md`](changelog-agent.md) | What agents changed |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy + Phase 0/1+ |
| [`obs-websocket-architecture.md`](obs-websocket-architecture.md) | OBS WS v5 model |
| [`websocket-connect-audit.md`](websocket-connect-audit.md) | Connect gaps (mostly fixed) |
| [`dashboard-store-websocket-audit.md`](dashboard-store-websocket-audit.md) | DashboardStore event handling |
| [`persistence-risk.md`](persistence-risk.md) / [`hive-ce-source-audit.md`](hive-ce-source-audit.md) | Hive CE safety |
| [`upgrade-plan.md`](upgrade-plan.md) | Flutter/package bump status |
