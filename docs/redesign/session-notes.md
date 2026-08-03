# Redesign session notes — branch `redesign` (2026-07-27)

What happened, in order, and what's worth knowing before continuing.

## Process

1. **Audit swarm** — 15 read-only agents covered every view, the shared UI kit,
   motion primitives, theme system, and state bindings. Raw output condensed into
   [`audit-digest.md`](audit-digest.md) (625 lines; read it before touching UI).
2. **Design spec** — [`design-system.md`](design-system.md): "On Air" concept
   (broadcast control room), token values, motion language, per-surface direction,
   hard rules (zero functional change; custom-theme hex→slot semantics frozen).
3. **Wave 0 (foundation)** — new `lib/shared/design/` module; theme factory
   modernized in `lib/app.dart`; `Fader` build-side-effect fixed; `BaseResult`
   animated stroke-draw; `FullOverlay` spring entrance.
4. **Wave 1** — 11 parallel agents restyled: shared kit, tab shell, intro, home,
   dashboard (3 scopes), statistics, settings core, custom theme editor,
   data mgmt/logs/dashboard customisation.

## The new design module (`lib/shared/design/`)

`AppMotion` (durations 80–700ms + curves), `AppSpacing` (4px grid), `AppRadius`,
`AppStatusColors` (ThemeExtension — replaces ~69 hardcoded status colors; access via
`Theme.of(context).extension<AppStatusColors>()!`), `buildAppTextTheme` (wired in
`app.dart`), `Pressable` (physical press feedback — global splash stays OFF by
design), `StaggeredEntrance` (one-shot, MobX-safe), `AnimatedResultIcon`,
`CountUpText` (cheap enough for the 1s stats cadence). Barrel: `design.dart`.

**Use these for any new UI.** Don't reintroduce ad-hoc durations/colors.

## Verification status

- `flutter analyze`: **143 issues, 0 errors** (master baseline: **269** — the
  redesign net-reduced lints; remaining are pre-existing infos/deprecations).
- `flutter test test/chat test/websocket test/persistence`: **38/38 pass**.
- Simulator smoke run: see changelog (debug build on iOS sim; release/profile not
  supported on this simulator image).

## Visual-QA round (round 2)

- **Harness**: `integration_test/screenshot_walk_test.dart` +
  `tool/visual_qa/capture_screenshots.sh` — walks every screen on a booted
  simulator (incl. real dashboard via local OBS), screenshots to `/tmp/obs_shots/`.
  **Always passes `--no-uninstall`** (flutter test defaults to uninstalling the
  app afterwards, which wipes the sim container — happened once; user data on the
  maintainer sim was lost; rule recorded in AGENTS.md Tooling).
- **Inspection**: 6-agent screenshot review (full-fidelity crops) → ~90 findings,
  mostly polish: token discipline, surface derivation, copy, affordance semantics.
  Root-cause highlights: fixed-height mobile containers (`obs_widgets_mobile`
  720pt → stats RenderFlex overflow + chat empty state below fold), two tab-bar
  languages on dashboard, `SubpageHeader` ignoring page margins, `IntroSlide`
  frame not hugging its image, saved-connection Connect button wrap (FittedBox
  lost in redesign), scaffold-colored wells on navy cards.
- **Fix swarm**: 8 parallel agents, all findings addressed or consciously
  deferred (noted in reports). Post-fix: analyze 138 issues / 0 errors,
  38/38 tests.
- **Re-shoot verification**: fixes confirmed on device captures — stats overflow
  gone, tab bars unified, subpage headers margined, intro frames hug images,
  filter well derived from card color, theme swatches single-row, About header
  composed. Two residuals fixed by hand: home fold (`RefresherAppBar`
  expandedHeight 200→160 so the first card clears the translucent tab bar at
  rest) and chat empty-state top padding (48→24 so it peeks above the fold).
- Known remaining: connect-overlay success morph + confetti not verifiable from
  statics (motion pass on device recommended); ~~statistics detail/log detail shots
  need real data~~ **resolved** (see below).

## Data restore (2026-07-27, late)

- Simulator data wiped by the `flutter test --uninstall` incident was **restored
  from the physical-device pull** (`build/phone_backup/Documents/*.hive`, from the
  persistence proof): all 10 boxes copied into the sim container. App boots clean —
  saved connections, statistics, logs, custom theme, and the Blacksmith flag are
  back. The restore also activated the user's real custom theme (Pure Indigo),
  which end-to-end validated the redesign's custom-theme hex→slot pipeline.
- Re-ran the walk with real data: new captures incl. `12_statistics_detail`
  (charts + gradient fills), `25_theme_editor`, `26_theme_color_picker`,
  `29_settings_log_detail`, populated `04_home_saved_connections` — the Connect
  button wrap fix is now verified against a real card.

## Device release build (2026-07-28, ~01:10)

- Release build installed + launched on the maintainer iPhone for manual testing.
- Two signing traps, fixed: (1) the Apple Development cert had **expired
  2024-11-14** — deleted it (`security delete-certificate -Z <sha1>`), fresh one
  created via Xcode → Accounts → Manage Certificates (GUI-only step);
  (2) first release build embedded a **`BuildMode=profile` Flutter.framework**
  (stale engine artifact, Info.plist modified post-sign → "integrity could not
  be verified" 0xe8008001). Fixed by `flutter clean` + rebuild; verified
  `codesign --verify --deep --strict` passes before installing.
- **Note:** `flutter clean` deletes `build/` incl. `build/phone_backup/` — keep a
  copy outside `build/` before cleaning (restored from `/tmp/phone_backup_safe`).

## Known deliberate deviations / notes

- `stream_rec_timers.dart` deleted — replaced by `status_app_bar/on_air_status_cluster.dart`
  (same timers, pill design). `entry_meta_chip.dart` deleted (was dead).
- Global `splashColor`/`highlightColor` remain transparent — feedback is physical
  (`Pressable`), not ink. This is intentional, don't "fix".
- Landmines from audit §6 were deliberately NOT fixed (filter_list firstWhere,
  resetLazySingleton-in-build, Bright Star hex, de_DE dates, tip-sum parsing).
- `DashboardElementsOrder` (typeId 12) **wired** in the 2026-08-03 finish batch
  (`dashboard_element_layout.dart`, compose-when-adjacent). Default order must
  still equal `DashboardElement.values` for upgrades with no saved order.
- textColorHex stays dead (persisted field, never consumed).
- **Parked 2026-08-03:** finish batch accepted on MacBook; stay on `redesign`
  until a deliberate `master` merge. Soft follow-ups: connect-overlay motion
  pass; Twitch console registrations (deferred).
