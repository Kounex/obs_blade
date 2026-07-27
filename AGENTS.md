# OBS Blade

Flutter remote for OBS Studio via **OBS WebSocket v5** (iOS/Android).  
Repo: `Kounex/obs_blade` · branches: `master`, `foss`, `legacy`.

## Start here (next session)

→ **[`docs/session-handoff.md`](docs/session-handoff.md)** — branch state, done vs
open work, chat Phase 1 pause point, verify commands.

## Agent constraints

- **500k+ live users** — treat persistence and release paths carefully.
- **NAS clone** (`~/agent/obs-blade`): `pub get` / `analyze` / unit tests only — **do not run the app**.
- **MacBook clone** (`~/development/flutter/obs_blade`): same branch; **simulator/device runs OK**.
- Keep this file short. Deeper notes live in [`docs/`](docs/).
- **Do not commit/push** unless the user explicitly asks. Active branch:
  `chore/flutter-deps-upgrade` (on origin; pull on both machines before editing).

## Quick map

| Area | Where |
|---|---|
| Entry / DI / Hive init | `lib/main.dart` |
| Tabs + routes | `lib/tab_base.dart`, `lib/utils/routing_helper.dart` |
| WebSocket session | `lib/stores/shared/network.dart`, `lib/utils/network_helper.dart` |
| Dashboard state | `lib/stores/views/dashboard.dart` |
| Protocol DTOs | `lib/types/classes/stream/` |
| Persisted models | `lib/models/` + `TypeIDs` |
| Stream chat (WebView) | `lib/views/dashboard/widgets/obs_widgets/stream_chat/` |
| YouTube video id helper | `lib/utils/youtube_video_id.dart` |

**Stack:** MobX + GetIt · **Hive CE** · freezed for nested OBS API objects.

**OBS control:** official WebSocket **v5** only — typed subset under
`lib/types/` (see architecture doc). `DashboardStore` is a large intentional
monolith; don’t split it unless asked.

**Chat:** WebView embeds today; Phase 0 hardened (parse + lifecycle). Next is
native Twitch (needs Dev Console credentials) — see chat audit + handoff.

## Docs index

| Doc | Use when |
|---|---|
| [`docs/session-handoff.md`](docs/session-handoff.md) | **Fresh agent** — resume state |
| [`docs/obs-websocket-architecture.md`](docs/obs-websocket-architecture.md) | How OBS WebSocket is modeled/used |
| [`docs/websocket-connect-audit.md`](docs/websocket-connect-audit.md) | Connect/handshake gaps + remediation |
| [`docs/dashboard-store-websocket-audit.md`](docs/dashboard-store-websocket-audit.md) | DashboardStore events/responses/batches |
| [`docs/chat-webview-audit.md`](docs/chat-webview-audit.md) | Twitch/YouTube/Owncast chat strategy |
| [`docs/upgrade-plan.md`](docs/upgrade-plan.md) | Flutter / package upgrade status |
| [`docs/persistence-risk.md`](docs/persistence-risk.md) | Hive CE, typeIds, shipping data safety |
| [`docs/hive-ce-source-audit.md`](docs/hive-ce-source-audit.md) | Classic Hive vs Hive CE on-disk audit |
| [`docs/changelog-agent.md`](docs/changelog-agent.md) | Session log of agent changes |
| [`docs/local-obs-e2e.md`](docs/local-obs-e2e.md) | Local OBS ↔ simulator E2E loop (MacBook) |

## Tooling

- **NAS:** Flutter `~/flutter` (3.44.8) or `./flutterw` — no `flutter run`.
- **MacBook:** Flutter `~/.dotfiles/flutter/sdk` (source `~/.zshrc` over SSH) — sims OK.
- **Local OBS E2E (MacBook):** `tool/obs_local/obs_test_env.sh start` →
  `dart run tool/obs_local/ws_smoke.dart --password 123456` →
  `flutter run -d <sim>` → `… stop`. Details: `docs/local-obs-e2e.md`.
- Branch: `chore/flutter-deps-upgrade`

## Related

- `Kounex/obs_blade_page` — marketing site  
- `Kounex/obs_station_server` — separate Twitch-era backend (historical)
