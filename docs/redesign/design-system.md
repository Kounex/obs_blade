# OBS Blade Redesign — "On Air" Design System

Branch: `redesign` · 2026-07-27 · Source audit: `docs/redesign/audit-digest.md`

## Concept

**"On Air" — a broadcast control room in your hand.** OBS Blade is a mission-control
tool for streamers on **phone and tablet**; the redesign leans into that identity:
layered studio-dark surfaces, signal-precise accents, glassy translucent bars, and
physics-feeling motion everywhere. We *evolve* the existing signature (flat 12-radius
cards, hairline dividers, blurred translucent bars, red/blue accent split) into a
deliberate system — we do not reskin into something unrecognizable. 500k users must
feel an upgrade, not a new app. Large-screen layouts (side-by-side scene/audio and
chat/stats) are first-party — not a stretched phone UI.

**Zero functional change.** Every capability, flow, Hive key, timing contract, and
customisation in the audit digest §6 is preserved. This is a visual/motion overhaul only.

## Hard rules (from audit §6)

- Hive models/typeIds/SettingsKeys frozen. `CustomTheme` hex→slot semantics unchanged:
  user-forged themes must render with the same meaning (card/appBar/tabBar/accent/
  highlight/background/divider/cardBorder/logo). `textColorHex` stays dead.
- Scene-button selection animation stays bound to the real OBS transition duration.
- Overlay/modal timing contracts (`OverlayHandler` 250ms buffer, `ModalHandler` 350ms)
  and APIs unchanged.
- No new package dependencies (no Lottie/Rive/google_fonts). All motion hand-rolled
  with the framework. No new persisted keys (except: none needed).
- `DashboardStore` stays a monolith; 1s stats rebuilds must stay cheap.
- Per-tab ScrollController-via-route-arguments and NestedScrollManager contract kept.

## Tokens (`lib/shared/design/` — new)

**`app_motion.dart`**
- Durations: `instant` 80ms (press), `fast` 150ms (micro), `medium` 250ms (standard,
  matches existing overlay timing), `slow` 400ms (entrances/theme), `dramatic` 700ms
  (celebration). Stagger step 30ms, max 12 items.
- Curves: `standard` = `Curves.easeOutCubic`; `emphasized` = `Cubic(0.2, 0.0, 0.0, 1.0)`;
  `spring` = `Curves.easeOutBack` (press/selection only); exit = `Curves.easeInCubic`.
- Rule: every new animation uses these; existing ad-hoc durations migrate when touched.

**`app_spacing.dart`** — 4px grid: `xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32.
Section labels get `lg` top rhythm. Existing layout constants (640 max width, 700
breakpoint) stay — see **Responsive layouts** below.

**`app_radius.dart`** — `sm` 8, `md` 12 (BaseCard contract), `lg` 16, `xl` 20, `pill`.

**Typography (`buildAppTextTheme`)** — platform typeface (no bundled font), defined scale:
- display 34/w700, title1 28/w700, title2 22/w600, title3 17/w600 (card titles),
  body 15/w400, callout 13/w400 (descriptions — replaces lone `grey[500]` bodySmall
  while keeping its color semantic), caption 11/w600 letterSpacing 0.8 uppercase
  (section headers), numeric readouts keep `FontFeature.tabularFigures()`.
- Mapped onto Material `textTheme` slots in `app.dart` so existing slot usages
  (headlineSmall, titleMedium, labelLarge, bodySmall…) get the scale automatically.

**Color** — slot semantics preserved; defaults refined in `styling_helper.dart` only
where they don't change saved-theme meaning: scaffold `#212123` stays, card `#101823`
stays, accent red `#FF4654` stays, highlight systemBlue stays. New `AppStatusColors`
`ThemeExtension`: live/stream green, recording red, warning amber, reachable states —
replaces ~69 hardcoded status colors (theme-aware derivation: on custom themes, status
colors stay constant, they're semantic not brand).

## Responsive layouts

OBS Blade is a **first-party phone and tablet** app. Prefer great UI on both; never
“ship phone and hope tablet stretches.”

| Mechanism | Where | Rule |
|---|---|---|
| Breakpoint | `StylingHelper.max_width_mobile` **700** | Width **>** 700 → tablet composition |
| Override | Settings → **Force Tablet Mode** (`EnforceTabletMode`) | Forces tablet branch even on narrow widths (QA + power users) |
| Swap widget | `ResponsiveWidgetWrapper` | Pass `mobileWidget` + `tabletWidget`; respects breakpoint + Force Tablet Mode |
| Content column | `BaseConstrainedBox` / `kBaseConstrainedMaxWidth` **640** | Keeps readable measure on very wide screens |

**Composition patterns (dashboard):**
- **Phone:** adjacent Scene Items + Audio (and Chat + Stats) compose into one **tabbed** block to save scroll. Separating them in Elements Order stacks them independently.
- **Tablet / large:** the same adjacent pairs compose into **side-by-side** cards (not stacked full-width tabs). Separated pairs still stack in list order.

When editing dashboard layout or the order feature, route through `ResponsiveWidgetWrapper` — do not collapse tablet to the mobile tab UI. Intro may portrait-lock phones only; tablets keep landscape.

## Motion language

- **Feedback everywhere**: new `Pressable` wrapper (scale 0.97 + opacity 0.88, 80–150ms,
  optional light haptic) replaces dead `GestureDetector` taps. Global splash stays off —
  feedback is physical, not ink.
- **Entrances**: `StaggeredEntrance` — one-shot fade + 12px rise, 30ms stagger,
  MobX-rebuild-safe (plays once per list identity, not on every Observer rebuild).
- **Transitions**: `pageTransitionsTheme` (keep Cupertino slide everywhere — it IS the
  app's feel; add subtle parallax via `CupertinoPageTransition` defaults — no change
  needed, just don't regress). Tab switches get a 200ms fade+scale via AnimatedSwitcher
  around the IndexedStack body (keeps per-tab navigators alive).
- **Theme change**: whole-app re-skin crossfades ~400ms (`AnimatedTheme` already
  implicit; ensure the MaterialApp subtree isn't rebuilt by key changes so the fade
  actually plays).
- **Signature moments**:
  1. `BaseResult` animated stroke-draw check/cross (caps every connect/purchase flow).
  2. Scene-button fill synced to OBS transition (existing — polish border + press).
  3. LIVE/REC status cluster: animated pill morph + elapsed timers with soft digit roll.
  4. Statistics charts: draw-in line animation + gradient area fill + scrub guide.
  5. Audio mixer: gradient dB meters, peak-hold ticks, smooth decay, mute crossfade.
  6. Connect overlay → success morph (FullOverlay spring scale 0.96→1.0, keep timing).
  7. Intro: fix 700ms dead gap; staggered entrances; real CTA hierarchy; celebration.
  8. Home pull-to-refresh stays (signature) — indicator themed, not hardcoded white/black.

## Surface language

- Cards: radius 12, elevation 0 (contract), hairline border from theme slot, subtle
  top-luminance step for raised surfaces (derived, not hardcoded).
- Bars: translucent blur on Apple (0.75/σ10 contract), opaque elsewhere.
- Section headers: caption style, uppercase, letterspaced, theme-aware grey.
- Status: pill clusters (LIVE/REC) with `TagBox` lineage; semantic colors via extension.
- Dialogs/sheets: unified radius (12 sheets / 16 dialogs), entrance fade+scale 250ms;
  keep `BaseAdaptiveDialog` API + adaptive semantics + `onOk(bool)` signature.

## Per-surface direction (summary for implementers)

- **Shared kit** (`lib/shared/**`): add design module; restyle internals of BaseButton/
  BaseCard/BaseIconButton/FormattedText (keep APIs; FormattedText gains animated value
  change); Pressable adopted; BaseResult animated; FullOverlay spring; fix `Fader`
  build side-effect; dialogs entrance motion.
- **Intro**: cinematic stages (no dead gap), staggered copy, primary CTA
  hierarchy, unified WS-setup + light app-tour slides (no OBS version fork).
- **Home**: branded stretchy app bar (themed refresh indicator), connection cards with
  press-scale + ambient reachability + connect-progress button, staggered entrances,
  animated re-sort.
- **Dashboard shell**: on-air status cluster in app bar, designed quick-action sheet
  (same entries/hiding rules), scene switcher with moving selection + haptics, studio
  mode PVW/PGM language, preview crossfade + hero-to-fullscreen.
- **Scene content**: audio mixer (gradient dB meter, peak hold, animated mute), scene
  item rows with press feedback + animated groups, keep NestedScrollManager.
- **Obs widgets**: stats as telemetry tiles (count-up tweens — cheap, 1s cadence),
  chat chrome polish + branded empty states + crossfade on reload (WebView internals
  untouched), kill dead PLACEHOLDERs only where purely visual.
- **Statistics**: chart draw-in + gradients + scrub, staggered list, animated star,
  stat tiles replacing disabled TextFields (keep `FormattedText` API or migrate
  call sites within scope), filter panel restyle — all 14 controls + semantics intact.
- **Settings**: inset-grouped modern sections, press fade, staggered sections,
  support dialog with loading skeleton + state AnimatedSwitchers (purchase logic
  untouched), subpage header unification.
- **Custom theme editor**: theme entries as preview cards (incl. appBar bubble),
  app-wide crossfade on activation, picker polish (checkerboard for transparent),
  editor section IA. Live-preview pane only if cheap — stretch goal.
- **Data mgmt / logs / customisation**: danger-zone IA (same double-confirm), log
  readability (level gutters, no perpetual pulse on static data — pulse only when
  "live"), order editor drag polish (spring lift + haptics).

## Verification

`./flutterw analyze` clean for touched files (infos OK pre-existing),
`./flutterw test test/chat test/websocket test/persistence` green, plus a manual
simulator pass on: intro, connect flow, dashboard (studio mode, hide mode), statistics
detail, custom theme forge + activate, settings toggles — **and** one wide / Force
Tablet Mode check that Scene Items/Audio and Chat/Stats stay side-by-side when adjacent.
