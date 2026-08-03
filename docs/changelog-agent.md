# Agent changelog

Running log of upgrade/migration work. Not store release notes.

## 2026-08-03 (redesign finish batch)

- Stats entry→detail **Hero removed** (plain push); `HeroMode` workaround in
  paginated list gone with it.
- **Unified onboarding:** GettingStarted → WS setup + light app-tour slides;
  deleted OBS version fork (`version_selection`, `twenty_eight_party`,
  `back_so_selection_wrapper`). Screenshot walk updated.
- **Reorder previews** tightened to reuse real leaf widgets (`BaseCheckbox`,
  `BaseDropdown`, `BaseButton`, `StatTile`, scene-item/audio chrome).
- **`DashboardElementsOrder` wired** into live `DashboardContent` via
  `dashboard_element_layout.dart` — compose-when-adjacent (mobile tabs /
  tablet side-by-side for Scene Items↔Audio and Chat↔Stats).
- **Phone + tablet product rule** documented in `AGENTS.md` + design-system
  § Responsive layouts; order screen hint; Force Tablet Mode noted for QA.
- Verify: persistence/chat/websocket tests **38/38**; analyze 0 errors on
  touched paths. Not committed/pushed — user review first.

## 2026-07-27 (redesign branch)

- **"On Air" visual overhaul on branch `redesign`** (not committed/pushed — user
  reviews first). Full audit (15-agent swarm → `docs/redesign/audit-digest.md`),
  design spec (`docs/redesign/design-system.md`), session notes
  (`docs/redesign/session-notes.md`).
- New design module `lib/shared/design/`: motion/spacing/radius tokens,
  `AppStatusColors` ThemeExtension, app text theme, `Pressable`,
  `StaggeredEntrance`, `AnimatedResultIcon`, `CountUpText`.
- `lib/app.dart` theme factory modernized (real textTheme, pageTransitionsTheme,
  dialog/snackBar/chip sub-themes, status extension) — custom-theme hex→slot
  semantics and all persistence contracts unchanged; zero functional change rule.
- 11-agent restyle: shared UI kit, tab transition, intro cinematic, home,
  dashboard (on-air status cluster replaces `stream_rec_timers.dart`, audio
  mixer gradient meters, chat chrome), statistics (chart draw-in + gradients,
  staggered lists, hero entry→detail), settings (support dialog skeleton +
  icon tiles), custom theme editor (preview cards + 8th appBar bubble), data
  mgmt/logs/customisation (mock previews replace PLACEHOLDERs).
- Verify: `flutter analyze` 143 issues / **0 errors** (master baseline 269);
  `flutter test test/chat test/websocket test/persistence` 38/38; debug build on
  iPhone simulator (release/profile unsupported on this sim image).
- **Visual-QA round:** screenshot harness (`integration_test/screenshot_walk_test.dart`
  + `tool/visual_qa/capture_screenshots.sh`, `--no-uninstall` permanently after a
  sim-data wipe incident — see `docs/redesign/session-notes.md`); 37-shot walk
  incl. live dashboard via local OBS; 6-agent visual inspection (~90 polish
  findings); 8-agent fix swarm (overflow root causes, surface derivation, tab-bar
  unification, copy pass, subpage headers, intro slide frames, Connect button
  wrap, …). Post-fix: analyze 138 / 0 errors, tests 38/38, re-shoot for
  spot-check.

## 2026-07-27

- **Public-repo docs pass:** repo is public — scrubbed tracked files of the
  local OBS dev password, simulator UDID, username-absolute paths, and
  machine nicknames; generalized E2E/tooling docs so any contributor's agent
  can follow them; maintainer-specific machine notes marked as such. Rule
  recorded in `AGENTS.md` (docs hygiene).
- **Merged the upgrade batch to `master`** (fast-forward), deleted
  `chore/flutter-deps-upgrade` (local + origin). Docs now describe a
  master-based flow; open before store release: Android build/test,
  version/build-number bump.
- **Persistence device proof DONE** (release gate closed): master-era dev
  build over the App Store app on a real ~2.5y-old iPhone install (worktree
  `obs_blade_master_check` + 5 throwaway compile shims — master itself
  untouched), real boxes pulled via `devicectl` (`build/phone_backup/`),
  simulator rehearsal passed, CE profile build installed, user verified all
  data, CE write to `app-log.hive` proven. Learnings: debug builds crash on
  cold home-screen launch (flutter#149214) → use profile/release on device;
  `devicectl ... process launch --console` broken in this Xcode (error
  10002) → verify via process list + container pulls.
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
