# OBS Blade

Flutter remote for OBS Studio via **OBS WebSocket v5** (**iOS/Android — phone and
tablet / large-screen first-party**). Great UI on both form factors is a product
requirement, not an afterthought.
Repo: `Kounex/obs_blade` (**public**) · branches: `master`, `redesign`, `foss`, `legacy`.

> **Docs hygiene (public repo):** no credentials, personal absolute paths,
> device IDs, or LAN/WAN addresses in tracked files. Write docs and tooling so
> any contributor's agent can follow them; keep maintainer-specific setup
> notes clearly marked as such. **Non-public content** (business strategy,
> infra/security architecture) goes in `docs/private/` — gitignored, never
> committed. See `docs/session-handoff.md`'s hygiene section for how that
> stays in sync across machines despite not being in git.

## Start here (next session)

→ **[`docs/session-handoff.md`](docs/session-handoff.md)** — reset at every
handoff, holds only current state + immediate next steps. Read it before
trusting anything below to still be current.

## Agent constraints

- **500k+ live users** — treat persistence and release paths carefully.
- **`git fetch --all` before trusting this file or the handoff doc** — both
  are only as current as whoever last updated them remembered to make them.
  Diff your branch against its remote counterpart and skim recent log first.
- **Commit per verified unit** — after each finished, tested/analyzed piece
  of work, commit it as a small, logically-scoped commit without waiting to
  be asked. **Push when the user asks, and always at wrap-up/handoff** —
  the remote is the source of truth; never leave work local-only when
  handing over. Active branch:
  `master` (includes "On Air" redesign; pull/fetch before editing — see the
  handoff doc for exactly how current each machine's clone is).
- Keep this file short. Deeper notes live in [`docs/`](docs/).

### Maintainer's agent setup (Kounex-specific — external contributors can ignore)

- **Headless clone** (`~/agent/obs-blade`): `pub get` / `analyze` / unit tests
  only — **do not run the app**.
- **Workstation clone** (`~/development/flutter/obs_blade`): same branch;
  **simulator/device runs, integration tests, visual-QA screenshots** — the
  heavy lifter for anything that needs a running app.

## Quick map

| Area | Where |
|---|---|
| Entry / DI / Hive init | `lib/main.dart` |
| Tabs + routes | `lib/tab_base.dart`, `lib/utils/routing_helper.dart` |
| WebSocket session | `lib/stores/shared/network.dart`, `lib/utils/network_helper.dart` |
| Dashboard state | `lib/stores/views/dashboard.dart` |
| Protocol DTOs | `lib/types/classes/stream/` |
| Persisted models | `lib/models/` + `TypeIDs` |
| Stream chat (WebView + native Twitch) | `lib/views/dashboard/widgets/obs_widgets/stream_chat/` |
| YouTube video id helper | `lib/utils/youtube_video_id.dart` |
| Shared design system ("On Air") | `lib/shared/design/` |
| Responsive phone↔tablet swap | `lib/shared/general/responsive_widget_wrapper.dart` (width > `StylingHelper.max_width_mobile` **700**, or Settings → **Force Tablet Mode**) |
| Content column max width | `BaseConstrainedBox` / `kBaseConstrainedMaxWidth` **640** |

**Stack:** MobX + GetIt · **Hive CE** · freezed for nested OBS API objects.

**Layouts:** Use `ResponsiveWidgetWrapper` when mobile and tablet need different
composition (e.g. tabs vs side-by-side). Don’t phone-optimize the dashboard in a
way that regresses tablet. Details: [`docs/redesign/design-system.md`](docs/redesign/design-system.md)
§ Responsive layouts.

**OBS control:** official WebSocket **v5** only — typed subset under
`lib/types/` (see architecture doc). `DashboardStore` is a large intentional
monolith; don't split it unless asked.

**Chat:** Twitch has a native engine (device-code login + EventSub chat +
Helix send input — reads AND writes) next to the WebView embeds; a manual
WebView↔Native switch lives in the chat bar (`SelectedChatEngine`, default
WebView; availability seam: `nativeChatAvailableFor` in
`lib/models/enums/chat_engine.dart`). The native side renders in
`NativeChatWindow` (optional `input` slot docks the generic, Twitch-free
`NativeChatInput`; silent `user:write:chat` scope upgrade — pre-upgrade
sessions get a read-only lock strip). Role badges + per-category toggles
ship via `TwitchBadgeStore` + the native chat options sheet (per-platform
seam). Next: availability/entitlement gate, 7TV/BTTV, replies/announce —
see chat audit + handoff.

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
| [`docs/changelog-agent.md`](docs/changelog-agent.md) | History of agent changes (not the handoff doc — that's current-state only) |
| [`docs/local-obs-e2e.md`](docs/local-obs-e2e.md) | Local OBS ↔ simulator E2E loop (macOS) |
| [`docs/redesign/`](docs/redesign/) | "On Air" redesign (now on `master`): design system, audit digest, session notes |
| [`docs/private/monetization-strategy.md`](docs/private/monetization-strategy.md) | Business model — pricing tiers, power-user/Studio revenue plan. **Gitignored — not public.** |
| [`docs/private/backend-architecture.md`](docs/private/backend-architecture.md) | Infra plan for paid backend features — Hetzner hosting, build order, open decisions. **Gitignored — not public.** |

## Tooling

- **Maintainer headless host:** Flutter `~/flutter` (3.44.8) or `./flutterw` — no `flutter run`.
- **Maintainer workstation:** Flutter via `~/.dotfiles/flutter/sdk` — sims OK.
- **Local OBS E2E (macOS):** `tool/obs_local/obs_test_env.sh start` →
  `dart run tool/obs_local/ws_smoke.dart --password <obs-ws-password>` →
  `flutter run -d <sim-id>` → `… stop`. Details: `docs/local-obs-e2e.md`.
- **Visual-QA screenshots (macOS, booted sim):**
  `tool/visual_qa/capture_screenshots.sh` — runs
  `integration_test/screenshot_walk_test.dart`, writes PNGs to
  `/tmp/obs_shots/`. OBS ws password is read from the local OBS config at
  runtime, never from the repo. **Always keeps `--no-uninstall`** in the
  flutter test call — the default uninstalls the app afterwards and wipes
  the simulator's data container. Phone-width by default; for a large-screen
  smoke, enable Settings → **Force Tablet Mode** (or use a wide / iPad sim)
  and re-check dashboard Scene Items/Audio + Chat/Stats side-by-side.
- Branch: `master`

## Related

- `Kounex/obs_blade_page` — marketing site
- `Kounex/obs_station_server` — separate Twitch-era backend (historical)
