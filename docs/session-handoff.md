# Session handoff (for the next agent)

Read this first after `AGENTS.md`. Last updated: **2026-07-27**.

## Workspace facts

| | |
|---|---|
| Remote | `Kounex/obs_blade` (private) |
| Branch | `chore/flutter-deps-upgrade` — pushed; sync both machines from this branch |
| Users | 500k+ live — persistence + release paths are sensitive |

### Machines

| Host | Path | Role |
|---|---|---|
| **NAS** (this scratchpad) | `/home/kounex/agent/obs-blade` | `pub get` / `analyze` / unit tests — Flutter `~/flutter` **3.44.8**. **Never `flutter run`.** |
| **MacBook** | `~/development/flutter/obs_blade` | Same branch for **simulator / device** work. Flutter via `~/.dotfiles/flutter/sdk` (**3.44.0** as of sync). iPhone 17 Pro sim available. |

Do not commit/push unless the user explicitly asks. Prefer pull before editing so the
two clones stay aligned.

## What’s already done on this branch

Themes of work from 2026-07-25 sessions (committed 2026-07-27 for Mac sync):

1. **Hive → Hive CE** — adapters, typeIds **0–12** preserved, persistence tests +
   classic→CE open proof. Device open of a real long-lived install still deferred
   to the user before any store ship.
2. **OBS WebSocket connect harden** — conditional Identify auth, 10s handshake,
   `ConnectionAttemptResult`, `websocketUri`, stream pump ownership, QR `obswss://`.
3. **DashboardStore WS audit** — event name fixes, lighter scene refresh, scoped
   item updates, `requestStatus` guards. **Do not multi-store-split** unless asked.
4. **Chat Phase 0** — YouTube video-id parse + WebView lifecycle + dialog
   validation (see below).

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

- Before store release: user device-open of an upgraded long-lived install
  (see `persistence-risk.md`). Classic→CE unit proof exists; device proof doesn’t.
- Ask before further commit/PR; branch is already on origin for dual-machine sync.

### Other parked notes

- **Local OBS E2E loop (MacBook)** — real OBS + simulator testing:
  [`docs/local-obs-e2e.md`](local-obs-e2e.md) (`tool/obs_local/`).
- DashboardStore: keep monolith; optional `part` split only if asked.
- `freezed` may resolve to a `-dev` version (analyzer clash with
  `hive_ce_generator`) — see `upgrade-plan.md`.
- Odd path: `lib/.../stream_chat/chat_username_bar.dart/` is a **directory**
  named `*.dart`.

## Verify quickly

```bash
# NAS
cd /home/kounex/agent/obs-blade
~/flutter/bin/flutter test test/chat/
~/flutter/bin/flutter test test/websocket/
~/flutter/bin/flutter test test/persistence/

# MacBook (login shell so PATH picks up Flutter)
cd ~/development/flutter/obs_blade
flutter test test/chat/ test/websocket/ test/persistence/
# Simulator: flutter devices && flutter run -d <sim-id>
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
