# Agent changelog

Running log of upgrade/migration work. Not store release notes.

## 2026-07-27

- Bumped `keyboard_actions` to `^4.2.1` — 4.2.0 breaks the iOS simulator
  build on Flutter 3.44 (`SemanticsConfiguration.isFocused` now `bool?`;
  fixed upstream in 4.2.1). First real device/sim build of the branch.
- Added local OBS ↔ simulator E2E loop on the MacBook
  (`docs/local-obs-e2e.md`): `tool/obs_local/obs_test_env.sh`
  (start/stop/status for the real OBS instance, reuses running OBS, minimizes
  window) + `tool/obs_local/ws_smoke.dart` (standalone Hello → Identify →
  Identified + GetVersion/GetSceneList/GetInputList probe mirroring
  `AuthenticationHelper` semantics; no new deps). Tests run against the
  existing `Untitled` profile/scene collection per user direction.
- Committed + pushed `chore/flutter-deps-upgrade` so MacBook
  (`~/development/flutter/obs_blade`) can mirror NAS for simulator testing.
- Folded MacBook-only order-list bottom padding (`kBottomNavigationBarHeight`)
  into the branch before push.
- Updated handoff/AGENTS for dual-machine roles (NAS = analyze/test; Mac = sim).

## 2026-07-25

- Cloned repo; lean `AGENTS.md` + `docs/`.
- Flutter **3.44.8** at `~/flutter`; branch `chore/flutter-deps-upgrade`.
- Migrated **Hive → Hive CE**; regenerated adapters; typeIds/fields verified.
- Built **foundation mock data** + committed `*.hive` boxes; open / cold-open /
  copy-reopen tests (`test/persistence/`).
- Classic **hive 2.2.3** writer (`tool/classic_hive_writer/`) → CE open proof
  (`classic_boxes/` + `hive_classic_to_ce_test.dart`); **17** persistence tests
  passing.
- Raised SDK to `^3.12.0`; bumped majors (get_it 9, fl_chart 1, slidable 4,
  plus packages, intl, …); replaced `qr_code_scanner` with `qr_code_scanner_plus`.
- `flutter analyze`: **0 errors**.
- Documented OBS WebSocket v5 architecture for agents
  (`docs/obs-websocket-architecture.md`): layers, handshake, request/event/batch
  patterns, inventories, DashboardStore role, legacy event-name pitfalls.
- **WebSocket connect harden:** conditional Identify auth, 10s staged handshake,
  `ConnectionAttemptResult` UX, `websocketUri` + domain default `ws://`, stream
  pump ownership, QR `obswss://`, FAQ + `docs/websocket-connect-audit.md`,
  `test/websocket/handshake_helpers_test.dart`.
- **DashboardStore WS audit** (`docs/dashboard-store-websocket-audit.md`): fixed
  `SceneListChanged` name, pause stats during collection change, lighter scene
  switch refresh, scoped scene-item enable updates, always track studio mode;
  requestStatus guards + safer UUID lookups on Get/batch handlers.
- **Chat WebView audit** (`docs/chat-webview-audit.md`): Twitch/YT/Owncast embed
  approach vs native EventSub/Helix / YouTube Live Chat APIs; recommended hybrid.
- **Chat Phase 0:** YouTube Live Chat API visibility check documented; fixed
  video-id parsing (`extractYouTubeVideoId`), WebView recreate-on-rebuild, dialog
  copy/validation; Owncast trailing-slash normalize. Tests in `test/chat/`.
- **Session close:** `docs/session-handoff.md` written for next agent; AGENTS.md
  points at it. Chat Phase 1 (native Twitch) parked pending Dev Console creds.
