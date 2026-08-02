# OBS Blade — Design Audit Digest (for redesign)

Condensed from 15 codebase audits (branch `redesign`, 2026-07). Purpose: everything a lead
designer needs to invent a new design system and restyle every screen **without reading the
codebase again**. File paths and API names are verbatim.

---

## 1. App purpose & flows

**OBS Blade** is a Flutter mobile remote control (iOS/Android, 500k+ users) for **OBS Studio**
via the **OBS WebSocket v5** protocol. Users connect to a running OBS instance on their network
and control scenes, audio, streaming/recording, and monitor stats from their phone.

**Main journeys:**

1. **First run**: native splash → `/intro` (4-stage onboarding: welcome → OBS version pick →
   confetti "party" or 3 install slides with forced 5s-per-slide reading locks) → gate flag
   `HasUserSeenIntro202208` → `/tabs`.
2. **Daily flow**: lands on Home tab → ConnectBox (Autodiscover WLAN scan / QR scan of
   `obsws://` URI / manual host+port+password) or a saved-connection card → global
   "Connecting…" overlay (≤5s) → success `pushReplacementNamed` to **Dashboard**.
3. **Dashboard** (core screen): status app bar (Live/Rec pulsing dots + elapsed timers),
   scene button grid (tap = switch program scene; studio mode adds preview + Transition),
   scene item & audio mixer panels, optional live scene preview (screenshot polling),
   stream chat WebView embed (Twitch/YouTube/Owncast), live stats pager. Overflow menu
   (⋯) holds stream/record/replay-buffer/virtual-cam/screenshot actions. Reconnect toast
   on connection drop.
4. **Statistics tab**: list of past stream/record sessions (sort/filter/paginate) → detail
   with 4 line charts (FPS/CPU/kbit/s/Memory) + aggregate numbers; favorite/rename/delete.
5. **Settings tab**: grouped list → Dashboard Customisation (Expose* toggles + element
   order editor), Custom Theme editor (paywalled "Blacksmith" IAP), True Dark/Reduce
   Smearing/Force-non-native-UI, Data Management (per-category wipes), Logs (filter/export),
   About/FAQ/Privacy, Support dialog (tips + Blacksmith purchase/restore).

Navigation shell: 3 tabs (Home/Statistics/Settings), each its own `Navigator` +
`HeroController` + `ScrollController` (`lib/tab_base.dart`); all in-tab pushes are
`CupertinoPageRoute` (iOS slide everywhere); tab re-tap pops or scrolls-to-top; Android back
pops in-tab or jumps to Home.

---

## 2. Global styling facts

### Theme factory (single source)
- `lib/app.dart` → `App._getCurrentTheme(Box settingsBox)` builds ONE `ThemeData`
  (`ThemeData.dark()` base by default, `light()` when custom theme has `useLightBrightness`),
  then a long `copyWith`. **No** `darkTheme`/`themeMode` (no OS auto dark/light), no `title`,
  no `pageTransitionsTheme`, no `scrollBehavior`, no localizations.
- Rebuilds: two nested `HiveBuilder`s (Settings box filtered to 5 theme keys + whole
  CustomTheme box) wrap `MaterialApp` → whole-app rebuild on any theme change; implicit
  ~200ms `AnimatedTheme` cross-fade.

### Default palette (hardcoded in `lib/utils/styling_helper.dart`)
- `primary_color` `#101823` (card/canvas/appBar base), `accent_color` `#FF4654` (red:
  switches/radios/checkboxes/buttonTheme), `highlight_color` = `CupertinoColors.systemBlue`
  (→ `colorScheme.secondary`: links, active tab, sliders, spinners),
  scaffold `#212123` (`'212123'.hexToColor()`), true-dark pure black, reduce-smearing
  `#050505`, `light_divider_color` `#6F6F6F`.
- Blur tokens: `opacity_blurry` 0.75, `sigma_blurry` 10 — app bars/tab bar/sheets translucent
  + `BackdropFilter` on Apple; forced opaque (`withOpacity(1.0)`) on non-Apple.
- `max_width_mobile` 700 (mobile/tablet breakpoint), `platformAwareScrollPhysics`,
  `isApple(context)` (reads `ThemeData.platform` — flippable via ForceNonNativeElements),
  `colorIsDark`, `lightenDarkenColor`, `surroundingAwareAccent` (contrast text on accent),
  `brightnessAwareOBSLogo`, `currentCustomTheme()` (reads Hive directly — non-reactive).

### CustomTheme persisted model (`lib/models/custom_theme.dart`, Hive **typeId 2**, fields 0–17)
Fields: `uuid`, `name`, `description`, `starred` (unused), `cardColorHex`, `appBarColorHex`,
`tabBarColorHex`, `accentColorHex`, `highlightColorHex`, `backgroundColorHex`,
`textColorHex` (**persisted but never consumed — keep field, don't wire or drop**),
`useLightBrightness`, created/updated dates, `customLogo` (base64 image shown in home app
bar), `logoAppBarColorHex`, `dividerColorHex`, `cardBorderColorHex` (BaseCard border @0.6
opacity). 4 built-ins with **fixed UUIDs** in `lib/utils/built_in_themes.dart` (Pure Indigo,
Bright Star — **has a 7-digit hex bug** `'34bafff'`, Red Underdog, Snowstorm).
Hex→slot mapping in `app.dart`: cardColorHex→cardColor/canvasColor/scheme.background;
highlightColorHex→colorScheme.secondary (via deprecated `ColorScheme.fromSwatch`);
accentColorHex→buttonTheme + toggleables (deprecated `MaterialStateProperty`);
appBarColorHex→appBarTheme @0.75 opacity; tabBarColorHex→cupertinoOverride barBackgroundColor
@0.75; dividerColorHex→dividerTheme.

### APIs widgets actually call (load-bearing conventions across ~94 files, 208 `Theme.of` calls)
- `Theme.of(context).cardColor` — the de-facto primary surface everywhere.
- `Theme.of(context).colorScheme.secondary` — active/highlight states.
- `Theme.of(context).buttonTheme.colorScheme!.secondary` — **legacy path** feeding
  `BaseButton` fills, `SelectableBox` selection, `BaseIconButton` (synthetic ButtonThemeData
  built at `app.dart:155`; must be migrated carefully or kept working).
- Text: `textTheme.headlineSmall` (card titles), `titleMedium`/`titleLarge` (list entries,
  stats), `labelLarge` (tile titles), `bodySmall` (ALL descriptions — only override is
  `grey[500]`), `labelSmall.copyWith(fontSize:…)` abused in intro.
- `CupertinoTheme.of(context).textTheme.navTitleTextStyle` + `.barBackgroundColor` — nav bars
  (incl. cross-theming hack where mobile TabBars reuse `cupertinoOverrideTheme.barBackgroundColor`).
- `StylingHelper` statics directly (blur tokens, divider color in charts/resize handle).
- `lib/types/extensions/string.dart` `hexToColor()`; `lib/types/extensions/color.dart`
  `toHex`/`lighten`/`darken`.

### Typography / feedback / platform
- **No text font bundled** — platform default typeface; only icon fonts in pubspec. Only
  textTheme override: `bodySmall: grey[500]`. `FontFeature.tabularFigures()` used on all
  numeric readouts (craft detail to keep). One hardcoded `fontFamily: '.SF UI Display'` in
  `support_header.dart` (breaks on Android).
- **Ripples globally disabled**: `splashColor`/`highlightColor` = `Colors.transparent` —
  pressed states hand-rolled per widget (mostly instant color swaps, many raw
  `GestureDetector`s with zero feedback).
- Layout constants: `kBaseCardBorderRadius` 12, `kBaseCardMaxWidth` 640
  (`lib/shared/general/base/card.dart` — also used by `ModalHandler` sheets),
  `kBaseConstrainedMaxWidth` 640. Signature look: flat elevation-0 cards, radius 12,
  hairline `BaseDivider` (dividerColor @0.4, thickness 0), translucent blurred bars.
- Platform adaptive: `StylingHelper.isApple` branches everywhere; user setting
  **ForceNonNativeElements** flips `ThemeData.platform`; **EnforceTabletMode** forces tablet
  layout in `ResponsiveWidgetWrapper` (breakpoint 700).
- Known inconsistencies: Material scaffold `#212123` vs Cupertino override `grey[900]`;
  `SettingsTabRoutingKeys.route` string-interpolation bug (works both sides, brittle);
  red-vs-blue split accent identity; un-overridden sub-themes (chips/dialogs/snackbars leak).

---

## 3. Per-scope digest

### 3.0 App shell & navigation (`lib/main.dart`, `lib/app.dart`, `lib/tab_base.dart`, `lib/purchase_base.dart`, `lib/utils/routing_helper.dart`)
- Boot: `runZonedGuarded`, GetIt lazy singletons (Network/Tabs/Intro/Home/Dashboard/
  Statistics/Logs stores), Hive init (9 model + 4 enum adapters, 10 boxes) **before**
  `runApp` → first frame already themed. `print` piped into persisted `AppLog` box.
- `TabBase`: per-tab `Navigator` (GlobalKeys in `TabsStore`), per-tab `HeroController`
  (`MaterialRectArcTween`), per-tab `ScrollController` passed via route `arguments`
  (views read it from `ModalRoute.settings.arguments` and forward it — **load-bearing**).
  `IndexedStack` tab swap = **zero transition**; stock `CupertinoTabBar` (translucent on
  Apple, opaque elsewhere); `PopScope(canPop:false)` back contract.
- `PurchaseBase`: IAP stream → pending overlay (10s), persists tips/`BoughtBlacksmith`,
  restore dialog via `RoutingHelper.tabBaseKey` (global overlay/dialog anchor).
- Routes: `/intro`, `/tabs` + per-tab tables in `RoutingHelper` (`StaticticsTabRoutingKeys`
  typo). Cross-tab push contract: Blacksmith "Forge Theme" pushes CustomTheme onto Settings
  navigator via `TabsStore.navigatorKeys`.
- Motion: intro `AnimatedSwitcher` 1s; global overlay fade+blur 250ms; re-tap scroll 250ms;
  `Fader` (build-time side effect); **absent**: tab transitions, theme-change lerp, ripples,
  branded boot motion.
- Top opportunities: M3 ColorScheme architecture preserving hex-slot mapping; custom animated
  tab bar (keep blur/back/re-tap contracts); overlay system glow-up (keep
  `showStatusOverlay` API + timing); `AnimatedTheme` cross-fade for theme swaps; explicit
  `pageTransitionsTheme`; deliberate press-feedback system; janitorial fixes (Bright Star
  hex, routing interpolation, scaffold mismatch, missing `MaterialApp.title`).

### 3.1 Theme & styling system (`lib/app.dart`, `lib/utils/styling_helper.dart`, `lib/utils/built_in_themes.dart`, `lib/models/custom_theme.dart`, `lib/shared/general/themed/*`, `lib/shared/general/flutter_modified/translucent_sliver_app_bar.dart`, `lib/views/settings/custom_theme/**`)
- Facts in §2. Wrappers: `ThemedCupertinoScaffold` (modal_bottom_sheet stacked modals),
  `ThemedCupertinoSliverNavigationBar`, `ThemedCupertinoButton` (color from
  `cupertinoOverrideTheme.primaryColor` = highlight), `ThemedRichText`,
  `TransculentCupertinoNavBarWrapper` (standard sub-page scaffold, ~14 screens),
  `TransculentSliverAppBar` (**1,274-line vendored SliverAppBar fork** adding blur; unused
  M3 .medium/.large variants; maintenance liability).
- Settings → Theme flows: True Dark toggles black scaffold; Reduce Smearing appears only
  under True Dark; both disabled while Custom Theme active (tap → InfoDialog). Custom Theme
  switch auto-selects first built-in if no `ActiveCustomThemeUUID`.
- ~69 hardcoded `Color(0x…)`/`Colors.x` sites in 28 files (status greens/reds, kPressedColor,
  kDialogColor, white refresh icon) — bypass custom themes.
- Motion: implicit AnimatedTheme 200ms; Hero on settings icons; `StatusDot` 4s pulse;
  `ScrollRefreshIcon` bounce; `SelectableBox` 300/50ms; **absent**: page transitions,
  staggered entrances, press-scale, picker motion.
- Top opportunities: explicit ColorScheme + ThemeExtension tokens (brand accent, blur,
  radius 12, width 640); real typography (keep grey-`bodySmall` semantic or sweep 48 files);
  motion layer (per-token theme lerp, staggered cards, spring press); theme-editor live
  preview; deliberate per-surface feedback; sweep deprecated APIs (`fromSwatch`,
  `buttonTheme`, `MaterialStateProperty`, `withOpacity`).

### 3.2 Intro / onboarding (`lib/views/intro/**`)
- Files: `intro.dart` (root, portrait lock on phones, stage `AnimatedSwitcher`),
  `widgets/getting_started.dart`, `version_selection.dart` (2 `SelectableBox`es),
  `twenty_eight_party.dart` (single confetti burst), `intro_slides/intro_slides.dart`
  (3-slide PageView, swipe disabled, 5s per-slide Next-lock with countdown ring),
  `slide_controls.dart`, `back_so_selection_wrapper.dart` (typo in filename).
- Entry: `/intro` unless `HasUserSeenIntro202208`; re-openable from Settings and after
  data wipe — **`manually: true` path is dead**: re-watch still imposes locks, exits to /tabs.
- Styling: body copy = `labelSmall.copyWith(fontSize:16/18)` (misuse); all-text
  `ThemedCupertinoButton`s (no CTA hierarchy); dot color pulled from
  `switchTheme.trackColor.resolve(...)` (fragile hack); duplicate conflicting
  `kIntroControlsBottomPadding` (24 vs 12).
- Motion: stage fade has `Interval(0.7,1.0)` → **~700ms dead black gap between stages**;
  staggered Faders only on stage 1; slide re-fades 750ms; single anticlimactic confetti puff;
  **absent**: hero/shared-element, logo animation, parallax, springs. `ConfettiController`
  never disposed.
- Top opportunities: fix stage-transition gap (fadeThrough/sharedAxis + staggered entrances
  everywhere); real CTA hierarchy (primary filled vs tertiary); type scale + spacing rhythm;
  version selection as hero interaction (big cards, spring selection); screenshots in device
  frames + expanding-dot indicator; real celebration moment (multi-burst confetti or success
  check — Lottie/Rive would be new dep); animated brand entrance.

### 3.3 Home / connection hub (`lib/views/home/**`)
- Files: `home.dart` (reactions: connect overlay, success route, OBS-terminated dialog;
  pull-to-refresh via `Listener.onPointerUp`), `widgets/connect_box/` (switcher_card with
  icon segmented control + animated title/body; `auto_discovery/` w/ isolate subnet scan,
  `SessionTile` expansion, 5 explanatory error states; `connect_form/` host/port/password,
  inline "Wrong password" via `StreamController<WebSocketCloseCode>`; `quick_connect/` QR
  camera sheet parsing `obsws://`), `refresher_app_bar/` (pinned stretchy
  `TransculentSliverAppBar`, expandedHeight 200, custom-theme logo or brightness-aware OBS
  logo, parallax+zoom+blur stretch), `scroll_refresh_icon.dart` (white circle arrow, pow-curve
  fade, haptic+bounce at threshold), `saved_connections/` (narrow: PageView carousel 0.75
  viewport / wide≥625px: Wrap; `ReachableBuilder` probes reachability in isolate, tri-state,
  reachable-first sort; `ConnectionBox` 250×180 card + pulsing `StatusDot`; `EditDialog`
  renames + migrates HiddenScene/HiddenSceneItem records; empty → `PlaceholderConnection`).
- Styling: theme-driven but hardcoded status green/red, white/black refresh icon (clashes
  with custom themes), magic numbers (250×180 cards, 0.75 carousel, 65px port field).
- Motion: SwitcherCard title/body AnimatedSwitchers (most deliberate); stretch/parallax app
  bar; refresh bounce+haptic; StatusDot pulse; ExpansionTile chevron; Faders; **absent**:
  Hero (logo→dashboard), carousel indicator/parallax, re-sort animation, in-button connect
  progress, any press feedback.
- Top opportunities: branded hero app bar (on-brand pull-to-refresh indicator replacing
  hardcoded white/black); connection cards as centerpiece (ambient reachability, press-scale,
  Connect button progress→success morph); unified motion tokens + staggered entrances +
  animated re-sort; restore tasteful press feedback; connect-form modernization; QR sheet
  branded reticle + animated result; type/spacing tokens.
- Keep: pull-to-refresh contract (threshold → release triggers refresh + mode reset),
  ConnectMode tri-state, close-code→inline-error branching, HiddenScene rename propagation,
  `Connection` Hive model untouched.

### 3.4 Dashboard part 1 — shell, status bar, scenes, preview (`lib/views/dashboard/dashboard.dart`, `widgets/status_app_bar/**`, `widgets/dashboard_content/{profile_scene_collection,scene_buttons,scene_preview}/**`)
- `dashboard.dart`: store init/reset, wakelock, reactions (save-connection prompt,
  OBS-terminated route-out, screenshot fullscreen); dead `DashboardScroll` InheritedWidget.
- `status_app_bar.dart`: pinned `TransculentSliverAppBar`; Close button, "Dashboard" title,
  Live/Recording `StatusDot`s, `GeneralActions` ⋯ menu (CupertinoActionSheet / bottom sheet;
  entries hidden when Expose* settings on), bottom `StreamRecTimers` (1s stats poll, tabular
  figures).
- `scene_buttons/`: wrap grid (≥3/row) or horizontalScroll mode; `SceneButton` =
  `SelectableBox`, selection border animates at **actual OBS transition duration** (signature
  detail); editSceneVisibility mode overlays eye badge, toggles persisted `HiddenScene`.
- `scene_preview/`: `CustomExpansionTile`-gated `Image.memory(gaplessPlayback)` screenshot
  polling; tap → black87 controls overlay (3s auto-hide) → fullscreen dialog; first-expand
  battery warning (`DontShowPreviewWarning`); streaming mode: drag-resizable (75–H/3).
- Styling: hardcoded Cupertino status colors, black preview surfaces; dual selection visuals
  (fill+border stacked AnimatedContainers); raw Material `DropdownButton` in
  TransitionControls vs `BaseDropdown` elsewhere; ad-hoc spacing.
- Motion: StatusDot pulse (recreated via `Key(isLive.toString())` — no color morph);
  transition-duration-linked selection; StudioModeTransitionButton fade+size 200ms;
  ReconnectToast fade+slide 500ms; **absent**: scene-switch press feedback, staggered
  entrances, preview placeholder→content crossfade, fullscreen hero, digit transitions.
- Top opportunities: scene switcher as hero (moving selection indicator, haptics, PVW/PGM
  broadcast language for studio mode); status bar → designed on-air cluster (LIVE/REC pill,
  animated color morph); preview upgrade (crossfade-in, hero to fullscreen, edge scrim);
  entrance choreography (one-shot, MobX-rebuild-safe); ⋯ menu → designed quick-action sheet
  (same action set/hiding rules); design tokens incl. theme-registered semantic status colors.

### 3.5 Dashboard part 2 — scene content (`widgets/dashboard_content/scene_content/**`)
- Tablet: Row of two fixed-400px BaseCards ("Scene Items", "Audio"); mobile:
  DefaultTabController + 300px scroll-locked TabBarView. `media_inputs.dart` = empty stub
  (never shipped, don't enable). `visibility_edit_toggle.dart` = dead code.
- Scene items: sorted desc by OBS index, group collapse (`displayGroup`), eye →
  `SetSceneItemEnabled` (group children use parent name; studio mode targets preview scene),
  filter icon → Cupertino sheet polling filters **every 500ms**, per-keystroke
  `SetSourceFilterSettings`. **Latent bug**: `filter_list.dart:72-74` `firstWhere` compares
  the item to itself (shadowed param) → can show wrong item's filters.
- Audio: Global/Scene sections (bold+underline headers — most dated element), live meter
  (50ms AnimatedContainer peak bar, 200ms AnimatedPositioned avg tick, first channel only),
  mute, `SetInputVolume` on **every** slider tick (no debounce — keep), optional sync-offset
  field (`ExposeInputAudioSyncOffset`).
- Hide mode: entered only from app-bar action (sets 3 edit flags at once); programmatic
  Slidable panes (50ms delay hack, gesture disabled); `HiddenSceneItem` persisted; hidden rows
  `Offstage`d. Scroll: `NestedScrollManager` overscroll hand-off (125px threshold, reads
  parent ScrollController from route arguments — **fragile but load-bearing**).
- Styling: 3 inconsistent color sources (colorScheme.primary, legacy buttonTheme smuggling,
  hardcoded destructiveRed/black); volume readout is linear multiplier not dB; slider
  active track deliberately transparent (meter container is the visual track).
- Top opportunities: audio mixer redesign (dB gradient meter, peak-hold, smooth decay,
  animated mute crossfade — derive colors from theme); ThemeExtension replacing color
  smuggling; scene-item tree design (animated groups, indent guides); purpose-built hide-edit
  mode (AnimatedSize, no Slidable hack); section-header + 8px spacing system (preserve
  NestedScrollManager contract); filter-sheet polish; designed empty/loading states.

### 3.6 Dashboard part 3 — obs_widgets + dialogs (`widgets/obs_widgets/**`, `widgets/dialogs/**`)
- Tablet: side-by-side "Chat" (750px) / "Stats" (650px) BaseCards; mobile: TabBar +
  720px scroll-locked TabBarView. Under hardcoded `'Widgets'` headlineMedium header.
- `stream_chat/stream_chat.dart`: WebView embeds (Twitch popout, YouTube live_chat, Owncast
  embed); hardcoded mobile-Safari UA, consent-banner-removal JS, keep-alive, keyed rebuild on
  type/username change (full reload flash), **pointer band 150–450px** freezes outer scroll
  (functional hack — replacement must preserve "scroll inside chat doesn't scroll page").
  `chat_username_bar.dart/` (dir named like a file): type dropdown (brand colors Twitch
  `0xFF6441a5`/YouTube red, YouTube beta warning `DontShowYouTubeChatBetaWarning`), username
  dropdown, Add|Edit|Delete row with VerticalDividers; 3 validated add/edit dialogs
  (`extractYouTubeVideoId` for YouTube).
- `stats/`: 3-page PageView (OBS/Stream/Recording) + SmoothPageIndicator; `StatsContainer`
  Wrap layout math; **`FormattedText` = disabled TextField abused as stat display** (used 30+
  times app-wide).
- **Dashboard layout customisation is dormant**: `DashboardElementsOrder` (List<DashboardElement>,
  Hive typeId 12) persisted by the settings Order view but **nothing in
  `lib/views/dashboard/` reads it** — layout is hardcoded in `dashboard_content.dart`. Editor
  also buggy (SceneItems listed 3×, `Text('PLACEHOLDER')`s, 5 elements render "Missing!").
  Redesign is free to define this feature; default order must equal `DashboardElement.values`.
- `dialogs/save_edit_connection.dart`: names connection, re-keys HiddenScene/HiddenSceneItem
  on rename.
- Motion: page dots, expansion chevron, dialog defaults, Fader validation errors; **absent**:
  stat value tweens, chat state transitions (blank flash on switch), loading skeletons.
- Top opportunities: stats → real telemetry tiles (count-up tweens, status accents, sparklines
  feasible from existing `streamData`/`recordData`); chat state-machine polish (branded empty
  states per platform, crossfade placeholder↔WebView, loading overlay via existing
  onProgress); username-bar modernization (keep Hive keys); kill magic geometry (750/650/720,
  pointer band); dialog motion system in `BaseAdaptiveDialog`; wire up (with team sign-off)
  or restyle-only the dormant reorder.
- Chat Hive keys to preserve: `TwitchUsernames`, `YouTubeUsernames`, `OwncastUsernames`,
  `Selected*`, `DontShowYouTubeChatBetaWarning`; `ChatType` enum (typeId 4). Native Twitch
  chat is a planned future phase → invest in chrome, not the WebView surface.

### 3.7 Statistics (`lib/views/statistics/**`)
- Landing `statistics.dart`: "Latest Stats." + "Previous Stats." cards, all sort/filter
  logic (`_sortPastStatsData`, `_filterPastStatsData`), ~50 lines commented mock data.
  **Landmine**: `GetIt.instance.resetLazySingleton<StatisticsStore>()` called **inside
  build()** (`statistics.dart:209`) — filter state resets on any rebuild (e.g. theme change);
  preserve or fix only with sign-off.
- Detail `statistic_detail/`: summary card, 4 `fl_chart` LineCharts (FPS green / CPU blue
  max 100 / kbit orange / Memory red — hardcoded accent colors), touch tooltips, "Some
  numbers" (9 aggregates as disabled TextFields), ⋯ menu (favorite/rename/delete → Hive).
- Sort/filter panel (14 controls): sort field + `OrderButton` (250ms rotation + haptic),
  name text, duration shorter/longer + amount + unit, date range (bottom-sheet pickers,
  **de_DE hardcoded formats**), favorites 3-state (bool-or-string key hack), type 3-state,
  page size 5/10/25/50, tristate unnamed checkbox (`Transform.translate(-14)` hack),
  "Default" reset, ON/OFF `FilterStatus` tag.
- Widgets: `StatsEntry` (nested Chip-in-Chip date pills, star overlay), `CardHeader` +
  `HeaderDecoration` (128px clipped offset decorative icon, no-op rotate), `PaginationControl`
  (⏮‹1/N›⏭, 64px). Dead: `EntryMetaChip`.
- Motion: detail push Cupertino slide; expansion + chevron; OrderButton rotation;
  FilterStatus crossfade; **absent**: ALL list transitions (instant cuts), chart entrance,
  hero entry→detail (HeroController exists, no Hero widgets), tap feedback, star animation.
- Top opportunities: charts as hero (gradient fills, draw-in animation, scrub with
  guide+haptic+readout — fl_chart supports all; keep 4 metric color identities + axis
  semantics); list life (staggered entrance, AnimatedSwitcher on page/sort change, animated
  star); hero transition entry→detail; detail layout (real stat tiles, per-metric chart
  theming); filter panel → modern surface (**all 14 controls + exact semantics survive**);
  entry card with sparkline (data already on model); designed empty states; safe cleanups
  (dead code, de_DE fix flagged as behavior change).

### 3.8 Settings core (`lib/views/settings/settings.dart`, `widgets/action_block.dart/`, `widgets/support_dialog/**`, `about/**`, `faq/**`, `privacy_policy/**`)
- `settings.dart`: sliver grouped list, 5 `ActionBlock`s (General/Dashboard/Theme/Misc./
  Support), live via HiveBuilder. Toggles persist SettingsKeys (WakeLock — immediately calls
  WakelockPlus if on dashboard; UnlimitedReconnects; StreamingMode; StudioMode;
  ForceTabletMode; TrueDark; ReduceSmearing; ForceNonNativeElements).
- `ActionBlock`/`BlockEntry`: iOS-style group (uppercase grey title above card, 44pt rows,
  32px icon wells, inset dividers, hardcoded `kPressedColor`, instant press swap, grey
  Material chevron). **BlockEntry is shared with dashboard_customisation** — restyle affects
  both. Its `Hero(tag: title)` is the app's **only Hero widget** — currently dead (no
  destination tags).
- `SupportDialog`: fetches ProductDetails (blacksmith, tip_1..3); spinner placeholders →
  priced buttons; tips gate pre-tip ConfirmationDialog (don't-show-again); "You tipped X"
  sums by **string-parsing localized prices** (fragile — keep); Blacksmith restore (10s
  overlay + 5s Hive check; success handled globally in `purchase_base.dart`); bought →
  "Forge Theme" pushes CustomTheme with `{'blacksmith': true}` after 350ms
  `ModalHandler.transitionDelayDuration`. `SupportHeader` = Transform.translate stack +
  hardcoded `.SF UI Display` + switchTheme.trackColor abuse.
- About: header (Kounex logo, w100/w300 weights, PackageInfo version), SocialBlocks
  (Twitter/LinkedIn/email/GitHub/Twitch), Credits → license modal (nested
  CupertinoModalBottomSheet on root navigator). FAQ/Privacy: icon+title headers + BaseCard
  rich text (EnumerationBlock bullets = 3× scaled middot hack).
- Inconsistencies: About uses ThemedCupertinoScaffold vs FAQ/Privacy plain Scaffold; landing
  large-title CupertinoSliverNavigationBar vs subpage static TransculentCupertinoNavBarWrapper
  (two navbar systems); leading icons monochrome vs accent social icons; icon sizes 28/26/30
  eyeballed.
- Motion: CupertinoPageRoute everywhere; instant BlockEntry press; **absent**: staggered
  sections, Reduce-Smearing row animation, support-dialog state transitions, SocialBlock
  feedback, haptics.
- Top opportunities: modern inset-grouped settings (squircle accent icon tiles, real press
  fade — keep theme slots); support dialog redesign (real header, skeleton loading,
  AnimatedSwitcher loading→priced→purchased; preserve purchase logic + `{'blacksmith':true}`
  arg exactly); delight layer (staggered sections, animated row insert); unify subpage headers
  + activate the dead Hero plumbing; named typography scale; credits search; micro-feedback
  (link press states, toggle haptics, real bullets).

### 3.9 Custom theme editor (`lib/views/settings/custom_theme/**`)
- `custom_theme.dart`: master "Use Custom Theme" switch (auto-selects first built-in),
  Predefined + Your Themes lists, Add Theme (Blacksmith IAP gate → SupportDialog; auto-opens
  editor when pushed with `{'blacksmith': true}` after 350ms).
- `custom_theme_list/`: `ThemeEntry` (tap=activate `ActiveCustomThemeUUID`, AnimatedSwitcher
  checkmark, Edit for user themes), `ThemeColorsRow` (7 ColorBubbles; **appBar missing**,
  textColor commented out).
- `add_edit_theme/`: name (unique among user themes) + description, `ThemeLoader` dropdown
  (copy config from built-in/user/base), `CustomLogoRow` (gallery → base64 Hive, shown in
  home app bar), logo bg color, "Is this a light theme?" switch, 8 color rows → ColorPicker,
  Delete (clears ActiveCustomThemeUUID if active), Save (`save()`/`add()`).
- `color_picker/`: non-dismissible sheet (buttons only); RGB⇄HSL segmented; hex field (6/8
  chars, counter, validated); per-channel sliders (HSL gradient tracks); Reset (confirm →
  `pop(true)` → row onReset). Contract: hex string out via onSave; `pop(true)` = reset.
- Styling: self-referential (editor re-skins itself live); magic numbers (64/75/192/128px);
  ColorBubble border width 0 (dead luminance border); transparent colors invisible (no
  checkerboard); copy typos ("cusotmise", "seperate"); dead `lightDivider` flag.
- Motion: checkmark fade+scale 200ms; framework modals; **absent**: **theme application is an
  instant whole-app hard cut** (biggest wow-gap), row press feedback, staggered entrances,
  picker tweens, selection morph.
- Top opportunities: live preview pane in editor (mini app-frame mock; zero data risk);
  theme entries as rich preview cards (incl. missing appBar color); animate the app-wide
  re-skin (300–400ms color crossfade = signature moment) + press-scale + morph checkmark;
  picker modernization (bigger targets, quick swatches, checkerboard, optional alpha already
  plumbed); editor IA (grouped sections, sticky preview); paywall/empty-state polish.
- Quirks to preserve/verify: deleting active theme → empty UUID → silent default fallback;
  divider reset uses light-divider constant; blacksmith auto-open depends on 350ms delay.

### 3.10 Data management, logs, dashboard customisation (`lib/views/settings/{data_management,logs,dashboard_customisation}/**`)
- Data Management: 8 category Clear entries (Saved Connections, Statistics, Hidden Scenes/
  Items, Twitch/YouTube Chats, Don't-ask-again, Logs) each with ConfirmationDialog; "All
  Data" danger block → double confirm (chained 350ms) → wipes boxes **preserving
  BoughtBlacksmith** → reset tab + root replace to Intro.
- Logs: explanation card (collapsible, color-coded levels), filter card (DateRange, level
  dropdown, amount 10/25/50/All, OrderButton), day-grouped list (`LogTile`: 102px date,
  pulsing StatusDot per level — **pulses forever on static data**, misleading). **Quirk**:
  `resetLazySingleton<LogsStore>()` inside build — filter resets on rebuild (preserve).
  Detail: expandable time-group cards (84px `[LEVEL]` column, color left border, stack
  traces), ⋯ menu: Export (merged JSON → share sheet) / Delete (confirm → pop).
- Dashboard Customisation: 8 Expose* toggles (`ExposeProfile`, `ExposeSceneCollection`,
  `ExposeStreamingControls`, `ExposeRecordingControls`, `ExposeReplayBufferControls`,
  `ExposeHotkeys`, `ExposeScenePreview` (default **true**), `ExposeInputAudioSyncOffset`);
  Order view: ReorderableListView (custom proxyDecorator elevation lift) persisting
  `DashboardElementsOrder`, Reset deletes key. Rough: `Text('PLACEHOLDER')`×2, 5 elements
  "Missing!", duplicate SceneItems config; previews (Profiles/Controls/SceneButtons mocks).
- Motion: expansion, OrderButton, reorder elevation, StatusDot pulse; **absent**: list
  insert/remove animation, entrances, scroll-linked nav bar, drag haptics/scale, success
  feedback after destructive actions.
- Top opportunities: order-view drag experience (faithful mini-mocks for all 10 elements,
  spring lift, haptics, AnimatedOpacity visibility); log-detail readability (level-tinted
  gutters, monospace collapsible stacks, timeline rail — keep grouping + export format);
  kill perpetual pulse (static dots or level-count bar); data-management IA (grouped danger
  list, isolated danger zone — keep double-confirm verbatim); log filter-bar modernization
  (same LogsStore API); scroll-aware nav bar + entrances (cross-scope decision); consistency
  (theme chevrons instead of hardcoded grey, retire CupertinoDropdown hack, fix non-Apple
  opaque nav bar).

### 3.11 Shared UI kit (`lib/shared/general/**`, 42 files — used by ~90 view files)
- `base/`: `BaseButton` (fill from legacy `buttonTheme.colorScheme.secondary`, contrast text
  via `surroundingAwareAccent`), **`BaseCard` (the core surface: radius 12, max 640,
  elevation 0, optional title+BaseDivider, custom-theme border @0.6, above/below slots)**,
  `BaseCheckbox` (haptic lightImpact — only haptic in kit), `BaseConstrainedBox`,
  `BaseDivider` (0.4 opacity hairline), `BaseDropdown`, `BaseIconButton` (GestureDetector, no
  feedback), `BaseAdaptiveSwitch` (Cupertino/Material; disabled-tap can explain via
  InfoDialog), `BaseAdaptiveTextField` + `CustomValidationTextEditingController`
  (submit-gated validation, error fades in, clears on edit), `BaseAdaptiveDialog` +
  `DialogActionConfig` (AlertDialog.adaptive, cardColor, elevation 0, don't-show-again
  checkbox → `onOk(bool)`), `AdaptiveDialogAction` (destructive red).
- `themed/`: `ThemedCupertinoScaffold`, `ThemedCupertinoSliverNavigationBar`,
  `ThemedCupertinoButton`, `ThemedRichText` — manually pipe Material theme into Cupertino
  widgets (Apple keeps 0.75 translucency; non-Apple forced opaque).
- Root: `AppBarActions` (⋯ → action sheet / bottom sheet), `CleanListTile` (labelLarge 16 +
  bodySmall), `ColumnSeparated` (dead `lightDivider` flag), `ConnectHostInput` (IP/Domain
  segmented + scheme dropdown), `CupertinoDropdown` (read-only CupertinoTextField stacked
  under Material DropdownButton — self-described "dirty workaround"),
  `CupertinoNumberTextField` (tabular, min/max clamp — **bug: max-clamp guarded by
  minValue != null**), `CustomCupertinoDialog`, `CustomExpansionTile` (expandable pkg + 200ms
  chevron + color tween), `CustomSliverList`, `DescribedBox` (fieldset, radius 8),
  **`FormattedText` (disabled TextField as stat display — 30+ uses)**, `HiveBuilder`
  (ValueListenableBuilder over Hive — the reactivity backbone), `KeyboardNumberHeader` (iOS
  Done bar, hardcoded RGBs), `NestedScrollManager` (125px overscroll hand-off),
  `QuestionMarkTooltip` (→ InfoDialog), `ResponsiveWidgetWrapper` (700px / EnforceTabletMode),
  `SocialBlock` (deep-link→web fallback, svg path commented out), `TagBox` (status pill,
  AnimatedContainer 200ms), `TransculentCupertinoNavBarWrapper` (standard subpage scaffold,
  ~14 screens), `date_range/` (From/To + `DatePickerSheet`; **de_DE hardcoded**),
  `enumeration_block/` (scaled-middot bullets), `flutter_modified/translucent_sliver_app_bar.dart`
  (1,274-line framework fork). Dead: `svg_path_widget.dart` (100% commented).
- Motion: expansion tile, TagBox/DescribedBox AnimatedContainers, framework sheets/dialogs;
  **absent**: press feedback on 3+ widgets, Hero, stagger, scroll-linked blur, motion tokens
  (ad-hoc 200/350/500ms), sheet drag-to-dismiss.
- Top opportunities: design-token layer under existing pipeline; interaction feedback
  everywhere (scale/fade pressed states); BaseCard as hero surface (keep 12/640 contract);
  motion system for expand/collapse + sheets (springs, drag dismiss, scroll-linked bars);
  form-control polish (animated focus/error, real CupertinoDropdown, FormattedText → stat
  readout with AnimatedSwitcher); unified dialog/sheet language (unused `kDialogColor`/
  `kDialogBlurAmount` 20 exist); formalize typography; extend haptics; housekeeping (dead
  files, re-fork vendored app bar).

### 3.12 Motion & overlay primitives (`lib/shared/animator/**`, `lib/shared/overlay/**`, `lib/shared/dialogs/**` + drivers `lib/utils/overlay_handler.dart`, `lib/utils/modal_handler.dart`)
- Animator: `SelectableBox` (fill crossfade 300ms default / dynamic OBS transition duration
  for scene buttons; 50ms border; no press feedback; dead `boxBorderAnimation` field),
  `OrderButton` (two controllers, 250ms easeOutCubic half-turn + haptic), `StatusDot`
  (infinite ping 4s loop), `Fader` (fade-in w/ delay; **`Future.delayed` inside build()**,
  no mounted guard), `FullOverlay` (black26 scrim + AbsorbPointer + 150×150 frosted card,
  blur 0→9σ + fade 250ms; no scale/slide).
- Overlay: `BaseProgressIndicator` (Material spinner + countdown / smoothed value via
  10ms `Timer.periodic` setState — janky, timer leak), `BaseResult` (static icon:
  Positive/Negative/Missing; **no animation**).
- Dialogs: `ConfirmationDialog`, `InfoDialog`, `InputDialog` (validated, destructive Cancel)
  — all on `BaseAdaptiveDialog`; don't-show-again → `onOk(bool)` persisted by callers.
- Drivers: `OverlayHandler.showStatusOverlay/closeAnyOverlay` — static singleton, **250ms
  delay buffer**, max-lifetime timer, `replaceIfActive`; `kShowDuration` 2000ms,
  `kAnimationDuration` 250ms — **timing contract load-bearing for MobX reactions in
  home.dart/purchase_base.dart**. `ModalHandler`: showFullscreen (Fader on black),
  showBaseDialog (`barrierDismissible` false default), showBaseBottomSheet (drag disabled,
  12px top radius), showBaseCupertinoBottomSheet (Apple blur); `transitionDelayDuration` 350ms.
- Flows: connect overlay (5s) → success close-immediately or negative result 2s; purchase
  pending 10s; quick-action result overlays; reconnect toast; ~25 destructive confirmations.
- Top opportunities: motion token layer FIRST (durations 50–4000ms + curves scattered);
  FullOverlay glow-up (spring scale 0.92→1.0, themed scrim — keep API + timing + AbsorbPointer);
  **BaseResult animated stroke-draw check/cross** (highest craft-per-effort — caps every
  connect/purchase/action flow); dialog visual language (12px radius system, entrance
  fade+scale — keep adaptive semantics + signatures); route status colors through theme
  extensions (custom-theme correctness); SelectableBox press-scale (keep dynamic duration
  binding); replace deprecated buttonTheme/MaterialStateProperty; BaseProgressIndicator →
  AnimationController + adaptive spinner (keep countdown contract); Fader build-side-effect
  fix (prerequisite for reliable staggers).

### 3.13 Cross-cutting animation & iconography (all of `lib/`, assets)
- See §4 (motion inventory) and §5 (assets). Key findings: **only 1 Hero in the entire app**
  (settings block icons, no destinations); 4 haptic call sites (all lightImpact); JamIcons
  font 896 glyphs / **9 real usages**; Material Icons ~139 call sites (49 files) mixed freely
  with CupertinoIcons 94 (35 files); no Lottie/Rive/SVG deps; dead `*_old.png` assets.
- Biggest gaps ranked: motion language/token layer; animated tab/root transitions +
  splash→app handoff; dashboard "alive" states (toggle celebrations, animated stat tickers,
  skeletons — keep scene-button duration binding); icon system unification (+ trim JamIcons);
  list/content entrances; micro-interaction pass (press-scale, richer haptics, morph
  reconnect pill); chart motion; intro cinematic refresh; hero moments (connection→dashboard,
  scene↔preview, swatch→editor); cleanup (dead assets, commented blocks, deprecated color
  paths).

### 3.14 State→UI bindings & user customisations (`lib/stores/views/dashboard.dart`, `lib/models/**`, `lib/types/enums/{settings_keys,hive_keys}.dart`, pubspec)
- `DashboardStore` (1,835 lines) = intentional MobX monolith (AGENTS.md: don't split); all
  OBS session + dashboard UI state (edit panes, `isPointerOnChat`, reconnect, studio mode).
  1s stats batch drives timers/charts — rebuild subtrees must stay cheap (Observer
  granularity; `InputVolumeMeters` high-frequency).
- Every user-facing customisation the redesign must respect: Expose* toggles (8, defaults:
  only ExposeScenePreview=true), DashboardElementsOrder (persisted, dormant), StreamingMode
  (layout swap + scroll lock), StudioMode, EnforceTabletMode, ForceNonNativeElements,
  TrueDark, ReduceSmearing, CustomTheme + ActiveCustomThemeUUID + BoughtBlacksmith,
  HiddenScene/HiddenSceneItem (per connectionName else host), chat keys, WakeLock (default
  true), UnlimitedReconnects, 9× `DontShow*` dialog-gate keys.
- Enum registry: `lib/models/type_ids.dart` typeIds 0–12 (**never reuse/renumber**);
  `DashboardElement` (typeId 12, 10 values — **append-only**, HiveField ordinals); `ChatType`
  (typeId 4); `SceneItemType` (Source/Audio keys hidden items per panel).
- `SettingsKeys`/`HiveKeys` string values = persisted contract; defaults must hold.
- Streaming-mode resizable preview height is session-only (persisting it would need a NEW
  key — don't rename existing).
- Top opportunities: modernize theme architecture on the persisted contract; make dashboard
  composition data-driven from DashboardElementsOrder (default = `DashboardElement.values`
  order = current hardcoded order → behavior-neutral); choreographed scene-switch/state
  motion; unify settings/theme-editor UX (live preview); replace fixed heights with real
  responsive system (keep 700px + EnforceTabletMode gating); extend existing motion
  primitives rather than replace.

---

## 4. Cross-cutting motion inventory

**Existing primitives** (`lib/shared/animator/`): `Fader` (fade-in w/ delay — build()
side-effect bug), `StatusDot` (infinite 4s ping), `OrderButton` (dual-controller 250ms
rotation + haptic), `SelectableBox` (300ms fill / 50ms border; dynamic OBS-transition
duration binding for scene buttons), `FullOverlay` (250ms fade + 0→9σ blur).

**Existing animated widgets**: `ReconnectToast` (fade+slide 500ms, two controllers),
`StudioModeTransitionButton` (fade+size 200ms), `SwitcherCard` (title/body AnimatedSwitcher),
`ScrollRefreshIcon` (pow-curve fade + bounce + haptic), `RefresherAppBar` (parallax + blur/
zoom stretch), `CustomExpansionTile` (200ms chevron + color tween), `SceneButton`
(transition-duration fill), `AudioSlider` meters (50/200ms), `ElementList` reorder
proxyDecorator, `ThemeEntry` checkmark (fade+scale 200ms), `TagBox`/`DescribedBox`
(AnimatedContainer 200ms), intro stage AnimatedSwitcher (1s, has 700ms dead gap), confetti,
SmoothPageIndicator dots, fl_chart tooltips, ScenePreview overlay (AnimatedOpacity 250ms;
dead `AnimatedScale(1.0)`), flutter_slidable panes (programmatic), BaseAdaptiveTextField
error Fader, FilterStatus crossfade, FullOverlay blur-in.

**Global motion gaps** (consensus across audits):
- Zero tab-switch transition; instant theme-application cut; hard splash→app cut.
- No ripples anywhere (globally disabled) + many raw GestureDetectors → app "feels dead".
- No list animations anywhere (no AnimatedList; no staggered entrances; instant cuts on
  sort/filter/page/reachability changes).
- No stat/value tweens (timers, stats, charts hard-swap); no chart entrance animation.
- Only 1 Hero widget (no destination); no shared-element transitions anywhere.
- No springs/physics; 15+ ad-hoc duration/curve combos (50/200/250/300/500/750/1000/4000ms ×
  linear/easeIn/easeOut/easeInQuad/easeOutCubic/bounceInOut) — no motion tokens.
- Dialogs/sheets = framework defaults; sheets not draggable; `BaseResult` icon static;
  `BaseProgressIndicator` Timer-driven (jank + leak).
- StatusDot pulses forever even on static log data (misleading).
- Only 4 haptic call sites (all `lightImpact`: checkbox, order buttons ×2, refresh icon).

---

## 5. Assets & dependencies

**Fonts** (pubspec): `assets/fonts/JamIcons.ttf` (896 glyphs, **9 real usages**: about,
privacy_policy, chat_type), `assets/fonts/CustomFlutterIcons.ttf` (**1 glyph**: Owncast logo).
**No text typeface bundled** — platform defaults everywhere; one `.SF UI Display` hardcode.

**Images** (`assets/images/`): `base_logo.png` / `base_logo_dark.png` (brightness-aware via
`StylingHelper.brightnessAwareOBSLogo`; intro, home app bar, license modal), `intro/*.png`
(3 OBS screenshots, dated Nov 2023), `kounex_logo_ai_no_background.png` (about),
`flutter_logo_render.png` (licenses). Custom user logo: base64 in Hive → `Image.memory`.
App icon/splash: `assets/icons/app/app_logo.png`, `app_logo_adaptive.png`, `splash.png`
(native splash color `#101823`). Dead: `*_old.png` ×3.

**UI-relevant deps** (pubspec): `fl_chart ^1.0.0` (only chart lib), `smooth_page_indicator`,
`expandable`, `flutter_slidable`, `modal_bottom_sheet`, `auto_size_text`, `keyboard_actions`,
`confetti ^0.8.0` (only particle effect), `cupertino_icons`, `flutter_native_splash`,
`webview_flutter` (chat), `qr_code_scanner_plus`, `image_picker`, `in_app_purchase`,
`wakelock_plus`, `share_plus`, `url_launcher`. State: MobX + GetIt. Persistence: Hive CE
(+ freezed for OBS API DTOs). **No Lottie/Rive/SVG/animations-package deps** — adding any is
a flagged decision.

---

## 6. Hard constraints — the redesign must NOT break

1. **Hive persistence (500k+ users)**: `lib/models/type_ids.dart` typeIds 0–12 never
   reuse/renumber; no field changes on `CustomTheme` (typeId 2, fields 0–17 — incl. dead
   `textColorHex`), `Connection`, `HiddenScene`, `HiddenSceneItem`, `PastStreamData`/
   `PastRecordData`/`PastStatsData`, `AppLog`, `DashboardElement` (typeId 12, append-only
   enum), `ChatType` (typeId 4). See `docs/persistence-risk.md`.
2. **SettingsKeys / HiveKeys string values + defaults** are persisted contract
   (ExposeScenePreview=true, other Expose*=false, WakeLock=true); all 9 `DontShow*` gates.
3. **Custom theme feature**: hex→slot mapping semantics (color-slot meaning changes visibly
   break saved user themes); 4 built-in UUIDs; base64 custom logos; TrueDark/ReduceSmearing
   disabled-while-custom-theme behavior; `ActiveCustomThemeUUID` lifecycle (auto-select,
   delete-clears); whole-app rebuild via HiveBuilder.
4. **Blacksmith IAP gate** on Add Theme: `BoughtBlacksmith` key, product IDs, pre-tip
   confirmation + don't-show-again, restore timing (10s overlay + 5s check), `{'blacksmith': true}`
   deep-link arg + 350ms delay, purchase stream handling in `purchase_base.dart`, tip-sum
   price parsing. Data Management full wipe **preserves BoughtBlacksmith**.
5. **Navigation contracts**: `TabsStore.navigatorKeys` (cross-tab push Blacksmith→CustomTheme),
   `RoutingHelper.tabBaseKey` (global dialog anchor), per-tab ScrollController passed via
   route arguments (tab re-tap scroll-to-top), PopScope back contract, `ActiveRouteObserver`,
   route names/arguments (`/tabs/statistic/detail` PastStatsData arg, LogDetail dateMS arg).
6. **Overlay/modal timing contracts**: `OverlayHandler.showStatusOverlay/closeAnyOverlay`
   API + 250ms delay buffer + showDuration + AbsorbPointer; `ModalHandler.transitionDelayDuration`
   350ms; `barrierDismissible:false` defaults; dialog `onOk(bool dontShowAgain)` signature.
7. **Behavioral semantics to preserve**: scene-button animation bound to OBS transition
   duration; `SetInputVolume` per-tick (no debounce); 500ms filter polling; 1s stats batch
   (cheap rebuilds); HiddenScene/HiddenSceneItem connection matching + rename re-keying
   (SaveEditConnectionDialog); `NestedScrollManager` 125px overscroll hand-off via route
   arguments; chat WebView internals (UA spoof, consent JS, keyed reload, 150–450px pointer
   band → "scroll inside chat doesn't scroll page"); pull-to-refresh threshold contract;
   ConnectMode tri-state; close-code→inline-error vs overlay branching; intro slide locks
   (5s) + `HasUserSeenIntro202208`; `ForceNonNativeElements`/`EnforceTabletMode` gating;
   `StylingHelper.isApple` adaptive branching; HiveBuilder reactivity (stats live-update
   while recording).
8. **Known landmines (don't "fix" silently)**: `filter_list.dart` firstWhere self-compare
   bug; `StatisticsStore`/`LogsStore` resetLazySingleton inside build(); Bright Star 7-digit
   hex; `CupertinoNumberTextField` max-clamp guard; Statistics reset-on-theme-change.
9. **DashboardStore stays a monolith** (AGENTS.md); motion hooks attach via existing
   MobX reaction/Observer patterns, not store refactors.
10. **WebSocket layer untouched**: all request payloads, batching, polling cadence,
    optimistic updates (`NetworkHelper`, `lib/types/`).
